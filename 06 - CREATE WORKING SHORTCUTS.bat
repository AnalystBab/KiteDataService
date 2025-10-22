@echo off
echo Creating Working Shortcuts with Correct Target Paths...
echo.

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "CreateWorkingShortcuts.ps1"

echo.
echo Working Shortcuts Created!
echo.
echo What was created:
echo    - Deleted old shortcuts with incorrect targets
echo    - Created new shortcuts with working target paths
echo    - Created export folders for target paths
echo.
echo Target Paths:
echo    - Market Transition Data: Main export folder
echo    - Previous Business Date: 2025-09-22 folder
echo    - Current Business Date: 2025-09-23 folder
echo    - All Excel Exports: Main export folder
echo    - Quick Access Menu: Batch file on desktop
echo.
echo Test the shortcuts now - they should open the correct locations!
echo.
pause


