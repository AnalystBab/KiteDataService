-- Clear All Table Data - Fresh Start
-- This will delete all data from all tables to start fresh

USE [KiteMarketData]

-- Clear all tables in order (respecting foreign key constraints)
PRINT 'Clearing all table data for fresh start...'

-- Clear CircuitLimitChangeDetails first (if it exists)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'CircuitLimitChangeDetails')
BEGIN
    DELETE FROM CircuitLimitChangeDetails
    PRINT 'Cleared CircuitLimitChangeDetails table'
END

-- Clear MarketQuotes
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'MarketQuotes')
BEGIN
    DELETE FROM MarketQuotes
    PRINT 'Cleared MarketQuotes table'
END

-- Clear IntradayTickData
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'IntradayTickData')
BEGIN
    DELETE FROM IntradayTickData
    PRINT 'Cleared IntradayTickData table'
END

-- Clear SpotData
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SpotData')
BEGIN
    DELETE FROM SpotData
    PRINT 'Cleared SpotData table'
END

-- Clear FullInstruments
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'FullInstruments')
BEGIN
    DELETE FROM FullInstruments
    PRINT 'Cleared FullInstruments table'
END

-- Clear Instruments
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Instruments')
BEGIN
    DELETE FROM Instruments
    PRINT 'Cleared Instruments table'
END

-- Clear ExcelExportData (if it exists)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelExportData')
BEGIN
    DELETE FROM ExcelExportData
    PRINT 'Cleared ExcelExportData table'
END

-- Reset identity columns to start from 1
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'MarketQuotes')
BEGIN
    DBCC CHECKIDENT ('MarketQuotes', RESEED, 0)
    PRINT 'Reset MarketQuotes identity column'
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'IntradayTickData')
BEGIN
    DBCC CHECKIDENT ('IntradayTickData', RESEED, 0)
    PRINT 'Reset IntradayTickData identity column'
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'SpotData')
BEGIN
    DBCC CHECKIDENT ('SpotData', RESEED, 0)
    PRINT 'Reset SpotData identity column'
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'FullInstruments')
BEGIN
    DBCC CHECKIDENT ('FullInstruments', RESEED, 0)
    PRINT 'Reset FullInstruments identity column'
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'Instruments')
BEGIN
    DBCC CHECKIDENT ('Instruments', RESEED, 0)
    PRINT 'Reset Instruments identity column'
END

IF EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelExportData')
BEGIN
    DBCC CHECKIDENT ('ExcelExportData', RESEED, 0)
    PRINT 'Reset ExcelExportData identity column'
END

PRINT ''
PRINT 'All tables cleared successfully!'
PRINT 'Ready for fresh data collection.'
PRINT ''
PRINT 'Tables cleared:'
PRINT '- CircuitLimitChangeDetails'
PRINT '- MarketQuotes'
PRINT '- IntradayTickData'
PRINT '- SpotData'
PRINT '- FullInstruments'
PRINT '- Instruments'
PRINT '- ExcelExportData'
PRINT ''
PRINT 'Identity columns reset to start from 1.'
PRINT ''
PRINT 'You can now run your service for fresh data collection!'


