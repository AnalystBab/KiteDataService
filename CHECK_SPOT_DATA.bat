@echo off
echo Checking for SENSEX spot data on 2025-10-13...
echo.
sqlcmd -S localhost -d KiteMarketData -Q "SELECT COUNT(*) as RecordsFound, MAX(ClosePrice) as LatestClose FROM HistoricalSpotData WHERE IndexName = 'SENSEX' AND TradingDate = '2025-10-13'"
echo.
echo If RecordsFound = 0, data is still being collected...
echo If RecordsFound = 1, data is available!
echo.
pause
