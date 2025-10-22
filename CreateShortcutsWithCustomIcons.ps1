# Create Shortcuts with Custom Icons - Alternative Method
# This uses a different approach to assign unique icons

Write-Host "Creating Shortcuts with Custom Icons - Alternative Method..." -ForegroundColor Green

# Base paths
$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"
$quickAccessFolder = "C:\Users\babu\Desktop\Quick-Access"

# Define shortcuts with different icon sources and methods
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
        TargetPath = "C:\Users\babu\Desktop\Quick Access Business Data.bat"
        Description = "Simple menu to choose what data to view"
        IconPath = "C:\Windows\System32\shell32.dll"
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

# Create new shortcuts with proper icons using a different method
Write-Host "Creating new shortcuts with unique icons..." -ForegroundColor Green
foreach ($shortcut in $shortcuts) {
    try {
        # Create WScript.Shell object
        $WScriptShell = New-Object -ComObject WScript.Shell
        
        # Create shortcut
        $Shortcut = $WScriptShell.CreateShortcut("$quickAccessFolder\$($shortcut.Name).lnk")
        $Shortcut.TargetPath = $shortcut.TargetPath
        $Shortcut.Description = $shortcut.Description
        
        # Set icon using the working method
        $iconLocation = "$($shortcut.IconPath),$($shortcut.IconIndex)"
        $Shortcut.IconLocation = $iconLocation
        
        # Save the shortcut
        $Shortcut.Save()
        
        Write-Host "Created: $($shortcut.Name) with icon: $iconLocation" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Failed to create: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Force refresh the desktop to update icons
Write-Host "Refreshing desktop to update icons..." -ForegroundColor Yellow
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DesktopRefresh {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
"@

[DesktopRefresh]::SHChangeNotify(0x8000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)

Write-Host ""
Write-Host "Shortcut Creation Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "What was created:" -ForegroundColor Yellow
Write-Host "   - Deleted old shortcuts with generic icons" -ForegroundColor Cyan
Write-Host "   - Created new shortcuts with unique icons from shell32.dll" -ForegroundColor Cyan
Write-Host "   - Forced desktop refresh to update icons" -ForegroundColor Cyan
Write-Host ""
Write-Host "Icon Assignments:" -ForegroundColor Yellow
Write-Host "   - Market Transition Data: Blue refresh icon (shell32.dll, 23)" -ForegroundColor Cyan
Write-Host "   - Previous Business Date: Green calendar icon (shell32.dll, 15)" -ForegroundColor Cyan
Write-Host "   - Current Business Date: Blue chart icon (shell32.dll, 21)" -ForegroundColor Cyan
Write-Host "   - All Excel Exports: Yellow folder icon (shell32.dll, 4)" -ForegroundColor Cyan
Write-Host "   - Quick Access Menu: Orange rocket icon (shell32.dll, 25)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check your Quick-Access folder - shortcuts should now have different icons!" -ForegroundColor Green


