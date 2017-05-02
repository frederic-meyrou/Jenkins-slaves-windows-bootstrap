@echo off
TITLE Automatic Installation Master Tools for Jenkins for Windows 2008/2012
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Installation Slave Jenkins x86 - W2K8/12-64 bits
REM For New HCIS Platform
REM V1.3 - Frederic Meyrou
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

reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters | findstr /I "%NTP_SERVER%" >> %ERRORLOG% 2>>&1
IF %ERRORLEVEL% == 1 reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" /v NtpServer /t REG_SZ /d %NTP_SERVER% /f 2>> %ERRORLOG%
IF %ERRORLEVEL% == 1 (
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
REM  Install Java and Git 
REM ---------------------------------------------------------------------------------------------------------------

echo ... Install/Update Java JDK and mSysGit
:JAVA
REM echo ... Install Java JDK 1.8
REM IF NOT EXIST %LOCAL_TOOLS%\JDK1.8 MKDIR %LOCAL_TOOLS%\JDK1.8\ 2> NUL
REM XCOPY /E/I/Q/H/K/Y %MASTER_DRIVE%\INSTALL\jdk-8u51-windows-x64\*.* %LOCAL_TOOLS%\JDK1.8\
REM SET JAVA_HOME=%LOCAL_TOOLS%\JDK1.8
REM PATH %LOCAL_TOOLS%\JDK1.8\bin;%PATH%

where java >> %ERRORLOG% 2>>&1
%LOCAL_TOOLS%\JDK1.8\bin\java -version >> %ERRORLOG% 2>>&1
IF %ERRORLEVEL% == 1 (
  echo ... WARNING! Java %LOCAL_TOOLS%\JDK1.8 is not installed, please contact ICS\ALM for further assistance.
  echo ... WARNING! Java %LOCAL_TOOLS%\JDK1.8 is not installed, please contact ICS\ALM for further assistance. >> %ERRORLOG%
  pause
  popd
  exit 1
)

echo ... Setup Java security
mkdir %WINDIR%\Sun\Java\Deployment 2> NUL
XCOPY /E/I/Q/H/K/Y %MASTER_DRIVE%\CONFIG\java-config\*.* %WINDIR%\Sun\Java\Deployment

:GIT
echo ... Install mSysGit
REM -- Setup LOCAL_TOOLS Path in configuration file
XCOPY /Q/Y %MASTER_DRIVE%\CONFIG\git\Git.conf %LOCAL_TOOLS%
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%LOCAL_TOOLS%\Git.conf" "@LOCALTOOLS@" "%LOCAL_TOOLS%" >> %ERRORLOG% 2>>&1
REM -- Start Silent install
%MASTER_DRIVE%\INSTALL\Git-2.9.2-64-bit.exe /SILENT /SUPPRESSMSGBOXES /NORESTART /NORESTARTAPPLICATIONS /NOCLOSEAPPLICATIONS /LOADINF=%LOCAL_TOOLS%\Git.conf  2>> %ERRORLOG%
echo %ERRORLEVEL% >> %ERRORLOG%
rem PATH %LOCAL_TOOLS%\Git-2.9.2\bin;%PATH%
CALL %MASTER_DRIVE%\BIN\pathmgr.cmd /add /system %LOCAL_TOOLS%\Git-2.9.2\bin /v /y

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
%MASTER_DRIVE%\INSTALL\CollabNetSubversion-client-1.8.14-1-x64.exe /S /Answerfile=%MASTER_DRIVE%\CONFIG\svn\collabnetSVN.conf /D=%LOCAL_TOOLS%\SVN_1.8 2>> %ERRORLOG%
CALL %MASTER_DRIVE%\BIN\pathmgr.cmd /add /system %LOCAL_TOOLS%\SVN_1.8 /v /y

REM ---------------------------------------------------------------------------------------------------------------
REM  Use GIT to Deploy JENKINS Client and Tooling
REM ---------------------------------------------------------------------------------------------------------------

REM -- Clone GIT Slave Repo or Pull it
cd /D D:\DEV
IF EXIST %SLAVE_FOLDER% IF NOT EXIST %SLAVE_FOLDER%\.git IF EXIST %SLAVE_FOLDER%\WS (
  echo ... Install Jenkins Slave Tooling
  echo WARNING : Can't install the Slave tooling, the Git repo is missing and a Worspace is already setup. 
  echo           Please move/save the Worskspace manually, delete %SLAVE_FOLDER% and restart installation. 
  echo WARNING : Can't install the Slave tooling, the Git repo is missing and a Worspace is already setup. >> %ERRORLOG%
  echo           Please move/save the Worskspace manually, delete %SLAVE_FOLDER% and restart installation. >> %ERRORLOG%
  pause
  popd
  exit 1  
)
IF EXIST %SLAVE_FOLDER% IF NOT EXIST %SLAVE_FOLDER%\.git (
  echo ... Clean Slave %SLAVE_FOLDER% folder
  DEL /S/Q  %SLAVE_FOLDER%
)
IF NOT EXIST %SLAVE_FOLDER% (
  echo ... Install Jenkins Slave Tools from Git Repo
  REM git config http.postBuffer 524288000 2>> %ERRORLOG%
  git clone --progress --depth 1 %GIT_REPO% %SLAVE_FOLDER%
  SET GITERROR=%ERRORLEVEL%
  echo ErrorLevel Git = !GITERROR!%GITERROR% >> %ERRORLOG%
) ELSE (
  echo ... Update Jenkins Slave Tools from Git Repo
  cd /D %SLAVE_HOME%
  git config --get remote.origin.url 2>> %ERRORLOG%
  git status 2>> %ERRORLOG%
  git reset --hard HEAD 2>> %ERRORLOG%
  git clean -f -d 2>> %ERRORLOG%
  git pull
  SET GITERROR=%ERRORLEVEL%
  echo ErrorLevel Git = !GITERROR!%GITERROR% >> %ERRORLOG%
  echo ... Updated!  
)
IF NOT !GITERROR! == 0 (
  echo WARNING : Can't install the Slave tooling, Git returned an error code !GITERROR!. >> %ERRORLOG%
  echo WARNING : Can't install the Slave tooling, Git returned an error code !GITERROR!.
  echo           Please check the log file %ERRORLOG%.
  pause
  popd
  exit 1  
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Grant all rights on SLAVE_HOME to EveryOne
REM ---------------------------------------------------------------------------------------------------------------

echo ... Grant all rights on SLAVE_HOME to EveryOne
cacls %SLAVE_HOME% /t /e /g Everyone:f > NUL 2>> %ERRORLOG%

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
