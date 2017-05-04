@echo off
TITLE Automatic Installation Slave Jenkins for Windows Workstation
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Installation Slave Jenkins x86 - Windows Workstation 64 bits
REM For New HCIS Platform
REM V1.7 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------
REM Known problem : Problem with Master share case sensitive
REM                 BOB Do not Work on Workstation -> Use local user name instead
REM ---------------------------------------------------------------------------------------------------------------

IF NOT "%ARCH%" == "64BIT" (
  echo ... WARNING! This Slave is running 32 Bits O/S, wrong Script! Please contact ICS\ALM for further assistance.
  echo ... WARNING! This Slave is running 32 Bits O/S, wrong Script! Please contact ICS\ALM for further assistance. >> %ERRORLOG% 
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
REM  Check time service
REM ---------------------------------------------------------------------------------------------------------------

:NTP
CALL %MASTER_DRIVE%\BIN\SUB\ntp.cmd

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
REM  Install JDK / GIT / SVN 
REM ---------------------------------------------------------------------------------------------------------------

:JAVA
CALL %MASTER_DRIVE%\BIN\SUB\install-jdk.cmd

:GIT
CALL %MASTER_DRIVE%\BIN\SUB\install-git.cmd

:SVN
CALL %MASTER_DRIVE%\BIN\SUB\install-svn.cmd

REM ---------------------------------------------------------------------------------------------------------------
REM  Install FireFox client 
REM ---------------------------------------------------------------------------------------------------------------

echo ... Install FireFox client for GUI testing
XCOPY /Q/Y %MASTER_DRIVE%\CONFIG\firefox\firefox.ini %LOCAL_TOOLS%
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%LOCAL_TOOLS%\firefox.ini" "@LOCALTOOLS@" "%LOCAL_TOOLS%" >> %ERRORLOG% 2>>&1
%MASTER_DRIVE%\INSTALL\"Firefox Setup 45.0.1.exe" /INI="%LOCAL_TOOLS%\firefox.ini" >> %ERRORLOG% 2>>&1

REM ---------------------------------------------------------------------------------------------------------------
REM  Use GIT to Deploy JENKINS Client and Tooling
REM ---------------------------------------------------------------------------------------------------------------

:CLONE
CALL %MASTER_DRIVE%\BIN\SUB\clone-tooling.cmd

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
REM  MOD here for Win7
REM ---------------------------------------------------------------------------------------------------------------

echo ... Copy Slave files from Master
XCOPY /E/I/Q/H/K/Y %MASTER_DRIVE%\SLAVE\*.* %SLAVE_HOME%
rem -- Configure XML Slave file
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%SLAVE_HOME%\jenkins-slave.xml" "@JAVA@" "%LOCAL_TOOLS%\JDK1.8\bin\java.exe" >> %ERRORLOG% 2>&1
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%SLAVE_HOME%\jenkins-slave.xml" "@JNLP@" "http://%MASTER%/computer/%SLAVE_NAME%/slave-agent.jnlp" >> %ERRORLOG% 2>&1

echo ... Install Jenkins
%SLAVE_HOME%\jenkins-slave.exe install 

echo ... Setup Jenkins as a service and setup service
rem -- set user bob and depdancy as Server service (make sure we have network!)
call :inputbox "Please enter your Windows password : " "Jenkins service configuration"
sc config %SERVICE_NAME% start= auto obj= "%USERDOMAIN%\%USERNAME%" password= "%input%" depend= LanmanServer
rem -- set restart service configuration in case of problem (reset time = 1day) (Restart = 1mn/5mn/20mn)
sc failure %SERVICE_NAME% reset= 43200 actions= restart/60/restart/300/restart/1200

REM echo ... Add bob to Admin group
REM net localgroup Administrators %SLAVE_USER% /add 2> NUL

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

:END
REM EOF
REM ---------------------------------------------------------------------------------------------------------------
