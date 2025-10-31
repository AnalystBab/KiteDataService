@echo off
echo ========================================
echo  Kite Market Data Service Manager
echo ========================================
echo.

REM Check if PowerShell is available
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: PowerShell is not available
    echo Please install PowerShell or run the service manually
    pause
    exit /b 1
)

REM Get the directory where this batch file is located
set "SERVICE_DIR=%~dp0"
set "SERVICE_DIR=%SERVICE_DIR:~0,-1%"

echo Service Directory: %SERVICE_DIR%
echo.

REM Check if the PowerShell script exists
if not exist "%SERVICE_DIR%\RunServiceInBackground.ps1" (
    echo ERROR: RunServiceInBackground.ps1 not found
    echo Please ensure the PowerShell script is in the same directory
    pause
    exit /b 1
)

REM Check if the monitoring script exists
if not exist "%SERVICE_DIR%\SimpleServiceMonitor.ps1" (
    echo ERROR: SimpleServiceMonitor.ps1 not found
    echo Please ensure the monitoring script is in the same directory
    pause
    exit /b 1
)

:menu
echo.
echo Choose an option:
echo 1. Start Service in Background
echo 2. Stop Service
echo 3. Restart Service
echo 4. Check Service Status
echo 5. Monitor Service Health (Continuous)
echo 6. Quick Health Check
echo 7. Detailed Health Report
echo 8. Open Web Interface
echo 9. Exit
echo.
set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto start_service
if "%choice%"=="2" goto stop_service
if "%choice%"=="3" goto restart_service
if "%choice%"=="4" goto check_status
if "%choice%"=="5" goto monitor_health
if "%choice%"=="6" goto quick_health
if "%choice%"=="7" goto detailed_health
if "%choice%"=="8" goto open_web
if "%choice%"=="9" goto exit
echo Invalid choice. Please try again.
goto menu

:start_service
echo.
echo Starting service in background...
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\RunServiceInBackground.ps1'"
echo.
echo Service start command completed.
echo Check status with option 4 or monitor with option 5.
pause
goto menu

:stop_service
echo.
echo Stopping service...
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\RunServiceInBackground.ps1' -Stop"
echo.
echo Service stop command completed.
pause
goto menu

:restart_service
echo.
echo Restarting service...
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\RunServiceInBackground.ps1' -Restart"
echo.
echo Service restart command completed.
pause
goto menu

:check_status
echo.
echo Checking service status...
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\RunServiceInBackground.ps1' -Status"
echo.
pause
goto menu

:monitor_health
echo.
echo Starting continuous health monitoring...
echo Press Ctrl+C to stop monitoring
echo.
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\SimpleServiceMonitor.ps1' -Continuous"
echo.
echo Monitoring stopped.
pause
goto menu

:quick_health
echo.
echo Quick health check...
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\SimpleServiceMonitor.ps1' -Quick"
echo.
pause
goto menu

:detailed_health
echo.
echo Detailed health report...
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\SimpleServiceMonitor.ps1'"
echo.
pause
goto menu

:open_web
echo.
echo Opening web interface...
echo If the service is running, this will open http://localhost:5000
echo.
start http://localhost:5000
echo Web interface opened in default browser.
pause
goto menu

:exit
echo.
echo Goodbye!
echo.
pause
exit /b 0
exit


echo.
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\SimpleServiceMonitor.ps1' -Continuous"
echo.
echo Monitoring stopped.
pause
goto menu

:quick_health
echo.
echo Quick health check...
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\SimpleServiceMonitor.ps1' -Quick"
echo.
pause
goto menu

:detailed_health
echo.
echo Detailed health report...
powershell -ExecutionPolicy Bypass -Command "& '%SERVICE_DIR%\SimpleServiceMonitor.ps1'"
echo.
pause
goto menu

:open_web
echo.
echo Opening web interface...
echo If the service is running, this will open http://localhost:5000
echo.
start http://localhost:5000
echo Web interface opened in default browser.
pause
goto menu

:exit
echo.
echo Goodbye!
echo.
pause
exit /b 0