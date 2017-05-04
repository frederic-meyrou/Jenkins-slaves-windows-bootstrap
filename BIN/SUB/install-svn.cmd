@echo off
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Sub-Component - Setup SVN for Slaves
REM For New HCIS Platform
REM V1.0 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------

REM ---------------------------------------------------------------------------------------------------------------
REM  Specific parameters
REM ---------------------------------------------------------------------------------------------------------------

SET LOCAL_SVN_PATH=%LOCAL_TOOLS%\SVN_1.8
IF "%ARCH%" == "64BIT" SET SVN_BIN=CollabNetSubversion-client-1.8.17-1-x64.exe
IF "%ARCH%" == "32BIT" SET SVN_BIN=CollabNetSubversion-client-1.8.17-1-Win32.exe

REM ---------------------------------------------------------------------------------------------------------------
REM  Install SVN Client
REM ---------------------------------------------------------------------------------------------------------------

echo ... Install/Update SVN Client
:SVN
%MASTER_DRIVE%\INSTALL\%SVN_BIN% /S /Answerfile=%MASTER_DRIVE%\CONFIG\svn\collabnetSVN.conf /D=%LOCAL_SVN_PATH% 2>> %ERRORLOG%
CALL %MASTER_DRIVE%\BIN\pathmgr.cmd /add /system %LOCAL_SVN_PATH% /v /y

svn --version | find " version "
svn --version | find " version " >> %ERRORLOG%
IF "%ERRORLEVEL%" == "1" echo WARNING : SVN Client is not deployed, please check! >> %ERRORLOG%

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
