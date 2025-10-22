# Fix Shortcut Target Paths
# This will fix the shortcuts to point to the correct locations

Write-Host "Fixing Shortcut Target Paths..." -ForegroundColor Green

# Base paths
$basePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\Exports\ConsolidatedLCUC"
$quickAccessFolder = "C:\Users\babu\Desktop\Quick-Access"

# Define shortcuts with correct target paths
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

# Check if target paths exist
Write-Host "Checking target paths..." -ForegroundColor Yellow
foreach ($shortcut in $shortcuts) {
    if (Test-Path $shortcut.TargetPath) {
        Write-Host "✅ Target exists: $($shortcut.TargetPath)" -ForegroundColor Green
    } else {
        Write-Host "❌ Target missing: $($shortcut.TargetPath)" -ForegroundColor Red
    }
}

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

# Create new shortcuts with correct target paths
Write-Host "Creating new shortcuts with correct target paths..." -ForegroundColor Green
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
        Write-Host "  Target: $($shortcut.TargetPath)" -ForegroundColor White
    }
    catch {
        Write-Host "Failed to create: $($shortcut.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Shortcut Target Fix Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "What was fixed:" -ForegroundColor Yellow
Write-Host "   - Deleted old shortcuts with incorrect targets" -ForegroundColor Cyan
Write-Host "   - Created new shortcuts with correct target paths" -ForegroundColor Cyan
Write-Host ""
Write-Host "Target Paths:" -ForegroundColor Yellow
Write-Host "   - Market Transition Data: $basePath" -ForegroundColor Cyan
Write-Host "   - Previous Business Date: $basePath\2025-09-22" -ForegroundColor Cyan
Write-Host "   - Current Business Date: $basePath\2025-09-23" -ForegroundColor Cyan
Write-Host "   - All Excel Exports: $basePath" -ForegroundColor Cyan
Write-Host "   - Quick Access Menu: C:\Users\babu\Desktop\Quick Access Business Data.bat" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test the shortcuts now - they should open the correct locations!" -ForegroundColor Green


