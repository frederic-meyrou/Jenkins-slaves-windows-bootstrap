@echo off
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Sub-Component - Setup JDK for Slaves
REM For New HCIS Platform
REM V1.0 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------

REM ---------------------------------------------------------------------------------------------------------------
REM  Specific parameters
REM ---------------------------------------------------------------------------------------------------------------

SET LOCAL_JDK_PATH=%LOCAL_TOOLS%\JDK1.8
IF "%ARCH%" == "64BIT" SET JDK_VERSION=jdk-8u131-windows-x64
IF "%ARCH%" == "32BIT" SET JDK_VERSION=jdk-8u131-windows-x32

REM ---------------------------------------------------------------------------------------------------------------
REM  Install Java
REM ---------------------------------------------------------------------------------------------------------------

:JAVA
echo ... Install/Update Java JDK %JDK_VERSION% for Slave (%ARCH%)
echo ... Install/Update Java JDK %JDK_VERSION% for Slave (%ARCH%) >> %ERRORLOG%

IF NOT EXIST %LOCAL_JDK_PATH% MKDIR %LOCAL_JDK_PATH%\
ROBOCOPY /MIR /NFL /NDL %MASTER_DRIVE%\INSTALL\%JDK_VERSION%\ %LOCAL_JDK_PATH%\ >> %ERRORLOG%
SET JAVA_HOME=%LOCAL_JDK_PATH%
PATH %LOCAL_JDK_PATH%\bin;%PATH%
rem CALL %MASTER_DRIVE%\BIN\pathmgr.cmd /add /system %LOCAL_JDK_PATH%\bin /v /y

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

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
