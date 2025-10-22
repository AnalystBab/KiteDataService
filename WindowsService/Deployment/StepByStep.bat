@echo off
REM 📋 STEP-BY-STEP WINDOWS SERVICE SETUP
REM Interactive setup with user confirmation at each step

title 📋 Step-by-Step Windows Service Setup

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                                                               ║
echo ║        📋 STEP-BY-STEP WINDOWS SERVICE SETUP 📋             ║
echo ║                                                               ║
echo ║    This will guide you through each step with confirmation   ║
echo ║    You can see exactly what's happening at each step!        ║
echo ║                                                               ║
echo ╚═══════════════════════════════════════════════════════════════╝
echo.

REM Check if running as Administrator
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ ERROR: This script must be run as Administrator!
    echo.
    echo 🔧 SOLUTION:
    echo 1. Right-click on this file
    echo 2. Select "Run as administrator"
    echo 3. Click "Yes" when prompted
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo ✅ Running as Administrator - Perfect!
echo.

echo 📋 This setup will guide you through each step:
echo.
echo STEP 1: Copy Windows Service files to main project
echo STEP 2: Update project file with required packages
echo STEP 3: Build the project in Release mode
echo STEP 4: Install Windows Service
echo STEP 5: Start the service
echo STEP 6: Open web interface
echo.

set /p continue="Ready to start? (Y/N): "
if /i not "%continue%"=="Y" (
    echo Setup cancelled.
    pause
    exit /b 0
)

echo.
echo ===================================================================
echo    📁 STEP 1: Copying Windows Service files...
echo ===================================================================
echo.

echo Copying files to main project...
echo.

REM Copy Services file
if exist "..\Services\" (
    copy "Services\WindowsServiceInstaller.cs" "..\Services\" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ Copied WindowsServiceInstaller.cs
    ) else (
        echo ❌ Failed to copy WindowsServiceInstaller.cs
        goto error
    )
) else (
    echo ❌ Services folder not found in parent directory
    goto error
)

REM Copy Controllers file
if exist "..\WebApi\Controllers\" (
    copy "Controllers\ServiceControlController.cs" "..\WebApi\Controllers\" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ Copied ServiceControlController.cs
    ) else (
        echo ❌ Failed to copy ServiceControlController.cs
        goto error
    )
) else (
    echo ❌ WebApi\Controllers folder not found in parent directory
    goto error
)

REM Copy Web Interface file
if exist "..\wwwroot\" (
    copy "WebInterface\token-management.html" "..\wwwroot\" >nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ Copied token-management.html
    ) else (
        echo ❌ Failed to copy token-management.html
        goto error
    )
) else (
    echo ❌ wwwroot folder not found in parent directory
    goto error
)

echo.
echo ✅ STEP 1 COMPLETE: All files copied successfully!
echo.

set /p continue="Continue to Step 2? (Y/N): "
if /i not "%continue%"=="Y" (
    echo Setup paused at Step 1.
    pause
    exit /b 0
)

echo.
echo ===================================================================
echo    📝 STEP 2: Updating project file...
echo ===================================================================
echo.

echo Adding WindowsServices package to project file...

REM Check if WindowsServices package already exists
findstr /C:"Microsoft.Extensions.Hosting.WindowsServices" "..\KiteMarketDataService.Worker.csproj" >nul 2>&1
if %errorlevel% neq 0 (
    echo Adding WindowsServices package...
    
    REM Create a temporary file with the new package reference
    echo ^<PackageReference Include="Microsoft.Extensions.Hosting.WindowsServices" Version="9.0.1" /^> > temp_package.txt
    
    REM Insert the package reference before the closing ItemGroup tag
    powershell -Command "(Get-Content '..\KiteMarketDataService.Worker.csproj') -replace '</ItemGroup>', (Get-Content 'temp_package.txt') + [Environment]::NewLine + '</ItemGroup>' | Set-Content '..\KiteMarketDataService.Worker.csproj'"
    
    REM Clean up temp file
    del temp_package.txt >nul 2>&1
    
    echo ✅ WindowsServices package added to project
) else (
    echo ✅ WindowsServices package already exists in project
)

echo.
echo ✅ STEP 2 COMPLETE: Project file updated!
echo.

set /p continue="Continue to Step 3? (Y/N): "
if /i not "%continue%"=="Y" (
    echo Setup paused at Step 2.
    pause
    exit /b 0
)

echo.
echo ===================================================================
echo    🔨 STEP 3: Building project in Release mode...
echo ===================================================================
echo.

echo Building project...
cd /d ".."
dotnet build --configuration Release
if %errorlevel% neq 0 (
    echo ❌ Build failed! Please check for errors.
    goto error
)

echo.
echo ✅ STEP 3 COMPLETE: Project built successfully!
echo.

set /p continue="Continue to Step 4? (Y/N): "
if /i not "%continue%"=="Y" (
    echo Setup paused at Step 3.
    pause
    exit /b 0
)

echo.
echo ===================================================================
echo    📦 STEP 4: Installing Windows Service...
echo ===================================================================
echo.

echo Installing Windows Service...

REM Check if service already exists
sc query "KiteMarketDataService" >nul 2>&1
if %errorlevel% equ 0 (
    echo Service already exists. Stopping and removing old service...
    net stop "KiteMarketDataService" >nul 2>&1
    sc delete "KiteMarketDataService" >nul 2>&1
    timeout /t 2 /nobreak >nul
)

REM Install the service
$ServicePath = (Get-Location).Path + "\bin\Release\net9.0\KiteMarketDataService.Worker.exe"
powershell -Command "New-Service -Name 'KiteMarketDataService' -BinaryPathName '$ServicePath' -DisplayName 'Kite Market Data Service' -Description 'Collects real-time market data from Kite Connect API' -StartupType Automatic"
if %errorlevel% neq 0 (
    echo ❌ Failed to install Windows Service
    goto error
)

echo.
echo ✅ STEP 4 COMPLETE: Windows Service installed!
echo.

set /p continue="Continue to Step 5? (Y/N): "
if /i not "%continue%"=="Y" (
    echo Setup paused at Step 4.
    pause
    exit /b 0
)

echo.
echo ===================================================================
echo    🚀 STEP 5: Starting Windows Service...
echo ===================================================================
echo.

echo Starting service...
net start "KiteMarketDataService"
if %errorlevel% neq 0 (
    echo ❌ Failed to start service
    goto error
)

echo.
echo ✅ STEP 5 COMPLETE: Service started successfully!
echo.

set /p continue="Continue to Step 6? (Y/N): "
if /i not "%continue%"=="Y" (
    echo Setup paused at Step 5.
    pause
    exit /b 0
)

echo.
echo ===================================================================
echo    🌐 STEP 6: Opening web interface...
echo ===================================================================
echo.

echo Waiting for service to initialize...
timeout /t 3 /nobreak >nul

echo Opening web interface...
start http://localhost:5000/token-management.html

echo.
echo ✅ STEP 6 COMPLETE: Web interface opened!
echo.

echo.
echo ===================================================================
echo    🎉 SETUP COMPLETE! 🎉
echo ===================================================================
echo.
echo ✅ Windows Service installed and running
echo ✅ Web interface opened automatically
echo ✅ Service will start automatically on Windows startup
echo ✅ You can now control everything via web interface
echo.
echo 🌐 Web Interface: http://localhost:5000/token-management.html
echo.
echo What you can do now:
echo • Start/Stop/Restart service via web interface
echo • Manage Kite Connect tokens via web interface
echo • Service runs 24/7 in background
echo • No command line needed - everything is web-based!
echo.
echo Press any key to exit...
pause >nul
exit /b 0

:error
echo.
echo ===================================================================
echo    ❌ SETUP FAILED
echo ===================================================================
echo.
echo Please check the error messages above and try again.
echo Make sure you're running as Administrator.
echo.
echo Press any key to exit...
pause >nul
exit /b 1






