# Launch Market Prediction Dashboard
# Simple PowerShell-based web server that connects to SQL Server

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "           🎯 MARKET PREDICTION DASHBOARD - STARTING..." -ForegroundColor Yellow
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if database is accessible
Write-Host "📊 Checking database connection..." -ForegroundColor Cyan
try {
    $testQuery = sqlcmd -S localhost -d KiteMarketData -Q "SELECT 1" -h -1 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ Database connection: OK" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Database connection: FAILED" -ForegroundColor Red
        Write-Host "   Please ensure SQL Server is running" -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "   ❌ Database connection: FAILED" -ForegroundColor Red
    exit 1
}

# Check for pattern data
Write-Host "🔍 Checking for pattern data..." -ForegroundColor Cyan
$patternCount = sqlcmd -S localhost -d KiteMarketData -Q "SELECT COUNT(*) FROM DiscoveredPatterns" -h -1 -W 2>&1
$patternCount = ($patternCount -split "`n" | Where-Object { $_ -match '^\s*\d+\s*$' } | Select-Object -First 1).Trim()

if ($patternCount) {
    Write-Host "   ✅ Patterns found: $patternCount" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  No patterns found yet - run the main service first" -ForegroundColor Yellow
    Write-Host "   Dashboard will show once patterns are discovered" -ForegroundColor White
}

# Open browser
Write-Host ""
Write-Host "🌐 Opening dashboard in browser..." -ForegroundColor Cyan
$htmlPath = Join-Path $PSScriptRoot "index.html"
Start-Process "file:///$($htmlPath.Replace('\', '/'))"

Write-Host ""
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "                      ✅ DASHBOARD LAUNCHED!" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Dashboard opened in your default browser" -ForegroundColor Green
Write-Host "🔄 Data updates: Refresh the page to see latest data" -ForegroundColor White
Write-Host ""
Write-Host "💡 Tips:" -ForegroundColor Cyan
Write-Host "   • Dashboard reads directly from database" -ForegroundColor White
Write-Host "   • No server needed - works offline!" -ForegroundColor White
Write-Host "   • Refresh page to see updated patterns" -ForegroundColor White
Write-Host "   • Run main service to discover new patterns" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

