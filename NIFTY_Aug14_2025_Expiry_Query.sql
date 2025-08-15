-- NIFTY Options Expiring August 14th, 2025
-- Separate queries for CALL and PUT options
-- Includes OHLC, Lower/Upper Circuit Limits
-- DEDUPLICATED VERSIONS (Latest record only)

USE KiteMarketData;

-- =============================================
-- QUERY 1: CALL Options (CE) - Ascending Order by Strike - DEDUPLICATED
-- =============================================
WITH LatestCALLQuotes AS (
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
    'CALL' as OptionType,
    TradingSymbol,
    Strike,
    Expiry,
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
FROM LatestCALLQuotes
WHERE rn = 1
ORDER BY Strike ASC;

-- =============================================
-- QUERY 2: PUT Options (PE) - Descending Order by Strike - DEDUPLICATED
-- =============================================
WITH LatestPUTQuotes AS (
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
    'PUT' as OptionType,
    TradingSymbol,
    Strike,
    Expiry,
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
FROM LatestPUTQuotes
WHERE rn = 1
ORDER BY Strike DESC;

-- =============================================
-- QUERY 3: COMBINED VIEW - DEDUPLICATED
-- =============================================
WITH LatestQuotes AS (
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
        AND i.InstrumentType IN ('CE', 'PE')
        AND mq.Expiry IS NOT NULL
)
SELECT 
    CASE 
        WHEN InstrumentType = 'CE' THEN 'CALL'
        WHEN InstrumentType = 'PE' THEN 'PUT'
    END as OptionType,
    TradingSymbol,
    Strike,
    Expiry,
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
FROM LatestQuotes
WHERE rn = 1
ORDER BY 
    InstrumentType,
    CASE WHEN InstrumentType = 'CE' THEN Strike END ASC,
    CASE WHEN InstrumentType = 'PE' THEN Strike END DESC;

-- =============================================
-- ORIGINAL QUERIES (WITH DUPLICATES) - FOR REFERENCE
-- =============================================

-- =============================================
-- QUERY 1: CALL Options (CE) - Ascending Order by Strike
-- =============================================
SELECT 
    'CALL' as OptionType,
    mq.TradingSymbol,
    i.Strike,
    mq.Expiry,
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
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-14'
    AND i.InstrumentType = 'CE'
    AND mq.Expiry IS NOT NULL
ORDER BY i.Strike ASC;

-- =============================================
-- QUERY 2: PUT Options (PE) - Descending Order by Strike
-- =============================================
SELECT 
    'PUT' as OptionType,
    mq.TradingSymbol,
    i.Strike,
    mq.Expiry,
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
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-14'
    AND i.InstrumentType = 'PE'
    AND mq.Expiry IS NOT NULL
ORDER BY i.Strike DESC;

-- =============================================
-- QUERY 3: COMBINED VIEW
-- =============================================
SELECT 
    CASE 
        WHEN i.InstrumentType = 'CE' THEN 'CALL'
        WHEN i.InstrumentType = 'PE' THEN 'PUT'
    END as OptionType,
    mq.TradingSymbol,
    i.Strike,
    mq.Expiry,
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
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-14'
    AND i.InstrumentType IN ('CE', 'PE')
    AND mq.Expiry IS NOT NULL
ORDER BY 
    i.InstrumentType,
    CASE WHEN i.InstrumentType = 'CE' THEN i.Strike END ASC,
    CASE WHEN i.InstrumentType = 'PE' THEN i.Strike END DESC;

-- =============================================
-- DUPLICATE ANALYSIS QUERY
-- =============================================
SELECT 
    mq.TradingSymbol,
    i.InstrumentType,
    COUNT(*) as RecordCount,
    MIN(mq.QuoteTimestamp) as FirstQuote,
    MAX(mq.QuoteTimestamp) as LastQuote
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-14'
    AND i.InstrumentType IN ('CE', 'PE')
    AND mq.Expiry IS NOT NULL
GROUP BY mq.TradingSymbol, i.InstrumentType
ORDER BY RecordCount DESC, mq.TradingSymbol;
