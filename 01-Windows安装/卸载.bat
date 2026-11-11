@echo off
setlocal
title Zhudong Armor Uninstaller (WorkBuddy)
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
pause