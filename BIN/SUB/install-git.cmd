@echo off
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Sub-Component - Setup GIT Windows for Slaves
REM For New HCIS Platform
REM V1.0 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------

REM ---------------------------------------------------------------------------------------------------------------
REM  Specific parameters
REM ---------------------------------------------------------------------------------------------------------------

SET OLD_GIT_PATH=%LOCAL_TOOLS%\Git-2.9.2
SET LOCAL_GIT_PATH=%LOCAL_TOOLS%\Git-2.x
IF "%ARCH%" == "64BIT" SET GIT_BIN=Git-2.12.2.2-64-bit.exe
IF "%ARCH%" == "32BIT" SET GIT_BIN=Git-2.12.2.2-32-bit.exe

REM ---------------------------------------------------------------------------------------------------------------
REM  Install GIT Windows
REM ---------------------------------------------------------------------------------------------------------------

echo ... Install/Update Git Windows %GIT_BIN% for Slave (%ARCH%)
echo ... Install/Update Git Windows %GIT_BIN% for Slave (%ARCH%) >> %ERRORLOG%

REM -- Setup LOCAL_TOOLS Path in configuration file
XCOPY /Q/Y %MASTER_DRIVE%\CONFIG\git\Git.conf %LOCAL_TOOLS%
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%LOCAL_TOOLS%\Git.conf" "@LOCALTOOLS@" "%LOCAL_TOOLS%" >> %ERRORLOG% 2>>&1

REM -- Check OLD installation
IF EXIST %OLD_GIT_PATH%\unins000.exe (
  %OLD_GIT_PATH%\unins000.exe /SILENT
  RMDIR /Q/S %OLD_GIT_PATH%
)

REM -- Start Silent install
%MASTER_DRIVE%\INSTALL\%GIT_BIN% /SILENT /SUPPRESSMSGBOXES /NORESTART /NORESTARTAPPLICATIONS /NOCLOSEAPPLICATIONS /LOADINF=%LOCAL_TOOLS%\Git.conf  2>> %ERRORLOG%
echo %ERRORLEVEL% >> %ERRORLOG%
PATH %LOCAL_GIT_PATH%\bin;%PATH%
rem CALL %MASTER_DRIVE%\BIN\pathmgr.cmd /add /system %LOCAL_GIT_PATH%\bin /v /y

echo ... Verify Git installation
where git
where git >> %ERRORLOG% 2>>&1
where git | findstr /C:"%LOCAL_GIT_PATH%" > NUL 2>&1
IF %ERRORLEVEL% == 1 (
  echo ... WARNING! Git is not installed, please contact ICS\ALM for further assistance.
  echo ... WARNING! Git is not installed, please contact ICS\ALM for further assistance. >> %ERRORLOG%
  pause
  popd
  exit 1
)

git --version >> %ERRORLOG%
git --version

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
