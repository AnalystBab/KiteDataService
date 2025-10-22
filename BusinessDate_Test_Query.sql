-- BusinessDate Test Query
-- This query shows how BusinessDate is calculated and used

USE KiteMarketData;
GO

-- =============================================
-- 1. CHECK BUSINESS DATE COLUMN EXISTS
-- =============================================

PRINT '=============================================';
PRINT 'BUSINESS DATE COLUMN VERIFICATION';
PRINT '=============================================';

-- Check if BusinessDate column exists in MarketQuotes table
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'MarketQuotes' 
    AND COLUMN_NAME = 'BusinessDate';

-- =============================================
-- 2. SAMPLE DATA WITH BUSINESS DATE
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'SAMPLE DATA WITH BUSINESS DATE';
PRINT '=============================================';

-- Show recent market quotes with BusinessDate
SELECT TOP 10
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    OpenPrice,
    HighPrice,
    LowPrice,
    ClosePrice,
    LastPrice,
    LowerCircuitLimit as Lc,
    UpperCircuitLimit as Uc,
    BusinessDate,
    TradingDate,
    LastTradeTime,
    QuoteTimestamp
FROM MarketQuotes
WHERE TradingSymbol LIKE 'NIFTY%'
    AND BusinessDate IS NOT NULL
ORDER BY QuoteTimestamp DESC;

-- =============================================
-- 3. BUSINESS DATE DISTRIBUTION
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'BUSINESS DATE DISTRIBUTION';
PRINT '=============================================';

-- Show distribution of BusinessDate values
SELECT 
    BusinessDate,
    COUNT(*) as QuoteCount,
    COUNT(DISTINCT TradingSymbol) as UniqueSymbols,
    MIN(QuoteTimestamp) as EarliestQuote,
    MAX(QuoteTimestamp) as LatestQuote
FROM MarketQuotes
WHERE BusinessDate IS NOT NULL
GROUP BY BusinessDate
ORDER BY BusinessDate DESC;

-- =============================================
-- 4. NIFTY SPOT DATA FOR BUSINESS DATE CALCULATION
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'NIFTY SPOT DATA FOR BUSINESS DATE CALCULATION';
PRINT '=============================================';

-- Show NIFTY spot data used for BusinessDate calculation
SELECT 
    TradingSymbol,
    OpenPrice,
    HighPrice,
    LowPrice,
    ClosePrice,
    LastPrice,
    QuoteTimestamp,
    LastTradeTime,
    BusinessDate,
    CASE 
        WHEN OpenPrice > 0 AND HighPrice > 0 AND LowPrice > 0 THEN 'MARKET_OPEN'
        ELSE 'MARKET_CLOSED'
    END as MarketStatus,
    CASE 
        WHEN OpenPrice > 0 AND HighPrice > 0 AND LowPrice > 0 THEN OpenPrice
        ELSE ClosePrice
    END as SpotPrice
FROM MarketQuotes
WHERE TradingSymbol = 'NIFTY'
ORDER BY QuoteTimestamp DESC;

-- =============================================
-- 5. NEAREST STRIKE CALCULATION EXAMPLE
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'NEAREST STRIKE CALCULATION EXAMPLE';
PRINT '=============================================';

-- Example of finding nearest strike to a spot price
DECLARE @SpotPrice DECIMAL(10,2) = 25200.00; -- Example spot price

SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    LastTradeTime,
    BusinessDate,
    ABS(Strike - @SpotPrice) as DistanceFromSpot
FROM MarketQuotes
WHERE TradingSymbol LIKE 'NIFTY%'
    AND TradingSymbol != 'NIFTY' -- Exclude spot
    AND LastTradeTime IS NOT NULL
    AND OptionType = 'CE'
ORDER BY DistanceFromSpot
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

-- =============================================
-- 6. BUSINESS DATE BY EXPIRY
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'BUSINESS DATE BY EXPIRY';
PRINT '=============================================';

-- Show BusinessDate for different expiries
SELECT 
    CAST(ExpiryDate AS DATE) as ExpiryDate,
    BusinessDate,
    COUNT(*) as QuoteCount,
    COUNT(DISTINCT TradingSymbol) as UniqueSymbols
FROM MarketQuotes
WHERE TradingSymbol LIKE 'NIFTY%'
    AND BusinessDate IS NOT NULL
    AND ExpiryDate >= CAST(GETDATE() AS DATE)
GROUP BY CAST(ExpiryDate AS DATE), BusinessDate
ORDER BY ExpiryDate, BusinessDate;

-- =============================================
-- 7. BUSINESS DATE VALIDATION
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'BUSINESS DATE VALIDATION';
PRINT '=============================================';

-- Validate BusinessDate logic
SELECT 
    'Total Quotes' as Metric,
    COUNT(*) as Count
FROM MarketQuotes
WHERE TradingSymbol LIKE 'NIFTY%'

UNION ALL

SELECT 
    'Quotes with BusinessDate',
    COUNT(*)
FROM MarketQuotes
WHERE TradingSymbol LIKE 'NIFTY%'
    AND BusinessDate IS NOT NULL

UNION ALL

SELECT 
    'Quotes without BusinessDate',
    COUNT(*)
FROM MarketQuotes
WHERE TradingSymbol LIKE 'NIFTY%'
    AND BusinessDate IS NULL;

GO

PRINT '=============================================';
PRINT 'BUSINESS DATE TEST COMPLETE';
PRINT '=============================================';




