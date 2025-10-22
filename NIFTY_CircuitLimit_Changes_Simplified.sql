-- NIFTY CIRCUIT LIMIT CHANGES - SIMPLIFIED VERSION
-- This query shows when circuit limits changed for NIFTY options
-- Focuses on the most reliable data source: CircuitLimitChanges table

USE KiteMarketData;
GO

-- =============================================
-- 1. TODAY'S CIRCUIT LIMIT CHANGES
-- =============================================

PRINT '=============================================';
PRINT 'NIFTY CIRCUIT LIMIT CHANGES - TODAY';
PRINT '=============================================';

SELECT 
    TradingDate,
    ChangeTime,
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    ChangeType,
    
    -- Previous vs New Values
    PreviousLC,
    NewLC,
    PreviousUC,
    NewUC,
    PreviousLastPrice,
    NewLastPrice,
    
    -- Change Summary
    CASE 
        WHEN ChangeType = 'LC_CHANGE' THEN CONCAT('LC: ', PreviousLC, ' → ', NewLC)
        WHEN ChangeType = 'UC_CHANGE' THEN CONCAT('UC: ', PreviousUC, ' → ', NewUC)
        WHEN ChangeType = 'BOTH_CHANGE' THEN CONCAT('LC: ', PreviousLC, ' → ', NewLC, ' | UC: ', PreviousUC, ' → ', NewUC)
        ELSE ChangeType
    END as ChangeSummary,
    
    -- Index Data at Change Time
    IndexLastPrice as NiftyLastPrice,
    
    -- Time Analysis
    FORMAT(ChangeTime, 'HH:mm:ss') as ChangeTimeFormatted,
    DATEPART(HOUR, ChangeTime) as ChangeHour,
    DATEPART(MINUTE, ChangeTime) as ChangeMinute,
    
    -- Market Session
    CASE 
        WHEN DATEPART(HOUR, ChangeTime) BETWEEN 9 AND 15 THEN 'MARKET_HOURS'
        WHEN DATEPART(HOUR, ChangeTime) BETWEEN 15 AND 16 THEN 'POST_MARKET'
        ELSE 'AFTER_HOURS'
    END as MarketSession

FROM CircuitLimitChanges
WHERE TradingSymbol LIKE 'NIFTY%'
    AND TradingDate = CAST(GETDATE() AS DATE)
ORDER BY ChangeTime DESC, Strike;

-- =============================================
-- 2. RECENT CIRCUIT LIMIT CHANGES (LAST 7 DAYS)
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'NIFTY CIRCUIT LIMIT CHANGES - LAST 7 DAYS';
PRINT '=============================================';

SELECT 
    TradingDate,
    ChangeTime,
    TradingSymbol,
    Strike,
    OptionType,
    ChangeType,
    
    -- Previous vs New Values
    PreviousLC,
    NewLC,
    PreviousUC,
    NewUC,
    
    -- Change Summary
    CASE 
        WHEN ChangeType = 'LC_CHANGE' THEN CONCAT('LC: ', PreviousLC, ' → ', NewLC)
        WHEN ChangeType = 'UC_CHANGE' THEN CONCAT('UC: ', PreviousUC, ' → ', NewUC)
        WHEN ChangeType = 'BOTH_CHANGE' THEN CONCAT('LC: ', PreviousLC, ' → ', NewLC, ' | UC: ', PreviousUC, ' → ', NewUC)
        ELSE ChangeType
    END as ChangeSummary,
    
    IndexLastPrice as NiftyLastPrice,
    FORMAT(ChangeTime, 'HH:mm:ss') as ChangeTimeFormatted

FROM CircuitLimitChanges
WHERE TradingSymbol LIKE 'NIFTY%'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE())
ORDER BY ChangeTime DESC, Strike;

-- =============================================
-- 3. CIRCUIT LIMIT CHANGES BY HOUR (PATTERN ANALYSIS)
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'NIFTY CIRCUIT LIMIT CHANGES BY HOUR';
PRINT '=============================================';

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
-- 4. SUMMARY BY DATE
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'NIFTY CIRCUIT LIMIT CHANGES SUMMARY BY DATE';
PRINT '=============================================';

SELECT 
    TradingDate,
    COUNT(*) as TotalChanges,
    COUNT(CASE WHEN ChangeType = 'LC_CHANGE' THEN 1 END) as LC_Changes,
    COUNT(CASE WHEN ChangeType = 'UC_CHANGE' THEN 1 END) as UC_Changes,
    COUNT(CASE WHEN ChangeType = 'BOTH_CHANGE' THEN 1 END) as Both_Changes,
    COUNT(DISTINCT TradingSymbol) as AffectedInstruments,
    MIN(ChangeTime) as FirstChange,
    MAX(ChangeTime) as LastChange
FROM CircuitLimitChanges
WHERE TradingSymbol LIKE 'NIFTY%'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY TradingDate
ORDER BY TradingDate DESC;

-- =============================================
-- 5. ALERT: CIRCUIT LIMITS CHANGED IN LAST 30 MINUTES
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'ALERT: NIFTY CIRCUIT LIMITS CHANGED IN LAST 30 MINUTES';
PRINT '=============================================';

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

-- =============================================
-- 6. CIRCUIT LIMIT CHANGES BY STRIKE RANGE
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'NIFTY CIRCUIT LIMIT CHANGES BY STRIKE RANGE';
PRINT '=============================================';

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
WHERE TradingSymbol LIKE 'NIFTY%'
    AND TradingDate >= DATEADD(DAY, -7, GETDATE())
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

GO

PRINT '=============================================';
PRINT 'NIFTY CIRCUIT LIMIT CHANGE TRACKING COMPLETE';
PRINT '=============================================';




