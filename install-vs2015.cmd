@echo off
cls
TITLE Automatic Installation MsBuild V2015
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Installation MsBuild V2015
REM For New HCIS Platform
REM V1.1 - Frederic Meyrou / Wolfgang Kiendle
REM ---------------------------------------------------------------------------------------------------------------
REM Mandatory pre-requisites : Standard Slave already installed on D:\DEV\CI
REM --------------------------------------------------------------------------------------------------------------- 
REM How to uninstall : %MASTER_DRIVE%\INSTALL\vs2015\vs_professional.exe /Uninstall /Force
REM ---------------------------------------------------------------------------------------------------------------

REM -- Define Environment
IF NOT EXIST %~dp0\env.cmd (
  echo ERROR! Can't find the script env.cmd ...
  pause
  exit 1
)
CALL %~dp0\env.cmd

SET MASTER_SHARE=\\%MASTER%\SLAVE-BOOTSTRAP\
SET SLAVE_NAME=%COMPUTERNAME%
SET LOCAL_TOOLS=D:\sApps
SET ERRORLOG=%LOCAL_TOOLS%\msbuild2015_setup.log
SET MSVS2015LIC=W6NQ4-PM9R9-P4HQ9-JBTKV-RGDDM 07062

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


IF "%SLAVE_OS%"=="win7" (
 echo WARNING! We don't support installation of MsBuild client on Seven Worstation, please contact ICS\ALM for further assistance
 pause 
 popd
 exit 1
)
IF "%SLAVE_OS%"=="win2k3" (
 echo WARNING! We don't support installation of MsBuild client on x32 bits servers, please contact ICS\ALM for further assistance
 pause 
 popd
 exit 1
)
IF "%SLAVE_OS%"=="NONE" (
 echo WARNING! We don't support installation of MsBuild client on Unknown windows version, please contact ICS\ALM for further assistance
 pause 
 popd
 exit 1
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Establish temporary Drive with Remote Share
REM ---------------------------------------------------------------------------------------------------------------

pushd %~dp0
SET SHARE=%~dp0
SET MASTER_DRIVE=%CD%

IF /I NOT "%MASTER_SHARE%"=="%SHARE%" (
  echo WARNING! Run this script from %MASTER_SHARE% ONLY
  echo You are currently on %SHARE% ...
  pause
  popd
  exit 1
)

echo ... Temporary drive is %MASTER_DRIVE%

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
REM  Unnatended installation of MsBuild 2015
REM ---------------------------------------------------------------------------------------------------------------

REM -- TimeStamp
echo %date% - %TIME% > %ERRORLOG%
echo ... Start installation of MsBuild V2015 on %SLAVE_HOME% from %MASTER_DRIVE% = %SHARE%

REM -- Setup LOCAL_TOOLS Path in configuration file
XCOPY /Q/Y %MASTER_DRIVE%\CONFIG\vs2015\AdminDeployment.xml %LOCAL_TOOLS%
cscript /nologo %MASTER_DRIVE%\BIN\replace.vbs "%LOCAL_TOOLS%\AdminDeployment.xml" "@LOCALTOOLS@" "%LOCAL_TOOLS%" >> %ERRORLOG% 2>>&1

REM -- Unnatended installation of MsBuild 2015
%MASTER_DRIVE%\INSTALL\vs2015\vs_professional.exe /adminfile "%LOCAL_TOOLS%\AdminDeployment.xml" /Silent /norestart >> %ERRORLOG%
rem %MASTER_DRIVE%\INSTALL\vs2015\vs_professional.exe /Uninstall /Force

IF %ERRORLEVEL% == 1 (
 echo WARNING! Installation failed, please contact ICS\ALM for further assistance
 pause 
 popd
 exit 1
)
echo Installation successful!

REM -- Set license code
echo ... Setup license for MsBuild V2015
IF NOT EXIST "%LOCAL_TOOLS%\MsVisualStudio_14.0\Common7\IDE\StorePID.exe" (
 echo WARNING! Visual Studio instllation not complete, please contact ICS\ALM for further assistance
 pause 
 popd
 exit 1
)
%LOCAL_TOOLS%\MsVisualStudio_14.0\Common7\IDE\StorePID.exe %MSVS2015LIC%
IF %ERRORLEVEL% == 1 (
 echo WARNING! License installation failed, please contact ICS\ALM for further assistance
 pause 
 popd
 exit 1
)
echo License setup is done

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