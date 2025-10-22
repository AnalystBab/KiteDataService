@echo off
echo Creating Quick Access Shortcuts for Business Date Records...
echo.

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "CreateQuickAccessShortcuts_Simple.ps1"

echo.
echo Quick Access Setup Complete!
echo.
echo You now have:
echo    - Desktop shortcuts for instant access
echo    - Batch file for simple menu
echo.
echo Double-click any desktop shortcut to access your data!
echo.
pause


