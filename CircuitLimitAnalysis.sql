-- COMPREHENSIVE CIRCUIT LIMIT ANALYSIS
-- This script provides detailed analysis of circuit limit changes

USE KiteMarketData;
GO

-- =============================================
-- 1. OVERVIEW OF ALL CIRCUIT LIMIT CHANGES
-- =============================================

PRINT '=== OVERVIEW OF ALL CIRCUIT LIMIT CHANGES ===';

SELECT 
    UnderlyingSymbol,
    COUNT(*) AS TotalChanges,
    COUNT(CASE WHEN InstrumentsAffected = 1 THEN 1 END) AS IndividualChanges,
    COUNT(CASE WHEN InstrumentsAffected > 1 THEN 1 END) AS UnderlyingLevelChanges,
    MIN(ChangeTimestamp) AS FirstChange,
    MAX(ChangeTimestamp) AS LastChange
FROM CircuitLimitChanges 
WHERE ChangeDate >= CAST(DATEADD(day, -7, GETDATE()) AS DATE)
GROUP BY UnderlyingSymbol
ORDER BY TotalChanges DESC;

-- =============================================
-- 2. INDIVIDUAL INSTRUMENT CHANGES
-- =============================================

PRINT '';
PRINT '=== INDIVIDUAL INSTRUMENT CIRCUIT LIMIT CHANGES ===';

SELECT 
    UnderlyingSymbol,
    TriggeredByTradingSymbol,
    TriggeredByStrike,
    TriggeredByExpiry,
    TriggeredByInstrumentType,
    ChangeDate,
    ChangeTimestamp,
    CONCAT(OldLowerLimit, '/', OldUpperLimit) AS OldLimits,
    CONCAT(NewLowerLimit, '/', NewUpperLimit) AS NewLimits,
    SpotLastPrice,
    DATEDIFF(MINUTE, ChangeTimestamp, GETDATE()) AS MinutesSinceChange
FROM CircuitLimitChanges 
WHERE InstrumentsAffected = 1  -- Individual instrument changes
    AND ChangeDate >= CAST(DATEADD(day, -7, GETDATE()) AS DATE)
ORDER BY ChangeTimestamp DESC;

-- =============================================
-- 3. UNDERLYING-LEVEL CHANGES
-- =============================================

PRINT '';
PRINT '=== UNDERLYING-LEVEL CIRCUIT LIMIT CHANGES ===';

SELECT 
    UnderlyingSymbol,
    ChangeDate,
    ChangeTimestamp,
    CONCAT(OldLowerLimit, '/', OldUpperLimit) AS OldLimits,
    CONCAT(NewLowerLimit, '/', NewUpperLimit) AS NewLimits,
    InstrumentsAffected,
    TriggeredByTradingSymbol,
    TriggeredByStrike,
    TriggeredByExpiry,
    SpotLastPrice,
    DATEDIFF(MINUTE, ChangeTimestamp, GETDATE()) AS MinutesSinceChange
FROM CircuitLimitChanges 
WHERE InstrumentsAffected > 1  -- Underlying-level changes
    AND ChangeDate >= CAST(DATEADD(day, -7, GETDATE()) AS DATE)
ORDER BY ChangeTimestamp DESC;

-- =============================================
-- 4. CHANGES BY INSTRUMENT TYPE
-- =============================================

PRINT '';
PRINT '=== CHANGES BY INSTRUMENT TYPE ===';

SELECT 
    TriggeredByInstrumentType,
    COUNT(*) AS ChangeCount,
    COUNT(CASE WHEN InstrumentsAffected = 1 THEN 1 END) AS IndividualChanges,
    COUNT(CASE WHEN InstrumentsAffected > 1 THEN 1 END) AS UnderlyingChanges
FROM CircuitLimitChanges 
WHERE ChangeDate >= CAST(DATEADD(day, -7, GETDATE()) AS DATE)
    AND TriggeredByInstrumentType IS NOT NULL
GROUP BY TriggeredByInstrumentType
ORDER BY ChangeCount DESC;

-- =============================================
-- 5. CHANGES BY STRIKE RANGE
-- =============================================

PRINT '';
PRINT '=== CHANGES BY STRIKE RANGE ===';

SELECT 
    CASE 
        WHEN TriggeredByStrike < 10000 THEN 'Low Strike (<10K)'
        WHEN TriggeredByStrike < 20000 THEN 'Medium Strike (10K-20K)'
        WHEN TriggeredByStrike < 50000 THEN 'High Strike (20K-50K)'
        ELSE 'Very High Strike (>50K)'
    END AS StrikeRange,
    COUNT(*) AS ChangeCount
FROM CircuitLimitChanges 
WHERE ChangeDate >= CAST(DATEADD(day, -7, GETDATE()) AS DATE)
    AND TriggeredByStrike IS NOT NULL
GROUP BY 
    CASE 
        WHEN TriggeredByStrike < 10000 THEN 'Low Strike (<10K)'
        WHEN TriggeredByStrike < 20000 THEN 'Medium Strike (10K-20K)'
        WHEN TriggeredByStrike < 50000 THEN 'High Strike (20K-50K)'
        ELSE 'Very High Strike (>50K)'
    END
ORDER BY ChangeCount DESC;

-- =============================================
-- 6. SPOT/INDEX CORRELATION ANALYSIS
-- =============================================

PRINT '';
PRINT '=== SPOT/INDEX CORRELATION ANALYSIS ===';

SELECT 
    UnderlyingSymbol,
    COUNT(*) AS ChangeCount,
    AVG(SpotLastPrice) AS AvgSpotPrice,
    AVG(NewUpperLimit - NewLowerLimit) AS AvgCircuitRange,
    AVG((NewUpperLimit - NewLowerLimit) / SpotLastPrice * 100) AS AvgCircuitRangePercent
FROM CircuitLimitChanges 
WHERE ChangeDate >= CAST(DATEADD(day, -7, GETDATE()) AS DATE)
    AND SpotLastPrice IS NOT NULL
    AND SpotLastPrice > 0
GROUP BY UnderlyingSymbol
ORDER BY ChangeCount DESC;

-- =============================================
-- 7. RECENT ACTIVITY SUMMARY
-- =============================================

PRINT '';
PRINT '=== RECENT ACTIVITY SUMMARY ===';

SELECT 
    'Today' AS Period,
    COUNT(*) AS TotalChanges,
    COUNT(CASE WHEN InstrumentsAffected = 1 THEN 1 END) AS IndividualChanges,
    COUNT(CASE WHEN InstrumentsAffected > 1 THEN 1 END) AS UnderlyingChanges
FROM CircuitLimitChanges 
WHERE ChangeDate = CAST(GETDATE() AS DATE)

UNION ALL

SELECT 
    'Yesterday' AS Period,
    COUNT(*) AS TotalChanges,
    COUNT(CASE WHEN InstrumentsAffected = 1 THEN 1 END) AS IndividualChanges,
    COUNT(CASE WHEN InstrumentsAffected > 1 THEN 1 END) AS UnderlyingChanges
FROM CircuitLimitChanges 
WHERE ChangeDate = CAST(DATEADD(day, -1, GETDATE()) AS DATE)

UNION ALL

SELECT 
    'Last 7 Days' AS Period,
    COUNT(*) AS TotalChanges,
    COUNT(CASE WHEN InstrumentsAffected = 1 THEN 1 END) AS IndividualChanges,
    COUNT(CASE WHEN InstrumentsAffected > 1 THEN 1 END) AS UnderlyingChanges
FROM CircuitLimitChanges 
WHERE ChangeDate >= CAST(DATEADD(day, -7, GETDATE()) AS DATE);

PRINT '';
PRINT '=== ANALYSIS COMPLETED ==='; 