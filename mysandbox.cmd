@echo off
setlocal enabledelayedexpansion

set "BASH="

for %%P in (
  "C:\Program Files\Git\bin\bash.exe"
  "C:\Program Files (x86)\Git\bin\bash.exe"
  "%LocalAppData%\Programs\Git\bin\bash.exe"
  "%USERPROFILE%\scoop\apps\git\current\bin\bash.exe"
) do (
  if exist %%P set "BASH=%%~P" & goto :run
)

for %%X in (bash.exe) do set "BASH_PATH=%%~$PATH:X"
if defined BASH_PATH (
  set "BASH=!BASH_PATH!"
  echo !BASH_PATH! | findstr /I "System32 Sysnative" >nul
  if errorlevel 1 goto :run
)

if exist "%SystemRoot%\System32\bash.exe" (
  "%SystemRoot%\System32\bash.exe" -c "exec ./mysandbox %*"
  exit /b !ERRORLEVEL!
)
if exist "%SystemRoot%\Sysnative\bash.exe" (
  "%SystemRoot%\Sysnative\bash.exe" -c "exec ./mysandbox %*"
  exit /b !ERRORLEVEL!
)

echo mysandbox requires Git Bash or WSL.
echo Install Git for Windows: https://git-scm.com
exit /b 1

:run
"%BASH%" "%~dp0mysandbox" %*
exit /b %ERRORLEVEL%
