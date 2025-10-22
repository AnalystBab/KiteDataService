-- Clear all tables for fresh data collection test
-- Run this before starting the service for testing

USE KiteMarketData;
GO

-- Disable all constraints temporarily
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';
GO

-- Clear all tables (in correct order due to foreign keys)
PRINT '🧹 Clearing CircuitLimitChanges...';
DELETE FROM CircuitLimitChanges;
PRINT '✅ CircuitLimitChanges cleared';

PRINT '🧹 Clearing IntradayTickData...';
DELETE FROM IntradayTickData;
PRINT '✅ IntradayTickData cleared';

PRINT '🧹 Clearing MarketQuotes...';
DELETE FROM MarketQuotes;
PRINT '✅ MarketQuotes cleared';

PRINT '🧹 Clearing SpotData...';
DELETE FROM SpotData;
PRINT '✅ SpotData cleared';

PRINT '🧹 Clearing Instruments...';
DELETE FROM Instruments;
PRINT '✅ Instruments cleared';

-- Re-enable all constraints
EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';
GO

-- Verify all tables are empty
PRINT '';
PRINT '📊 VERIFICATION - Row Counts:';
SELECT 'CircuitLimitChanges' AS TableName, COUNT(*) AS RowCount FROM CircuitLimitChanges
UNION ALL
SELECT 'IntradayTickData', COUNT(*) FROM IntradayTickData
UNION ALL
SELECT 'MarketQuotes', COUNT(*) FROM MarketQuotes
UNION ALL
SELECT 'SpotData', COUNT(*) FROM SpotData
UNION ALL
SELECT 'Instruments', COUNT(*) FROM Instruments;

PRINT '';
PRINT '✅ ALL TABLES CLEARED - READY FOR FRESH TEST!';
GO

