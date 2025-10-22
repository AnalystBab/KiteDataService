@echo off
REM 🚀 ONE-CLICK WINDOWS SERVICE SETUP
REM Just double-click this file and everything happens automatically!

title 🎯 One-Click Windows Service Setup

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                                                               ║
echo ║        🚀 ONE-CLICK WINDOWS SERVICE SETUP 🚀                 ║
echo ║                                                               ║
echo ║    This will automatically set up everything for you!        ║
echo ║    Just sit back and watch the magic happen! 🎉              ║
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

echo 🎯 Starting automated setup...
echo.

REM Step 1: Copy Files
echo 📁 STEP 1: Copying Windows Service files...
echo.

REM Copy Services file
if exist "..\Services\WindowsServiceInstaller.cs" (
    if exist "..\..\Services\" (
        copy "..\Services\WindowsServiceInstaller.cs" "..\..\Services\" /Y >nul 2>&1
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
) else (
    echo ❌ WindowsServiceInstaller.cs not found in Services folder
    goto error
)

REM Copy Controllers file
if exist "..\Controllers\ServiceControlController.cs" (
    if exist "..\..\WebApi\Controllers\" (
        copy "..\Controllers\ServiceControlController.cs" "..\..\WebApi\Controllers\" /Y >nul 2>&1
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
) else (
    echo ❌ ServiceControlController.cs not found in Controllers folder
    goto error
)

REM Copy Web Interface file
if exist "..\WebInterface\token-management.html" (
    if exist "..\..\wwwroot\" (
        copy "..\WebInterface\token-management.html" "..\..\wwwroot\" /Y >nul 2>&1
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
) else (
    echo ❌ token-management.html not found in WebInterface folder
    goto error
)

echo ✅ All files copied successfully!
echo.

REM Step 2: Update Project File
echo 📝 STEP 2: Updating project file...
echo.

REM Check if WindowsServices package already exists
findstr /C:"Microsoft.Extensions.Hosting.WindowsServices" "..\..\KiteMarketDataService.Worker.csproj" >nul 2>&1
if %errorlevel% neq 0 (
    echo Adding WindowsServices package to project file...
    
    REM Create a temporary file with the new package reference
    echo ^<PackageReference Include="Microsoft.Extensions.Hosting.WindowsServices" Version="9.0.1" /^> > temp_package.txt
    
    REM Insert the package reference before the closing ItemGroup tag
    powershell -Command "(Get-Content '..\..\KiteMarketDataService.Worker.csproj') -replace '</ItemGroup>', (Get-Content 'temp_package.txt') + [Environment]::NewLine + '</ItemGroup>' | Set-Content '..\..\KiteMarketDataService.Worker.csproj'"
    
    REM Clean up temp file
    del temp_package.txt >nul 2>&1
    
    echo ✅ WindowsServices package added to project
) else (
    echo ✅ WindowsServices package already exists in project
)

echo.

REM Step 3: Build Project
echo 🔨 STEP 3: Building project in Release mode...
echo.

cd /d "..\.."
dotnet build --configuration Release
if %errorlevel% neq 0 (
    echo ❌ Build failed! Please check for errors.
    goto error
)

echo ✅ Project built successfully!
echo.

REM Step 4: Install Windows Service
echo 📦 STEP 4: Installing Windows Service...
echo.

REM Check if service already exists
sc query "KiteMarketDataService" >nul 2>&1
if %errorlevel% equ 0 (
    echo Service already exists. Stopping and removing old service...
    net stop "KiteMarketDataService" >nul 2>&1
    sc delete "KiteMarketDataService" >nul 2>&1
    timeout /t 2 /nobreak >nul
)

REM Install the service
powershell -Command "$ServicePath = (Get-Location).Path + '\bin\Release\net9.0\KiteMarketDataService.Worker.exe'; New-Service -Name 'KiteMarketDataService' -BinaryPathName $ServicePath -DisplayName 'Kite Market Data Service' -Description 'Collects real-time market data from Kite Connect API' -StartupType Automatic"
if %errorlevel% neq 0 (
    echo ❌ Failed to install Windows Service
    goto error
)

echo ✅ Windows Service installed successfully!
echo.

REM Step 5: Start Service
echo 🚀 STEP 5: Starting Windows Service...
echo.

net start "KiteMarketDataService"
if %errorlevel% neq 0 (
    echo ❌ Failed to start service
    goto error
)

echo ✅ Service started successfully!
echo.

REM Step 6: Wait for service to initialize
echo ⏳ STEP 6: Waiting for service to initialize...
echo.

timeout /t 5 /nobreak >nul

REM Step 7: Open Web Interface
echo 🌐 STEP 7: Opening web interface...
echo.

start http://localhost:5000/token-management.html

echo.
echo ===================================================================
echo    🎉 INSTALLATION COMPLETE! 🎉
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
echo    ❌ INSTALLATION FAILED
echo ===================================================================
echo.
echo Please check the error messages above and try again.
echo Make sure you're running as Administrator.
echo.
echo Press any key to exit...
pause >nul
exit /b 1