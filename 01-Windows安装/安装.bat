@echo off
setlocal
title Zhudong Armor Installer (WorkBuddy)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0apply.ps1" %*
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo Install failed, exit code %RC%.
pause
exit /b %RC%