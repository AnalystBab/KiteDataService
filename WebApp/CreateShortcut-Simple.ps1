# Create Desktop Shortcut - Simple Version

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Market Dashboard.lnk"
$targetPath = Join-Path $PSScriptRoot "OpenDashboard.bat"

$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = $targetPath
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.Description = "Market Prediction Dashboard"
$Shortcut.Save()

Write-Host "Desktop shortcut created successfully!" -ForegroundColor Green
Write-Host "Location: $shortcutPath" -ForegroundColor Cyan
Write-Host ""
Write-Host "Double-click 'Market Dashboard' on your desktop to launch!" -ForegroundColor Yellow

