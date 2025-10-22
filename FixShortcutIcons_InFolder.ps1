# Fix Shortcut Icons in Quick-Access Folder
# This will fix the shortcuts in the Quick-Access folder on desktop

Write-Host "Fixing Shortcut Icons in Quick-Access Folder..." -ForegroundColor Green

# Base paths
$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$quickAccessFolder = "$desktopPath\Quick-Access"

# Define shortcuts with specific icon assignments
$shortcuts = @(
    @{
        Name = "Market Transition Data"
        TargetPath = $basePath
        Description = "Quick access to market transition Excel files"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 23
    },
    @{
        Name = "Previous Business Date"
        TargetPath = "$basePath\2025-09-22"
        Description = "Previous business date records (22-09-2025)"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 15
    },
    @{
        Name = "Current Business Date"
        TargetPath = "$basePath\2025-09-23"
        Description = "Current business date records (23-09-2025)"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 21
    },
    @{
        Name = "All Excel Exports"
        TargetPath = $basePath
        Description = "All consolidated Excel exports"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 4
    },
    @{
        Name = "Quick Access Menu"
        TargetPath = "$desktopPath\Quick Access Business Data.bat"
        Description = "Simple menu to choose what data to view"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 25
    }
)

# Check if Quick-Access folder exists
if (Test-Path $quickAccessFolder) {
    Write-Host "Found Quick-Access folder: $quickAccessFolder" -ForegroundColor Green
    
    # Fix existing shortcuts with proper icons
    foreach ($shortcut in $shortcuts) {
        try {
            $shortcutPath = "$quickAccessFolder\$($shortcut.Name).lnk"
            
            if (Test-Path $shortcutPath) {
                # Create WScript.Shell object
                $WScriptShell = New-Object -ComObject WScript.Shell
                
                # Load existing shortcut
                $Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
                
                # Update icon location with full path
                $Shortcut.IconLocation = "$($shortcut.IconPath),$($shortcut.IconIndex)"
                
                # Save the shortcut
                $Shortcut.Save()
                
                Write-Host "Fixed: $($shortcut.Name) with icon index $($shortcut.IconIndex)" -ForegroundColor Cyan
            } else {
                Write-Host "Shortcut not found: $($shortcut.Name)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Failed to fix: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "Quick-Access folder not found at: $quickAccessFolder" -ForegroundColor Red
    Write-Host "Please check the folder name and location" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Icon Fix Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "What was fixed:" -ForegroundColor Yellow
Write-Host "   - Updated shortcuts in Quick-Access folder with proper icons" -ForegroundColor Cyan
Write-Host ""
Write-Host "Icon Assignments:" -ForegroundColor Yellow
Write-Host "   - Market Transition Data: Blue refresh icon" -ForegroundColor Cyan
Write-Host "   - Previous Business Date: Green calendar icon" -ForegroundColor Cyan
Write-Host "   - Current Business Date: Blue chart icon" -ForegroundColor Cyan
Write-Host "   - All Excel Exports: Yellow folder icon" -ForegroundColor Cyan
Write-Host "   - Quick Access Menu: Orange rocket icon" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check your Quick-Access folder - shortcuts should now have different icons!" -ForegroundColor Green


