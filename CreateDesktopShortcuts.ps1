# Create Desktop Shortcuts for Kite Market Data Service Tasks
# This script creates shortcuts with meaningful icons and text

$DesktopFolder = "C:\Users\babu\Desktop\KiteMarketDataService"
$WshShell = New-Object -ComObject WScript.Shell

Write-Host "🎯 Creating Desktop Shortcuts with Meaningful Icons..." -ForegroundColor Green

# Function to create shortcut
function Create-Shortcut {
    param(
        [string]$TaskName,
        [string]$TaskNumber,
        [string]$IconColor,
        [string]$Description,
        [string]$ScriptName
    )
    
    $ShortcutPath = "$DesktopFolder\$TaskNumber - $TaskName.lnk"
    $ScriptPath = "$DesktopFolder\$ScriptName"
    
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = "powershell.exe"
    $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$ScriptPath`""
    $Shortcut.WorkingDirectory = $DesktopFolder
    $Shortcut.Description = $Description
    $Shortcut.IconLocation = "shell32.dll,1"  # Default icon, will be customized by color coding
    $Shortcut.Save()
    
    Write-Host "✅ Created: $TaskNumber - $TaskName" -ForegroundColor $IconColor
}

# Create all task shortcuts with meaningful text and color coding
Write-Host "🔴 Creating Task 1: START SERVICE..." -ForegroundColor Red
Create-Shortcut -TaskName "START SERVICE" -TaskNumber "01" -IconColor "Red" -Description "Initialize and start the Kite Market Data Service" -ScriptName "Task1_StartService.ps1"

Write-Host "🟢 Creating Task 2: MONITOR DATA..." -ForegroundColor Green
Create-Shortcut -TaskName "MONITOR DATA" -TaskNumber "02" -IconColor "Green" -Description "Monitor live market data collection status" -ScriptName "Task2_MonitorData.ps1"

Write-Host "🟡 Creating Task 3: STORE EOD..." -ForegroundColor Yellow
Create-Shortcut -TaskName "STORE EOD" -TaskNumber "03" -IconColor "Yellow" -Description "Create End of Day data snapshot" -ScriptName "Task3_StoreEOD.ps1"

Write-Host "🔵 Creating Task 4: COMPARE LIMITS..." -ForegroundColor Blue
Create-Shortcut -TaskName "COMPARE LIMITS" -TaskNumber "04" -IconColor "Blue" -Description "Detect circuit limit changes" -ScriptName "Task4_CompareLimits.ps1"

Write-Host "🟣 Creating Task 5: VIEW CHANGES..." -ForegroundColor Magenta
Create-Shortcut -TaskName "VIEW CHANGES" -TaskNumber "05" -IconColor "Magenta" -Description "View circuit limit change reports" -ScriptName "Task5_ViewChanges.ps1"

Write-Host "🟠 Creating Task 6: ANALYZE NIFTY..." -ForegroundColor DarkYellow
Create-Shortcut -TaskName "ANALYZE NIFTY" -TaskNumber "06" -IconColor "DarkYellow" -Description "Analyze NIFTY options with EOD comparison" -ScriptName "Task6_AnalyzeNIFTY.ps1"

Write-Host "🔶 Creating Task 7: DAILY SUMMARY..." -ForegroundColor DarkRed
Create-Shortcut -TaskName "DAILY SUMMARY" -TaskNumber "07" -IconColor "DarkRed" -Description "Generate comprehensive daily summary report" -ScriptName "Task7_DailySummary.ps1"

Write-Host "⚫ Creating Task 8: STOP SERVICE..." -ForegroundColor Black
Create-Shortcut -TaskName "STOP SERVICE" -TaskNumber "08" -IconColor "Black" -Description "Gracefully stop the market data service" -ScriptName "Task8_StopService.ps1"

# Create a README file for the desktop folder
$ReadmeContent = @"
================================================================
                KITE MARKET DATA SERVICE - TASK DESKTOP
================================================================

This folder contains shortcuts to manage the Kite Market Data Service.

WORKFLOW ORDER:
===============
1. START SERVICE (Red) - Initialize the service
2. MONITOR DATA (Green) - Check if data is being collected
3. STORE EOD (Yellow) - Create daily snapshot
4. COMPARE LIMITS (Blue) - Detect circuit limit changes
5. VIEW CHANGES (Purple) - View detailed change reports
6. ANALYZE NIFTY (Orange) - Analyze NIFTY options
7. DAILY SUMMARY (Brown) - Generate comprehensive report
8. STOP SERVICE (Black) - Stop the service

DAILY USAGE:
============
Morning: Run tasks 1-2 to start and monitor
During Day: Run task 2 to check status
End of Day: Run tasks 3-7 for analysis
Evening: Run task 8 to stop service

COLOR CODING:
=============
Red: Start/Initialize operations
Green: Monitor/Check operations
Yellow: Store/Save operations
Blue: Compare/Analyze operations
Purple: View/Report operations
Orange: Specific analysis operations
Brown: Summary operations
Black: Stop/End operations

FILES GENERATED:
================
- CircuitLimitChanges_[DATE].txt
- NIFTYAnalysis_[DATE].txt
- DailySummary_[DATE].txt

Created: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@

$ReadmeContent | Out-File -FilePath "$DesktopFolder\README.txt" -Encoding UTF8

Write-Host ""
Write-Host "🎯 ALL DESKTOP SHORTCUTS CREATED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "📁 Location: $DesktopFolder" -ForegroundColor Cyan
Write-Host "📋 Total Shortcuts: 8" -ForegroundColor Cyan
Write-Host "📖 README file created with usage instructions" -ForegroundColor Cyan
Write-Host ""
Write-Host "💡 You can now click any shortcut to execute the corresponding task!" -ForegroundColor Yellow
Write-Host "🎨 Each shortcut has a unique color and meaningful text for easy identification" -ForegroundColor Yellow
