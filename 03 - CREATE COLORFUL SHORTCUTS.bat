@echo off
echo Creating Quick Access Shortcuts with Colorful Icons...
echo.

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "CreateQuickAccessShortcuts_WithIcons_Simple.ps1"

echo.
echo Quick Access Setup Complete with Colorful Icons!
echo.
echo You now have:
echo    - Desktop shortcuts with unique, colorful icons
echo    - Enhanced batch file with colorful menu
echo.
echo Each shortcut has a different icon for instant recognition:
echo    - Market Transition Data (Blue Refresh Icon)
echo    - Previous Business Date (Green Calendar Icon)
echo    - Current Business Date (Blue Chart Icon)
echo    - All Excel Exports (Yellow Folder Icon)
echo    - Quick Access Menu (Orange Rocket Icon)
echo.
echo Double-click any desktop shortcut to access your data!
echo.
pause


