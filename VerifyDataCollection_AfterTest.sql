-- ========================================
-- DATA COLLECTION VERIFICATION QUERIES
-- Run these AFTER service has collected data
-- ========================================

USE KiteMarketData;
GO

PRINT '================================================';
PRINT '1️⃣  TABLE ROW COUNTS';
PRINT '================================================';
SELECT 'Instruments' AS [Table], COUNT(*) AS [Rows] FROM Instruments
UNION ALL
SELECT 'SpotData', COUNT(*) FROM SpotData
UNION ALL
SELECT 'MarketQuotes', COUNT(*) FROM MarketQuotes
UNION ALL
SELECT 'CircuitLimitChanges', COUNT(*) FROM CircuitLimitChanges
UNION ALL
SELECT 'IntradayTickData', COUNT(*) FROM IntradayTickData;
GO

PRINT '';
PRINT '================================================';
PRINT '2️⃣  SPOTDATA - Historical Data Check';
PRINT '================================================';
SELECT 
    IndexName,
    TradingDate,
    FORMAT(QuoteTimestamp, 'yyyy-MM-dd HH:mm:ss') AS QuoteTimestamp,
    OpenPrice,
    HighPrice,
    LowPrice,
    ClosePrice,
    LastPrice,
    DataSource,
    IsMarketOpen
FROM SpotData
ORDER BY IndexName, TradingDate DESC, QuoteTimestamp DESC;
GO

PRINT '';
PRINT '================================================';
PRINT '3️⃣  BUSINESSDATE CHECK - Critical Test!';
PRINT '================================================';
SELECT 
    BusinessDate,
    FORMAT(RecordDateTime, 'yyyy-MM-dd HH:mm:ss') AS RecordDateTime_Sample,
    COUNT(*) AS QuoteCount,
    MIN(FORMAT(RecordDateTime, 'HH:mm:ss')) AS EarliestTime,
    MAX(FORMAT(RecordDateTime, 'HH:mm:ss')) AS LatestTime
FROM MarketQuotes
GROUP BY BusinessDate, CAST(RecordDateTime AS DATE)
ORDER BY BusinessDate DESC;
GO

PRINT '';
PRINT '================================================';
PRINT '4️⃣  SAMPLE MARKET QUOTES - Check Data Quality';
PRINT '================================================';
SELECT TOP 10
    TradingSymbol,
    Strike,
    OptionType,
    LastPrice,
    LowerCircuitLimit AS LC,
    UpperCircuitLimit AS UC,
    FORMAT(LastTradeTime, 'yyyy-MM-dd HH:mm:ss') AS LastTradeTime,
    FORMAT(RecordDateTime, 'yyyy-MM-dd HH:mm:ss') AS RecordDateTime,
    BusinessDate
FROM MarketQuotes
ORDER BY RecordDateTime DESC;
GO

PRINT '';
PRINT '================================================';
PRINT '5️⃣  BUSINESSDATE vs COLLECTION TIME CHECK';
PRINT '================================================';
-- This checks if pre-market data has correct BusinessDate
SELECT 
    CASE 
        WHEN CAST(RecordDateTime AS TIME) < '09:15:00' THEN 'PRE-MARKET'
        WHEN CAST(RecordDateTime AS TIME) BETWEEN '09:15:00' AND '15:30:00' THEN 'MARKET-HOURS'
        ELSE 'POST-MARKET'
    END AS CollectionPeriod,
    CAST(RecordDateTime AS DATE) AS CollectionDate,
    BusinessDate,
    CASE 
        WHEN CAST(RecordDateTime AS TIME) < '09:15:00' 
             AND BusinessDate < CAST(RecordDateTime AS DATE) THEN '✅ CORRECT (Previous day)'
        WHEN CAST(RecordDateTime AS TIME) < '09:15:00' 
             AND BusinessDate >= CAST(RecordDateTime AS DATE) THEN '❌ WRONG (Should be previous day)'
        WHEN CAST(RecordDateTime AS TIME) BETWEEN '09:15:00' AND '15:30:00'
             AND BusinessDate = CAST(RecordDateTime AS DATE) THEN '✅ CORRECT (Current day)'
        WHEN CAST(RecordDateTime AS TIME) > '15:30:00'
             AND BusinessDate = CAST(RecordDateTime AS DATE) THEN '✅ CORRECT (Current day)'
        ELSE '❌ NEEDS REVIEW'
    END AS BusinessDateStatus,
    COUNT(*) AS QuoteCount
FROM MarketQuotes
GROUP BY 
    CASE 
        WHEN CAST(RecordDateTime AS TIME) < '09:15:00' THEN 'PRE-MARKET'
        WHEN CAST(RecordDateTime AS TIME) BETWEEN '09:15:00' AND '15:30:00' THEN 'MARKET-HOURS'
        ELSE 'POST-MARKET'
    END,
    CAST(RecordDateTime AS DATE),
    BusinessDate
ORDER BY CollectionDate DESC, CollectionPeriod;
GO

PRINT '';
PRINT '================================================';
PRINT '6️⃣  SPOT DATA - Historical vs Real-time Check';
PRINT '================================================';
SELECT 
    DataSource,
    COUNT(*) AS RecordCount,
    MIN(TradingDate) AS EarliestDate,
    MAX(TradingDate) AS LatestDate
FROM SpotData
GROUP BY DataSource
ORDER BY DataSource;
GO

PRINT '';
PRINT '================================================';
PRINT '7️⃣  DUPLICATE CHECK - Should be ZERO';
PRINT '================================================';
-- Check for duplicate spot data
SELECT 
    'SpotData Duplicates' AS CheckType,
    IndexName,
    TradingDate,
    DataSource,
    COUNT(*) AS DuplicateCount
FROM SpotData
GROUP BY IndexName, TradingDate, DataSource
HAVING COUNT(*) > 1
UNION ALL
-- Check for duplicate instruments
SELECT 
    'Instrument Duplicates',
    TradingSymbol,
    NULL,
    NULL,
    COUNT(*)
FROM Instruments
GROUP BY TradingSymbol
HAVING COUNT(*) > 1;
GO

PRINT '';
PRINT '================================================';
PRINT '8️⃣  LC/UC CIRCUIT LIMIT VALUES - Sample Data';
PRINT '================================================';
SELECT TOP 20
    TradingSymbol,
    Strike,
    OptionType,
    LastPrice,
    LowerCircuitLimit AS LC,
    UpperCircuitLimit AS UC,
    CAST((UpperCircuitLimit - LowerCircuitLimit) AS DECIMAL(10,2)) AS LC_UC_Range,
    FORMAT(RecordDateTime, 'yyyy-MM-dd HH:mm:ss') AS CollectedAt,
    BusinessDate
FROM MarketQuotes
WHERE LowerCircuitLimit > 0 AND UpperCircuitLimit > 0
ORDER BY Strike, OptionType, RecordDateTime DESC;
GO

PRINT '';
PRINT '================================================';
PRINT '9️⃣  CIRCUIT LIMIT CHANGES - If Any Detected';
PRINT '================================================';
SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    OldLC,
    NewLC,
    OldUC,
    NewUC,
    FORMAT(ChangeTimestamp, 'yyyy-MM-dd HH:mm:ss') AS ChangedAt,
    BusinessDate
FROM CircuitLimitChanges
ORDER BY ChangeTimestamp DESC;
GO

PRINT '';
PRINT '================================================';
PRINT '🎯 KEY CHECKS SUMMARY';
PRINT '================================================';
PRINT '✅ = PASS, ❌ = FAIL';
PRINT '';
PRINT 'Check these results:';
PRINT '1. SpotData has historical data (TradingDate, DataSource = "Kite Historical API")';
PRINT '2. BusinessDate is CORRECT for pre-market, market, post-market';
PRINT '3. No duplicate entries in SpotData';
PRINT '4. MarketQuotes has LC/UC values';
PRINT '5. All timestamps are in IST';
PRINT '6. LastTradeTime is not NULL/MinValue';
PRINT '';
PRINT '================================================';
GO

