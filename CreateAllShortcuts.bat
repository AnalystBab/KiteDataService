@echo off
echo Creating Desktop Shortcuts for Kite Market Data Service...

set "DesktopFolder=C:\Users\babu\Desktop\KiteMarketDataService"

REM Create Task 1 - START SERVICE
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DesktopFolder%\01 - START SERVICE.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%DesktopFolder%\Task1_StartService.ps1\"'; $Shortcut.WorkingDirectory = '%DesktopFolder%'; $Shortcut.Description = 'Initialize and start the Kite Market Data Service'; $Shortcut.Save()"

REM Create Task 2 - MONITOR DATA
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DesktopFolder%\02 - MONITOR DATA.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%DesktopFolder%\Task2_MonitorData.ps1\"'; $Shortcut.WorkingDirectory = '%DesktopFolder%'; $Shortcut.Description = 'Monitor live market data collection status'; $Shortcut.Save()"

REM Create Task 3 - STORE EOD
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DesktopFolder%\03 - STORE EOD.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%DesktopFolder%\Task3_StoreEOD.ps1\"'; $Shortcut.WorkingDirectory = '%DesktopFolder%'; $Shortcut.Description = 'Create End of Day data snapshot'; $Shortcut.Save()"

REM Create Task 4 - COMPARE LIMITS
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DesktopFolder%\04 - COMPARE LIMITS.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%DesktopFolder%\Task4_CompareLimits.ps1\"'; $Shortcut.WorkingDirectory = '%DesktopFolder%'; $Shortcut.Description = 'Detect circuit limit changes'; $Shortcut.Save()"

REM Create Task 5 - VIEW CHANGES
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DesktopFolder%\05 - VIEW CHANGES.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%DesktopFolder%\Task5_ViewChanges.ps1\"'; $Shortcut.WorkingDirectory = '%DesktopFolder%'; $Shortcut.Description = 'View circuit limit change reports'; $Shortcut.Save()"

REM Create Task 6 - ANALYZE NIFTY
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DesktopFolder%\06 - ANALYZE NIFTY.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%DesktopFolder%\Task6_AnalyzeNIFTY.ps1\"'; $Shortcut.WorkingDirectory = '%DesktopFolder%'; $Shortcut.Description = 'Analyze NIFTY options with EOD comparison'; $Shortcut.Save()"

REM Create Task 7 - DAILY SUMMARY
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DesktopFolder%\07 - DAILY SUMMARY.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%DesktopFolder%\Task7_DailySummary.ps1\"'; $Shortcut.WorkingDirectory = '%DesktopFolder%'; $Shortcut.Description = 'Generate comprehensive daily summary report'; $Shortcut.Save()"

REM Create Task 8 - STOP SERVICE
powershell -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DesktopFolder%\08 - STOP SERVICE.lnk'); $Shortcut.TargetPath = 'powershell.exe'; $Shortcut.Arguments = '-ExecutionPolicy Bypass -File \"%DesktopFolder%\Task8_StopService.ps1\"'; $Shortcut.WorkingDirectory = '%DesktopFolder%'; $Shortcut.Description = 'Gracefully stop the market data service'; $Shortcut.Save()"

echo All shortcuts created successfully!
echo Location: %DesktopFolder%
echo.
echo Now starting the market data service since market is open...
echo.
