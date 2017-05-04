@echo off
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Sub-Component - Clone Tooling from Git Repo
REM For New HCIS Platform
REM V1.0 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------

REM ---------------------------------------------------------------------------------------------------------------
REM  Specific parameters
REM ---------------------------------------------------------------------------------------------------------------

cd /D D:\DEV

REM ---------------------------------------------------------------------------------------------------------------
REM  Use GIT to Deploy JENKINS Client and Tooling
REM ---------------------------------------------------------------------------------------------------------------

REM -- Clone GIT Slave Repo or Pull it
IF EXIST %SLAVE_FOLDER% IF NOT EXIST %SLAVE_FOLDER%\.git IF EXIST %SLAVE_FOLDER%\WS (
  echo ... Install Jenkins Slave Tooling
  echo WARNING : Can't install the Slave tooling, the Git repo is missing and a Worspace is already setup. 
  echo           Please move/save the Worskspace manually, delete %SLAVE_FOLDER% and restart installation. 
  echo WARNING : Can't install the Slave tooling, the Git repo is missing and a Worspace is already setup. >> %ERRORLOG%
  echo           Please move/save the Worskspace manually, delete %SLAVE_FOLDER% and restart installation. >> %ERRORLOG%
  pause
  popd
  exit 1  
)
IF EXIST %SLAVE_FOLDER% IF NOT EXIST %SLAVE_FOLDER%\.git (
  echo ... Clean Slave %SLAVE_FOLDER% folder
  DEL /S/Q  %SLAVE_FOLDER%
)
IF NOT EXIST %SLAVE_FOLDER% (
  echo ... Install Jenkins Slave Tools from Git Repo
  REM git config http.postBuffer 524288000 2>> %ERRORLOG%
  git clone --progress --depth 1 %GIT_REPO% %SLAVE_FOLDER%
  SET GITERROR=%ERRORLEVEL%
  echo ErrorLevel Git = !GITERROR!%GITERROR% >> %ERRORLOG%
) ELSE (
  echo ... Update Jenkins Slave Tools from Git Repo
  cd /D %SLAVE_HOME%
  git config --get remote.origin.url 2>> %ERRORLOG%
  git status 2>> %ERRORLOG%
  git reset --hard HEAD 2>> %ERRORLOG%
  git clean -f -d 2>> %ERRORLOG%
  git pull
  SET GITERROR=%ERRORLEVEL%
  echo ErrorLevel Git = !GITERROR!%GITERROR% >> %ERRORLOG%
  echo ... Updated!  
)
IF NOT !GITERROR! == 0 (
  echo WARNING : Can't install the Slave tooling, Git returned an error code !GITERROR!. >> %ERRORLOG%
  echo WARNING : Can't install the Slave tooling, Git returned an error code !GITERROR!.
  echo           Please check the log file %ERRORLOG%.
  pause
  popd
  exit 1  
)

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
