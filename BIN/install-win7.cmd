@echo off
cls
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Installation Slave Jenkins x86 - Win7-64 bits
REM For New HCIS Platform
REM V1.0 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------
REM Mandatory pre-requisites : D:\ Drive
REM Mandatory pre-requisites : Slave already created on MASTER as JNLP using hostname of slave, installation on D:\DEV\CI
REM ---------------------------------------------------------------------------------------------------------------
REM Known problem : Problem with Master share case sensitive
REM                 BOB Do not Work on Workstation -> Use local user name instead
REM ---------------------------------------------------------------------------------------------------------------

SET MASTER=jenkins-hcis-test.agfahealthcare.com
SET MASTER_SHARE=\\%MASTER%\SLAVE-BOOTSTRAP\
SET GIT_REPO=http://gitbucket-hcis.agfahealthcare.com/git/Jenkins/Slave-Common.git
SET SLAVE_NAME=%COMPUTERNAME%
SET SLAVE_FOLDER=CI
SET SLAVE_HOME=D:\DEV\%SLAVE_FOLDER%
SET LOCAL_TOOLS=D:\TOOLS
SET ERRORLOG=D:\DEV\slave_setup.log
SET SERVICE_NAME="jenkins_slave"

REM ---------------------------------------------------------------------------------------------------------------
REM  Establish temporary Drive with Remote Share
REM ---------------------------------------------------------------------------------------------------------------

setlocal enableextensions
setlocal enabledelayedexpansion

pushd %~dp0
SET SHARE=%~dp0
SET MASTER_DRIVE=%CD%

IF NOT %MASTER_SHARE%==%SHARE% (
  echo ... WARNING! Run this script from %MASTER_SHARE% ONLY! You are currently on %SHARE% ...
  pause
  popd
  exit 1
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Check User is Admin 
REM  MOD here for Win7
REM ---------------------------------------------------------------------------------------------------------------

whoami /groups | findstr /c:" S-1-5-32-544 " > NUL 2>&1
IF %ERRORLEVEL% == 1 (
 echo WARNING! You MUST be Administrator and run the script as Administrator, please contact ICS\ALM for further assistance
 pause 
 popd
 exit 1
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Check Folders
REM ---------------------------------------------------------------------------------------------------------------

REM -- Test if Drive D exist
IF NOT EXIST D:\ (
 echo WARNING! Drive D:\ MUST be setup before you setup a Jenkins Slave, please contact ICS\ALM for further assistance
 pause 
 popd
 exit 1
)
REM -- Check D:\DEV exist or create it
IF NOT EXIST D:\DEV MKDIR D:\DEV
IF NOT EXIST D:\DEV\TEMP MKDIR D:\DEV\TEMP

REM -- TimeStamp
echo %date% - %TIME% > %ERRORLOG%

REM ---------------------------------------------------------------------------------------------------------------
REM  Check FW .NET v3.5
REM ---------------------------------------------------------------------------------------------------------------

echo ... Check Framework v3.5
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP" | find /C "v3.5" > NUL 2>> %ERRORLOG%
IF %ERRORLEVEL% == 1 (
  echo ... WARNING! Install .NET Framework V3.5 from Features of Server Manager, please contact ICS\ALM for further assistance.
  echo ... WARNING! Install .NET Framework V3.5 from Features of Server Manager, please contact ICS\ALM for further assistance. >> %ERRORLOG%
  pause
  popd
  exit 1
)

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

reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters | findstr /I "time.windows.com" >> %ERRORLOG% 2>&1
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
REM %MASTER_DRIVE%\INSTALL\jdk-8u51-windows-x64.exe /s ADDLOCAL="ToolsFeature,SourceFeature" INSTALLDIR=%LOCAL_TOOLS%\JDK1.8 2>> %ERRORLOG%
SET JAVA_HOME=%LOCAL_TOOLS%\JDK1.8
PATH %LOCAL_TOOLS%\JDK1.8\bin;%PATH%

where java >> %ERRORLOG% 2>&1
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
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%LOCAL_TOOLS%\Git.conf" "@LOCALTOOLS@" "%LOCAL_TOOLS%" >> %ERRORLOG% 2>&1
REM -- Start Silent install
%MASTER_DRIVE%\INSTALL\Git-2.6.3-64-bit.exe /SILENT /SUPPRESSMSGBOXES /NORESTART /NORESTARTAPPLICATIONS /NOCLOSEAPPLICATIONS /LOADINF=%LOCAL_TOOLS%\Git.conf  2>> %ERRORLOG%
echo %ERRORLEVEL% >> %ERRORLOG%
PATH %LOCAL_TOOLS%\Git-2.6.3\bin;%PATH%

where git >> %ERRORLOG% 2>&1
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
cacls %SLAVE_HOME% /t /e /g Everyone:f > NUL 2> %ERRORLOG%

REM ---------------------------------------------------------------------------------------------------------------
REM  Link Slave to MASTER and Deploy/start service
REM  MOD here for Win7
REM ---------------------------------------------------------------------------------------------------------------

echo ... Copy Slave files from Master
XCOPY /E/I/Q/H/K/Y %MASTER_DRIVE%\SLAVE\*.* %SLAVE_HOME%
rem -- Configure XML Slave file
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%SLAVE_HOME%\jenkins-slave.xml" "@JAVA@" "%LOCAL_TOOLS%\JAVA\JDK1.8\bin\java.exe" >> %ERRORLOG% 2>&1
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%SLAVE_HOME%\jenkins-slave.xml" "@JNLP@" "http://%MASTER%/computer/%SLAVE_NAME%/slave-agent.jnlp" >> %ERRORLOG% 2>&1

%SLAVE_HOME%\jenkins-slave.exe install 

echo ... Setup Jenkins as a service and setup service
rem -- set user bob and depdancy as Server service (make sure we have network!)
call :inputbox "Please enter your Windows password : " "Jenkins service configuration"
sc config %SERVICE_NAME% start= auto obj= "%USERDOMAIN%\%USERNAME%" password= "%input%" depend= LanmanServer
rem -- set restart service configuration in case of problem (reset time = 1day) (Restart = 1mn/5mn Reboot = 1h)
sc failure %SERVICE_NAME% reset= 43200 reboot= "Jenkins slave has crashed, restarting the server" actions= restart/60/restart/300/reboot/3600

REM echo ... Add bob to Admin group
REM net localgroup Administrators BE\bob /add 2> NUL

REM -- Start new service
echo ... Start Jenkins service
%SLAVE_HOME%\jenkins-slave.exe start  2>> %ERRORLOG%

REM ---------------------------------------------------------------------------------------------------------------
REM  INPUT BOX
REM  MOD here for Win7
REM ---------------------------------------------------------------------------------------------------------------

GOTO END

:InputBox
set input=
set heading=%~2
set message=%~1
echo wscript.echo inputbox(WScript.Arguments(0),WScript.Arguments(1)) >"%temp%\input.vbs"
for /f "tokens=* delims=" %%a in ('cscript //nologo "%temp%\input.vbs" "%message%" "%heading%"') do set input=%%a
exit /b

REM ---------------------------------------------------------------------------------------------------------------
REM  END : Display logs
REM ---------------------------------------------------------------------------------------------------------------

:DONOTHING
:END
echo logs are on %ERRORLOG%
echo ... OK : Slave installed and started!
popd
echo END - %TIME% >> %ERRORLOG%
pause
REM start notepad %ERRORLOG%

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
