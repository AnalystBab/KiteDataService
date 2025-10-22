# Create Desktop Shortcut for Market Prediction Dashboard

Write-Host "🎯 Creating Desktop Shortcut..." -ForegroundColor Cyan

$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktopPath "Market Prediction Dashboard.lnk"
$targetPath = Join-Path $PSScriptRoot "Launch-Dashboard.ps1"
$iconPath = "%SystemRoot%\System32\chart data.ico"

# Create shortcut using WScript.Shell
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "powershell.exe"
$Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$targetPath`""
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.Description = "Market Prediction Dashboard - AI-Powered Trading Predictions"
$Shortcut.Save()

Write-Host "✅ Desktop shortcut created!" -ForegroundColor Green
Write-Host "📍 Location: $shortcutPath" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Double-click the shortcut to launch dashboard!" -ForegroundColor Yellow
Write-Host ""

