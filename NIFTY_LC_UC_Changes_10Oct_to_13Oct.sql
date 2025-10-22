-- ========================================================================
-- SQL Query to Show LC/UC Changes from Last Business Date to Current Business Date
-- From: 2025-10-10 (Last Record) to 2025-10-13 (Current Business Date)
-- For: NIFTY 25200 CE & PE Options
-- ========================================================================

-- Main Query: Show all changes with detailed information
WITH LastBusinessDateRecord AS (
    SELECT 
        i.TradingSymbol,
        i.Strike,
        i.InstrumentType,
        mq.UpperCircuitLimit as UC_LastBD,
        mq.LowerCircuitLimit as LC_LastBD,
        mq.RecordDateTime as LastBD_DateTime,
        mq.BusinessDate as LastBusinessDate,
        mq.InsertionSequence,
        ROW_NUMBER() OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.Strike = 25200
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'NIFTY%'
        AND mq.BusinessDate = '2025-10-10'  -- Last business date
),
CurrentBusinessDateRecord AS (
    SELECT 
        i.TradingSymbol,
        i.Strike,
        i.InstrumentType,
        mq.UpperCircuitLimit as UC_CurrentBD,
        mq.LowerCircuitLimit as LC_CurrentBD,
        mq.RecordDateTime as CurrentBD_DateTime,
        mq.BusinessDate as CurrentBusinessDate,
        mq.InsertionSequence,
        ROW_NUMBER() OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.Strike = 25200
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'NIFTY%'
        AND mq.BusinessDate = '2025-10-13'  -- Current business date
)
SELECT 
    COALESCE(l.TradingSymbol, c.TradingSymbol) as TradingSymbol,
    COALESCE(l.Strike, c.Strike) as Strike,
    COALESCE(l.InstrumentType, c.InstrumentType) as InstrumentType,
    
    -- Last Business Date (2025-10-10) Values
    l.UC_LastBD as UC_10Oct,
    l.LC_LastBD as LC_10Oct,
    l.InsertionSequence as [IS_10Oct],
    CONVERT(VARCHAR(19), l.LastBD_DateTime, 120) as LastBD_UpdateTime,
    
    -- Current Business Date (2025-10-13) Values
    c.UC_CurrentBD as UC_13Oct,
    c.LC_CurrentBD as LC_13Oct,
    c.InsertionSequence as [IS_13Oct],
    CONVERT(VARCHAR(19), c.CurrentBD_DateTime, 120) as CurrentBD_UpdateTime,
    
    -- Changes
    (c.UC_CurrentBD - l.UC_LastBD) as UC_Change,
    (c.LC_CurrentBD - l.LC_LastBD) as LC_Change,
    
    -- Change Percentage
    CASE 
        WHEN l.UC_LastBD > 0 THEN 
            CAST(((c.UC_CurrentBD - l.UC_LastBD) / l.UC_LastBD * 100) AS DECIMAL(10,2))
        ELSE NULL 
    END as UC_Change_Pct,
    
    CASE 
        WHEN l.LC_LastBD > 0.05 THEN 
            CAST(((c.LC_CurrentBD - l.LC_LastBD) / l.LC_LastBD * 100) AS DECIMAL(10,2))
        ELSE NULL 
    END as LC_Change_Pct,
    
    -- Change Status
    CASE 
        WHEN c.UC_CurrentBD IS NULL THEN 'NOT_TRADED_13OCT'
        WHEN l.UC_LastBD IS NULL THEN 'NEW_ON_13OCT'
        WHEN (c.UC_CurrentBD - l.UC_LastBD) > 0 THEN 'UC_INCREASED'
        WHEN (c.UC_CurrentBD - l.UC_LastBD) < 0 THEN 'UC_DECREASED'
        ELSE 'UC_UNCHANGED'
    END as UC_Status,
    
    CASE 
        WHEN c.LC_CurrentBD IS NULL THEN 'NOT_TRADED_13OCT'
        WHEN l.LC_LastBD IS NULL THEN 'NEW_ON_13OCT'
        WHEN (c.LC_CurrentBD - l.LC_LastBD) > 0 THEN 'LC_INCREASED'
        WHEN (c.LC_CurrentBD - l.LC_LastBD) < 0 THEN 'LC_DECREASED'
        ELSE 'LC_UNCHANGED'
    END as LC_Status
    
FROM LastBusinessDateRecord l
FULL OUTER JOIN CurrentBusinessDateRecord c 
    ON l.TradingSymbol = c.TradingSymbol 
    AND l.rn = 1 
    AND c.rn = 1
WHERE l.rn = 1 OR c.rn = 1
ORDER BY 
    COALESCE(l.InstrumentType, c.InstrumentType),
    COALESCE(l.TradingSymbol, c.TradingSymbol);


-- ========================================================================
-- Detailed Timeline: All LC/UC Changes for Each Option
-- Shows every update from 10-Oct-2025 to 13-Oct-2025
-- ========================================================================
SELECT '====== DETAILED TIMELINE: ALL UPDATES ======' as Info;

SELECT 
    i.TradingSymbol,
    i.Strike,
    i.InstrumentType,
    mq.BusinessDate,
    mq.UpperCircuitLimit as UC,
    mq.LowerCircuitLimit as LC,
    mq.InsertionSequence as [IS],
    CONVERT(VARCHAR(19), mq.RecordDateTime, 120) as UpdateDateTime,
    DATENAME(WEEKDAY, mq.BusinessDate) as DayOfWeek,
    
    -- Show changes from previous record
    LAG(mq.UpperCircuitLimit) OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime) as Prev_UC,
    LAG(mq.LowerCircuitLimit) OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime) as Prev_LC,
    
    (mq.UpperCircuitLimit - LAG(mq.UpperCircuitLimit) OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime)) as UC_Change_FromPrev,
    (mq.LowerCircuitLimit - LAG(mq.LowerCircuitLimit) OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime)) as LC_Change_FromPrev
    
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.Strike = 25200
    AND i.InstrumentType IN ('CE', 'PE')
    AND i.TradingSymbol LIKE 'NIFTY%'
    AND mq.BusinessDate IN ('2025-10-10', '2025-10-13')
ORDER BY 
    i.TradingSymbol,
    mq.RecordDateTime;


-- ========================================================================
-- Summary Statistics by Option Type (CE vs PE)
-- ========================================================================
SELECT '====== SUMMARY STATISTICS ======' as Info;

WITH LastBusinessDateRecord AS (
    SELECT 
        i.TradingSymbol,
        i.InstrumentType,
        mq.UpperCircuitLimit as UC_LastBD,
        mq.LowerCircuitLimit as LC_LastBD,
        ROW_NUMBER() OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.Strike = 25200
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'NIFTY%'
        AND mq.BusinessDate = '2025-10-10'
),
CurrentBusinessDateRecord AS (
    SELECT 
        i.TradingSymbol,
        i.InstrumentType,
        mq.UpperCircuitLimit as UC_CurrentBD,
        mq.LowerCircuitLimit as LC_CurrentBD,
        ROW_NUMBER() OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.Strike = 25200
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'NIFTY%'
        AND mq.BusinessDate = '2025-10-13'
)
SELECT 
    COALESCE(l.InstrumentType, c.InstrumentType) as OptionType,
    COUNT(*) as TotalOptions,
    SUM(CASE WHEN c.UC_CurrentBD > l.UC_LastBD THEN 1 ELSE 0 END) as UC_Increased,
    SUM(CASE WHEN c.UC_CurrentBD < l.UC_LastBD THEN 1 ELSE 0 END) as UC_Decreased,
    SUM(CASE WHEN c.UC_CurrentBD = l.UC_LastBD THEN 1 ELSE 0 END) as UC_Unchanged,
    SUM(CASE WHEN c.LC_CurrentBD > l.LC_LastBD THEN 1 ELSE 0 END) as LC_Increased,
    SUM(CASE WHEN c.LC_CurrentBD < l.LC_LastBD THEN 1 ELSE 0 END) as LC_Decreased,
    SUM(CASE WHEN c.LC_CurrentBD = l.LC_LastBD THEN 1 ELSE 0 END) as LC_Unchanged,
    SUM(CASE WHEN c.UC_CurrentBD IS NULL THEN 1 ELSE 0 END) as NotTraded_CurrentBD,
    CAST(AVG(c.UC_CurrentBD - l.UC_LastBD) AS DECIMAL(10,2)) as Avg_UC_Change,
    CAST(AVG(c.LC_CurrentBD - l.LC_LastBD) AS DECIMAL(10,2)) as Avg_LC_Change,
    CAST(MIN(c.UC_CurrentBD - l.UC_LastBD) AS DECIMAL(10,2)) as Min_UC_Change,
    CAST(MAX(c.UC_CurrentBD - l.UC_LastBD) AS DECIMAL(10,2)) as Max_UC_Change,
    CAST(MIN(c.LC_CurrentBD - l.LC_LastBD) AS DECIMAL(10,2)) as Min_LC_Change,
    CAST(MAX(c.LC_CurrentBD - l.LC_LastBD) AS DECIMAL(10,2)) as Max_LC_Change
FROM LastBusinessDateRecord l
FULL OUTER JOIN CurrentBusinessDateRecord c 
    ON l.TradingSymbol = c.TradingSymbol 
    AND l.rn = 1 
    AND c.rn = 1
WHERE l.rn = 1 OR c.rn = 1
GROUP BY COALESCE(l.InstrumentType, c.InstrumentType)
ORDER BY OptionType;


-- ========================================================================
-- Expiry-wise Breakdown
-- ========================================================================
SELECT '====== EXPIRY-WISE BREAKDOWN ======' as Info;

WITH LastBusinessDateRecord AS (
    SELECT 
        i.TradingSymbol,
        i.InstrumentType,
        i.Expiry,
        mq.UpperCircuitLimit as UC_LastBD,
        mq.LowerCircuitLimit as LC_LastBD,
        ROW_NUMBER() OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.Strike = 25200
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'NIFTY%'
        AND mq.BusinessDate = '2025-10-10'
),
CurrentBusinessDateRecord AS (
    SELECT 
        i.TradingSymbol,
        i.InstrumentType,
        i.Expiry,
        mq.UpperCircuitLimit as UC_CurrentBD,
        mq.LowerCircuitLimit as LC_CurrentBD,
        ROW_NUMBER() OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.Strike = 25200
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'NIFTY%'
        AND mq.BusinessDate = '2025-10-13'
)
SELECT 
    COALESCE(l.Expiry, c.Expiry) as Expiry,
    COALESCE(l.InstrumentType, c.InstrumentType) as OptionType,
    COUNT(*) as TotalOptions,
    CAST(AVG(c.UC_CurrentBD - l.UC_LastBD) AS DECIMAL(10,2)) as Avg_UC_Change,
    CAST(AVG(c.LC_CurrentBD - l.LC_LastBD) AS DECIMAL(10,2)) as Avg_LC_Change
FROM LastBusinessDateRecord l
FULL OUTER JOIN CurrentBusinessDateRecord c 
    ON l.TradingSymbol = c.TradingSymbol 
    AND l.rn = 1 
    AND c.rn = 1
WHERE l.rn = 1 OR c.rn = 1
GROUP BY COALESCE(l.Expiry, c.Expiry), COALESCE(l.InstrumentType, c.InstrumentType)
ORDER BY Expiry, OptionType;

