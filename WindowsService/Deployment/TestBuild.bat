@echo off
REM Test if the service code will build correctly
REM This script tests the build before running OneClickSetup

title 🔧 Testing Service Code Build

echo.
echo ===================================================================
echo    🔧 TESTING SERVICE CODE BUILD
echo ===================================================================
echo.
echo This will test if the Windows Service code will build correctly
echo before running the full OneClickSetup.
echo.

REM Check if we're in the right directory
if not exist "Services\WindowsServiceInstaller.cs" (
    echo ❌ ERROR: Please run this script from the WindowsService folder
    echo Current directory: %CD%
    echo Expected files not found.
    pause
    exit /b 1
)

echo ✅ Found Windows Service files
echo.

REM Step 1: Copy files to main project
echo 📁 STEP 1: Copying files to main project...
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

echo ✅ All files copied successfully!
echo.

REM Step 2: Update project file
echo 📝 STEP 2: Updating project file...
echo.

REM Check if WindowsServices package already exists
findstr /C:"Microsoft.Extensions.Hosting.WindowsServices" "..\KiteMarketDataService.Worker.csproj" >nul 2>&1
if %errorlevel% neq 0 (
    echo Adding WindowsServices package to project file...
    
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

REM Step 3: Test build
echo 🔨 STEP 3: Testing build...
echo.

cd /d ".."
echo Building project in Debug mode first...
dotnet build --configuration Debug
if %errorlevel% neq 0 (
    echo ❌ Debug build failed! Please check for errors.
    echo.
    echo Common issues:
    echo • Missing using statements
    echo • Missing service registrations
    echo • Missing dependencies
    echo.
    goto error
)

echo ✅ Debug build successful!
echo.

echo Building project in Release mode...
dotnet build --configuration Release
if %errorlevel% neq 0 (
    echo ❌ Release build failed! Please check for errors.
    goto error
)

echo ✅ Release build successful!
echo.

echo ===================================================================
echo    🎉 BUILD TEST SUCCESSFUL! 🎉
echo ===================================================================
echo.
echo ✅ All files copied successfully
echo ✅ Project file updated with required packages
echo ✅ Debug build successful
echo ✅ Release build successful
echo.
echo 🚀 The service code is ready for OneClickSetup!
echo.
echo You can now safely run:
echo • OneClickSetup.bat
echo • StepByStep.bat
echo • AutoInstaller.bat
echo.
echo Press any key to exit...
pause >nul
exit /b 0

:error
echo.
echo ===================================================================
echo    ❌ BUILD TEST FAILED
echo ===================================================================
echo.
echo Please check the error messages above and fix the issues.
echo Common solutions:
echo • Check that all required services are registered
echo • Verify all using statements are correct
echo • Make sure all dependencies are available
echo.
echo Press any key to exit...
pause >nul
exit /b 1






