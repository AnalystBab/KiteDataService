@echo off
echo Fixing InstrumentToken Column Issue...
echo.

REM Run SQL script to add missing column
sqlcmd -S "LAPTOP-B68L4IP9" -d "KiteMarketData" -i "AddInstrumentTokenColumn.sql"

echo.
echo InstrumentToken column fix completed!
echo.
echo The service should now be able to insert market data.
echo.
echo Next steps:
echo 1. Stop the service (if running)
echo 2. Restart the service
echo 3. Monitor for successful data insertion
echo.
pause


