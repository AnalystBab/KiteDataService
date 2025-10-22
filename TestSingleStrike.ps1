# Test Single Strike Data Fetch
# This script tests fetching LC/UC data for SENSEX 75400 CE directly from Kite API

Write-Host "Testing Single Strike Data Fetch..." -ForegroundColor Green
Write-Host "Strike: SENSEX25AUG75400CE" -ForegroundColor Yellow
Write-Host "Token: 211682565" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check if we have any existing data for this strike
Write-Host "=== TEST 1: Check Existing Data ===" -ForegroundColor Cyan
$existingData = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT COUNT(*) as DataCount FROM MarketQuotes WHERE InstrumentToken = 211682565"
Write-Host "Existing data count: $existingData" -ForegroundColor White

# Test 2: Check if we have data for today
Write-Host "=== TEST 2: Check Today's Data ===" -ForegroundColor Cyan
$todayData = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT COUNT(*) as TodayCount FROM MarketQuotes WHERE InstrumentToken = 211682565 AND CAST(TradingDate AS date) = CAST(GETDATE() AS date)"
Write-Host "Today's data count: $todayData" -ForegroundColor White

# Test 3: Check latest data for this strike
Write-Host "=== TEST 3: Latest Data Details ===" -ForegroundColor Cyan
$latestData = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT TOP 1 TradingDate, TradeTime, LowerCircuitLimit, UpperCircuitLimit, LastPrice, OpenPrice, HighPrice, LowPrice, ClosePrice FROM MarketQuotes WHERE InstrumentToken = 211682565 ORDER BY QuoteTimestamp DESC"
Write-Host "Latest data: $latestData" -ForegroundColor White

# Test 4: Check what other SENSEX strikes have data today
Write-Host "=== TEST 4: Other SENSEX Strikes with Data ===" -ForegroundColor Cyan
$otherStrikes = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT TOP 5 i.Strike, COUNT(*) as DataCount FROM MarketQuotes mq INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken WHERE i.TradingSymbol LIKE 'SENSEX25AUG%' AND i.InstrumentType = 'CE' AND CAST(mq.TradingDate AS date) = CAST(GETDATE() AS date) GROUP BY i.Strike ORDER BY i.Strike"
Write-Host "Other strikes with data: $otherStrikes" -ForegroundColor White

Write-Host ""
Write-Host "=== ANALYSIS ===" -ForegroundColor Green
Write-Host "If 75400 CE has no data but other strikes do, the issue is:" -ForegroundColor Yellow
Write-Host "1. Kite API not returning data for this specific strike" -ForegroundColor Red
Write-Host "2. Our API request is missing this strike" -ForegroundColor Red
Write-Host "3. Rate limiting or batch processing issue" -ForegroundColor Red
Write-Host ""
Write-Host "Next step: Test direct API call for this single strike" -ForegroundColor Cyan



