-- Circuit Limit Change Tracking - Query Examples and Test Queries
-- Use this file after running CircuitLimitTracking.sql

USE KiteMarketData;
GO

-- =============================================
-- 1. QUERY: GET TODAY'S CIRCUIT LIMIT CHANGES (Complete View)
-- =============================================
SELECT 
    TradingSymbol,
    Strike,
    InstrumentType,
    Expiry,
    ChangeType,
    
    -- Previous Day Values
    PreviousLC, PreviousUC,
    PreviousOHLC_Open, PreviousOHLC_High, PreviousOHLC_Low, PreviousOHLC_Close, PreviousLastPrice,
    
    -- Current Day Values
    NewLC, NewUC,
    NewOHLC_Open, NewOHLC_High, NewOHLC_Low, NewOHLC_Close, NewLastPrice,
    
    -- Change Details
    ChangeTime,
    IndexOHLC_Close as NiftyClose,
    IndexLastPrice as NiftyLastPrice
FROM CircuitLimitChanges
WHERE TradingDate = CAST(GETDATE() AS DATE)
ORDER BY ChangeTime DESC;

-- =============================================
-- 2. QUERY: COMPARE TODAY vs YESTERDAY EOD DATA (Strike-wise)
-- =============================================
SELECT 
    t.TradingSymbol,
    t.Strike,
    t.InstrumentType,
    t.Expiry,
    
    -- LC Comparison
    t.LowerCircuitLimit as TodayLC,
    y.LowerCircuitLimit as YesterdayLC,
    CASE 
        WHEN t.LowerCircuitLimit != y.LowerCircuitLimit THEN 'LC_CHANGED'
        ELSE 'NO_CHANGE'
    END as LC_ChangeStatus,
    
    -- UC Comparison
    t.UpperCircuitLimit as TodayUC,
    y.UpperCircuitLimit as YesterdayUC,
    CASE 
        WHEN t.UpperCircuitLimit != y.UpperCircuitLimit THEN 'UC_CHANGED'
        ELSE 'NO_CHANGE'
    END as UC_ChangeStatus,
    
    -- OHLC Comparison
    t.OHLC_Close as TodayClose,
    y.OHLC_Close as YesterdayClose,
    t.LastPrice as TodayLastPrice,
    y.LastPrice as YesterdayLastPrice
FROM EODMarketData t
LEFT JOIN EODMarketData y ON t.TradingSymbol = y.TradingSymbol 
    AND y.TradingDate = DATEADD(DAY, -1, t.TradingDate)
WHERE t.TradingDate = CAST(GETDATE() AS DATE)
    AND (t.LowerCircuitLimit != y.LowerCircuitLimit OR t.UpperCircuitLimit != y.UpperCircuitLimit)
ORDER BY t.Strike, t.TradingSymbol;

-- =============================================
-- 3. QUERY: NIFTY AUG 14 CALL OPTIONS WITH EOD COMPARISON (Your Format)
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
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS lowerLimit,
    UpperCircuitLimit AS UpperLimit,
    
    -- EOD comparison columns
    eod.LowerCircuitLimit as EOD_LC,
    eod.UpperCircuitLimit as EOD_UC,
    eod.OHLC_Close as EOD_Close,
    eod.LastPrice as EOD_LastPrice,
    
    CASE 
        WHEN eod.LowerCircuitLimit != LowerCircuitLimit THEN 'LC_CHANGED'
        WHEN eod.UpperCircuitLimit != UpperCircuitLimit THEN 'UC_CHANGED'
        ELSE 'NO_CHANGE'
    END as CircuitChange
FROM LatestCALLQuotes lq
LEFT JOIN EODMarketData eod ON lq.TradingSymbol = eod.TradingSymbol 
    AND eod.TradingDate = CAST(GETDATE() AS DATE)
WHERE lq.rn = 1
ORDER BY Strike ASC;

-- =============================================
-- 4. TEST QUERY: VERIFY EOD DATA STORAGE
-- =============================================
SELECT 
    TradingDate,
    COUNT(*) as InstrumentCount,
    MIN(QuoteTimestamp) as EarliestQuote,
    MAX(QuoteTimestamp) as LatestQuote
FROM EODMarketData
GROUP BY TradingDate
ORDER BY TradingDate DESC;

-- =============================================
-- 5. TEST QUERY: VERIFY CHANGE TRACKING
-- =============================================
SELECT 
    TradingDate,
    ChangeType,
    COUNT(*) as ChangeCount
FROM CircuitLimitChanges
GROUP BY TradingDate, ChangeType
ORDER BY TradingDate DESC, ChangeType;

-- =============================================
-- 6. AUTOMATION SCRIPT: DAILY EOD PROCESS
-- =============================================
-- Run this daily after market hours:
-- EXEC StoreEODData;           -- Store today's EOD data
-- EXEC DetectCircuitLimitChanges;  -- Compare with yesterday and detect changes

-- =============================================
-- 7. TEST: STORE TODAY'S EOD DATA
-- =============================================
-- EXEC StoreEODData;  -- Uncomment to test

-- =============================================
-- 8. TEST: DETECT CHANGES (will work after you have EOD data for yesterday)
-- =============================================
-- EXEC DetectCircuitLimitChanges;  -- Uncomment to test

-- =============================================
-- 9. QUERY: GET ALL INSTRUMENTS WITH CIRCUIT LIMITS
-- =============================================
SELECT 
    TradingSymbol,
    Strike,
    InstrumentType,
    Expiry,
    LowerCircuitLimit,
    UpperCircuitLimit,
    OHLC_Close,
    LastPrice,
    QuoteTimestamp
FROM EODMarketData
WHERE TradingDate = CAST(GETDATE() AS DATE)
ORDER BY TradingSymbol;

-- =============================================
-- 10. QUERY: CIRCUIT LIMIT CHANGES BY STRIKE RANGE
-- =============================================
SELECT 
    CASE 
        WHEN Strike < 22000 THEN 'Below 22000'
        WHEN Strike BETWEEN 22000 AND 23000 THEN '22000-23000'
        WHEN Strike BETWEEN 23000 AND 24000 THEN '23000-24000'
        WHEN Strike BETWEEN 24000 AND 25000 THEN '24000-25000'
        ELSE 'Above 25000'
    END as StrikeRange,
    COUNT(*) as ChangeCount,
    ChangeType
FROM CircuitLimitChanges
WHERE TradingDate = CAST(GETDATE() AS DATE)
GROUP BY 
    CASE 
        WHEN Strike < 22000 THEN 'Below 22000'
        WHEN Strike BETWEEN 22000 AND 23000 THEN '22000-23000'
        WHEN Strike BETWEEN 23000 AND 24000 THEN '23000-24000'
        WHEN Strike BETWEEN 24000 AND 25000 THEN '24000-25000'
        ELSE 'Above 25000'
    END,
    ChangeType
ORDER BY StrikeRange, ChangeType;
