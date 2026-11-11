@echo off
chcp 65001 >nul
setlocal
title Zhudong Armor - One Click Uninstall
set "HERE=%~dp0"
set "PS1=%HERE%01-Windows安装\uninstall.ps1"
if not exist "%PS1%" (
  echo [!] Missing: 01-Windows安装\uninstall.ps1
  pause
  exit /b 1
)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS1%" %*
pause