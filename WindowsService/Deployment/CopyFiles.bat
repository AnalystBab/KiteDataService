@echo off
REM Copy Windows Service files to main project
REM Run this from the WindowsService folder

title Copy Windows Service Files

echo.
echo ===================================================================
echo    COPYING WINDOWS SERVICE FILES TO MAIN PROJECT
echo ===================================================================
echo.

REM Check if we're in the right directory
if not exist "Services\WindowsServiceInstaller.cs" (
    echo ERROR: Please run this script from the WindowsService folder
    echo Current directory: %CD%
    echo Expected files not found.
    pause
    exit /b 1
)

echo Copying files to main project...
echo.

REM Copy Services file
if exist "..\Services\" (
    copy "Services\WindowsServiceInstaller.cs" "..\Services\" >nul
    echo ✅ Copied WindowsServiceInstaller.cs
) else (
    echo ❌ Services folder not found in parent directory
)

REM Copy Controllers file
if exist "..\WebApi\Controllers\" (
    copy "Controllers\ServiceControlController.cs" "..\WebApi\Controllers\" >nul
    echo ✅ Copied ServiceControlController.cs
) else (
    echo ❌ WebApi\Controllers folder not found in parent directory
)

REM Copy Web Interface file
if exist "..\wwwroot\" (
    copy "WebInterface\token-management.html" "..\wwwroot\" >nul
    echo ✅ Copied token-management.html
) else (
    echo ❌ wwwroot folder not found in parent directory
)

REM Copy Scripts to main project root
copy "Scripts\InstallService.ps1" "..\" >nul
echo ✅ Copied InstallService.ps1

copy "Scripts\ManageService.bat" "..\" >nul
echo ✅ Copied ManageService.bat

echo.
echo ===================================================================
echo    FILES COPIED SUCCESSFULLY!
echo ===================================================================
echo.
echo Next steps:
echo 1. Update your .csproj file (add WindowsServices package)
echo 2. Build the project: dotnet build --configuration Release
echo 3. Run ManageService.bat as Administrator
echo 4. Choose "1. Install Windows Service"
echo 5. Open http://localhost:5000/token-management.html
echo.
echo Press any key to exit...
pause >nul






