@echo off
echo Clearing All Table Data for Fresh Start...
echo.

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "ClearAllTables.ps1"

echo.
echo All Tables Cleared Successfully!
echo.
echo Ready for fresh data collection!
echo.
echo You can now run your service: dotnet run
echo.
pause


