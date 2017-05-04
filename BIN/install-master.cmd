@echo off
TITLE Automatic Installation Master Tools for Jenkins for Windows server 64 bits
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Installation Slave Jenkins Tooling - Windows server 64 bits
REM For New HCIS Platform
REM V1.4 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------

IF NOT "%ARCH%" == "64BIT" (
  echo ... WARNING! This Slave is running 32 Bits O/S, wrong Script! Please contact ICS\ALM for further assistance.
  echo ... WARNING! This Slave is running 32 Bits O/S, wrong Script! Please contact ICS\ALM for further assistance. >> %ERRORLOG% 
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
REM  Install JDK / GIT / SVN 
REM ---------------------------------------------------------------------------------------------------------------

:JAVA
where java
where java >> %ERRORLOG% 2>>&1

%LOCAL_JDK_PATH%\bin\java -version
%LOCAL_JDK_PATH%\bin\java -version >> %ERRORLOG% 2>>&1
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
CALL %MASTER_DRIVE%\BIN\SUB\install-git.cmd

:SVN
CALL %MASTER_DRIVE%\BIN\SUB\install-svn.cmd

REM ---------------------------------------------------------------------------------------------------------------
REM  Use GIT to Deploy JENKINS Client and Tooling
REM ---------------------------------------------------------------------------------------------------------------

:CLONE
CALL %MASTER_DRIVE%\BIN\SUB\clone-tooling.cmd

REM ---------------------------------------------------------------------------------------------------------------
REM  Grant all rights on SLAVE_HOME to EveryOne
REM ---------------------------------------------------------------------------------------------------------------

echo ... Grant all rights on SLAVE_HOME to EveryOne
cacls %SLAVE_HOME% /t /e /g Everyone:f > NUL 2>> %ERRORLOG%

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
