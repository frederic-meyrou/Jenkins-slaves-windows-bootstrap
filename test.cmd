@echo off
cls
TITLE Automatic Installation Slave Jenkins
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Installation Slave Jenkins Windows x86 - Launcher
REM For New HCIS Platform
REM V1.6 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------
REM Mandatory pre-requisites : D:\ Drive
REM Mandatory pre-requisites : Slave already created on MASTER as JNLP using hostname of slave, installation on D:\DEV\CI
REM ---------------------------------------------------------------------------------------------------------------
REM Known problem : ClearCase need a separate Client installation
REM                 MsBuild   need additional Microsoft runtime installations
REM In case of problems with runas credential, use "rundll32.exe keymgr.dll, KRShowKeyMgr" to remove a faulty credential  
REM ---------------------------------------------------------------------------------------------------------------

REM -- Define Environment
IF NOT EXIST %~dp0\env.cmd (
  echo ERROR! Can't find the script env.cmd ...
  pause
  exit 1
)
CALL %~dp0\env.cmd

SET MASTER_SHARE=\\%MASTER%\SLAVE-BOOTSTRAP\
SET MASTER_ROOT=D:\JENKINS
SET GIT_REPO=http://gitbucket-hcis.agfahealthcare.com/git/Jenkins/Slave-Tooling.git
SET SLAVE_NAME=%COMPUTERNAME%
SET SLAVE_FOLDER=CI
SET SLAVE_HOME=D:\DEV\%SLAVE_FOLDER%
SET SLAVE_USER=BE\bob
SET SLAVE_USER_PASS=bobthebuilder
SET LOCAL_TOOLS=D:\sApps
SET NTP_SERVER=time.windows.com
SET NTP_SERVER=ntp.agfa.be
SET ERRORLOG=D:\DEV\slave_setup.log
SET SETUPUSERLOG=D:\DEV\user_setup.log
SET SERVICE_NAME="jenkins_slave"

setlocal enableextensions
setlocal enabledelayedexpansion

REM ---------------------------------------------------------------------------------------------------------------
REM  Get O/S Name
REM ---------------------------------------------------------------------------------------------------------------

SET SLAVE_OS=NONE
wmic os get Caption /value | findstr /c:"2003" > NUL
IF %ERRORLEVEL% == 0 SET SLAVE_OS=win2k3
wmic os get Caption /value | findstr /c:"2008" > NUL
IF %ERRORLEVEL% == 0 SET SLAVE_OS=win2k8
wmic os get Caption /value | findstr /c:"2012" > NUL
IF %ERRORLEVEL% == 0 SET SLAVE_OS=win2k12
wmic os get Caption /value | findstr /c:"7" > NUL
IF %ERRORLEVEL% == 0 SET SLAVE_OS=win7

REM ---------------------------------------------------------------------------------------------------------------
REM  Establish temporary Drive with Remote Share
REM ---------------------------------------------------------------------------------------------------------------

pushd %~dp0
SET SHARE=%~dp0
SET MASTER_DRIVE=%CD%

REM MOD for Win2003
IF "%SLAVE_OS%"=="win2k3" SET MASTER_SHARE=\\%MASTER_HOST%\SLAVE-BOOTSTRAP\

IF /I NOT %MASTER_SHARE%==%SHARE% (
  echo WARNING! Run this script from %MASTER_SHARE% ONLY! You are currently on %SHARE% ...
  pause
  popd
  exit 1
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Check User is Admin
REM ---------------------------------------------------------------------------------------------------------------

REM MOD for Seven
IF "%SLAVE_OS%"=="win7" GOTO FOLDERS

whoami /groups | findstr /c:" S-1-5-32-544 " | findstr /c:" Enabled group" > NUL 2>&1
IF %ERRORLEVEL% == 1 (
 echo WARNING! You MUST be Administrator and run the script as Administrator, please contact ICS\ALM for further assistance
 pause 
 popd
 exit 1
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Check Folders
REM ---------------------------------------------------------------------------------------------------------------

:FOLDERS
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
echo Start installation of Jenkins slave on %SLAVE_HOME% from %MASTER_DRIVE% = %SHARE%

REM ---------------------------------------------------------------------------------------------------------------
REM  Check FW .NET
REM ---------------------------------------------------------------------------------------------------------------

echo ... Check Framework v3.5
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP" | findstr /C:"v3.5" > NUL 2>> %ERRORLOG%
IF %ERRORLEVEL% == 1 (
  echo ... WARNING! Install .NET Framework V3.5 from Features of Server Manager, please contact ICS\ALM for further assistance.
  echo ... WARNING! Install .NET Framework V3.5 from Features of Server Manager, please contact ICS\ALM for further assistance. >> %ERRORLOG%
  pause
  popd
  exit 1
)

echo ... Check Framework v4
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP" | findstr /C:"v4" > NUL 2>> %ERRORLOG%
IF %ERRORLEVEL% == 1 (
  echo ... WARNING! Install .NET Framework V4+, please contact ICS\ALM for further assistance.
  reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP" >> %ERRORLOG%
  echo ... WARNING! Install .NET Framework V4+, please contact ICS\ALM for further assistance. >> %ERRORLOG%
  pause
  popd
  exit 1
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Clean PATH
REM ---------------------------------------------------------------------------------------------------------------

CALL %MASTER_DRIVE%\BIN\pathmgr.cmd /clean /system /v /y

REM ---------------------------------------------------------------------------------------------------------------
REM  Install Chrome 
REM ---------------------------------------------------------------------------------------------------------------

echo ... Install Chrome for GUI testing
start /wait MSIEXEC.EXE /package %MASTER_DRIVE%\INSTALL\googlechromestandaloneenterprise.msi /qn >> %ERRORLOG% 2>>&1


REM ---------------------------------------------------------------------------------------------------------------
REM  END
REM ---------------------------------------------------------------------------------------------------------------

:END
echo logs are on %ERRORLOG%
popd
echo END - %TIME% >> %ERRORLOG%
pause
rem start notepad %ERRORLOG%

REM EOF
REM ---------------------------------------------------------------------------------------------------------------