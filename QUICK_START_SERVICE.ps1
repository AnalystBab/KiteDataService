# Quick Start Service with Existing Token
# Purpose: Start the Kite Market Data Service with the provided request token

param(
    [string]$ServicePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker",
    [string]$RequestToken = "JT5S0jUakgD8c6NlLAfzY4Csh2Rdpkpr"
)

Write-Host "QUICK START: KITE MARKET DATA SERVICE" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Check if service path exists
if (-not (Test-Path $ServicePath)) {
    Write-Host "ERROR: Service path not found: $ServicePath" -ForegroundColor Red
    exit 1
}

Write-Host "Step 1: Updating configuration with request token..." -ForegroundColor Cyan

# Update appsettings.json with the new token
$ConfigFile = "$ServicePath\appsettings.json"
if (Test-Path $ConfigFile) {
    $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
    $Config.KiteConnect.RequestToken = $RequestToken
    $Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile
    Write-Host "Configuration updated with token: $RequestToken" -ForegroundColor Green
} else {
    Write-Host "ERROR: appsettings.json not found. Cannot proceed." -ForegroundColor Red
    exit 1
}

Write-Host "Step 2: Stopping any existing service..." -ForegroundColor Cyan

# Stop any existing dotnet processes
try {
    Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Stop-Process -Force
    Write-Host "Existing processes stopped." -ForegroundColor Yellow
} catch {
    Write-Host "No existing processes found." -ForegroundColor Yellow
}

Write-Host "Step 3: Starting the service..." -ForegroundColor Cyan

# Navigate to service directory
Set-Location $ServicePath

Write-Host "Service Path: $ServicePath" -ForegroundColor Cyan
Write-Host "Starting .NET Worker Service..." -ForegroundColor Yellow

try {
    # Start the service using dotnet run
    Write-Host "Executing: dotnet run" -ForegroundColor Green
    Start-Process -FilePath "dotnet" -ArgumentList "run" -WorkingDirectory $ServicePath -WindowStyle Normal
    
    Write-Host ""
    Write-Host "SUCCESS: Service started successfully!" -ForegroundColor Green
    Write-Host "Service is now collecting live market data..." -ForegroundColor Cyan
    Write-Host "Waiting for service to initialize..." -ForegroundColor Yellow
    
    # Wait a bit for service to start
    Start-Sleep -Seconds 15
    
    Write-Host ""
    Write-Host "Step 4: Testing service connection..." -ForegroundColor Cyan
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/api/SystemMonitor/status" -UseBasicParsing -TimeoutSec 10
        Write-Host "Service is responding! Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "Web interface available at: http://localhost:5000" -ForegroundColor Cyan
    } catch {
        Write-Host "Service may still be starting up. Check http://localhost:5000 in a few minutes." -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "ERROR: Failed to start service" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "QUICK START COMPLETED" -ForegroundColor Green
Write-Host "Service should now be collecting data for today (2025-10-23)" -ForegroundColor Cyan
