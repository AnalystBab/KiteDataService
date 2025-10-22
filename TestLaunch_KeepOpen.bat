@echo off
REM Test launcher that shows detailed output and stays open

echo.
echo ===================================================================
echo    DIAGNOSTIC LAUNCHER - Shows all output
echo ===================================================================
echo.

cd /d "%~dp0"

echo Current directory: %CD%
echo.

REM Check .NET is installed
echo Checking .NET SDK...
dotnet --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: .NET SDK not found!
    echo Please install .NET 9 SDK from: https://dotnet.microsoft.com/download
    echo.
    pause
    exit /b 1
)

echo .NET SDK found: 
dotnet --version
echo.

REM Check project file
if not exist "KiteMarketDataService.Worker.csproj" (
    echo ERROR: Not in correct directory!
    echo Current: %CD%
    echo Expected: *\KiteMarketDataService.Worker\
    echo.
    pause
    exit /b 1
)

echo Found project file
echo.

REM Check if port 5000 is already in use
echo Checking if port 5000 is available...
netstat -ano | findstr ":5000" >nul 2>&1
if %errorlevel% equ 0 (
    echo WARNING: Port 5000 is already in use!
    echo Another instance might be running.
    echo.
    echo Do you want to continue anyway? (Y/N)
    set /p continue=
    if /i not "%continue%"=="Y" (
        echo Cancelled.
        pause
        exit /b 0
    )
)

echo Port 5000 is available
echo.

echo ===================================================================
echo    BUILDING PROJECT...
echo ===================================================================
echo.

dotnet build --configuration Release
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Build failed!
    echo Please check the errors above.
    echo.
    pause
    exit /b 1
)

echo.
echo ===================================================================
echo    BUILD SUCCESSFUL! Starting service...
echo ===================================================================
echo.
echo The browser will open automatically in 3 seconds...
echo Web API will be available at: http://localhost:5000
echo.
echo Press Ctrl+C to stop the service when done.
echo.

REM Start the service
dotnet run --configuration Release

REM Only reaches here if service stops
echo.
echo Service has stopped.
pause










