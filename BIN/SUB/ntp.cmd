@echo off
REM ---------------------------------------------------------------------------------------------------------------
REM ICS\ALM : Sub-Component - NTP setup
REM For New HCIS Platform
REM V1.0 - Frederic Meyrou
REM ---------------------------------------------------------------------------------------------------------------

REM ---------------------------------------------------------------------------------------------------------------
REM  Specific parameters
REM ---------------------------------------------------------------------------------------------------------------


REM ---------------------------------------------------------------------------------------------------------------
REM  Check time service
REM ---------------------------------------------------------------------------------------------------------------

echo ... Check NTP service
W32tm /query /status >> %ERRORLOG%
IF NOT %ERRORLEVEL% == 0 (
  echo ... WARNING! NTP time service is not configured, please contact ICS\ALM for further assistance.
  echo ... WARNING! NTP time service is not configured, please contact ICS\ALM for further assistance. >> %ERRORLOG% 
  pause
  popd
  exit 1
)

reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters | findstr /I "%NTP_SERVER%" >> %ERRORLOG% 2>>&1
IF %ERRORLEVEL% == 1 reg add "HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters" /v NtpServer /t REG_SZ /d %NTP_SERVER% /f 2>> %ERRORLOG%
IF %ERRORLEVEL% == 1 (
  echo ... WARNING! NTP time service is not configured, please contact ICS\ALM for further assistance.
  echo ... WARNING! NTP time service is not configured, please contact ICS\ALM for further assistance. >> %ERRORLOG%
  reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters | findstr /I "NtpServer" >> %ERRORLOG% 
  pause
  popd
  exit 1
)

rem -- Make sure server is on time
w32tm /resync

REM EOF
REM ---------------------------------------------------------------------------------------------------------------
