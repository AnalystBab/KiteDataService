@echo off
REM 🗑️ WINDOWS SERVICE UNINSTALLER
REM Completely removes the Windows Service and all related files

title 🗑️ Windows Service Uninstaller

echo.
echo ╔═══════════════════════════════════════════════════════════════╗
echo ║                                                               ║
echo ║        🗑️ WINDOWS SERVICE UNINSTALLER 🗑️                   ║
echo ║                                                               ║
echo ║    This will completely remove the Windows Service           ║
echo ║    and all related files from your system.                  ║
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

echo ✅ Running as Administrator - Good!
echo.

echo ⚠️  WARNING: This will completely remove the Windows Service!
echo.
echo What will be removed:
echo • Windows Service (KiteMarketDataService)
echo • Service will be stopped and deleted
echo • All service-related files
echo.
echo The main project files will NOT be affected.
echo.

set /p confirm="Are you sure you want to uninstall? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Uninstall cancelled.
    pause
    exit /b 0
)

echo.
echo ===================================================================
echo    🛑 STEP 1: Stopping Windows Service...
echo ===================================================================
echo.

REM Check if service exists and is running
sc query "KiteMarketDataService" >nul 2>&1
if %errorlevel% equ 0 (
    echo Service found. Stopping service...
    net stop "KiteMarketDataService"
    if %errorlevel% equ 0 (
        echo ✅ Service stopped successfully
    ) else (
        echo ⚠️  Service was not running or failed to stop
    )
    
    echo.
    echo ===================================================================
    echo    🗑️ STEP 2: Removing Windows Service...
    echo ===================================================================
    echo.
    
    echo Removing service from Windows...
    sc delete "KiteMarketDataService"
    if %errorlevel% equ 0 (
        echo ✅ Service removed successfully
    ) else (
        echo ❌ Failed to remove service
        goto error
    )
) else (
    echo ℹ️  Service not found - may already be uninstalled
)

echo.
echo ===================================================================
echo    🧹 STEP 3: Cleaning up files...
echo ===================================================================
echo.

echo Removing copied files from main project...

REM Remove copied files (optional - user can choose to keep them)
set /p cleanup="Remove copied Windows Service files from main project? (Y/N): "
if /i "%cleanup%"=="Y" (
    echo Removing copied files...
    
    if exist "..\Services\WindowsServiceInstaller.cs" (
        del "..\Services\WindowsServiceInstaller.cs" >nul 2>&1
        echo ✅ Removed WindowsServiceInstaller.cs
    )
    
    if exist "..\WebApi\Controllers\ServiceControlController.cs" (
        del "..\WebApi\Controllers\ServiceControlController.cs" >nul 2>&1
        echo ✅ Removed ServiceControlController.cs
    )
    
    if exist "..\wwwroot\token-management.html" (
        del "..\wwwroot\token-management.html" >nul 2>&1
        echo ✅ Removed token-management.html
    )
    
    echo ✅ Copied files removed
) else (
    echo ℹ️  Keeping copied files in main project
)

echo.
echo ===================================================================
echo    🎉 UNINSTALL COMPLETE! 🎉
echo ===================================================================
echo.
echo ✅ Windows Service completely removed
echo ✅ Service will no longer start automatically
echo ✅ All service-related components removed
echo.
echo Note: The main project is unchanged and can still be run manually
echo using: dotnet run
echo.
echo Press any key to exit...
pause >nul
exit /b 0

:error
echo.
echo ===================================================================
echo    ❌ UNINSTALL FAILED
echo ===================================================================
echo.
echo Please check the error messages above and try again.
echo Make sure you're running as Administrator.
echo.
echo Press any key to exit...
pause >nul
exit /b 1






