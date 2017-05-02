@echo off
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Automatic Configuration of user for Slave Jenkins Windows x86
REM For New HCIS Platform
REM V1.8 - Frederic Meyrou
REM To be run as BOB user (Or user with Jenkins ownerShip on Slave)
REM ---------------------------------------------------------------------------------------------------------------

REM -- Define Environment
IF NOT EXIST %~dp0\env.cmd (
  echo ERROR! Can't find the script env.cmd ...
  pause
  exit 1
)
CALL %~dp0\env.cmd

SET MASTER_SHARE=\\%MASTER%\SLAVE-BOOTSTRAP\
SET SLAVE_FOLDER=CI
SET SLAVE_HOME=D:\DEV\%SLAVE_FOLDER%
SET SVN_URL=http://jirasvnprod.agfahealthcare.com/svn/empty
SET SVN_USER=bob
SET SVN_PASS=bobthebuilder

SET SETUPUSERLOG=D:\DEV\user_setup.log

TITLE User Configuration for Jenkins Slaves
echo ... Start configuration of User for Jenkins Slaves on %SLAVE_HOME%
echo ... Start configuration of User for Jenkins Slaves > %SETUPUSERLOG%

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

IF "%SLAVE_OS%"=="win2k3" SET MASTER_SHARE=\\%MASTER_HOST%\SLAVE-BOOTSTRAP

REM ---------------------------------------------------------------------------------------------------------------
REM  Get local IP and SITE NAME and Short site name (bdx/trr/vie/mor)
REM ---------------------------------------------------------------------------------------------------------------

FOR /F "tokens=4 delims= " %%i in ('route print ^| find " 0.0.0.0"') do (
	set LOCALIP=%%i
    goto EOL	
)
:EOL
echo - My IP is %LOCALIP% >> %SETUPUSERLOG%

SET SITE=NONE
echo %LOCALIP% | FINDSTR "10.234.92 10.234.93 10.234.94 10.234.95" && SET SITE=BORDEAUX
echo %LOCALIP% | FINDSTR "10.18.218" && SET SITE=BORDEAUX-WIFI
echo %LOCALIP% | FINDSTR "10.4 10.233.6 10.232.8 10.232.9 10.232.1 10.233.1" && SET SITE=MORTSEL
echo %LOCALIP% | FINDSTR "10.233.2 10.233.3 10.233.8" && SET SITE=GENT
echo %LOCALIP% | FINDSTR "172.25" && SET SITE=TRIER
echo %LOCALIP% | FINDSTR "10.6.234" && SET SITE=TRIER-WIFI
echo %LOCALIP% | FINDSTR "10.231.16" && SET SITE=WIEN
echo %LOCALIP% | FINDSTR "10.18.202" && SET SITE=WIEN-WIFI

echo - The slave is located in %SITE% DC/Network >> %SETUPUSERLOG%

IF "%SITE%"=="BORDEAUX" (
  SET SHORTSITE=bdx
) ELSE IF "%SITE%"=="BORDEAUX-WIFI" (
  SET SHORTSITE=bdx  
) ELSE IF "%SITE%"=="TRIER" (
  SET SHORTSITE=trr
) ELSE IF "%SITE%"=="TRIER-WIFI" (
  SET SHORTSITE=trr
) ELSE IF "%SITE%"=="WIEN" (
  SET SHORTSITE=vie
) ELSE IF "%SITE%"=="WIEN-WIFI" (
  SET SHORTSITE=vie
) ELSE (
  REM -- Default is Central in Mortsel
  SET SHORTSITE=mor
)
echo - My ShortSite is %SHORTSITE% >> %SETUPUSERLOG%

REM ---------------------------------------------------------------------------------------------------------------
REM  Display current running User
REM ---------------------------------------------------------------------------------------------------------------

echo - Jenkins slave user is : >> %SETUPUSERLOG%
whoami >> %SETUPUSERLOG%
echo - User profile is stored on %USERPROFILE% >> %SETUPUSERLOG%
cd >> %SETUPUSERLOG%

REM ---------------------------------------------------------------------------------------------------------------
REM  Setup user specific SVN files
REM ---------------------------------------------------------------------------------------------------------------

echo - Setup SVN >> %SETUPUSERLOG%
IF NOT EXIST %APPDATA%\subversion mkdir %APPDATA%\subversion 2> NUL
XCOPY /E/I/Q/H/K/Y %MASTER_SHARE%\CONFIG\svn\*.* "%APPDATA%\subversion" >> %SETUPUSERLOG% 2>>&1

echo - First authent SVN >> %SETUPUSERLOG%
WHERE svn > NUL 2>&1
IF %ERRORLEVEL% == 0 (
  CD /D %TEMP%
  svn co %SVN_URL% --username %SVN_USER% --password %SVN_PASS% >> %SETUPUSERLOG% 2>>&1
) ELSE (
  echo WARNING! Can't find SVN binary! >> %SETUPUSERLOG%
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Setup user specific ClearCase files
REM ---------------------------------------------------------------------------------------------------------------

echo - Setup ClearCase client >> %SETUPUSERLOG%
IF NOT EXIST "%USERPROFILE%\.scm" mkdir "%USERPROFILE%\.scm" 2> NUL
XCOPY /Q/H/K/Y %MASTER_SHARE%\CONFIG\clearcase\*.* "%USERPROFILE%\.scm" >> %SETUPUSERLOG% 2>>&1

REM ---------------------------------------------------------------------------------------------------------------
REM  Setup user specific Maven settings.xml
REM ---------------------------------------------------------------------------------------------------------------
echo - Setup Maven settings.xml >> %SETUPUSERLOG%
IF NOT EXIST "%USERPROFILE%\.m2" mkdir "%USERPROFILE%\.m2" 2> NUL
IF EXIST %MASTER_SHARE%\CONFIG\maven\settings.xml.%SHORTSITE% (
  COPY /Y %MASTER_SHARE%\CONFIG\maven\settings.xml.%SHORTSITE% "%USERPROFILE%\.m2\settings.xml" >> %SETUPUSERLOG% 2>>&1
) ELSE (
  echo WARNING! Can't find %MASTER_SHARE%\CONFIG\maven\settings.xml.%SHORTSITE%! >> %SETUPUSERLOG%
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Setup user specific NodeJS .npmrc
REM ---------------------------------------------------------------------------------------------------------------
echo - Setup NodeJS >> %SETUPUSERLOG%
IF EXIST %MASTER_SHARE%\CONFIG\nodejs\.npmrc.%SHORTSITE%  (
  COPY /Y %MASTER_SHARE%\CONFIG\nodejs\.npmrc.%SHORTSITE% "%USERPROFILE%\.npmrc" >> %SETUPUSERLOG% 2>>&1
) ELSE (
  echo WARNING! Can't find %MASTER_SHARE%\CONFIG\nodejs\.npmrc.%SHORTSITE%! >> %SETUPUSERLOG%
)

REM ---------------------------------------------------------------------------------------------------------------
REM  Setup user specific SSH/SCP
REM ---------------------------------------------------------------------------------------------------------------
echo - Setup SSH/SCP >> %SETUPUSERLOG%
IF NOT EXIST "%USERPROFILE%\.ssh" mkdir "%USERPROFILE%\.ssh" 2> NUL
XCOPY /Q/H/K/Y %MASTER_SHARE%\CONFIG\ssh\*.* "%USERPROFILE%\.ssh" >> %SETUPUSERLOG% 2>>&1

REM ---------------------------------------------------------------------------------------------------------------
REM  Setup user specific Git files
REM ---------------------------------------------------------------------------------------------------------------
echo - Setup GIT >> %SETUPUSERLOG%
IF "%USERNAME%"=="bob" (
  git config --global user.name "Bob the Builder"
  git config --global user.email %USERNAME%-noreply@agfa.com
  git config --global color.ui auto
  git config --global core.autocrlf false
  git config --list --show-origin >> %SETUPUSERLOG% 2>>&1
  XCOPY /Q/H/K/Y %MASTER_SHARE%\CONFIG\git\_netrc "%USERPROFILE%" >> %SETUPUSERLOG% 2>>&1
) ELSE IF NOT EXIST "%USERPROFILE%\.gitconfig" (
  git config --global user.name "%USERNAME%"
  git config --global user.email %USERNAME%-noreply@agfa.com
  git config --global color.ui auto
  git config --global core.autocrlf false
  git config --list --show-origin >> %SETUPUSERLOG% 2>>&1
) ELSE git config --list --show-origin >> %SETUPUSERLOG% 2>>&1

IF NOT EXIST "%USERPROFILE%\_netrc" XCOPY /Q/H/K/Y %MASTER_SHARE%\CONFIG\git\_netrc "%USERPROFILE%" >> %SETUPUSERLOG% 2>>&1
IF NOT DEFINED HOME SETX HOME "%USERPROFILE%" >> %SETUPUSERLOG% 2>>&1

REM ---------------------------------------------------------------------------------------------------------------
REM  Setup user PATH for Tooling
REM ---------------------------------------------------------------------------------------------------------------

REM -- CLEAN and Display PATH
CALL %MASTER_SHARE%\BIN\pathmgr.cmd /clean /user /v /y >> %SETUPUSERLOG% 2>>&1
CALL %MASTER_SHARE%\BIN\pathmgr.cmd /list /user >> %SETUPUSERLOG% 2>>&1

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
