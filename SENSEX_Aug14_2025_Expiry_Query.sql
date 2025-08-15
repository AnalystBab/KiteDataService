-- SENSEX OPTIONS QUERIES FOR AUGUST 12TH, 2025 EXPIRY (TODAY'S EXPIRY)
-- Similar to NIFTY query but for SENSEX options expiring today

USE KiteMarketData;
GO

-- =============================================
-- 1. SENSEX CALL OPTIONS (Ascending Order by Strike)
-- =============================================

PRINT '=== SENSEX CALL OPTIONS (AUGUST 12TH, 2025 - TODAY) ===';

WITH LatestCALLQuotes AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'SENSEX25812%' 
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
FROM LatestCALLQuotes
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike ASC;

-- =============================================
-- 2. SENSEX PUT OPTIONS (Descending Order by Strike)
-- =============================================

PRINT '';
PRINT '=== SENSEX PUT OPTIONS (AUGUST 12TH, 2025 - TODAY) ===';

WITH LatestPUTQuotes AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'SENSEX25812%' 
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
FROM LatestPUTQuotes
WHERE rn = 1 AND OHLC_Open > 0
ORDER BY Strike DESC;

-- =============================================
-- 3. SENSEX OPTIONS SUMMARY
-- =============================================

PRINT '';
PRINT '=== SENSEX OPTIONS SUMMARY ===';

SELECT 
    i.InstrumentType,
    COUNT(*) as TotalOptions,
    COUNT(CASE WHEN mq.OHLC_Open > 0 THEN 1 END) as ActiveOptions,
    MIN(i.Strike) as MinStrike,
    MAX(i.Strike) as MaxStrike,
    AVG(mq.LastPrice) as AvgLastPrice
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'SENSEX25812%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-12'
    AND i.InstrumentType IN ('CE', 'PE')
    AND mq.Expiry IS NOT NULL
GROUP BY i.InstrumentType
ORDER BY i.InstrumentType;

-- =============================================
-- 4. SENSEX SPOT DATA (for reference)
-- =============================================

PRINT '';
PRINT '=== SENSEX SPOT DATA ===';

SELECT 
    TradingSymbol,
    OHLC_Open,
    OHLC_High,
    OHLC_Low,
    OHLC_Close,
    LastPrice,
    LowerCircuitLimit,
    UpperCircuitLimit,
    QuoteTimestamp
FROM MarketQuotes 
WHERE TradingSymbol = 'SENSEX'
ORDER BY QuoteTimestamp DESC;

GO
