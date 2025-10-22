@echo off
REM SIMPLE LAUNCHER - Runs service and opens browser
REM Window stays open to show logs

title Market Prediction Dashboard - Starting...

cd /d "%~dp0"

echo.
echo ===================================================================
echo    MARKET PREDICTION WEB APP
echo ===================================================================
echo.
echo Starting service...
echo This window will show service logs.
echo Browser will open automatically.
echo.
echo To stop: Press Ctrl+C in this window
echo.
echo ===================================================================
echo.

REM Start browser after 5 seconds (in background)
start /B cmd /c "timeout /t 5 /nobreak >nul && start http://localhost:5000"

REM Run the service (this keeps the window open)
dotnet run

REM Only gets here if service stops
echo.
echo Service stopped.
pause










