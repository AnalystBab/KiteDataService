# Update existing desktop shortcut to use LAUNCH_WEB_APP.bat
# This fixes the "closes immediately" issue

$scriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($scriptPath)) {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
}

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Market Dashboard.lnk"
$targetPath = Join-Path $scriptPath "LAUNCH_WEB_APP.bat"

if (-not (Test-Path $shortcutPath)) {
    Write-Host "Shortcut not found. Creating new one..." -ForegroundColor Yellow
}

$WScriptShell = New-Object -ComObject WScript.Shell
$shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $targetPath
$shortcut.WorkingDirectory = $scriptPath
$shortcut.Description = "Market Prediction Dashboard - 99.84% Accurate!"
$shortcut.WindowStyle = 1
$shortcut.IconLocation = "%SystemRoot%\System32\SHELL32.dll,238"
$shortcut.Save()

Write-Host ""
Write-Host "Desktop shortcut updated successfully!" -ForegroundColor Green
Write-Host "Target: LAUNCH_WEB_APP.bat" -ForegroundColor Cyan
Write-Host "This version keeps the window open and shows logs." -ForegroundColor Cyan
Write-Host ""
Write-Host "Try double-clicking the desktop shortcut now!" -ForegroundColor Yellow
Write-Host ""

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($WScriptShell) | Out-Null










