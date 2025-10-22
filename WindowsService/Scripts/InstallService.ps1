# Windows Service Installation Script
# Run as Administrator

param(
    [switch]$Uninstall
)

$ServiceName = "KiteMarketDataService"
$ServiceDisplayName = "Kite Market Data Service"
$ServiceDescription = "Collects real-time market data from Kite Connect API and provides web interface for token management"

Write-Host "🔧 Kite Market Data Service - Windows Service Installer" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

if ($Uninstall) {
    Write-Host "🗑️ Uninstalling Windows Service..." -ForegroundColor Yellow
    
    try {
        # Stop service if running
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq 'Running') {
            Write-Host "⏹️ Stopping service..." -ForegroundColor Yellow
            Stop-Service -Name $ServiceName -Force
            Start-Sleep -Seconds 3
        }
        
        # Remove service
        sc.exe delete $ServiceName
        Write-Host "✅ Service uninstalled successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to uninstall service: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host "📦 Installing Windows Service..." -ForegroundColor Green
    
    # Get current directory
    $ServicePath = (Get-Location).Path + "\bin\Release\net9.0\KiteMarketDataService.Worker.exe"
    
    # Check if executable exists
    if (-not (Test-Path $ServicePath)) {
        Write-Host "❌ Service executable not found at: $ServicePath" -ForegroundColor Red
        Write-Host "💡 Please build the project first: dotnet build --configuration Release" -ForegroundColor Yellow
        exit 1
    }
    
    try {
        # Create Windows Service
        Write-Host "🔨 Creating Windows Service..." -ForegroundColor Cyan
        New-Service -Name $ServiceName -BinaryPathName $ServicePath -DisplayName $ServiceDisplayName -Description $ServiceDescription -StartupType Automatic
        
        Write-Host "✅ Windows Service installed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "📋 Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Start the service: Start-Service -Name $ServiceName" -ForegroundColor White
        Write-Host "2. Open web interface: http://localhost:5000/token-management.html" -ForegroundColor White
        Write-Host "3. Use web interface to manage tokens and control service" -ForegroundColor White
        Write-Host ""
        Write-Host "🎯 The service will now start automatically on Windows startup!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Failed to install service: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")






