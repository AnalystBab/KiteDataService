@echo off
echo Stopping Kite Market Data Service instances...
echo.

REM Try to stop all instances
taskkill /F /IM "KiteMarketDataService.Worker.exe" 2>nul
if %errorlevel% equ 0 (
    echo Successfully stopped all service instances.
) else (
    echo No running instances found or access denied.
)

echo.
echo Checking for remaining instances...
tasklist /FI "IMAGENAME eq KiteMarketDataService.Worker.exe" 2>nul
if %errorlevel% equ 0 (
    echo.
    echo Some instances may still be running.
    echo Please close the console windows manually if needed.
) else (
    echo All instances stopped successfully.
)

echo.
pause


