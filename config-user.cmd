@echo off
cls
TITLE Automatic Installation Slave Jenkins
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Installation Slave Jenkins Windows x86 - Launcher
REM For New HCIS Platform
REM V1.4 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------

REM -- Define Environment
IF NOT EXIST %~dp0\env.cmd (
  echo ERROR! Can't find the script env.cmd ...
  pause
  exit 1
)
CALL %~dp0\env.cmd

SET MASTER_SHARE=\\%MASTER%\SLAVE-BOOTSTRAP\
SET SLAVE_USER=BE\bob
SET SETUPUSERLOG=D:\DEV\user_setup.log

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
CD > NUL

REM MOD for Win2003
IF "%SLAVE_OS%"=="win2k3" SET MASTER_SHARE=\\%MASTER_HOST%\SLAVE-BOOTSTRAP\

IF /I NOT %MASTER_SHARE%==%SHARE% (
  echo WARNING! Run this script from %MASTER_SHARE% ONLY! You are currently on %SHARE% ...
  pause
  popd
  exit 1
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Call Sub script as bob for user configuration
REM ---------------------------------------------------------------------------------------------------------------

echo ... User configuration for %USERNAME% (%SLAVE_OS%)

REM -- MOD for Seven
IF "%SLAVE_OS%"=="win7" (
  echo ... Case Seven 
  %MASTER_DRIVE%\BIN\setup-user.cmd
  GOTO USERLOG  
)

RUNAS /USER:%SLAVE_USER% /SAVECRED "%MASTER_SHARE%BIN\setup-user.cmd"
REM -- Sleep for 15 Sec
ping 127.0.0.1 -n 15 > NUL

:USERLOG
IF EXIST %SETUPUSERLOG% (
  TYPE %SETUPUSERLOG%
) ELSE (
  echo WARNING! ... Echo can't find LOG file!
)
popd
pause
REM ---------------------------------------------------------------------------------------------------------------
