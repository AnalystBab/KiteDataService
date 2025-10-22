# Create Desktop Folder and Web Dashboard Shortcut
$desktopPath = [Environment]::GetFolderPath("Desktop")
$folderPath = Join-Path $desktopPath "Kite Market Data Service"

# Create folder if it doesn't exist
if (!(Test-Path $folderPath)) {
    New-Item -ItemType Directory -Path $folderPath -Force
    Write-Host "✅ Created folder: $folderPath" -ForegroundColor Green
}

# Create web dashboard shortcut
$shortcutPath = Join-Path $folderPath "Open Web Dashboard.lnk"
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "http://localhost:5000"
$Shortcut.Description = "Open Kite Market Data Service Web Dashboard"
$Shortcut.Save()

Write-Host "✅ Created web dashboard shortcut: $shortcutPath" -ForegroundColor Green

# Create service status checker shortcut
$statusShortcutPath = Join-Path $folderPath "Check Service Status.lnk"
$StatusShortcut = $WshShell.CreateShortcut($statusShortcutPath)
$StatusShortcut.TargetPath = "powershell.exe"
$StatusShortcut.Arguments = "-Command `"& {try {Invoke-WebRequest -Uri 'http://localhost:5000/api/status' -UseBasicParsing | Out-Null; Write-Host 'Service is RUNNING' -ForegroundColor Green} catch {Write-Host 'Service is NOT RUNNING' -ForegroundColor Red}; Read-Host 'Press Enter to close'}`""
$StatusShortcut.Description = "Check if Kite Market Data Service is running"
$StatusShortcut.Save()

Write-Host "✅ Created service status checker shortcut: $statusShortcutPath" -ForegroundColor Green

Write-Host "`n🎯 Desktop shortcuts created successfully!" -ForegroundColor Cyan
Write-Host "📁 Folder: $folderPath" -ForegroundColor Yellow
Write-Host "🌐 Web Dashboard: http://localhost:5000" -ForegroundColor Yellow





