@echo off
REM Simple batch launcher for Market Prediction Web App
REM Keeps window open to see any errors

echo.
echo ===================================================================
echo    MARKET PREDICTION WEB APP - LAUNCHER
echo ===================================================================
echo.

cd /d "%~dp0"

echo Checking directory: %CD%
echo.

REM Check if project file exists
if not exist "KiteMarketDataService.Worker.csproj" (
    echo ERROR: Project file not found!
    echo Current directory: %CD%
    echo Expected file: KiteMarketDataService.Worker.csproj
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo Found project file: KiteMarketDataService.Worker.csproj
echo.
echo ===================================================================
echo    STARTING SERVICE...
echo    Please wait for browser to open automatically
echo ===================================================================
echo.

REM Run the service
dotnet run --configuration Release

REM If we get here, service has stopped
echo.
echo ===================================================================
echo    SERVICE STOPPED
echo ===================================================================
echo.
echo Press any key to exit...
pause >nul
