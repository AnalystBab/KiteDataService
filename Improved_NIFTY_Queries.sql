-- =====================================================
-- Improved NIFTY Queries with Better Filtering
-- =====================================================

-- IMPORTANT: Run Fix_Database_Structure.sql first to set up the improved structure

-- Query 1: Check if database structure is properly set up
SELECT 
    'Database Structure Check' as CheckType,
    CASE 
        WHEN EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Instruments' AND COLUMN_NAME = 'IndexName') 
        THEN 'PASS' 
        ELSE 'FAIL - Run Fix_Database_Structure.sql first' 
    END as Status;

-- Query 2: Check IndexName distribution
SELECT 
    IndexName,
    COUNT(*) as InstrumentCount,
    COUNT(DISTINCT Expiry) as UniqueExpiries,
    MIN(Expiry) as EarliestExpiry,
    MAX(Expiry) as LatestExpiry
FROM Instruments 
WHERE IndexName IS NOT NULL
GROUP BY IndexName
ORDER BY InstrumentCount DESC;

-- Query 3: Get NIFTY options for July 31st expiry - CALL options (ascending strike)
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
WHERE i.IndexName = 'NIFTY'  -- Clean filtering - excludes NIFTYNXT50
    AND i.Expiry = '2025-07-31'
    AND i.InstrumentType = 'CE'
ORDER BY i.Strike ASC;

-- Query 4: Get NIFTY options for July 31st expiry - PUT options (descending strike)
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
WHERE i.IndexName = 'NIFTY'  -- Clean filtering - excludes NIFTYNXT50
    AND i.Expiry = '2025-07-31'
    AND i.InstrumentType = 'PE'
ORDER BY i.Strike DESC;

-- Query 5: Get NIFTY data for specific trade date (July 28, 2025) - CALL options
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
WHERE i.IndexName = 'NIFTY'
    AND i.Expiry = '2025-07-31'
    AND i.InstrumentType = 'CE'
    AND CAST(mq.QuoteTimestamp AS DATE) = '2025-07-28'
ORDER BY i.Strike ASC;

-- Query 6: Get NIFTY data for specific trade date (July 28, 2025) - PUT options
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
WHERE i.IndexName = 'NIFTY'
    AND i.Expiry = '2025-07-31'
    AND i.InstrumentType = 'PE'
    AND CAST(mq.QuoteTimestamp AS DATE) = '2025-07-28'
ORDER BY i.Strike DESC;

-- Query 7: NIFTY Summary view - Latest data for each strike (CALL and PUT side by side)
WITH LatestNiftyQuotes AS (
    SELECT 
        i.InstrumentToken,
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
        mq.QuoteTimestamp,
        ROW_NUMBER() OVER (PARTITION BY i.InstrumentToken ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.IndexName = 'NIFTY'
        AND i.Expiry = '2025-07-31'
)
SELECT 
    CAST(lq.QuoteTimestamp AS DATE) AS TradeDate,
    lq.Expiry,
    'NIFTY' AS IndexName,
    lq.Strike,
    MAX(CASE WHEN lq.InstrumentType = 'CE' THEN lq.OHLC_Open END) AS Call_Open,
    MAX(CASE WHEN lq.InstrumentType = 'CE' THEN lq.OHLC_High END) AS Call_High,
    MAX(CASE WHEN lq.InstrumentType = 'CE' THEN lq.OHLC_Low END) AS Call_Low,
    MAX(CASE WHEN lq.InstrumentType = 'CE' THEN lq.OHLC_Close END) AS Call_Close,
    MAX(CASE WHEN lq.InstrumentType = 'CE' THEN lq.LowerCircuitLimit END) AS Call_LowerLimit,
    MAX(CASE WHEN lq.InstrumentType = 'CE' THEN lq.UpperCircuitLimit END) AS Call_UpperLimit,
    MAX(CASE WHEN lq.InstrumentType = 'CE' THEN lq.LastPrice END) AS Call_LastPrice,
    MAX(CASE WHEN lq.InstrumentType = 'PE' THEN lq.OHLC_Open END) AS Put_Open,
    MAX(CASE WHEN lq.InstrumentType = 'PE' THEN lq.OHLC_High END) AS Put_High,
    MAX(CASE WHEN lq.InstrumentType = 'PE' THEN lq.OHLC_Low END) AS Put_Low,
    MAX(CASE WHEN lq.InstrumentType = 'PE' THEN lq.OHLC_Close END) AS Put_Close,
    MAX(CASE WHEN lq.InstrumentType = 'PE' THEN lq.LowerCircuitLimit END) AS Put_LowerLimit,
    MAX(CASE WHEN lq.InstrumentType = 'PE' THEN lq.UpperCircuitLimit END) AS Put_UpperLimit,
    MAX(CASE WHEN lq.InstrumentType = 'PE' THEN lq.LastPrice END) AS Put_LastPrice
FROM LatestNiftyQuotes lq
WHERE lq.rn = 1
GROUP BY 
    CAST(lq.QuoteTimestamp AS DATE),
    lq.Expiry,
    lq.Strike
ORDER BY lq.Strike ASC;

-- Query 8: Using the indexed view for better performance
SELECT TOP 50
    TradingSymbol,
    Expiry,
    Strike,
    InstrumentType,
    OHLC_Open,
    OHLC_High,
    OHLC_Low,
    OHLC_Close,
    LowerCircuitLimit,
    UpperCircuitLimit,
    LastPrice,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM vw_NIFTY_Options
WHERE Expiry = '2025-07-31'
ORDER BY Strike, InstrumentType;

-- Query 8b: Using the indexed view for SENSEX options
SELECT TOP 50
    TradingSymbol,
    Expiry,
    Strike,
    InstrumentType,
    OHLC_Open,
    OHLC_High,
    OHLC_Low,
    OHLC_Close,
    LowerCircuitLimit,
    UpperCircuitLimit,
    LastPrice,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM vw_SENSEX_Options
WHERE Expiry = '2025-07-31'
ORDER BY Strike, InstrumentType;

-- Query 9: Using stored procedure for NIFTY options
-- EXEC sp_GetNIFTYOptionsByExpiry @ExpiryDate = '2025-07-31', @InstrumentType = 'PE', @OrderByStrike = 0;

-- Query 10: Get latest NIFTY quotes using stored procedure
-- EXEC sp_GetLatestQuotesByIndex @IndexName = 'NIFTY', @TopCount = 20;

-- Query 11: Check available trade dates for NIFTY July 31st expiry
SELECT DISTINCT 
    CAST(mq.QuoteTimestamp AS DATE) AS TradeDate,
    COUNT(*) as QuoteCount,
    MIN(mq.QuoteTimestamp) as FirstQuote,
    MAX(mq.QuoteTimestamp) as LastQuote
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.IndexName = 'NIFTY'
    AND i.Expiry = '2025-07-31'
GROUP BY CAST(mq.QuoteTimestamp AS DATE)
ORDER BY CAST(mq.QuoteTimestamp AS DATE);

-- Query 12: Check if NIFTY July 31st expiry data exists
SELECT 
    'NIFTY Instruments' as TableName,
    COUNT(*) as RecordCount
FROM Instruments i
WHERE i.IndexName = 'NIFTY'
    AND i.Expiry = '2025-07-31'
UNION ALL
SELECT 
    'NIFTY MarketQuotes' as TableName,
    COUNT(*) as RecordCount
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.IndexName = 'NIFTY'
    AND i.Expiry = '2025-07-31';

-- Query 13: Compare NIFTY vs NIFTYNXT50 data (NIFTYNXT50 excluded)
SELECT 
    'NIFTY' as IndexType,
    COUNT(*) as InstrumentCount,
    COUNT(DISTINCT Expiry) as UniqueExpiries
FROM Instruments 
WHERE IndexName = 'NIFTY'
UNION ALL
SELECT 
    'NIFTYNXT50 (EXCLUDED)' as IndexType,
    COUNT(*) as InstrumentCount,
    COUNT(DISTINCT Expiry) as UniqueExpiries
FROM Instruments 
WHERE IndexName = 'EXCLUDED' AND TradingSymbol LIKE 'NIFTYNXT%';

-- Query 14: Get latest NIFTY quote for each strike (simplified view)
SELECT TOP 20
    i.Strike,
    i.InstrumentType,
    mq.OHLC_Open,
    mq.OHLC_High,
    mq.OHLC_Low,
    mq.OHLC_Close,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.LastPrice,
    mq.QuoteTimestamp
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.IndexName = 'NIFTY'
    AND i.Expiry = '2025-07-31'
    AND mq.QuoteTimestamp = (
        SELECT MAX(mq2.QuoteTimestamp) 
        FROM MarketQuotes mq2 
        WHERE mq2.InstrumentToken = mq.InstrumentToken
    )
ORDER BY i.Strike, i.InstrumentType;

-- Query 15: Performance comparison - Old vs New filtering
-- Old way (problematic):
-- WHERE i.TradingSymbol LIKE 'NIFTY%'  -- This includes NIFTYNXT50

-- New way (clean):
-- WHERE i.IndexName = 'NIFTY'  -- This excludes NIFTYNXT50

-- Query 16: Get SENSEX options for July 31st expiry - CALL options
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
WHERE i.IndexName = 'SENSEX'
    AND i.Expiry = '2025-07-31'
    AND i.InstrumentType = 'CE'
ORDER BY i.Strike ASC;

-- Query 17: Get SENSEX options for July 31st expiry - PUT options
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
WHERE i.IndexName = 'SENSEX'
    AND i.Expiry = '2025-07-31'
    AND i.InstrumentType = 'PE'
ORDER BY i.Strike DESC;

PRINT 'Improved NIFTY and SENSEX queries completed!'
PRINT 'Key improvements:'
PRINT '1. Clean filtering using IndexName column'
PRINT '2. Proper separation of NIFTY vs NIFTYNXT50'
PRINT '3. SENSEX included in data collection'
PRINT '4. Better performance with indexed views'
PRINT '5. Stored procedures for common queries'
PRINT '6. No more string parsing in WHERE clauses' 