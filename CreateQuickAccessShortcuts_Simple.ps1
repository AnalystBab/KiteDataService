# Create Quick Access Shortcuts for Business Date Records
# Simple version without emoji characters

Write-Host "Creating Quick Access Shortcuts..." -ForegroundColor Green

# Base paths
$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Create shortcuts
$shortcuts = @(
    @{
        Name = "Market Transition Data"
        TargetPath = $basePath
        Description = "Quick access to market transition Excel files"
    },
    @{
        Name = "Previous Business Date"
        TargetPath = "$basePath\2025-09-22"
        Description = "Previous business date records (22-09-2025)"
    },
    @{
        Name = "Current Business Date"
        TargetPath = "$basePath\2025-09-23"
        Description = "Current business date records (23-09-2025)"
    },
    @{
        Name = "All Excel Exports"
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
        
        Write-Host "Created: $($shortcut.Name)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Failed to create: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create a batch file for quick folder opening
$batchContent = @"
@echo off
echo Quick Access to Business Date Records
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

Write-Host "Created: Quick Access Business Data.bat" -ForegroundColor Cyan

Write-Host ""
Write-Host "Quick Access Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Created Shortcuts:" -ForegroundColor Yellow
Write-Host "   - Market Transition Data" -ForegroundColor Cyan
Write-Host "   - Previous Business Date" -ForegroundColor Cyan
Write-Host "   - Current Business Date" -ForegroundColor Cyan
Write-Host "   - All Excel Exports" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created Script:" -ForegroundColor Yellow
Write-Host "   - Quick Access Business Data.bat" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage:" -ForegroundColor Green
Write-Host "   - Double-click desktop shortcuts for instant access" -ForegroundColor White
Write-Host "   - Run .bat file for simple menu" -ForegroundColor White
Write-Host ""
Write-Host "Quick Access Ready!" -ForegroundColor Green


