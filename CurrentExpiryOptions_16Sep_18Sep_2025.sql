-- NIFTY AND SENSEX OPTIONS QUERIES FOR CURRENT RUNNING EXPIRIES
-- Expiry Dates: 16-09-2025 and 18-09-2025
-- Order: CALL options ASC, PUT options DESC by Strike Price
-- Separate queries for NIFTY and SENSEX

USE KiteMarketData;
GO

-- =============================================
-- NIFTY OPTIONS QUERIES
-- =============================================

PRINT '=============================================';
PRINT 'NIFTY OPTIONS - EXPIRY 16-09-2025 AND 18-09-2025';
PRINT '=============================================';

-- =============================================
-- 1. NIFTY CALL OPTIONS - 16-09-2025 EXPIRY (ASCENDING ORDER)
-- =============================================

PRINT '';
PRINT '=== NIFTY CALL OPTIONS (16-09-2025 EXPIRY) - ASCENDING ORDER ===';

WITH LatestNIFTYCALLQuotes_16Sep AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'NIFTY%' 
        AND CAST(mq.Expiry AS DATE) = '2025-09-16'
        AND i.InstrumentType = 'CE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    '16-Sep-2025' as ExpiryDate,
    'CALL' as OptionType,
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS LowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM LatestNIFTYCALLQuotes_16Sep
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike ASC;

-- =============================================
-- 2. NIFTY PUT OPTIONS - 16-09-2025 EXPIRY (DESCENDING ORDER)
-- =============================================

PRINT '';
PRINT '=== NIFTY PUT OPTIONS (16-09-2025 EXPIRY) - DESCENDING ORDER ===';

WITH LatestNIFTYPUTQuotes_16Sep AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'NIFTY%' 
        AND CAST(mq.Expiry AS DATE) = '2025-09-16'
        AND i.InstrumentType = 'PE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    '16-Sep-2025' as ExpiryDate,
    'PUT' as OptionType,
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS LowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM LatestNIFTYPUTQuotes_16Sep
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike DESC;

-- =============================================
-- 3. NIFTY CALL OPTIONS - 18-09-2025 EXPIRY (ASCENDING ORDER)
-- =============================================

PRINT '';
PRINT '=== NIFTY CALL OPTIONS (18-09-2025 EXPIRY) - ASCENDING ORDER ===';

WITH LatestNIFTYCALLQuotes_18Sep AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'NIFTY%' 
        AND CAST(mq.Expiry AS DATE) = '2025-09-18'
        AND i.InstrumentType = 'CE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    '18-Sep-2025' as ExpiryDate,
    'CALL' as OptionType,
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS LowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM LatestNIFTYCALLQuotes_18Sep
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike ASC;

-- =============================================
-- 4. NIFTY PUT OPTIONS - 18-09-2025 EXPIRY (DESCENDING ORDER)
-- =============================================

PRINT '';
PRINT '=== NIFTY PUT OPTIONS (18-09-2025 EXPIRY) - DESCENDING ORDER ===';

WITH LatestNIFTYPUTQuotes_18Sep AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'NIFTY%' 
        AND CAST(mq.Expiry AS DATE) = '2025-09-18'
        AND i.InstrumentType = 'PE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    '18-Sep-2025' as ExpiryDate,
    'PUT' as OptionType,
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS LowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM LatestNIFTYPUTQuotes_18Sep
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike DESC;

-- =============================================
-- SENSEX OPTIONS QUERIES
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'SENSEX OPTIONS - EXPIRY 16-09-2025 AND 18-09-2025';
PRINT '=============================================';

-- =============================================
-- 5. SENSEX CALL OPTIONS - 16-09-2025 EXPIRY (ASCENDING ORDER)
-- =============================================

PRINT '';
PRINT '=== SENSEX CALL OPTIONS (16-09-2025 EXPIRY) - ASCENDING ORDER ===';

WITH LatestSENSEXCALLQuotes_16Sep AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'SENSEX%' 
        AND CAST(mq.Expiry AS DATE) = '2025-09-16'
        AND i.InstrumentType = 'CE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    '16-Sep-2025' as ExpiryDate,
    'CALL' as OptionType,
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS LowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM LatestSENSEXCALLQuotes_16Sep
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike ASC;

-- =============================================
-- 6. SENSEX PUT OPTIONS - 16-09-2025 EXPIRY (DESCENDING ORDER)
-- =============================================

PRINT '';
PRINT '=== SENSEX PUT OPTIONS (16-09-2025 EXPIRY) - DESCENDING ORDER ===';

WITH LatestSENSEXPUTQuotes_16Sep AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'SENSEX%' 
        AND CAST(mq.Expiry AS DATE) = '2025-09-16'
        AND i.InstrumentType = 'PE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    '16-Sep-2025' as ExpiryDate,
    'PUT' as OptionType,
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS LowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM LatestSENSEXPUTQuotes_16Sep
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike DESC;

-- =============================================
-- 7. SENSEX CALL OPTIONS - 18-09-2025 EXPIRY (ASCENDING ORDER)
-- =============================================

PRINT '';
PRINT '=== SENSEX CALL OPTIONS (18-09-2025 EXPIRY) - ASCENDING ORDER ===';

WITH LatestSENSEXCALLQuotes_18Sep AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'SENSEX%' 
        AND CAST(mq.Expiry AS DATE) = '2025-09-18'
        AND i.InstrumentType = 'CE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    '18-Sep-2025' as ExpiryDate,
    'CALL' as OptionType,
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS LowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM LatestSENSEXCALLQuotes_18Sep
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike ASC;

-- =============================================
-- 8. SENSEX PUT OPTIONS - 18-09-2025 EXPIRY (DESCENDING ORDER)
-- =============================================

PRINT '';
PRINT '=== SENSEX PUT OPTIONS (18-09-2025 EXPIRY) - DESCENDING ORDER ===';

WITH LatestSENSEXPUTQuotes_18Sep AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'SENSEX%' 
        AND CAST(mq.Expiry AS DATE) = '2025-09-18'
        AND i.InstrumentType = 'PE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    '18-Sep-2025' as ExpiryDate,
    'PUT' as OptionType,
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS LowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    QuoteTimestamp
FROM LatestSENSEXPUTQuotes_18Sep
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike DESC;

-- =============================================
-- SUMMARY STATISTICS
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'SUMMARY STATISTICS';
PRINT '=============================================';

SELECT 
    'NIFTY' as IndexName,
    '16-Sep-2025' as ExpiryDate,
    'CALL' as OptionType,
    COUNT(*) as TotalOptions,
    COUNT(CASE WHEN mq.OHLC_Open > 0 THEN 1 END) as ActiveOptions,
    MIN(i.Strike) as MinStrike,
    MAX(i.Strike) as MaxStrike,
    AVG(mq.LastPrice) as AvgLastPrice
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-09-16'
    AND i.InstrumentType = 'CE'
    AND mq.Expiry IS NOT NULL

UNION ALL

SELECT 
    'NIFTY',
    '16-Sep-2025',
    'PUT',
    COUNT(*),
    COUNT(CASE WHEN mq.OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-09-16'
    AND i.InstrumentType = 'PE'
    AND mq.Expiry IS NOT NULL

UNION ALL

SELECT 
    'NIFTY',
    '18-Sep-2025',
    'CALL',
    COUNT(*),
    COUNT(CASE WHEN mq.OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-09-18'
    AND i.InstrumentType = 'CE'
    AND mq.Expiry IS NOT NULL

UNION ALL

SELECT 
    'NIFTY',
    '18-Sep-2025',
    'PUT',
    COUNT(*),
    COUNT(CASE WHEN mq.OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-09-18'
    AND i.InstrumentType = 'PE'
    AND mq.Expiry IS NOT NULL

UNION ALL

SELECT 
    'SENSEX',
    '16-Sep-2025',
    'CALL',
    COUNT(*),
    COUNT(CASE WHEN mq.OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'SENSEX%' 
    AND CAST(mq.Expiry AS DATE) = '2025-09-16'
    AND i.InstrumentType = 'CE'
    AND mq.Expiry IS NOT NULL

UNION ALL

SELECT 
    'SENSEX',
    '16-Sep-2025',
    'PUT',
    COUNT(*),
    COUNT(CASE WHEN mq.OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'SENSEX%' 
    AND CAST(mq.Expiry AS DATE) = '2025-09-16'
    AND i.InstrumentType = 'PE'
    AND mq.Expiry IS NOT NULL

UNION ALL

SELECT 
    'SENSEX',
    '18-Sep-2025',
    'CALL',
    COUNT(*),
    COUNT(CASE WHEN mq.OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'SENSEX%' 
    AND CAST(mq.Expiry AS DATE) = '2025-09-18'
    AND i.InstrumentType = 'CE'
    AND mq.Expiry IS NOT NULL

UNION ALL

SELECT 
    'SENSEX',
    '18-Sep-2025',
    'PUT',
    COUNT(*),
    COUNT(CASE WHEN mq.OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'SENSEX%' 
    AND CAST(mq.Expiry AS DATE) = '2025-09-18'
    AND i.InstrumentType = 'PE'
    AND mq.Expiry IS NOT NULL

ORDER BY IndexName, ExpiryDate, OptionType;

GO
