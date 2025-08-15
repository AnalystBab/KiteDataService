# Task 1: Start Market Data Service
# Purpose: Initialize the Kite Market Data Service
# Icon: 🔴 Red Circle with "START SERVICE" text

param(
    [string]$ServicePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker"
)

Write-Host "🚀 TASK 1: STARTING MARKET DATA SERVICE" -ForegroundColor Red
Write-Host "================================================" -ForegroundColor Red

# Check if service path exists
if (-not (Test-Path $ServicePath)) {
    Write-Host "❌ ERROR: Service path not found: $ServicePath" -ForegroundColor Red
    Write-Host "Please check the service installation path." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Navigate to service directory
Set-Location $ServicePath

Write-Host "📍 Service Path: $ServicePath" -ForegroundColor Cyan
Write-Host "⏳ Starting .NET Worker Service..." -ForegroundColor Yellow

try {
    # Start the service using dotnet run
    Write-Host "🔄 Executing: dotnet run" -ForegroundColor Green
    Start-Process -FilePath "dotnet" -ArgumentList "run" -WorkingDirectory $ServicePath -WindowStyle Normal
    
    Write-Host "✅ Service started successfully!" -ForegroundColor Green
    Write-Host "📊 Service is now collecting live market data..." -ForegroundColor Cyan
    Write-Host "💡 Next: Run Task 2 to monitor data collection" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ ERROR: Failed to start service" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🎯 TASK 1 COMPLETED: Service is running" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
