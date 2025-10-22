# Fix Shortcut Icons - Assign Unique Colorful Icons
# This will fix the existing shortcuts with proper icons

Write-Host "Fixing Shortcut Icons with Unique Colors..." -ForegroundColor Green

# Base paths
$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"
$desktopPath = [Environment]::GetFolderPath("Desktop")

# Define shortcuts with specific icon assignments
$shortcuts = @(
    @{
        Name = "Market Transition Data"
        TargetPath = $basePath
        Description = "Quick access to market transition Excel files"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 23  # Blue refresh/update icon
    },
    @{
        Name = "Previous Business Date"
        TargetPath = "$basePath\2025-09-22"
        Description = "Previous business date records (22-09-2025)"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 15  # Green calendar icon
    },
    @{
        Name = "Current Business Date"
        TargetPath = "$basePath\2025-09-23"
        Description = "Current business date records (23-09-2025)"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 21  # Blue chart/graph icon
    },
    @{
        Name = "All Excel Exports"
        TargetPath = $basePath
        Description = "All consolidated Excel exports"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 4   # Yellow folder icon
    },
    @{
        Name = "Quick Access Menu"
        TargetPath = "$desktopPath\Quick Access Business Data.bat"
        Description = "Simple menu to choose what data to view"
        IconPath = "C:\Windows\System32\shell32.dll"
        IconIndex = 25  # Orange rocket/launch icon
    }
)

# Fix existing shortcuts with proper icons
foreach ($shortcut in $shortcuts) {
    try {
        $shortcutPath = "$desktopPath\$($shortcut.Name).lnk"
        
        if (Test-Path $shortcutPath) {
            # Create WScript.Shell object
            $WScriptShell = New-Object -ComObject WScript.Shell
            
            # Load existing shortcut
            $Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
            
            # Update icon location with full path
            $Shortcut.IconLocation = "$($shortcut.IconPath),$($shortcut.IconIndex)"
            
            # Save the shortcut
            $Shortcut.Save()
            
            Write-Host "✅ Fixed: $($shortcut.Name) with icon index $($shortcut.IconIndex)" -ForegroundColor Cyan
        } else {
            Write-Host "❌ Shortcut not found: $($shortcut.Name)" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "❌ Failed to fix: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Create alternative shortcuts with different icon sources
Write-Host ""
Write-Host "Creating Alternative Shortcuts with Different Icons..." -ForegroundColor Yellow

$alternativeShortcuts = @(
    @{
        Name = "Market Transition Data (Alt)"
        TargetPath = $basePath
        Description = "Market transition data with different icon"
        IconPath = "C:\Windows\System32\imageres.dll"
        IconIndex = 2   # Different icon source
    },
    @{
        Name = "Previous Business Date (Alt)"
        TargetPath = "$basePath\2025-09-22"
        Description = "Previous business date with different icon"
        IconPath = "C:\Windows\System32\imageres.dll"
        IconIndex = 15  # Different icon source
    },
    @{
        Name = "Current Business Date (Alt)"
        TargetPath = "$basePath\2025-09-23"
        Description = "Current business date with different icon"
        IconPath = "C:\Windows\System32\imageres.dll"
        IconIndex = 21  # Different icon source
    },
    @{
        Name = "All Excel Exports (Alt)"
        TargetPath = $basePath
        Description = "All exports with different icon"
        IconPath = "C:\Windows\System32\imageres.dll"
        IconIndex = 4   # Different icon source
    }
)

foreach ($shortcut in $alternativeShortcuts) {
    try {
        # Create WScript.Shell object
        $WScriptShell = New-Object -ComObject WScript.Shell
        
        # Create shortcut
        $Shortcut = $WScriptShell.CreateShortcut("$desktopPath\$($shortcut.Name).lnk")
        $Shortcut.TargetPath = $shortcut.TargetPath
        $Shortcut.Description = $shortcut.Description
        $Shortcut.IconLocation = "$($shortcut.IconPath),$($shortcut.IconIndex)"
        
        $Shortcut.Save()
        
        Write-Host "✅ Created: $($shortcut.Name) with alternative icon" -ForegroundColor Cyan
    }
    catch {
        Write-Host "❌ Failed to create: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "🎉 Icon Fix Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 What was fixed:" -ForegroundColor Yellow
Write-Host "   - Updated existing shortcuts with proper icons" -ForegroundColor Cyan
Write-Host "   - Created alternative shortcuts with different icon sources" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎯 Icon Assignments:" -ForegroundColor Yellow
Write-Host "   - Market Transition Data: Blue refresh icon (shell32.dll, 23)" -ForegroundColor Cyan
Write-Host "   - Previous Business Date: Green calendar icon (shell32.dll, 15)" -ForegroundColor Cyan
Write-Host "   - Current Business Date: Blue chart icon (shell32.dll, 21)" -ForegroundColor Cyan
Write-Host "   - All Excel Exports: Yellow folder icon (shell32.dll, 4)" -ForegroundColor Cyan
Write-Host "   - Quick Access Menu: Orange rocket icon (shell32.dll, 25)" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚡ Check your desktop - shortcuts should now have different icons!" -ForegroundColor Green


