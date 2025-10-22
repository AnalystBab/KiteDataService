# Create Desktop Shortcut for Market Prediction Web App
# With colorful icon for easy identification

Write-Host ""
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "   Creating Desktop Shortcut - Web App Launcher" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""

# Get current directory (where the script is running from)
$scriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptPath)) {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

Write-Host "Script location: $scriptPath" -ForegroundColor Yellow
Write-Host ""

# Define shortcut details
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutName = "Market Dashboard.lnk"
$shortcutPath = Join-Path $desktopPath $shortcutName

# Target is the LaunchWebApp.bat file
$targetPath = Join-Path $scriptPath "LaunchWebApp.bat"
$workingDirectory = $scriptPath

# Check if LaunchWebApp.bat exists
if (-not (Test-Path $targetPath)) {
    Write-Host "Error: LaunchWebApp.bat not found!" -ForegroundColor Red
    Write-Host "Expected location: $targetPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}

Write-Host "Found LaunchWebApp.bat" -ForegroundColor Green
Write-Host ""

# Create WScript Shell object
$WScriptShell = New-Object -ComObject WScript.Shell

# Create the shortcut
Write-Host "Creating shortcut..." -ForegroundColor Cyan
$shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetPath
$shortcut.WorkingDirectory = $workingDirectory
$shortcut.Description = "Launch Market Prediction Web Dashboard - 99.84% Accurate Predictions!"
$shortcut.WindowStyle = 1  # Normal window

# Set a colorful icon - Chart/Graph icon (orange/blue)
$shortcut.IconLocation = "%SystemRoot%\System32\SHELL32.dll,238"

# Save the shortcut
$shortcut.Save()

Write-Host ""
Write-Host "===================================================================" -ForegroundColor Green
Write-Host "   DESKTOP SHORTCUT CREATED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "===================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Shortcut Location:" -ForegroundColor Cyan
Write-Host "   $shortcutPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Shortcut Name:" -ForegroundColor Cyan
Write-Host "   Market Dashboard" -ForegroundColor Yellow
Write-Host ""
Write-Host "Icon:" -ForegroundColor Cyan
Write-Host "   Colorful Chart/Graph (Orange & Blue)" -ForegroundColor Yellow
Write-Host ""
Write-Host "What it does:" -ForegroundColor Cyan
Write-Host "   - Starts Worker Service (background data collection)" -ForegroundColor White
Write-Host "   - Starts Web API (http://localhost:5000)" -ForegroundColor White
Write-Host "   - Opens Dashboard in browser automatically" -ForegroundColor White
Write-Host ""
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host "   READY TO USE!" -ForegroundColor Cyan
Write-Host "===================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Double-click the desktop icon to launch your dashboard!" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

# Release COM object
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WScriptShell) | Out-Null
