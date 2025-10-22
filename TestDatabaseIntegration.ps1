# Test Database Integration for Kite Market Strategy Framework
# This script tests the connection to the existing KiteMarketData database

Write-Host "🚀 Testing Kite Market Strategy Framework Database Integration" -ForegroundColor Green
Write-Host "=============================================================" -ForegroundColor Green

# Check if we're in the right directory
if (-not (Test-Path "KiteMarketStrategyFramework.Console")) {
    Write-Host "❌ Error: Please run this script from the KiteMarketStrategyFramework directory" -ForegroundColor Red
    exit 1
}

# Check if the console application exists
$consoleApp = "KiteMarketStrategyFramework.Console\bin\Debug\net9.0\KiteMarketStrategyFramework.Console.exe"
if (-not (Test-Path $consoleApp)) {
    Write-Host "🔨 Building the solution first..." -ForegroundColor Yellow
    dotnet build
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Build failed!" -ForegroundColor Red
        exit 1
    }
}

# Check if the appsettings.json exists
$configFile = "KiteMarketStrategyFramework.Console\appsettings.json"
if (-not (Test-Path $configFile)) {
    Write-Host "❌ Error: appsettings.json not found!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found console application: $consoleApp" -ForegroundColor Green
Write-Host "✅ Found configuration file: $configFile" -ForegroundColor Green

# Display configuration
Write-Host "`n📋 Configuration:" -ForegroundColor Cyan
$config = Get-Content $configFile | ConvertFrom-Json
Write-Host "   Database: $($config.ConnectionStrings.DefaultConnection)" -ForegroundColor White

# Test database connection
Write-Host "`n🔍 Testing database connection..." -ForegroundColor Yellow

try {
    # Run the console application
    Write-Host "   Running database integration test..." -ForegroundColor White
    & $consoleApp
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n✅ Database integration test completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`n❌ Database integration test failed with exit code: $LASTEXITCODE" -ForegroundColor Red
    }
}
catch {
    Write-Host "`n❌ Error running database integration test: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n📊 Test Summary:" -ForegroundColor Cyan
Write-Host "   • Database connection: $(if ($LASTEXITCODE -eq 0) { '✅ PASSED' } else { '❌ FAILED' })" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Red' })
Write-Host "   • Data retrieval: $(if ($LASTEXITCODE -eq 0) { '✅ PASSED' } else { '❌ FAILED' })" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Red' })
Write-Host "   • Strategy execution: $(if ($LASTEXITCODE -eq 0) { '✅ PASSED' } else { '❌ FAILED' })" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { 'Green' } else { 'Red' })

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. If tests passed: Your Strategy Framework is ready to use!" -ForegroundColor White
Write-Host "   2. If tests failed: Check your database connection and data availability" -ForegroundColor White
Write-Host "   3. Run the Data Service to ensure fresh market data is available" -ForegroundColor White

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")





