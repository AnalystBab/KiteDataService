-- Clear Database and Fix Expiry Data
-- This script will clear all corrupted data and ensure proper expiry storage

USE KiteMarketData;

-- Clear all market quotes (they have wrong expiry data)
DELETE FROM MarketQuotes;
PRINT 'Cleared all MarketQuotes';

-- Clear all circuit limits (they depend on market quotes)
DELETE FROM CircuitLimits;
PRINT 'Cleared all CircuitLimits';

-- Clear all instruments (to reload with correct expiry data)
DELETE FROM Instruments;
PRINT 'Cleared all Instruments';

-- Reset identity columns
DBCC CHECKIDENT ('MarketQuotes', RESEED, 0);
DBCC CHECKIDENT ('CircuitLimits', RESEED, 0);
PRINT 'Reset identity columns';

-- Verify tables are empty
SELECT 'MarketQuotes' as TableName, COUNT(*) as RecordCount FROM MarketQuotes
UNION ALL
SELECT 'CircuitLimits' as TableName, COUNT(*) as RecordCount FROM CircuitLimits
UNION ALL
SELECT 'Instruments' as TableName, COUNT(*) as RecordCount FROM Instruments;

PRINT 'Database cleared successfully. Run the service to reload with correct expiry data.';
PRINT 'The service will now:';
PRINT '1. Load instruments with proper expiry dates';
PRINT '2. Store market quotes with correct expiry information';
PRINT '3. Use IST timestamps for all date/time fields';
