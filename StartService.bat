@echo off
echo Starting Kite Market Data Service...
echo.

REM Check if service is already running
tasklist /FI "IMAGENAME eq KiteMarketDataService.Worker.exe" 2>nul | find /I "KiteMarketDataService.Worker.exe" >nul
if %errorlevel% equ 0 (
    echo Service is already running!
    echo The service will automatically detect this and exit gracefully.
    echo.
)

REM Start the service
echo Starting service...
dotnet run

echo.
echo Service has stopped.
pause