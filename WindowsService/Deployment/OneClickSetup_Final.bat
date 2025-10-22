@echo off
echo Starting Windows Service Setup...
echo.

REM Change to the script's directory (important when running as admin)
cd /d "%~dp0"
echo Changed to script directory: %CD%
echo.

echo Step 1: Checking and copying files...
echo.

REM Check if files already exist in main project
if exist "..\..\Services\WindowsServiceInstaller.cs" (
    echo ✅ WindowsServiceInstaller.cs already exists in main project
) else (
    echo Copying WindowsServiceInstaller.cs...
    if exist "..\Services\WindowsServiceInstaller.cs" (
        copy "..\Services\WindowsServiceInstaller.cs" "..\..\Services\" /Y
        if %errorlevel% equ 0 (
            echo ✅ Copied WindowsServiceInstaller.cs
        ) else (
            echo ❌ Failed to copy WindowsServiceInstaller.cs
            goto error
        )
    ) else (
        echo ❌ Source file not found
        goto error
    )
)

if exist "..\..\WebApi\Controllers\ServiceControlController.cs" (
    echo ✅ ServiceControlController.cs already exists in main project
) else (
    echo Copying ServiceControlController.cs...
    if exist "..\Controllers\ServiceControlController.cs" (
        copy "..\Controllers\ServiceControlController.cs" "..\..\WebApi\Controllers\" /Y
        if %errorlevel% equ 0 (
            echo ✅ Copied ServiceControlController.cs
        ) else (
            echo ❌ Failed to copy ServiceControlController.cs
            goto error
        )
    ) else (
        echo ❌ Source file not found
        goto error
    )
)

if exist "..\..\wwwroot\token-management.html" (
    echo ✅ token-management.html already exists in main project
) else (
    echo Copying token-management.html...
    if exist "..\WebInterface\token-management.html" (
        copy "..\WebInterface\token-management.html" "..\..\wwwroot\" /Y
        if %errorlevel% equ 0 (
            echo ✅ Copied token-management.html
        ) else (
            echo ❌ Failed to copy token-management.html
            goto error
        )
    ) else (
        echo ❌ Source file not found
        goto error
    )
)

echo.
echo ✅ All files are ready!
echo.

echo Step 2: Updating project file...
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
echo Step 3: Building project...
cd /d "..\.."
dotnet build --configuration Release
if %errorlevel% neq 0 (
    echo ❌ Build failed
    goto error
)

echo ✅ Build successful!
echo.

echo Step 4: Installing service...
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
powershell -Command "$ServicePath = (Get-Location).Path + '\bin\Release\net9.0-windows\KiteMarketDataService.Worker.exe'; New-Service -Name 'KiteMarketDataService' -BinaryPathName $ServicePath -DisplayName 'Kite Market Data Service' -Description 'Collects real-time market data from Kite Connect API' -StartupType Automatic"
if %errorlevel% neq 0 (
    echo ❌ Service installation failed
    goto error
)

echo ✅ Service installed!
echo.

echo Step 5: Starting service...
net start "KiteMarketDataService"
if %errorlevel% neq 0 (
    echo ❌ Service start failed
    goto error
)

echo ✅ Service started!
echo.

echo Step 6: Opening web interface...
start http://localhost:5000/token-management.html

echo.
echo ========================================
echo    SETUP COMPLETE!
echo ========================================
echo.
echo Service is running and web interface is open.
echo.
echo What you can do now:
echo • Start/Stop/Restart service via web interface
echo • Manage Kite Connect tokens via web interface
echo • Service runs 24/7 in background
echo.
pause
exit /b 0

:error
echo.
echo ========================================
echo    SETUP FAILED
echo ========================================
echo.
echo Check the error messages above.
echo.
pause
exit /b 1
