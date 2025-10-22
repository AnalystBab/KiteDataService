@echo off
echo Creating Shortcuts for Manual Icon Assignment...
echo.

REM Run PowerShell script
powershell -ExecutionPolicy Bypass -File "ManualIconAssignment.ps1"

echo.
echo Shortcuts Created Successfully!
echo.
echo MANUAL ICON ASSIGNMENT INSTRUCTIONS:
echo.
echo Since automatic icon assignment isn't working, here's how to manually assign icons:
echo.
echo 1. Right-click on each shortcut in your Quick-Access folder
echo 2. Select 'Properties' from the context menu
echo 3. Click the 'Change Icon...' button
echo 4. In the 'Look for icons in this file' field, enter one of these paths:
echo.
echo    For Market Transition Data:
echo    C:\Windows\System32\shell32.dll
echo    Then select icon #23 (blue refresh arrow)
echo.
echo    For Previous Business Date:
echo    C:\Windows\System32\shell32.dll
echo    Then select icon #15 (green calendar)
echo.
echo    For Current Business Date:
echo    C:\Windows\System32\shell32.dll
echo    Then select icon #21 (blue chart)
echo.
echo    For All Excel Exports:
echo    C:\Windows\System32\shell32.dll
echo    Then select icon #4 (yellow folder)
echo.
echo    For Quick Access Menu:
echo    C:\Windows\System32\shell32.dll
echo    Then select icon #25 (orange rocket)
echo.
echo 5. Click 'OK' to apply the icon
echo 6. Click 'OK' to close the Properties dialog
echo.
echo This will give you unique, colorful icons for each shortcut!
echo.
pause


