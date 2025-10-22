# Create Desktop Shortcut for Market Prediction Dashboard

Write-Host "Creating Desktop Shortcut..." -ForegroundColor Cyan

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Market Dashboard.lnk"
$targetPath = Join-Path $PSScriptRoot "Launch-Dashboard.ps1"

# Create shortcut using WScript.Shell
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetPath`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.Description = "Market Prediction Dashboard"
$Shortcut.Save()

Write-Host "Desktop shortcut created!" -ForegroundColor Green
Write-Host "Location: $shortcutPath" -ForegroundColor White
Write-Host ""
Write-Host "Double-click 'Market Dashboard' icon on your desktop to launch!" -ForegroundColor Yellow
Write-Host ""

