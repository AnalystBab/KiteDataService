# Task 2: Monitor Live Data Collection
# Purpose: Verify service is collecting market data
# Icon: 🟢 Green Circle with "MONITOR DATA" text

Write-Host "🟢 TASK 2: MONITORING LIVE DATA COLLECTION" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

# Database connection parameters
$Server = "localhost"
$Database = "KiteMarketData"

Write-Host "📊 Checking live market data collection..." -ForegroundColor Cyan
Write-Host "🔗 Database: $Server\$Database" -ForegroundColor Yellow

try {
    # Check total records in MarketQuotes
    $TotalQuotesQuery = "SELECT COUNT(*) as TotalQuotes FROM MarketQuotes"
    $TotalQuotes = sqlcmd -S $Server -d $Database -Q $TotalQuotesQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    # Check recent quotes (last 5 minutes)
    $RecentQuotesQuery = "SELECT COUNT(*) as RecentQuotes FROM MarketQuotes WHERE QuoteTimestamp >= DATEADD(MINUTE, -5, GETDATE())"
    $RecentQuotes = sqlcmd -S $Server -d $Database -Q $RecentQuotesQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    # Check latest quote timestamp
    $LatestQuery = "SELECT MAX(QuoteTimestamp) as LatestQuote FROM MarketQuotes"
    $LatestQuote = sqlcmd -S $Server -d $Database -Q $LatestQuery -h -1 | Select-String -Pattern "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}" | ForEach-Object { $_.Matches[0].Value }
    
    Write-Host ""
    Write-Host "📈 DATA COLLECTION STATUS:" -ForegroundColor Yellow
    Write-Host "=========================" -ForegroundColor Yellow
    Write-Host "📊 Total Quotes: $TotalQuotes" -ForegroundColor Cyan
    Write-Host "🕐 Recent Quotes (5 min): $RecentQuotes" -ForegroundColor Cyan
    Write-Host "⏰ Latest Quote: $LatestQuote" -ForegroundColor Cyan
    
    # Determine status
    if ([int]$RecentQuotes -gt 0) {
        Write-Host ""
        Write-Host "✅ STATUS: LIVE DATA COLLECTION ACTIVE" -ForegroundColor Green
        Write-Host "📡 Service is successfully collecting market data" -ForegroundColor Green
        Write-Host "💡 Next: Run Task 3 to store EOD data" -ForegroundColor Yellow
    } else {
        Write-Host ""
        Write-Host "⚠️  WARNING: NO RECENT DATA" -ForegroundColor Yellow
        Write-Host "📡 Service may not be collecting data properly" -ForegroundColor Yellow
        Write-Host "🔍 Check if Task 1 (Start Service) is running" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ ERROR: Failed to check data collection" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔍 Check database connection and service status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 TASK 2 COMPLETED: Data monitoring finished" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
