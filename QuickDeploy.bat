@echo off
echo.
echo ============================================================
echo.
echo      KITE MARKET DATA SERVICE - AUTO DEPLOY
echo.
echo ============================================================
echo.
echo Building and deploying service...
echo.

powershell.exe -ExecutionPolicy Bypass -File "%~dp0AutoBuildAndDeploy.ps1"

echo.
echo Press any key to close...
pause > nul