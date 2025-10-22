# Create Unique Shortcuts with Different Icons
# This will delete existing shortcuts and create new ones with proper icons

Write-Host "Creating Unique Shortcuts with Different Icons..." -ForegroundColor Green

# Base paths
$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"
$quickAccessFolder = "C:\Users\babu\Desktop\Quick-Access"

# Define shortcuts with different icon sources
$shortcuts = @(
    @{
        Name = "Market Transition Data"
        TargetPath = $basePath
        Description = "Quick access to market transition Excel files"
        IconPath = "C:\Windows\System32\imageres.dll"
        IconIndex = 2
    },
    @{
        Name = "Previous Business Date"
        TargetPath = "$basePath\2025-09-22"
        Description = "Previous business date records (22-09-2025)"
        IconPath = "C:\Windows\System32\imageres.dll"
        IconIndex = 15
    },
    @{
        Name = "Current Business Date"
        TargetPath = "$basePath\2025-09-23"
        Description = "Current business date records (23-09-2025)"
        IconPath = "C:\Windows\System32\imageres.dll"
        IconIndex = 21
    },
    @{
        Name = "All Excel Exports"
        TargetPath = $basePath
        Description = "All consolidated Excel exports"
        IconPath = "C:\Windows\System32\imageres.dll"
        IconIndex = 4
    },
    @{
        Name = "Quick Access Menu"
        TargetPath = "C:\Users\babu\Desktop\Quick Access Business Data.bat"
        Description = "Simple menu to choose what data to view"
        IconPath = "C:\Windows\System32\imageres.dll"
        IconIndex = 25
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

# Create new shortcuts with proper icons
Write-Host "Creating new shortcuts with unique icons..." -ForegroundColor Green
foreach ($shortcut in $shortcuts) {
    try {
        # Create WScript.Shell object
        $WScriptShell = New-Object -ComObject WScript.Shell
        
        # Create shortcut
        $Shortcut = $WScriptShell.CreateShortcut("$quickAccessFolder\$($shortcut.Name).lnk")
        $Shortcut.TargetPath = $shortcut.TargetPath
        $Shortcut.Description = $shortcut.Description
        
        # Set icon with full path
        $Shortcut.IconLocation = "$($shortcut.IconPath),$($shortcut.IconIndex)"
        
        # Save the shortcut
        $Shortcut.Save()
        
        Write-Host "Created: $($shortcut.Name) with icon from $($shortcut.IconPath) index $($shortcut.IconIndex)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Failed to create: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Shortcut Creation Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "What was created:" -ForegroundColor Yellow
Write-Host "   - Deleted old shortcuts with generic icons" -ForegroundColor Cyan
Write-Host "   - Created new shortcuts with unique icons from imageres.dll" -ForegroundColor Cyan
Write-Host ""
Write-Host "Icon Assignments:" -ForegroundColor Yellow
Write-Host "   - Market Transition Data: Icon index 2" -ForegroundColor Cyan
Write-Host "   - Previous Business Date: Icon index 15" -ForegroundColor Cyan
Write-Host "   - Current Business Date: Icon index 21" -ForegroundColor Cyan
Write-Host "   - All Excel Exports: Icon index 4" -ForegroundColor Cyan
Write-Host "   - Quick Access Menu: Icon index 25" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check your Quick-Access folder - shortcuts should now have different icons!" -ForegroundColor Green


