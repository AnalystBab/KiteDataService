@echo off
echo Fixing Shortcut Icons in Quick-Access Folder...
echo.

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "FixShortcutIcons_InFolder.ps1"

echo.
echo Icon Fix Complete!
echo.
echo Your shortcuts in the Quick-Access folder should now have:
echo    - Market Transition Data: Blue refresh icon
echo    - Previous Business Date: Green calendar icon
echo    - Current Business Date: Blue chart icon
echo    - All Excel Exports: Yellow folder icon
echo    - Quick Access Menu: Orange rocket icon
echo.
echo Check your Quick-Access folder - shortcuts should now have different icons!
echo.
pause


