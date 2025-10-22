-- ========================================================================
-- SQL Query to Show LC/UC Changes from Last Business Date to Current Business Date
-- From: 2025-10-10 (Last Record) to 2025-10-13 (Current Business Date)
-- For: SENSEX 82500 CE & PE Options
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
        ROW_NUMBER() OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.Strike = 82500
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'SENSEX%'
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
        ROW_NUMBER() OVER (PARTITION BY i.TradingSymbol ORDER BY mq.RecordDateTime DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.Strike = 82500
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'SENSEX%'
        AND mq.BusinessDate = '2025-10-13'  -- Current business date
)
SELECT 
    COALESCE(l.TradingSymbol, c.TradingSymbol) as TradingSymbol,
    COALESCE(l.Strike, c.Strike) as Strike,
    COALESCE(l.InstrumentType, c.InstrumentType) as InstrumentType,
    
    -- Last Business Date (2025-10-10) Values
    l.UC_LastBD as UC_10Oct,
    l.LC_LastBD as LC_10Oct,
    CONVERT(VARCHAR(19), l.LastBD_DateTime, 120) as LastBD_UpdateTime,
    
    -- Current Business Date (2025-10-13) Values
    c.UC_CurrentBD as UC_13Oct,
    c.LC_CurrentBD as LC_13Oct,
    CONVERT(VARCHAR(19), c.CurrentBD_DateTime, 120) as CurrentBD_UpdateTime,
    
    -- Changes
    (c.UC_CurrentBD - l.UC_LastBD) as UC_Change,
    (c.LC_CurrentBD - l.LC_LastBD) as LC_Change,
    
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
-- Summary Statistics
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
    WHERE i.Strike = 82500
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'SENSEX%'
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
    WHERE i.Strike = 82500
        AND i.InstrumentType IN ('CE', 'PE')
        AND i.TradingSymbol LIKE 'SENSEX%'
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
    AVG(c.UC_CurrentBD - l.UC_LastBD) as Avg_UC_Change,
    AVG(c.LC_CurrentBD - l.LC_LastBD) as Avg_LC_Change
FROM LastBusinessDateRecord l
FULL OUTER JOIN CurrentBusinessDateRecord c 
    ON l.TradingSymbol = c.TradingSymbol 
    AND l.rn = 1 
    AND c.rn = 1
WHERE l.rn = 1 OR c.rn = 1
GROUP BY COALESCE(l.InstrumentType, c.InstrumentType)
ORDER BY OptionType;

