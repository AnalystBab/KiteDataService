# Manual Icon Assignment Helper
# This will create shortcuts and provide instructions for manual icon assignment

Write-Host "Creating Shortcuts for Manual Icon Assignment..." -ForegroundColor Green

# Base paths
$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"
$quickAccessFolder = "C:\Users\babu\Desktop\Quick-Access"

# Define shortcuts
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
    },
    @{
        Name = "Quick Access Menu"
        TargetPath = "C:\Users\babu\Desktop\Quick Access Business Data.bat"
        Description = "Simple menu to choose what data to view"
    }
)

# Delete existing shortcuts first
Write-Host "Deleting existing shortcuts..." -ForegroundColor Yellow
foreach ($shortcut in $shortcuts) {
    $shortcutPath = "$quickAccessFolder\$($shortcut.Name).lnk"
    if (Test-Path $shortcutPath) {
        Remove-Item $shortcutPath -Force
        Write-Host "Deleted: $($shortcut.Name)" -ForegroundColor Red
    }
}

# Wait a moment
Start-Sleep -Seconds 2

# Create new shortcuts without icons first
Write-Host "Creating new shortcuts..." -ForegroundColor Green
foreach ($shortcut in $shortcuts) {
    try {
        # Create WScript.Shell object
        $WScriptShell = New-Object -ComObject WScript.Shell
        
        # Create shortcut
        $Shortcut = $WScriptShell.CreateShortcut("$quickAccessFolder\$($shortcut.Name).lnk")
        $Shortcut.TargetPath = $shortcut.TargetPath
        $Shortcut.Description = $shortcut.Description
        
        # Save the shortcut
        $Shortcut.Save()
        
        Write-Host "Created: $($shortcut.Name)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Failed to create: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Shortcuts Created Successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "MANUAL ICON ASSIGNMENT INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host ""
Write-Host "Since automatic icon assignment isn't working, here's how to manually assign icons:" -ForegroundColor White
Write-Host ""
Write-Host "1. Right-click on each shortcut in your Quick-Access folder" -ForegroundColor Cyan
Write-Host "2. Select 'Properties' from the context menu" -ForegroundColor Cyan
Write-Host "3. Click the 'Change Icon...' button" -ForegroundColor Cyan
Write-Host "4. In the 'Look for icons in this file' field, enter one of these paths:" -ForegroundColor Cyan
Write-Host ""
Write-Host "   For Market Transition Data:" -ForegroundColor Green
Write-Host "   C:\Windows\System32\shell32.dll" -ForegroundColor White
Write-Host "   Then select icon #23 (blue refresh arrow)" -ForegroundColor White
Write-Host ""
Write-Host "   For Previous Business Date:" -ForegroundColor Green
Write-Host "   C:\Windows\System32\shell32.dll" -ForegroundColor White
Write-Host "   Then select icon #15 (green calendar)" -ForegroundColor White
Write-Host ""
Write-Host "   For Current Business Date:" -ForegroundColor Green
Write-Host "   C:\Windows\System32\shell32.dll" -ForegroundColor White
Write-Host "   Then select icon #21 (blue chart)" -ForegroundColor White
Write-Host ""
Write-Host "   For All Excel Exports:" -ForegroundColor Green
Write-Host "   C:\Windows\System32\shell32.dll" -ForegroundColor White
Write-Host "   Then select icon #4 (yellow folder)" -ForegroundColor White
Write-Host ""
Write-Host "   For Quick Access Menu:" -ForegroundColor Green
Write-Host "   C:\Windows\System32\shell32.dll" -ForegroundColor White
Write-Host "   Then select icon #25 (orange rocket)" -ForegroundColor White
Write-Host ""
Write-Host "5. Click 'OK' to apply the icon" -ForegroundColor Cyan
Write-Host "6. Click 'OK' to close the Properties dialog" -ForegroundColor Cyan
Write-Host ""
Write-Host "This will give you unique, colorful icons for each shortcut!" -ForegroundColor Green


