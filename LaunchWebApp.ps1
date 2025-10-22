# Launch Market Prediction Web App
# Starts the service with both Worker and Web API

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   🚀 MARKET PREDICTION WEB APP - LAUNCHER" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Check if running from correct directory
if (-not (Test-Path "KiteMarketDataService.Worker.csproj")) {
    Write-Host "❌ Error: Must run from KiteMarketDataService.Worker directory!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Current directory: $PWD" -ForegroundColor Yellow
    Write-Host "Expected directory: *\KiteMarketDataService.Worker\" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "✅ Checking prerequisites..." -ForegroundColor Green
Write-Host ""

# Check .NET SDK
try {
    $dotnetVersion = dotnet --version
    Write-Host "  ✓ .NET SDK: $dotnetVersion" -ForegroundColor Green
} catch {
    Write-Host "  ❌ .NET SDK not found! Please install .NET 9 SDK" -ForegroundColor Red
    Write-Host "  Download from: https://dotnet.microsoft.com/download" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   📦 Building Project..." -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Build the project
$buildResult = dotnet build --configuration Release 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Build output:" -ForegroundColor Yellow
    Write-Host $buildResult
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green
Write-Host ""

Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   🎯 Starting Service..." -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  🔄 Worker Service: Background data collection" -ForegroundColor Yellow
Write-Host "  🌐 Web API: http://localhost:5000" -ForegroundColor Yellow
Write-Host "  📊 Dashboard: http://localhost:5000" -ForegroundColor Yellow
Write-Host "  📖 API Docs: http://localhost:5000/api-docs" -ForegroundColor Yellow
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Wait a moment for user to see the info
Start-Sleep -Seconds 2

# Open browser after 3 seconds
$openBrowser = {
    Start-Sleep -Seconds 3
    Write-Host "🌐 Opening browser..." -ForegroundColor Green
    Start-Process "http://localhost:5000"
}
Start-Job -ScriptBlock $openBrowser | Out-Null

# Run the service
Write-Host "⏳ Service starting... (Browser will open automatically)" -ForegroundColor Cyan
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   📝 SERVICE LOGS:" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

dotnet run --configuration Release

# This only executes if service stops
Write-Host ""
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
Write-Host "   🛑 SERVICE STOPPED" -ForegroundColor Red
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Red
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")










