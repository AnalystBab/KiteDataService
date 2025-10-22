# Create Quick Access Shortcuts for Business Date Records
# Run this script to create desktop shortcuts for instant access

Write-Host "🚀 Creating Quick Access Shortcuts..." -ForegroundColor Green

# Base paths
$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Create shortcuts
$shortcuts = @(
    @{
        Name = "📊 Market Transition Data"
        TargetPath = $basePath
        Description = "Quick access to market transition Excel files"
    },
    @{
        Name = "📅 Previous Business Date"
        TargetPath = "$basePath\2025-09-22"
        Description = "Previous business date records (22-09-2025)"
    },
    @{
        Name = "📅 Current Business Date"
        TargetPath = "$basePath\2025-09-23"
        Description = "Current business date records (23-09-2025)"
    },
    @{
        Name = "📁 All Excel Exports"
        TargetPath = $basePath
        Description = "All consolidated Excel exports"
    }
)

foreach ($shortcut in $shortcuts) {
    try {
        # Create WScript.Shell object
        $WScriptShell = New-Object -ComObject WScript.Shell
        
        # Create shortcut
        $Shortcut = $WScriptShell.CreateShortcut("$desktopPath\$($shortcut.Name).lnk")
        $Shortcut.TargetPath = $shortcut.TargetPath
        $Shortcut.Description = $shortcut.Description
        $Shortcut.Save()
        
        Write-Host "✅ Created: $($shortcut.Name)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Failed to create: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create a batch file for quick folder opening
$batchContent = @"
@echo off
echo 🚀 Quick Access to Business Date Records
echo.
echo 1. Market Transition Data
echo 2. Previous Business Date (22-09-2025)
echo 3. Current Business Date (23-09-2025)
echo 4. All Excel Exports
echo 5. Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    start "" "$basePath"
    goto :end
)
if "%choice%"=="2" (
    start "" "$basePath\2025-09-22"
    goto :end
)
if "%choice%"=="3" (
    start "" "$basePath\2025-09-23"
    goto :end
)
if "%choice%"=="4" (
    start "" "$basePath"
    goto :end
)
if "%choice%"=="5" (
    exit
)

:end
pause
"@

$batchPath = "$desktopPath\Quick Access Business Data.bat"
$batchContent | Out-File -FilePath $batchPath -Encoding ASCII

Write-Host "✅ Created: Quick Access Business Data.bat" -ForegroundColor Cyan

# Create a PowerShell script for advanced access
$psContent = @"
# Quick Access PowerShell Script
Write-Host "🚀 Business Date Records Quick Access" -ForegroundColor Green
Write-Host ""

# Get current date
`$currentDate = Get-Date -Format "yyyy-MM-dd"
`$previousDate = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")

Write-Host "📅 Current Date: `$currentDate" -ForegroundColor Yellow
Write-Host "📅 Previous Date: `$previousDate" -ForegroundColor Yellow
Write-Host ""

# Base path
`$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"

# Check for market transition folder
`$transitionFolder = Get-ChildItem -Path `$basePath -Directory | Where-Object { `$_.Name -like "*MarketTransition*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (`$transitionFolder) {
    Write-Host "🔄 Latest Market Transition: `$(`$transitionFolder.Name)" -ForegroundColor Green
    Write-Host "   Path: `$(`$transitionFolder.FullName)" -ForegroundColor Cyan
    Write-Host ""
}

# Check for business date folders
`$businessDateFolders = Get-ChildItem -Path `$basePath -Directory | Where-Object { `$_.Name -match "^\d{4}-\d{2}-\d{2}$" } | Sort-Object Name -Descending

Write-Host "📊 Available Business Date Folders:" -ForegroundColor Green
foreach (`$folder in `$businessDateFolders) {
    `$excelFiles = Get-ChildItem -Path `$folder.FullName -Recurse -Filter "*.xlsx"
    Write-Host "   📁 `$(`$folder.Name) - `$(`$excelFiles.Count) Excel files" -ForegroundColor Cyan
}
Write-Host ""

# Menu
Write-Host "🎯 Quick Actions:" -ForegroundColor Green
Write-Host "1. Open Market Transition Folder (Latest)"
Write-Host "2. Open Previous Business Date Folder"
Write-Host "3. Open Current Business Date Folder"
Write-Host "4. Open All Excel Exports Folder"
Write-Host "5. Exit"
Write-Host ""

`$choice = Read-Host "Enter your choice (1-5)"

switch (`$choice) {
    "1" {
        if (`$transitionFolder) {
            Start-Process "explorer.exe" -ArgumentList "`"`$(`$transitionFolder.FullName)`""
        } else {
            Write-Host "❌ No market transition folder found" -ForegroundColor Red
        }
    }
    "2" {
        `$prevFolder = `$businessDateFolders | Where-Object { `$_.Name -eq `$previousDate }
        if (`$prevFolder) {
            Start-Process "explorer.exe" -ArgumentList "`"`$(`$prevFolder.FullName)`""
        } else {
            Write-Host "❌ No previous business date folder found for `$previousDate" -ForegroundColor Red
        }
    }
    "3" {
        `$currentFolder = `$businessDateFolders | Where-Object { `$_.Name -eq `$currentDate }
        if (`$currentFolder) {
            Start-Process "explorer.exe" -ArgumentList "`"`$(`$currentFolder.FullName)`""
        } else {
            Write-Host "❌ No current business date folder found for `$currentDate" -ForegroundColor Red
        }
    }
    "4" {
        Start-Process "explorer.exe" -ArgumentList "`"`$basePath`""
    }
    "5" {
        exit
    }
    default {
        Write-Host "❌ Invalid choice" -ForegroundColor Red
    }
}

Read-Host "Press Enter to continue"
"@

$psPath = "$desktopPath\Quick Access Business Data.ps1"
$psContent | Out-File -FilePath $psPath -Encoding UTF8

Write-Host "✅ Created: Quick Access Business Data.ps1" -ForegroundColor Cyan

Write-Host ""
Write-Host "🎉 Quick Access Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Created Shortcuts:" -ForegroundColor Yellow
Write-Host "   • 📊 Market Transition Data" -ForegroundColor Cyan
Write-Host "   • 📅 Previous Business Date" -ForegroundColor Cyan
Write-Host "   • 📅 Current Business Date" -ForegroundColor Cyan
Write-Host "   • 📁 All Excel Exports" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Created Scripts:" -ForegroundColor Yellow
Write-Host "   • Quick Access Business Data.bat" -ForegroundColor Cyan
Write-Host "   • Quick Access Business Data.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Usage:" -ForegroundColor Green
Write-Host "   • Double-click desktop shortcuts for instant access" -ForegroundColor White
Write-Host "   • Run .bat file for simple menu" -ForegroundColor White
Write-Host "   • Run .ps1 file for advanced PowerShell menu" -ForegroundColor White
Write-Host ""
Write-Host "⚡ Quick Access Ready!" -ForegroundColor Green


