-- Add InstrumentToken column to MarketQuotes table
-- This will fix the "Invalid column name 'InstrumentToken'" error

USE [KiteMarketData]

PRINT 'Adding InstrumentToken column to MarketQuotes table...'

-- Check if InstrumentToken column exists
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('MarketQuotes') AND name = 'InstrumentToken')
BEGIN
    -- Add InstrumentToken column
    ALTER TABLE MarketQuotes
    ADD InstrumentToken BIGINT NOT NULL DEFAULT 0;
    
    PRINT '✅ InstrumentToken column added successfully'
    
    -- Add index for performance
    CREATE INDEX IX_MarketQuotes_InstrumentToken ON MarketQuotes (InstrumentToken);
    PRINT '✅ Index created for InstrumentToken column'
END
ELSE
BEGIN
    PRINT '⚠️ InstrumentToken column already exists'
END

-- Verify the column was added
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'MarketQuotes' 
AND COLUMN_NAME = 'InstrumentToken';

PRINT ''
PRINT 'InstrumentToken column fix completed!'
PRINT 'The service should now be able to insert market data.'
PRINT ''
PRINT 'Next steps:'
PRINT '1. Stop the service (if running)'
PRINT '2. Restart the service'
PRINT '3. Monitor for successful data insertion'


