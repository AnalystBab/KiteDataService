-- =====================================================
-- Database Structure Fixes for Kite Market Data
-- =====================================================

-- Phase 1: Add IndexName column to Instruments table
PRINT 'Adding IndexName column to Instruments table...'
GO

-- Add IndexName column
IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Instruments' AND COLUMN_NAME = 'IndexName')
BEGIN
    ALTER TABLE Instruments ADD IndexName NVARCHAR(20);
    PRINT 'IndexName column added successfully.'
END
ELSE
BEGIN
    PRINT 'IndexName column already exists.'
END
GO

-- Update existing data with correct index names
PRINT 'Updating existing data with correct index names...'
GO

UPDATE Instruments 
SET IndexName = 
    CASE 
        WHEN TradingSymbol LIKE 'NIFTY[0-9]%' AND TradingSymbol NOT LIKE 'NIFTYNXT%' THEN 'NIFTY'
        WHEN TradingSymbol LIKE 'NIFTYNXT%' THEN 'EXCLUDED'  -- Mark NIFTYNXT50 as excluded
        WHEN TradingSymbol LIKE 'BANKNIFTY%' THEN 'BANKNIFTY'
        WHEN TradingSymbol LIKE 'FINNIFTY%' THEN 'FINNIFTY'
        WHEN TradingSymbol LIKE 'MIDCPNIFTY%' THEN 'MIDCPNIFTY'
        WHEN TradingSymbol LIKE 'SENSEX%' THEN 'SENSEX'
        ELSE 'OTHER'
    END
WHERE IndexName IS NULL OR IndexName = '';

PRINT 'Index names updated successfully.'
GO

-- Create indexes for better performance
PRINT 'Creating performance indexes...'
GO

-- Index for Instruments table
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Instruments_IndexName_Expiry_Strike')
BEGIN
    CREATE INDEX IX_Instruments_IndexName_Expiry_Strike 
    ON Instruments (IndexName, Expiry, Strike, InstrumentType);
    PRINT 'Created index IX_Instruments_IndexName_Expiry_Strike'
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Instruments_TradingSymbol')
BEGIN
    CREATE INDEX IX_Instruments_TradingSymbol 
    ON Instruments (TradingSymbol);
    PRINT 'Created index IX_Instruments_TradingSymbol'
END

-- Index for MarketQuotes table
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MarketQuotes_InstrumentToken_QuoteTimestamp')
BEGIN
    CREATE INDEX IX_MarketQuotes_InstrumentToken_QuoteTimestamp 
    ON MarketQuotes (InstrumentToken, QuoteTimestamp);
    PRINT 'Created index IX_MarketQuotes_InstrumentToken_QuoteTimestamp'
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MarketQuotes_QuoteTimestamp')
BEGIN
    CREATE INDEX IX_MarketQuotes_QuoteTimestamp 
    ON MarketQuotes (QuoteTimestamp);
    PRINT 'Created index IX_MarketQuotes_QuoteTimestamp'
END
GO

-- Phase 2: Create indexed views for better performance
PRINT 'Creating indexed views...'
GO

-- Drop existing views if they exist
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_NIFTY_Options')
    DROP VIEW vw_NIFTY_Options;
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_BANKNIFTY_Options')
    DROP VIEW vw_BANKNIFTY_Options;
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_FINNIFTY_Options')
    DROP VIEW vw_FINNIFTY_Options;
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_MIDCPNIFTY_Options')
    DROP VIEW vw_MIDCPNIFTY_Options;
GO

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_SENSEX_Options')
    DROP VIEW vw_SENSEX_Options;
GO

-- Create indexed view for NIFTY options (excluding NIFTYNXT50)
CREATE VIEW vw_NIFTY_Options WITH SCHEMABINDING AS
SELECT 
    i.InstrumentToken,
    i.TradingSymbol,
    i.Expiry,
    i.Strike,
    i.InstrumentType,
    i.IndexName,
    mq.QuoteTimestamp,
    mq.LastPrice,
    mq.OHLC_Open,
    mq.OHLC_High,
    mq.OHLC_Low,
    mq.OHLC_Close,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.Volume,
    mq.OpenInterest,
    mq.BuyQuantity,
    mq.SellQuantity,
    mq.AveragePrice,
    mq.NetChange
FROM dbo.Instruments i
INNER JOIN dbo.MarketQuotes mq ON i.InstrumentToken = mq.InstrumentToken
WHERE i.IndexName = 'NIFTY';  -- This excludes NIFTYNXT50 automatically
GO

-- Create unique clustered index for NIFTY view
CREATE UNIQUE CLUSTERED INDEX IX_vw_NIFTY_Options 
ON vw_NIFTY_Options (InstrumentToken, QuoteTimestamp);
GO

PRINT 'Created vw_NIFTY_Options view with clustered index'
GO

-- Create indexed view for BANKNIFTY options
CREATE VIEW vw_BANKNIFTY_Options WITH SCHEMABINDING AS
SELECT 
    i.InstrumentToken,
    i.TradingSymbol,
    i.Expiry,
    i.Strike,
    i.InstrumentType,
    i.IndexName,
    mq.QuoteTimestamp,
    mq.LastPrice,
    mq.OHLC_Open,
    mq.OHLC_High,
    mq.OHLC_Low,
    mq.OHLC_Close,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.Volume,
    mq.OpenInterest,
    mq.BuyQuantity,
    mq.SellQuantity,
    mq.AveragePrice,
    mq.NetChange
FROM dbo.Instruments i
INNER JOIN dbo.MarketQuotes mq ON i.InstrumentToken = mq.InstrumentToken
WHERE i.IndexName = 'BANKNIFTY';
GO

-- Create unique clustered index for BANKNIFTY view
CREATE UNIQUE CLUSTERED INDEX IX_vw_BANKNIFTY_Options 
ON vw_BANKNIFTY_Options (InstrumentToken, QuoteTimestamp);
GO

PRINT 'Created vw_BANKNIFTY_Options view with clustered index'
GO

-- Create indexed view for SENSEX options
CREATE VIEW vw_SENSEX_Options WITH SCHEMABINDING AS
SELECT 
    i.InstrumentToken,
    i.TradingSymbol,
    i.Expiry,
    i.Strike,
    i.InstrumentType,
    i.IndexName,
    mq.QuoteTimestamp,
    mq.LastPrice,
    mq.OHLC_Open,
    mq.OHLC_High,
    mq.OHLC_Low,
    mq.OHLC_Close,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.Volume,
    mq.OpenInterest,
    mq.BuyQuantity,
    mq.SellQuantity,
    mq.AveragePrice,
    mq.NetChange
FROM dbo.Instruments i
INNER JOIN dbo.MarketQuotes mq ON i.InstrumentToken = mq.InstrumentToken
WHERE i.IndexName = 'SENSEX';
GO

-- Create unique clustered index for SENSEX view
CREATE UNIQUE CLUSTERED INDEX IX_vw_SENSEX_Options 
ON vw_SENSEX_Options (InstrumentToken, QuoteTimestamp);
GO

PRINT 'Created vw_SENSEX_Options view with clustered index'
GO

-- Phase 3: Create stored procedures for common queries
PRINT 'Creating stored procedures for common queries...'
GO

-- Stored procedure for NIFTY options by expiry
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_GetNIFTYOptionsByExpiry')
    DROP PROCEDURE sp_GetNIFTYOptionsByExpiry;
GO

CREATE PROCEDURE sp_GetNIFTYOptionsByExpiry
    @ExpiryDate DATE,
    @InstrumentType NVARCHAR(2) = NULL, -- 'CE' or 'PE' or NULL for both
    @OrderByStrike BIT = 1 -- 1 for ascending, 0 for descending
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = '
    SELECT 
        CAST(mq.QuoteTimestamp AS DATE) AS TradeDate,
        i.Expiry,
        i.IndexName,
        i.Strike,
        i.InstrumentType,
        i.TradingSymbol,
        mq.OHLC_Open,
        mq.OHLC_High,
        mq.OHLC_Low,
        mq.OHLC_Close,
        mq.LowerCircuitLimit,
        mq.UpperCircuitLimit,
        mq.LastPrice,
        mq.Volume,
        mq.OpenInterest,
        mq.QuoteTimestamp
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.IndexName = ''NIFTY''
        AND i.Expiry = @ExpiryDate';
    
    IF @InstrumentType IS NOT NULL
        SET @SQL = @SQL + ' AND i.InstrumentType = @InstrumentType';
    
    SET @SQL = @SQL + ' ORDER BY i.Strike ' + CASE WHEN @OrderByStrike = 1 THEN 'ASC' ELSE 'DESC' END;
    
    EXEC sp_executesql @SQL, 
        N'@ExpiryDate DATE, @InstrumentType NVARCHAR(2)', 
        @ExpiryDate, @InstrumentType;
END
GO

PRINT 'Created sp_GetNIFTYOptionsByExpiry stored procedure'
GO

-- Stored procedure for latest quotes by index
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_GetLatestQuotesByIndex')
    DROP PROCEDURE sp_GetLatestQuotesByIndex;
GO

CREATE PROCEDURE sp_GetLatestQuotesByIndex
    @IndexName NVARCHAR(20),
    @ExpiryDate DATE = NULL,
    @TopCount INT = 100
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SQL NVARCHAR(MAX);
    
    SET @SQL = '
    SELECT TOP (@TopCount)
        i.IndexName,
        i.TradingSymbol,
        i.Expiry,
        i.Strike,
        i.InstrumentType,
        mq.OHLC_Open,
        mq.OHLC_High,
        mq.OHLC_Low,
        mq.OHLC_Close,
        mq.LowerCircuitLimit,
        mq.UpperCircuitLimit,
        mq.LastPrice,
        mq.Volume,
        mq.OpenInterest,
        mq.QuoteTimestamp
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.IndexName = @IndexName
        AND mq.QuoteTimestamp = (
            SELECT MAX(mq2.QuoteTimestamp) 
            FROM MarketQuotes mq2 
            WHERE mq2.InstrumentToken = mq.InstrumentToken
        )';
    
    IF @ExpiryDate IS NOT NULL
        SET @SQL = @SQL + ' AND i.Expiry = @ExpiryDate';
    
    SET @SQL = @SQL + ' ORDER BY i.Strike, i.InstrumentType';
    
    EXEC sp_executesql @SQL, 
        N'@IndexName NVARCHAR(20), @ExpiryDate DATE, @TopCount INT', 
        @IndexName, @ExpiryDate, @TopCount;
END
GO

PRINT 'Created sp_GetLatestQuotesByIndex stored procedure'
GO

-- Phase 4: Verify the fixes
PRINT 'Verifying the fixes...'
GO

-- Check IndexName distribution
SELECT 
    IndexName,
    COUNT(*) as InstrumentCount,
    COUNT(DISTINCT Expiry) as UniqueExpiries
FROM Instruments 
WHERE IndexName IS NOT NULL
GROUP BY IndexName
ORDER BY InstrumentCount DESC;
GO

-- Check NIFTY vs NIFTYNXT50 separation (NIFTYNXT50 should be excluded)
SELECT 
    'NIFTY' as IndexType,
    COUNT(*) as Count
FROM Instruments 
WHERE IndexName = 'NIFTY'
UNION ALL
SELECT 
    'NIFTYNXT50 (EXCLUDED)' as IndexType,
    COUNT(*) as Count
FROM Instruments 
WHERE IndexName = 'EXCLUDED' AND TradingSymbol LIKE 'NIFTYNXT%';
GO

PRINT 'Database structure fixes completed successfully!'
GO

-- Phase 5: Create sample queries for testing
PRINT 'Creating sample queries for testing...'
GO

-- Sample query 1: Get NIFTY options for July 31st expiry
PRINT 'Sample Query 1: NIFTY options for July 31st expiry'
EXEC sp_GetNIFTYOptionsByExpiry @ExpiryDate = '2025-07-31', @InstrumentType = 'PE', @OrderByStrike = 0;
GO

-- Sample query 2: Get latest NIFTY quotes
PRINT 'Sample Query 2: Latest NIFTY quotes'
EXEC sp_GetLatestQuotesByIndex @IndexName = 'NIFTY', @TopCount = 10;
GO

-- Sample query 3: Check data quality
PRINT 'Sample Query 3: Data quality check'
SELECT 
    'MarketQuotes' as TableName,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT InstrumentToken) as UniqueInstruments,
    MIN(QuoteTimestamp) as EarliestQuote,
    MAX(QuoteTimestamp) as LatestQuote
FROM MarketQuotes
UNION ALL
SELECT 
    'Instruments' as TableName,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT InstrumentToken) as UniqueInstruments,
    NULL as EarliestQuote,
    NULL as LatestQuote
FROM Instruments;
GO

PRINT 'All database structure fixes and improvements completed!'
PRINT 'You can now use the improved queries with proper index filtering.'
GO 