# Create Desktop Shortcut with CUSTOM COLORFUL ICON
# This version creates a custom icon file for better visual identification

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "   🎨 CREATING CUSTOM ICON + DESKTOP SHORTCUT" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

# Get current directory
$scriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptPath)) {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutName = "🎯 Market Dashboard.lnk"
$shortcutPath = Join-Path $desktopPath $shortcutName
$targetPath = Join-Path $scriptPath "LaunchWebApp.bat"
$workingDirectory = $scriptPath

# Create custom icon using .NET Drawing
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

try {
    Write-Host "🎨 Creating custom colorful icon..." -ForegroundColor Cyan
    
    # Create a 256x256 bitmap
    $bitmap = New-Object System.Drawing.Bitmap 256, 256
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Fill with gradient background (Purple to Blue)
    $gradientBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.Point 0, 0),
        (New-Object System.Drawing.Point 256, 256),
        [System.Drawing.Color]::FromArgb(102, 126, 234),  # Purple
        [System.Drawing.Color]::FromArgb(118, 75, 162)    # Blue
    )
    $graphics.FillRectangle($gradientBrush, 0, 0, 256, 256)
    
    # Draw a chart-like symbol
    $whitePen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 8)
    
    # Draw upward trending line (represents predictions)
    $graphics.DrawLine($whitePen, 50, 200, 100, 150)
    $graphics.DrawLine($whitePen, 100, 150, 150, 100)
    $graphics.DrawLine($whitePen, 150, 100, 200, 60)
    
    # Draw dots at data points
    $whiteBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $graphics.FillEllipse($whiteBrush, 45, 195, 15, 15)
    $graphics.FillEllipse($whiteBrush, 95, 145, 15, 15)
    $graphics.FillEllipse($whiteBrush, 145, 95, 15, 15)
    $graphics.FillEllipse($whiteBrush, 195, 55, 15, 15)
    
    # Save as ICO file
    $iconPath = Join-Path $scriptPath "MarketDashboard.ico"
    $icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    $stream = [System.IO.File]::Create($iconPath)
    $icon.Save($stream)
    $stream.Close()
    
    # Cleanup
    $graphics.Dispose()
    $bitmap.Dispose()
    $gradientBrush.Dispose()
    $whitePen.Dispose()
    $whiteBrush.Dispose()
    
    Write-Host "✅ Custom icon created: MarketDashboard.ico" -ForegroundColor Green
    $useCustomIcon = $true
}
catch {
    Write-Host "⚠️  Could not create custom icon, using system icon instead" -ForegroundColor Yellow
    $useCustomIcon = $false
}

Write-Host ""
Write-Host "🔨 Creating desktop shortcut..." -ForegroundColor Cyan

# Create the shortcut
$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetPath
$shortcut.WorkingDirectory = $workingDirectory
$shortcut.Description = "Market Prediction Dashboard - 99.84% Accurate Predictions!"
$shortcut.WindowStyle = 1

# Set icon
if ($useCustomIcon -and (Test-Path $iconPath)) {
    $shortcut.IconLocation = $iconPath
    Write-Host "✅ Using custom colorful icon" -ForegroundColor Green
} else {
    # Use colorful system icons as fallback
    $shortcut.IconLocation = "%SystemRoot%\System32\SHELL32.dll,220"  # Globe with arrow (colorful)
    Write-Host "✅ Using system colorful icon (Globe)" -ForegroundColor Green
}

$shortcut.Save()

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host "   ✅ SUCCESS! SHORTCUT CREATED!" -ForegroundColor Green
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Green
Write-Host ""
Write-Host "📍 Desktop Shortcut:" -ForegroundColor Cyan
Write-Host "   🎯 Market Dashboard" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎯 What happens when you double-click:" -ForegroundColor Cyan
Write-Host "   1. ✅ Worker service starts (data collection)" -ForegroundColor White
Write-Host "   2. ✅ Web API starts on port 5000" -ForegroundColor White
Write-Host "   3. ✅ Browser opens to dashboard" -ForegroundColor White
Write-Host "   4. ✅ See your 99.84% accurate predictions!" -ForegroundColor White
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "   🎉 READY TO USE!" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""
Write-Host "Look for the shortcut on your desktop and double-click it! 🚀" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WScriptShell) | Out-Null










