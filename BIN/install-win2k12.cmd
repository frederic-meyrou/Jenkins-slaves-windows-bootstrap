@echo off
TITLE Automatic Installation Slave Jenkins for Windows 2008/2012
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Installation Slave Jenkins x86 - W2K8/12-64 bits
REM For New HCIS Platform
REM V1.0 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------

REM ---------------------------------------------------------------------------------------------------------------
REM  Check time service
REM ---------------------------------------------------------------------------------------------------------------

echo ... Check NTP service
W32tm /query /status >> %ERRORLOG%
IF NOT %ERRORLEVEL% == 0 (
  echo ... WARNING! NTP time service is not configured, please contact ICS\ALM for further assistance.
  echo ... WARNING! NTP time service is not configured, please contact ICS\ALM for further assistance. >> %ERRORLOG% 
  pause
  popd
  exit 1
)

reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters | findstr /I "time.windows.com" >> %ERRORLOG% 2>>&1
IF %ERRORLEVEL% == 1 (
  rem reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" /v NtpServer /t REG_SZ /d time.windows.com /f 2>> %ERRORLOG% 
  echo ... WARNING! NTP time service is not configured, please contact ICS\ALM for further assistance.
  echo ... WARNING! NTP time service is not configured, please contact ICS\ALM for further assistance. >> %ERRORLOG%
  reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters | findstr /I "NtpServer" >> %ERRORLOG% 
  pause
  popd
  exit 1
)

rem -- Make sure server is on time
w32tm /resync

REM ---------------------------------------------------------------------------------------------------------------
REM  SETUP Services Timeout to 60s instead of 30s
REM  https://support.microsoft.com/en-us/kb/884495
REM ---------------------------------------------------------------------------------------------------------------

echo ... setup Services Timeout
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control" /v ServicesPipeTimeout /t REG_DWORD /d 60000 /f 2>> %ERRORLOG%

REM ---------------------------------------------------------------------------------------------------------------
REM  Stop Jenkins Service
REM ---------------------------------------------------------------------------------------------------------------

REM -- Stop Jenkins service in order to eventually update JDK
echo ... Stop Jenkins service if any
sc stop %SERVICE_NAME% > NUL 2>&1

REM ---------------------------------------------------------------------------------------------------------------
REM  Install Java and Git 
REM ---------------------------------------------------------------------------------------------------------------

echo ... Install/Update Java JDK and mSysGit
:JAVA
echo ... Install Java JDK 1.8
IF NOT EXIST %LOCAL_TOOLS%\JDK1.8 MKDIR %LOCAL_TOOLS%\JDK1.8\ 2> NUL
XCOPY /E/I/Q/H/K/Y %MASTER_DRIVE%\INSTALL\jdk-8u51-windows-x64\*.* %LOCAL_TOOLS%\JDK1.8\
SET JAVA_HOME=%LOCAL_TOOLS%\JDK1.8
PATH %LOCAL_TOOLS%\JDK1.8\bin;%PATH%

where java >> %ERRORLOG% 2>>&1
IF %ERRORLEVEL% == 1 (
  echo ... WARNING! Java is not installed, please contact ICS\ALM for further assistance.
  echo ... WARNING! Java is not installed, please contact ICS\ALM for further assistance. >> %ERRORLOG%
  pause
  popd
  exit 1
)

echo ... Setup Java security
mkdir %WINDIR%\Sun\Java\Deployment 2> NUL
XCOPY /E/I/Q/H/K/Y %MASTER_DRIVE%\INSTALL\java-config\*.* %WINDIR%\Sun\Java\Deployment

:GIT
echo ... Install mSysGit
REM -- Setup LOCAL_TOOLS Path in configuration file
XCOPY /Q/Y %MASTER_DRIVE%\INSTALL\Git.conf %LOCAL_TOOLS%
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%LOCAL_TOOLS%\Git.conf" "@LOCALTOOLS@" "%LOCAL_TOOLS%" >> %ERRORLOG% 2>>&1
REM -- Start Silent install
%MASTER_DRIVE%\INSTALL\Git-2.6.3-64-bit.exe /SILENT /SUPPRESSMSGBOXES /NORESTART /NORESTARTAPPLICATIONS /NOCLOSEAPPLICATIONS /LOADINF=%LOCAL_TOOLS%\Git.conf  2>> %ERRORLOG%
echo %ERRORLEVEL% >> %ERRORLOG%
PATH %LOCAL_TOOLS%\Git-2.6.3\bin;%PATH%

where git >> %ERRORLOG% 2>>&1
IF %ERRORLEVEL% == 1 (
  echo ... WARNING! Git is not installed, please contact ICS\ALM for further assistance.
  echo ... WARNING! Git is not installed, please contact ICS\ALM for further assistance. >> %ERRORLOG%
  pause
  popd
  exit 1
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Install SVN Client
REM ---------------------------------------------------------------------------------------------------------------

echo ... Install/Update SVN Client
:SVN
%MASTER_DRIVE%\INSTALL\CollabNetSubversion-client-1.8.14-1-x64.exe /S /Answerfile=%MASTER_DRIVE%\INSTALL\collabnetSVN.conf /D=%LOCAL_TOOLS%\SVN_1.8 2>> %ERRORLOG%

REM ---------------------------------------------------------------------------------------------------------------
REM  Use GIT to Deploy JENKINS Client and Tooling
REM ---------------------------------------------------------------------------------------------------------------

REM -- Clone GIT Slave Repo or Pull it
cd /D D:\DEV
IF NOT EXIST %SLAVE_HOME% (
  echo ... Install Jenkins Slave Tools from Git Repo
  git clone %GIT_REPO% %SLAVE_FOLDER% 2>> %ERRORLOG%
) ELSE (
  echo ... Update Jenkins Slave Tools from Git Repo
  cd /D %SLAVE_HOME%
  git status >> %ERRORLOG%
  git pull
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Uninstall old JENKINS Service
REM ---------------------------------------------------------------------------------------------------------------

:JENKINS
echo ... Uninstall old JENKINS Service if necessary
REM -- Check Jenkins service exist (We only uninstall the same service)
sc queryex type= service state= all | findstr "SERVICE_NAME" | findstr /I "jenkins" > NUL 2>&1
IF %ERRORLEVEL% == 0 (
  echo ... Remove old service!
  SC delete %SERVICE_NAME% > NUL 2>> %ERRORLOG% 
  timeout 2 > NUL 
)

REM -- Check if a Jenkins process is still running
tasklist /svc | findstr /I "jenkins"  > NUL 2>> %ERRORLOG%
IF %ERRORLEVEL% == 0 (
  echo WARNING : Some Jenkins process are still running, can't deploy a new instance!
  tasklist /svc | findstr /I "jenkins"
  echo WARNING : Some Jenkins process are still running, can't deploy a new instance! >> %ERRORLOG%
  pause
  popd
  exit 1      
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Grant all rights on SLAVE_HOME to EveryOne
REM ---------------------------------------------------------------------------------------------------------------

echo ... Grant all rights on SLAVE_HOME to EveryOne
cacls %SLAVE_HOME% /t /e /g Everyone:f > NUL 2>> %ERRORLOG%

REM ---------------------------------------------------------------------------------------------------------------
REM  Link Slave to MASTER and Deploy/start service
REM ---------------------------------------------------------------------------------------------------------------

echo ... Copy Slave files from Master
XCOPY /E/I/Q/H/K/Y %MASTER_DRIVE%\SLAVE\*.* %SLAVE_HOME%
rem -- Configure XML Slave file
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%SLAVE_HOME%\jenkins-slave.xml" "@JAVA@" "%LOCAL_TOOLS%\JDK1.8\bin\java.exe" >> %ERRORLOG% 2>>&1
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%SLAVE_HOME%\jenkins-slave.xml" "@JNLP@" "http://%MASTER%/computer/%SLAVE_NAME%/slave-agent.jnlp" >> %ERRORLOG% 2>>&1

%SLAVE_HOME%\jenkins-slave.exe install 

echo ... Setup Jenkins as a service and setup service
rem -- set user bob and depdancy as Server service (make sure we have network!)
sc config %SERVICE_NAME% start= auto obj= "BE\bob" password= "bobthebuilder" depend= LanmanServer
rem -- set restart service configuration in case of problem (reset time = 1day) (Restart = 1mn/5mn Reboot = 1h)
sc failure %SERVICE_NAME% reset= 43200 reboot= "Jenkins slave has crashed, restarting the server" actions= restart/60/restart/300/reboot/3600

echo ... Add bob to Admin group
net localgroup Administrators BE\bob /add 2> NUL

REM -- Start new service
echo ... Start Jenkins service
%SLAVE_HOME%\jenkins-slave.exe start  2>> %ERRORLOG%

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
