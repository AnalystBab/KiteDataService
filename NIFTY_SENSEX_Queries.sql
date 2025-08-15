-- NIFTY AND SENSEX OPTIONS QUERIES
-- NIFTY: August 14th, 2025 expiry
-- SENSEX: August 12th, 2025 expiry (today's expiry)

USE KiteMarketData;
GO

-- =============================================
-- 1. NIFTY CALL OPTIONS (August 14th, 2025)
-- =============================================

PRINT '=== NIFTY CALL OPTIONS (AUGUST 14TH, 2025) ===';

WITH LatestNIFTYCALLQuotes AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'NIFTY%' 
        AND CAST(mq.Expiry AS DATE) = '2025-08-14'
        AND i.InstrumentType = 'CE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS lowerLimit,
    UpperCircuitLimit AS UpperLimit
FROM LatestNIFTYCALLQuotes
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike ASC;

-- =============================================
-- 2. NIFTY PUT OPTIONS (August 14th, 2025)
-- =============================================

PRINT '';
PRINT '=== NIFTY PUT OPTIONS (AUGUST 14TH, 2025) ===';

WITH LatestNIFTYPUTQuotes AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'NIFTY%' 
        AND CAST(mq.Expiry AS DATE) = '2025-08-14'
        AND i.InstrumentType = 'PE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS lowerLimit,
    UpperCircuitLimit AS UpperLimit
FROM LatestNIFTYPUTQuotes
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike DESC;

-- =============================================
-- 3. SENSEX CALL OPTIONS (August 12th, 2025 - TODAY)
-- =============================================

PRINT '';
PRINT '=== SENSEX CALL OPTIONS (AUGUST 12TH, 2025 - TODAY) ===';

WITH LatestSENSEXCALLQuotes AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'SENSEX%' 
        AND CAST(mq.Expiry AS DATE) = '2025-08-12'
        AND i.InstrumentType = 'CE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS lowerLimit,
    UpperCircuitLimit AS UpperLimit
FROM LatestSENSEXCALLQuotes
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike ASC;

-- =============================================
-- 4. SENSEX PUT OPTIONS (August 12th, 2025 - TODAY)
-- =============================================

PRINT '';
PRINT '=== SENSEX PUT OPTIONS (AUGUST 12TH, 2025 - TODAY) ===';

WITH LatestSENSEXPUTQuotes AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'SENSEX%' 
        AND CAST(mq.Expiry AS DATE) = '2025-08-12'
        AND i.InstrumentType = 'PE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS lowerLimit,
    UpperCircuitLimit AS UpperLimit
FROM LatestSENSEXPUTQuotes
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike DESC;

-- =============================================
-- 5. SUMMARY STATISTICS
-- =============================================

PRINT '';
PRINT '=== SUMMARY STATISTICS ===';

SELECT 
    'NIFTY Aug 14' as IndexExpiry,
    'CALL' as OptionType,
    COUNT(*) as TotalOptions,
    COUNT(CASE WHEN OHLC_Open > 0 THEN 1 END) as ActiveOptions,
    MIN(i.Strike) as MinStrike,
    MAX(i.Strike) as MaxStrike,
    AVG(mq.LastPrice) as AvgLastPrice
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-14'
    AND i.InstrumentType = 'CE'
    AND mq.Expiry IS NOT NULL
GROUP BY 'NIFTY Aug 14', 'CALL'

UNION ALL

SELECT 
    'NIFTY Aug 14',
    'PUT',
    COUNT(*),
    COUNT(CASE WHEN OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-14'
    AND i.InstrumentType = 'PE'
    AND mq.Expiry IS NOT NULL
GROUP BY 'NIFTY Aug 14', 'PUT'

UNION ALL

SELECT 
    'SENSEX Aug 12',
    'CALL',
    COUNT(*),
    COUNT(CASE WHEN OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'SENSEX%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-12'
    AND i.InstrumentType = 'CE'
    AND mq.Expiry IS NOT NULL
GROUP BY 'SENSEX Aug 12', 'CALL'

UNION ALL

SELECT 
    'SENSEX Aug 12',
    'PUT',
    COUNT(*),
    COUNT(CASE WHEN OHLC_Open > 0 THEN 1 END),
    MIN(i.Strike),
    MAX(i.Strike),
    AVG(mq.LastPrice)
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'SENSEX%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-12'
    AND i.InstrumentType = 'PE'
    AND mq.Expiry IS NOT NULL
GROUP BY 'SENSEX Aug 12', 'PUT'

ORDER BY IndexExpiry, OptionType;

GO
