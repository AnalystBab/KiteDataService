@echo off
REM Simple launcher for creating desktop shortcut

cd /d "%~dp0"
powershell.exe -ExecutionPolicy Bypass -File "CreateDesktopShortcut_WebApp.ps1"










