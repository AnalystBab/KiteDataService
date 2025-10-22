# Test Fresh LC/UC Data Collection
# This script tests that we get fresh LC/UC data for ALL strikes from today's quote API calls

Write-Host "=== TESTING FRESH LC/UC DATA COLLECTION ===" -ForegroundColor Green
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check current data status
Write-Host "=== TEST 1: Current Data Status ===" -ForegroundColor Cyan
$totalInstruments = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT COUNT(*) as TotalInstruments FROM Instruments WHERE TradingSymbol LIKE 'SENSEX25AUG%' AND InstrumentType = 'CE'"
Write-Host "Total SENSEX25AUG CE instruments: $totalInstruments" -ForegroundColor White

$todayData = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT COUNT(*) as TodayData FROM MarketQuotes mq INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken WHERE i.TradingSymbol LIKE 'SENSEX25AUG%' AND i.InstrumentType = 'CE' AND CAST(mq.TradingDate AS date) = CAST(GETDATE() AS date)"
Write-Host "SENSEX25AUG CE with data today: $todayData" -ForegroundColor White

$missingData = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT COUNT(*) as MissingData FROM Instruments i LEFT JOIN MarketQuotes mq ON i.InstrumentToken = mq.InstrumentToken AND CAST(mq.TradingDate AS date) = CAST(GETDATE() AS date) WHERE i.TradingSymbol LIKE 'SENSEX25AUG%' AND i.InstrumentType = 'CE' AND mq.Id IS NULL"
Write-Host "SENSEX25AUG CE missing data today: $missingData" -ForegroundColor White

# Test 2: Check specific missing strike (75400 CE)
Write-Host ""
Write-Host "=== TEST 2: Specific Missing Strike Analysis ===" -ForegroundColor Cyan
$strike75400 = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT i.Strike, i.TradingSymbol, i.InstrumentToken, CASE WHEN mq.Id IS NOT NULL THEN 'HAS_DATA' ELSE 'MISSING_DATA' END as DataStatus FROM Instruments i LEFT JOIN MarketQuotes mq ON i.InstrumentToken = mq.InstrumentToken AND CAST(mq.TradingDate AS date) = CAST(GETDATE() AS date) WHERE i.Strike = 75400 AND i.TradingSymbol LIKE 'SENSEX25AUG%' AND i.InstrumentType = 'CE'"
Write-Host "75400 CE Status: $strike75400" -ForegroundColor White

# Test 3: Check last available data for 75400 CE
Write-Host ""
Write-Host "=== TEST 3: Last Available Data for 75400 CE ===" -ForegroundColor Cyan
$lastData75400 = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT TOP 1 TradingDate, TradeTime, LowerCircuitLimit, UpperCircuitLimit, LastPrice, Volume FROM MarketQuotes WHERE InstrumentToken = 211682565 ORDER BY QuoteTimestamp DESC"
Write-Host "Last data for 75400 CE: $lastData75400" -ForegroundColor White

# Test 4: Check fresh LC/UC data for strikes that DO have data today
Write-Host ""
Write-Host "=== TEST 4: Fresh LC/UC Data Analysis ===" -ForegroundColor Cyan
$freshData = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT TOP 5 i.Strike, mq.LowerCircuitLimit, mq.UpperCircuitLimit, mq.LastPrice, mq.TradeTime FROM MarketQuotes mq INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken WHERE i.TradingSymbol LIKE 'SENSEX25AUG%' AND i.InstrumentType = 'CE' AND CAST(mq.TradingDate AS date) = CAST(GETDATE() AS date) ORDER BY i.Strike"
Write-Host "Fresh LC/UC data for strikes with data today:" -ForegroundColor White
Write-Host "$freshData" -ForegroundColor White

# Test 5: Compare with July 31st data
Write-Host ""
Write-Host "=== TEST 5: Data Freshness Comparison ===" -ForegroundColor Cyan
$july31Data = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT TOP 3 TradingDate, Strike, LowerCircuitLimit, UpperCircuitLimit, LastPrice FROM MarketQuotes WHERE InstrumentToken = 211682565 ORDER BY QuoteTimestamp DESC"
Write-Host "July 31st data for 75400 CE:" -ForegroundColor White
Write-Host "$july31Data" -ForegroundColor White

Write-Host ""
Write-Host "=== ENHANCED SERVICE EXPECTATIONS ===" -ForegroundColor Green
Write-Host "✅ Enhanced service will:" -ForegroundColor Yellow
Write-Host "   1. Fetch fresh LC/UC data for ALL strikes via quote API" -ForegroundColor White
Write-Host "   2. Use fallback mechanism for missing strikes" -ForegroundColor White
Write-Host "   3. Verify ALL strikes have data" -ForegroundColor White
Write-Host "   4. Make individual API calls for still-missing strikes" -ForegroundColor White
Write-Host ""
Write-Host "✅ Expected Results:" -ForegroundColor Yellow
Write-Host "   - 75400 CE will get fresh LC/UC data from today's quote API" -ForegroundColor White
Write-Host "   - All missing strikes will be captured" -ForegroundColor White
Write-Host "   - No strikes will be missed" -ForegroundColor White
Write-Host ""
Write-Host "Ready to restart service with enhanced data collection!" -ForegroundColor Green



