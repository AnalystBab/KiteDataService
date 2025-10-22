-- NIFTY CIRCUIT LIMIT CHANGE TIME TRACKING
-- This query shows exactly when circuit limits changed for NIFTY options
-- Includes multiple data sources for comprehensive tracking

USE KiteMarketData;
GO

-- =============================================
-- 1. CIRCUIT LIMIT CHANGES FROM CircuitLimitChanges TABLE
-- =============================================

PRINT '=============================================';
PRINT 'NIFTY CIRCUIT LIMIT CHANGES - DETAILED TRACKING';
PRINT '=============================================';

PRINT '';
PRINT '=== 1. CIRCUIT LIMIT CHANGES (CircuitLimitChanges Table) ===';

SELECT 
    'CircuitLimitChanges' as DataSource,
    TradingDate,
    ChangeTime,
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    ChangeType,
    
    -- Previous Values
    PreviousLC,
    PreviousUC,
    PreviousLastPrice,
    
    -- New Values  
    NewLC,
    NewUC,
    NewLastPrice,
    
    -- Change Details
    CASE 
        WHEN ChangeType = 'LC_CHANGE' THEN CONCAT('LC: ', PreviousLC, ' → ', NewLC)
        WHEN ChangeType = 'UC_CHANGE' THEN CONCAT('UC: ', PreviousUC, ' → ', NewUC)
        WHEN ChangeType = 'BOTH_CHANGE' THEN CONCAT('LC: ', PreviousLC, ' → ', NewLC, ' | UC: ', PreviousUC, ' → ', NewUC)
        ELSE ChangeType
    END as ChangeSummary,
    
    -- Index Data at Change Time
    IndexLastPrice as NiftyLastPrice,
    
    -- Time Analysis
    DATEPART(HOUR, ChangeTime) as ChangeHour,
    DATEPART(MINUTE, ChangeTime) as ChangeMinute,
    FORMAT(ChangeTime, 'HH:mm:ss') as ChangeTimeFormatted,
    
    -- Market Session
    CASE 
        WHEN DATEPART(HOUR, ChangeTime) BETWEEN 9 AND 15 THEN 'MARKET_HOURS'
        WHEN DATEPART(HOUR, ChangeTime) BETWEEN 15 AND 16 THEN 'POST_MARKET'
        ELSE 'AFTER_HOURS'
    END as MarketSession

FROM CircuitLimitChanges
WHERE TradingSymbol LIKE 'NIFTY%'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE()) -- Last 7 days
ORDER BY ChangeTime DESC, Strike;

-- =============================================
-- 2. CIRCUIT LIMIT CHANGES FROM CircuitLimitChangeHistory TABLE
-- =============================================

PRINT '';
PRINT '=== 2. CIRCUIT LIMIT CHANGES (CircuitLimitChangeHistory Table) ===';

SELECT 
    'CircuitLimitChangeHistory' as DataSource,
    TradingDate,
    CAST(TradedTime AS DATETIME) as ChangeTime,
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    
    -- Circuit Limits
    LowerCircuit as CurrentLC,
    UpperCircuit as CurrentUC,
    
    -- OHLC Data
    [Open],
    [High],
    [Low],
    [Close],
    LastTradedPrice,
    
    -- Market Hour Flag
    MarketHourFlag,
    
    -- Spot Data at Change Time
    SpotLastPrice as NiftyLastPrice,
    
    -- Time Analysis
    DATEPART(HOUR, TradedTime) as ChangeHour,
    DATEPART(MINUTE, TradedTime) as ChangeMinute,
    FORMAT(TradedTime, 'HH:mm:ss') as ChangeTimeFormatted,
    
    ChangeTimestamp

FROM CircuitLimitChangeHistory
WHERE IndexName = 'NIFTY'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE()) -- Last 7 days
ORDER BY ChangeTime DESC, Strike;

-- =============================================
-- 3. DAILY SNAPSHOTS WITH CIRCUIT LIMIT CHANGES
-- =============================================

PRINT '';
PRINT '=== 3. DAILY SNAPSHOTS (DailyMarketSnapshots Table) ===';

SELECT 
    'DailyMarketSnapshots' as DataSource,
    TradingDate,
    SnapshotTime as ChangeTime,
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    
    -- Circuit Limits
    LowerCircuitLimit as CurrentLC,
    UpperCircuitLimit as CurrentUC,
    
    -- OHLC Data
    OpenPrice,
    HighPrice,
    LowPrice,
    ClosePrice,
    LastPrice,
    
    -- Snapshot Type
    SnapshotType,
    
    -- Time Analysis
    DATEPART(HOUR, SnapshotTime) as ChangeHour,
    DATEPART(MINUTE, SnapshotTime) as ChangeMinute,
    FORMAT(SnapshotTime, 'HH:mm:ss') as ChangeTimeFormatted

FROM DailyMarketSnapshots
WHERE TradingSymbol LIKE 'NIFTY%'
    AND SnapshotType = 'LC_UC_CHANGE'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE()) -- Last 7 days
ORDER BY SnapshotTime DESC, Strike;

-- =============================================
-- 4. COMPREHENSIVE CIRCUIT LIMIT CHANGE SUMMARY
-- =============================================

PRINT '';
PRINT '=== 4. CIRCUIT LIMIT CHANGE SUMMARY BY DATE AND TIME ===';

-- Summary from CircuitLimitChanges
SELECT 
    'CircuitLimitChanges' as DataSource,
    TradingDate,
    COUNT(*) as TotalChanges,
    COUNT(CASE WHEN ChangeType = 'LC_CHANGE' THEN 1 END) as LC_Changes,
    COUNT(CASE WHEN ChangeType = 'UC_CHANGE' THEN 1 END) as UC_Changes,
    COUNT(CASE WHEN ChangeType = 'BOTH_CHANGE' THEN 1 END) as Both_Changes,
    MIN(ChangeTime) as FirstChange,
    MAX(ChangeTime) as LastChange,
    COUNT(DISTINCT TradingSymbol) as AffectedInstruments
FROM CircuitLimitChanges
WHERE TradingSymbol LIKE 'NIFTY%'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY TradingDate

UNION ALL

-- Summary from CircuitLimitChangeHistory
SELECT 
    'CircuitLimitChangeHistory' as DataSource,
    TradingDate,
    COUNT(*) as TotalChanges,
    0 as LC_Changes,
    0 as UC_Changes,
    0 as Both_Changes,
    MIN(CAST(TradedTime AS DATETIME)) as FirstChange,
    MAX(CAST(TradedTime AS DATETIME)) as LastChange,
    COUNT(DISTINCT TradingSymbol) as AffectedInstruments
FROM CircuitLimitChangeHistory
WHERE IndexName = 'NIFTY'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY TradingDate

UNION ALL

-- Summary from DailyMarketSnapshots
SELECT 
    'DailyMarketSnapshots' as DataSource,
    TradingDate,
    COUNT(*) as TotalChanges,
    0 as LC_Changes,
    0 as UC_Changes,
    0 as Both_Changes,
    MIN(SnapshotTime) as FirstChange,
    MAX(SnapshotTime) as LastChange,
    COUNT(DISTINCT TradingSymbol) as AffectedInstruments
FROM DailyMarketSnapshots
WHERE TradingSymbol LIKE 'NIFTY%'
    AND SnapshotType = 'LC_UC_CHANGE'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY TradingDate

ORDER BY TradingDate DESC, DataSource;

-- =============================================
-- 5. TODAY'S CIRCUIT LIMIT CHANGES (REALTIME)
-- =============================================

PRINT '';
PRINT '=== 5. TODAY''S NIFTY CIRCUIT LIMIT CHANGES ===';

SELECT 
    'TODAY' as Period,
    TradingDate,
    ChangeTime,
    TradingSymbol,
    Strike,
    OptionType,
    ChangeType,
    PreviousLC,
    NewLC,
    PreviousUC,
    NewUC,
    IndexLastPrice as NiftyLastPrice,
    FORMAT(ChangeTime, 'HH:mm:ss') as ChangeTimeFormatted
FROM CircuitLimitChanges
WHERE TradingSymbol LIKE 'NIFTY%'
    AND TradingDate = CAST(GETDATE() AS DATE)
ORDER BY ChangeTime DESC, Strike;

-- =============================================
-- 6. CIRCUIT LIMIT CHANGES BY HOUR (PATTERN ANALYSIS)
-- =============================================

PRINT '';
PRINT '=== 6. CIRCUIT LIMIT CHANGES BY HOUR (PATTERN ANALYSIS) ===';

SELECT 
    DATEPART(HOUR, ChangeTime) as HourOfDay,
    COUNT(*) as ChangeCount,
    COUNT(DISTINCT TradingSymbol) as AffectedInstruments,
    COUNT(CASE WHEN ChangeType = 'LC_CHANGE' THEN 1 END) as LC_Changes,
    COUNT(CASE WHEN ChangeType = 'UC_CHANGE' THEN 1 END) as UC_Changes,
    COUNT(CASE WHEN ChangeType = 'BOTH_CHANGE' THEN 1 END) as Both_Changes,
    MIN(ChangeTime) as FirstChange,
    MAX(ChangeTime) as LastChange
FROM CircuitLimitChanges
WHERE TradingSymbol LIKE 'NIFTY%'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY DATEPART(HOUR, ChangeTime)
ORDER BY HourOfDay;

-- =============================================
-- 7. RECENT CIRCUIT LIMIT CHANGES WITH MARKET DATA
-- =============================================

PRINT '';
PRINT '=== 7. RECENT CIRCUIT LIMIT CHANGES WITH CURRENT MARKET DATA ===';

WITH LatestQuotes AS (
    SELECT 
        mq.*,
        i.Expiry,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE mq.TradingSymbol LIKE 'NIFTY%'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    clc.TradingDate,
    clc.ChangeTime,
    clc.TradingSymbol,
    clc.Strike,
    clc.OptionType,
    clc.ChangeType,
    
    -- Previous vs New Circuit Limits
    clc.PreviousLC,
    clc.NewLC,
    clc.PreviousUC,
    clc.NewUC,
    
    -- Current Market Data
    lq.LowerCircuitLimit as CurrentLC,
    lq.UpperCircuitLimit as CurrentUC,
    lq.LastPrice as CurrentLastPrice,
    lq.OHLC_Close as CurrentClose,
    
    -- Time Analysis
    FORMAT(clc.ChangeTime, 'HH:mm:ss') as ChangeTimeFormatted,
    DATEDIFF(MINUTE, clc.ChangeTime, GETDATE()) as MinutesAgo

FROM CircuitLimitChanges clc
LEFT JOIN LatestQuotes lq ON clc.TradingSymbol = lq.TradingSymbol AND lq.rn = 1
WHERE clc.TradingSymbol LIKE 'NIFTY%'
    AND clc.TradingDate >= DATEADD(DAY, -3, GETDATE()) -- Last 3 days
ORDER BY clc.ChangeTime DESC, clc.Strike;

-- =============================================
-- 8. ALERT QUERY: CIRCUIT LIMITS CHANGED IN LAST 30 MINUTES
-- =============================================

PRINT '';
PRINT '=== 8. ALERT: CIRCUIT LIMITS CHANGED IN LAST 30 MINUTES ===';

SELECT 
    'ALERT' as Status,
    TradingDate,
    ChangeTime,
    TradingSymbol,
    Strike,
    OptionType,
    ChangeType,
    PreviousLC,
    NewLC,
    PreviousUC,
    NewUC,
    IndexLastPrice as NiftyLastPrice,
    FORMAT(ChangeTime, 'HH:mm:ss') as ChangeTimeFormatted,
    DATEDIFF(MINUTE, ChangeTime, GETDATE()) as MinutesAgo
FROM CircuitLimitChanges
WHERE TradingSymbol LIKE 'NIFTY%'
    AND ChangeTime >= DATEADD(MINUTE, -30, GETDATE())
ORDER BY ChangeTime DESC;

GO

PRINT '=============================================';
PRINT 'NIFTY CIRCUIT LIMIT CHANGE TRACKING COMPLETE';
PRINT '=============================================';
