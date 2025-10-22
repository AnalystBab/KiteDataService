@echo off
echo.
echo ============================================================
echo.
echo      AUTO-DEPLOY ON CODE CHANGES - ENABLED
echo.
echo ============================================================
echo.
echo This will watch for code changes and automatically deploy...
echo Press Ctrl+C to stop watching
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0AutoBuildAndDeploy.ps1" -Watch

echo.
echo Press any key to close...
pause > nul
