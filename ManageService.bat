@echo off
REM Windows Service Management Script
REM Run as Administrator for install/uninstall

title Kite Market Data Service - Management

echo.
echo ===================================================================
echo    KITE MARKET DATA SERVICE - WINDOWS SERVICE MANAGEMENT
echo ===================================================================
echo.

:menu
echo Choose an option:
echo.
echo 1. Install Windows Service
echo 2. Uninstall Windows Service  
echo 3. Start Service
echo 4. Stop Service
echo 5. Restart Service
echo 6. Check Service Status
echo 7. Open Web Interface
echo 8. Exit
echo.

set /p choice="Enter your choice (1-8): "

if "%choice%"=="1" goto install
if "%choice%"=="2" goto uninstall
if "%choice%"=="3" goto start
if "%choice%"=="4" goto stop
if "%choice%"=="5" goto restart
if "%choice%"=="6" goto status
if "%choice%"=="7" goto web
if "%choice%"=="8" goto exit

echo Invalid choice. Please try again.
goto menu

:install
echo.
echo Installing Windows Service...
powershell -ExecutionPolicy Bypass -File "InstallService.ps1"
goto menu

:uninstall
echo.
echo Uninstalling Windows Service...
powershell -ExecutionPolicy Bypass -File "InstallService.ps1" -Uninstall
goto menu

:start
echo.
echo Starting service...
net start "KiteMarketDataService"
if %errorlevel% equ 0 (
    echo Service started successfully!
) else (
    echo Failed to start service.
)
goto menu

:stop
echo.
echo Stopping service...
net stop "KiteMarketDataService"
if %errorlevel% equ 0 (
    echo Service stopped successfully!
) else (
    echo Failed to stop service.
)
goto menu

:restart
echo.
echo Restarting service...
net stop "KiteMarketDataService"
timeout /t 3 /nobreak >nul
net start "KiteMarketDataService"
if %errorlevel% equ 0 (
    echo Service restarted successfully!
) else (
    echo Failed to restart service.
)
goto menu

:status
echo.
echo Checking service status...
sc query "KiteMarketDataService"
goto menu

:web
echo.
echo Opening web interface...
start http://localhost:5000/token-management.html
goto menu

:exit
echo.
echo Goodbye!
pause
exit

