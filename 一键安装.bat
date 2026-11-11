@echo off
chcp 65001 >nul
setlocal
title Zhudong Armor - One Click Install
set "HERE=%~dp0"
set "PS1=%HERE%01-Windows安装\apply.ps1"
if not exist "%PS1%" (
  echo [!] Missing: 01-Windows安装\apply.ps1
  echo     Unzip the whole package first, then double-click this file again.
  pause
  exit /b 1
)
echo ============================================
echo   Zhudong Armor / WorkBuddy  -  One Click
echo ============================================
echo   It will close WorkBuddy automatically,
echo   write the persona files AND install prompt hooks,
echo   restart it, then open the QQ group page (group 994974110)
echo   plus the offline promo page: 05-推广页\index.html
echo.
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
set "RC=%ERRORLEVEL%"
echo.
if not "%RC%"=="0" echo Failed, exit code %RC%.
pause
exit /b %RC%