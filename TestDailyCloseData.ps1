# Test script to verify daily close data collection
# This script can be used to test the DailyCloseDataService

Write-Host "Testing Daily Close Data Service..." -ForegroundColor Green

# Test getting correct SENSEX close for 30-09-2025
Write-Host "Checking SENSEX close for 30-09-2025..." -ForegroundColor Yellow

# Query to check current data
$query = @"
SELECT IndexName, TradingDate, ClosePrice, DataSource, QuoteTimestamp 
FROM SpotData 
WHERE IndexName = 'SENSEX' AND TradingDate = '2025-09-30'
ORDER BY QuoteTimestamp DESC;
"@

Write-Host "Current SENSEX data for 30-09-2025:" -ForegroundColor Cyan
sqlcmd -S localhost -d KiteMarketData -E -Q $query

Write-Host "`nNote: If the close price is not 80267, the DailyCloseDataService will correct it." -ForegroundColor Magenta
Write-Host "The service will automatically run at 4:00 PM IST daily to download proper close prices." -ForegroundColor Magenta
