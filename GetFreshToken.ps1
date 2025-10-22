# Simple script to get fresh request token

Write-Host "=== GET FRESH REQUEST TOKEN ===" -ForegroundColor Green

# Read API key
$appSettings = Get-Content ".\appsettings.json" | ConvertFrom-Json
$apiKey = $appSettings.KiteConnect.ApiKey

$loginUrl = "https://kite.trade/connect/login?api_key=$apiKey&v=3"

Write-Host "`n1. Click this link to get fresh token:" -ForegroundColor White
Write-Host "$loginUrl" -ForegroundColor Cyan

# Open browser
Start-Process $loginUrl

Write-Host "`n2. After login, copy the request_token from the redirect URL" -ForegroundColor White
Write-Host "3. Paste it below:" -ForegroundColor White

$freshToken = Read-Host "Fresh Request Token"

if ($freshToken) {
    Write-Host "`n✅ Fresh token received: $freshToken" -ForegroundColor Green
    Write-Host "`nNow run the download script with this token:" -ForegroundColor Yellow
    Write-Host ".\DownloadSENSEXOptionsBulletproof.ps1 -RequestToken '$freshToken'" -ForegroundColor Cyan
} else {
    Write-Host "No token provided" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
