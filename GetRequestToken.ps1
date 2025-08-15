# Kite Connect Request Token Helper
# This script helps you get your request token for the Kite Market Data Service

param(
    [string]$ApiKey = "kw3ptb0zmocwupmo"
)

Write-Host "=== Kite Connect Request Token Helper ===" -ForegroundColor Green
Write-Host ""

# Create the login URL
$loginUrl = "https://kite.trade/connect/login?api_key=$ApiKey&v=3"

Write-Host "Step 1: Copy and open this URL in your browser:" -ForegroundColor Yellow
Write-Host $loginUrl -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 2: Login with your Zerodha credentials" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 3: After successful login, you'll be redirected to a URL like:" -ForegroundColor Yellow
Write-Host "http://127.0.0.1:3000?action=login&status=success&request_token=YOUR_TOKEN_HERE" -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 4: Copy the request_token value from the URL" -ForegroundColor Yellow
Write-Host ""

Write-Host "Step 5: Update your appsettings.json file with the request token:" -ForegroundColor Yellow
Write-Host '  "KiteConnect": {' -ForegroundColor Cyan
Write-Host '    "ApiKey": "your_api_key",' -ForegroundColor Cyan
Write-Host '    "ApiSecret": "your_api_secret",' -ForegroundColor Cyan
Write-Host '    "RequestToken": "YOUR_TOKEN_HERE"' -ForegroundColor Cyan
Write-Host '  }' -ForegroundColor Cyan
Write-Host ""

Write-Host "Step 6: Run the service with: dotnet run" -ForegroundColor Yellow
Write-Host ""

Write-Host "=== Note ===" -ForegroundColor Green
Write-Host "Request tokens expire quickly. You may need to get a new one if the service fails to authenticate." -ForegroundColor Yellow
Write-Host ""

# Try to open the URL automatically
$openUrl = Read-Host "Would you like to open the login URL in your browser now? (y/n)"
if ($openUrl -eq 'y' -or $openUrl -eq 'Y') {
    Start-Process $loginUrl
    Write-Host "Login URL opened in your default browser." -ForegroundColor Green
}
