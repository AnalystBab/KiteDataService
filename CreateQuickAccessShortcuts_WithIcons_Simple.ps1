# Create Quick Access Shortcuts with Colorful Icons
# Simple version without emoji characters

Write-Host "Creating Quick Access Shortcuts with Colorful Icons..." -ForegroundColor Green

# Base paths
$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Create shortcuts with unique icons
$shortcuts = @(
    @{
        Name = "Market Transition Data"
        TargetPath = $basePath
        Description = "Quick access to market transition Excel files"
        IconPath = "shell32.dll"
        IconIndex = 23  # Refresh/Update icon (blue circular arrow)
    },
    @{
        Name = "Previous Business Date"
        TargetPath = "$basePath\2025-09-22"
        Description = "Previous business date records (22-09-2025)"
        IconPath = "shell32.dll"
        IconIndex = 15  # Calendar icon (green calendar)
    },
    @{
        Name = "Current Business Date"
        TargetPath = "$basePath\2025-09-23"
        Description = "Current business date records (23-09-2025)"
        IconPath = "shell32.dll"
        IconIndex = 21  # Chart/Graph icon (blue chart)
    },
    @{
        Name = "All Excel Exports"
        TargetPath = $basePath
        Description = "All consolidated Excel exports"
        IconPath = "shell32.dll"
        IconIndex = 4   # Folder icon (yellow folder)
    },
    @{
        Name = "Quick Access Menu"
        TargetPath = "$desktopPath\Quick Access Business Data.bat"
        Description = "Simple menu to choose what data to view"
        IconPath = "shell32.dll"
        IconIndex = 25  # Rocket/Launch icon (orange rocket)
    }
)

# Create shortcuts with icons
foreach ($shortcut in $shortcuts) {
    try {
        # Create WScript.Shell object
        $WScriptShell = New-Object -ComObject WScript.Shell
        
        # Create shortcut
        $Shortcut = $WScriptShell.CreateShortcut("$desktopPath\$($shortcut.Name).lnk")
        $Shortcut.TargetPath = $shortcut.TargetPath
        $Shortcut.Description = $shortcut.Description
        
        # Set icon if specified
        if ($shortcut.IconPath -and $shortcut.IconIndex) {
            $Shortcut.IconLocation = "$($shortcut.IconPath),$($shortcut.IconIndex)"
        }
        
        $Shortcut.Save()
        
        Write-Host "Created: $($shortcut.Name) with icon" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Failed to create: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create an enhanced batch file with colors
$batchContent = @"
@echo off
color 0A
title Quick Access to Business Date Records

:menu
cls
echo.
echo ================================================================
echo                QUICK ACCESS MENU
echo ================================================================
echo.
echo  1. Market Transition Data
echo  2. Previous Business Date (22-09-2025)
echo  3. Current Business Date (23-09-2025)
echo  4. All Excel Exports
echo  5. Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo Opening Market Transition Data...
    start "" "$basePath"
    goto :end
)
if "%choice%"=="2" (
    echo Opening Previous Business Date...
    start "" "$basePath\2025-09-22"
    goto :end
)
if "%choice%"=="3" (
    echo Opening Current Business Date...
    start "" "$basePath\2025-09-23"
    goto :end
)
if "%choice%"=="4" (
    echo Opening All Excel Exports...
    start "" "$basePath"
    goto :end
)
if "%choice%"=="5" (
    echo Goodbye!
    exit
)

echo Invalid choice! Please try again.
timeout /t 2 /nobreak > nul
goto :menu

:end
echo Done! Check your file explorer.
timeout /t 3 /nobreak > nul
goto :menu
"@

$batchPath = "$desktopPath\Quick Access Business Data.bat"
$batchContent | Out-File -FilePath $batchPath -Encoding ASCII

Write-Host "Created: Enhanced Quick Access Business Data.bat" -ForegroundColor Cyan

Write-Host ""
Write-Host "Quick Access Setup Complete with Colorful Icons!" -ForegroundColor Green
Write-Host ""
Write-Host "Created Shortcuts with Icons:" -ForegroundColor Yellow
Write-Host "   - Market Transition Data (Blue Refresh Icon)" -ForegroundColor Cyan
Write-Host "   - Previous Business Date (Green Calendar Icon)" -ForegroundColor Cyan
Write-Host "   - Current Business Date (Blue Chart Icon)" -ForegroundColor Cyan
Write-Host "   - All Excel Exports (Yellow Folder Icon)" -ForegroundColor Cyan
Write-Host "   - Quick Access Menu (Orange Rocket Icon)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Created Enhanced Script:" -ForegroundColor Yellow
Write-Host "   - Quick Access Business Data.bat (Colorful menu)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Usage:" -ForegroundColor Green
Write-Host "   - Each shortcut has a unique, colorful icon for instant recognition" -ForegroundColor White
Write-Host "   - Double-click shortcuts for instant access" -ForegroundColor White
Write-Host "   - Run .bat file for colorful menu" -ForegroundColor White
Write-Host ""
Write-Host "Colorful Quick Access Ready!" -ForegroundColor Green


