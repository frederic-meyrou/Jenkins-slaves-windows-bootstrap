@echo off
cls
TITLE Automatic Installation Slave Jenkins
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Installation Slave Jenkins x86 - Launcher
REM For New HCIS Platform
REM V1.0 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------
REM Mandatory pre-requisites : D:\ Drive
REM Mandatory pre-requisites : Slave already created on MASTER as JNLP using hostname of slave, installation on D:\DEV\CI
REM ---------------------------------------------------------------------------------------------------------------
REM Known problem : 
REM ---------------------------------------------------------------------------------------------------------------

SET MASTER=jenkins-hcis-test.agfahealthcare.com
SET MASTER_HOST=morswv720.agfahealthcare.com
SET MASTER_SHARE=\\%MASTER%\SLAVE-BOOTSTRAP\
SET GIT_REPO=http://gitbucket-hcis.agfahealthcare.com/git/Jenkins/Slave-Common.git
SET SLAVE_NAME=%COMPUTERNAME%
SET SLAVE_FOLDER=CI
SET SLAVE_HOME=D:\DEV\%SLAVE_FOLDER%
SET LOCAL_TOOLS=D:\sApps
SET ERRORLOG=D:\DEV\slave_setup.log
SET SERVICE_NAME="jenkins_slave"

setlocal enableextensions
setlocal enabledelayedexpansion

REM ---------------------------------------------------------------------------------------------------------------
REM  Get O/S Name
REM ---------------------------------------------------------------------------------------------------------------

SET SLAVE_OS=NONE
wmic os get Caption /value | find /C "2003" > NUL
IF %ERRORLEVEL% == 0 SET SLAVE_OS=win2k3
wmic os get Caption /value | find /C "2008" > NUL
IF %ERRORLEVEL% == 0 SET SLAVE_OS=win2k8
wmic os get Caption /value | find /C "2012" > NUL
IF %ERRORLEVEL% == 0 SET SLAVE_OS=win2k12
wmic os get Caption /value | find /C "7" > NUL
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
REM  Call Sub script according to OS version
REM ---------------------------------------------------------------------------------------------------------------

IF "%SLAVE_OS%"=="NONE" ( 
  wmic os get Caption /value
  echo ... WARNING! This operation system is not supported. please contact ICS\ALM for further assistance.
  echo ... WARNING! This operation system is not supported. please contact ICS\ALM for further assistance. >> %ERRORLOG%
  pause
  popd
  exit 1
)

echo ... Slave OS = %SLAVE_OS%
CALL %MASTER_DRIVE%\BIN\install-%SLAVE_OS%.cmd

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