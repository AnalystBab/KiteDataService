# Test Kite API Direct Call
# This script tests direct API call to Kite for missing strike data

Write-Host "Testing Direct Kite API Call..." -ForegroundColor Green
Write-Host "Strike: SENSEX25AUG75400CE" -ForegroundColor Yellow
Write-Host "Token: 211682565" -ForegroundColor Yellow
Write-Host ""

# Test 1: Check if we can get data for this specific token
Write-Host "=== TEST 1: Direct API Call for Single Token ===" -ForegroundColor Cyan

# This would require the actual Kite API credentials and access token
# For now, let's check what we can learn from the existing data

Write-Host "Since we can't make direct API calls without credentials, let's analyze the pattern:" -ForegroundColor Yellow

# Test 2: Check which strikes DO have data today
Write-Host "=== TEST 2: Strikes with Data Today ===" -ForegroundColor Cyan
$strikesWithData = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT DISTINCT i.Strike FROM MarketQuotes mq INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken WHERE i.TradingSymbol LIKE 'SENSEX25AUG%' AND i.InstrumentType = 'CE' AND CAST(mq.TradingDate AS date) = CAST(GETDATE() AS date) ORDER BY i.Strike"
Write-Host "Strikes with data today: $strikesWithData" -ForegroundColor White

# Test 3: Check which strikes DON'T have data today
Write-Host "=== TEST 3: Strikes Missing Data Today ===" -ForegroundColor Cyan
$strikesMissingData = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT i.Strike FROM Instruments i LEFT JOIN MarketQuotes mq ON i.InstrumentToken = mq.InstrumentToken AND CAST(mq.TradingDate AS date) = CAST(GETDATE() AS date) WHERE i.TradingSymbol LIKE 'SENSEX25AUG%' AND i.InstrumentType = 'CE' AND mq.Id IS NULL ORDER BY i.Strike"
Write-Host "Strikes missing data today: $strikesMissingData" -ForegroundColor White

# Test 4: Check if there's a pattern in missing strikes
Write-Host "=== TEST 4: Pattern Analysis ===" -ForegroundColor Cyan
Write-Host "Let's see if missing strikes follow a pattern..." -ForegroundColor Yellow

Write-Host ""
Write-Host "=== SOLUTION APPROACH ===" -ForegroundColor Green
Write-Host "Based on the image you showed, Kite DOES provide LC/UC for 75400 CE:" -ForegroundColor Yellow
Write-Host "- Lower Circuit: 3,592.75" -ForegroundColor White
Write-Host "- Upper Circuit: 9,062.20" -ForegroundColor White
Write-Host ""
Write-Host "The issue is likely:" -ForegroundColor Red
Write-Host "1. API rate limiting - we're hitting limits" -ForegroundColor Red
Write-Host "2. Batch size too large - some requests failing" -ForegroundColor Red
Write-Host "3. Network timeouts - some API calls timing out" -ForegroundColor Red
Write-Host ""
Write-Host "SOLUTION: Implement retry logic with smaller batches" -ForegroundColor Green



