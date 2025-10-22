-- ================================================================================
-- TEST PATTERN DISCOVERY - Find ALL combinations that match target values
-- This demonstrates the automatic pattern discovery capability
-- ================================================================================

USE KiteMarketData;
GO

DECLARE @D0Date DATE = '2025-10-09';
DECLARE @IndexName NVARCHAR(50) = 'BANKNIFTY';
DECLARE @TargetValue DECIMAL(18,2) = 804.80; -- D1 56100 PE UC value

PRINT '================================================================================';
PRINT 'AUTOMATIC PATTERN DISCOVERY TEST';
PRINT '================================================================================';
PRINT '';
PRINT 'D0 Date: ' + CONVERT(VARCHAR, @D0Date, 120);
PRINT 'Index: ' + @IndexName;
PRINT 'Target Value: ' + CAST(@TargetValue AS VARCHAR(20));
PRINT '';
PRINT '================================================================================';
PRINT 'SEARCHING FOR PATTERNS...';
PRINT '================================================================================';
PRINT '';

-- Get all D0 labels
WITH AllLabels AS (
    SELECT 
        LabelName, 
        LabelValue
    FROM StrategyLabels
    WHERE BusinessDate = @D0Date 
      AND IndexName = @IndexName
),

-- Try all mathematical combinations
AllCombinations AS (
    -- Pattern 1: Single label (identity)
    SELECT 
        '1-LABEL: ' + LabelName AS PatternType,
        LabelName AS Formula,
        LabelValue AS CalculatedValue,
        ABS(LabelValue - @TargetValue) AS ErrorAbs,
        CASE 
            WHEN @TargetValue = 0 THEN 999.99
            ELSE (ABS(LabelValue - @TargetValue) / @TargetValue) * 100 
        END AS ErrorPct,
        1 AS Complexity
    FROM AllLabels
    
    UNION ALL
    
    -- Pattern 2: Label + Label
    SELECT 
        '2-LABEL-ADD: ' + L1.LabelName + ' + ' + L2.LabelName,
        L1.LabelName + ' + ' + L2.LabelName,
        L1.LabelValue + L2.LabelValue,
        ABS((L1.LabelValue + L2.LabelValue) - @TargetValue),
        (ABS((L1.LabelValue + L2.LabelValue) - @TargetValue) / @TargetValue) * 100,
        2
    FROM AllLabels L1
    CROSS JOIN AllLabels L2
    WHERE L1.LabelName < L2.LabelName
    
    UNION ALL
    
    -- Pattern 3: Label - Label
    SELECT 
        '2-LABEL-SUB: ' + L1.LabelName + ' - ' + L2.LabelName,
        L1.LabelName + ' - ' + L2.LabelName,
        L1.LabelValue - L2.LabelValue,
        ABS((L1.LabelValue - L2.LabelValue) - @TargetValue),
        (ABS((L1.LabelValue - L2.LabelValue) - @TargetValue) / @TargetValue) * 100,
        2
    FROM AllLabels L1
    CROSS JOIN AllLabels L2
    WHERE L1.LabelName <> L2.LabelName
    
    UNION ALL
    
    -- Pattern 4: ABS(Label)
    SELECT 
        '1-LABEL-ABS: ABS(' + LabelName + ')',
        'ABS(' + LabelName + ')',
        ABS(LabelValue),
        ABS(ABS(LabelValue) - @TargetValue),
        (ABS(ABS(LabelValue) - @TargetValue) / @TargetValue) * 100,
        1
    FROM AllLabels
    WHERE LabelValue < 0
    
    UNION ALL
    
    -- Pattern 5: Label / 2
    SELECT 
        '1-LABEL-DIV2: ' + LabelName + ' / 2',
        LabelName + ' / 2',
        LabelValue / 2,
        ABS((LabelValue / 2) - @TargetValue),
        (ABS((LabelValue / 2) - @TargetValue) / @TargetValue) * 100,
        1
    FROM AllLabels
    WHERE LabelValue <> 0
    
    UNION ALL
    
    -- Pattern 6: Label * 2
    SELECT 
        '1-LABEL-MUL2: ' + LabelName + ' * 2',
        LabelName + ' * 2',
        LabelValue * 2,
        ABS((LabelValue * 2) - @TargetValue),
        (ABS((LabelValue * 2) - @TargetValue) / @TargetValue) * 100,
        1
    FROM AllLabels
    WHERE LabelValue <> 0
)

-- Show top 30 best matches
SELECT TOP 30
    ROW_NUMBER() OVER (ORDER BY ErrorPct) AS Rank,
    PatternType,
    Formula,
    CAST(CalculatedValue AS DECIMAL(18,2)) AS CalculatedValue,
    @TargetValue AS TargetValue,
    CAST(ErrorAbs AS DECIMAL(18,2)) AS ErrorAbs,
    CAST(ErrorPct AS DECIMAL(18,4)) AS ErrorPct,
    Complexity,
    CASE 
        WHEN ErrorPct < 0.5 THEN '★★★★★ EXCELLENT'
        WHEN ErrorPct < 1.0 THEN '★★★★☆ VERY GOOD'
        WHEN ErrorPct < 2.0 THEN '★★★☆☆ GOOD'
        WHEN ErrorPct < 5.0 THEN '★★☆☆☆ FAIR'
        ELSE '★☆☆☆☆ POOR'
    END AS Rating
FROM AllCombinations
WHERE ErrorAbs <= (@TargetValue * 0.10) -- Within 10% tolerance
ORDER BY ErrorPct, Complexity;

PRINT '';
PRINT '================================================================================';
PRINT 'TOP PATTERNS SUMMARY';
PRINT '================================================================================';

-- Show summary statistics
SELECT TOP 10
    Formula,
    CAST(CalculatedValue AS DECIMAL(18,2)) AS Value,
    CAST(ErrorPct AS DECIMAL(18,4)) AS [Error%],
    CASE 
        WHEN ErrorPct < 0.5 THEN 'EXCELLENT ★★★★★'
        WHEN ErrorPct < 1.0 THEN 'VERY GOOD ★★★★☆'
        WHEN ErrorPct < 2.0 THEN 'GOOD ★★★☆☆'
        ELSE 'FAIR ★★☆☆☆'
    END AS Quality
FROM (
    SELECT 
        Formula,
        CalculatedValue,
        ErrorPct
    FROM (
        SELECT 
            L1.LabelName + ' + ' + L2.LabelName AS Formula,
            L1.LabelValue + L2.LabelValue AS CalculatedValue,
            (ABS((L1.LabelValue + L2.LabelValue) - @TargetValue) / @TargetValue) * 100 AS ErrorPct
        FROM (SELECT LabelName, LabelValue FROM StrategyLabels WHERE BusinessDate = @D0Date AND IndexName = @IndexName) L1
        CROSS JOIN (SELECT LabelName, LabelValue FROM StrategyLabels WHERE BusinessDate = @D0Date AND IndexName = @IndexName) L2
        WHERE L1.LabelName < L2.LabelName
        
        UNION ALL
        
        SELECT 
            L1.LabelName + ' - ' + L2.LabelName,
            L1.LabelValue - L2.LabelValue,
            (ABS((L1.LabelValue - L2.LabelValue) - @TargetValue) / @TargetValue) * 100
        FROM (SELECT LabelName, LabelValue FROM StrategyLabels WHERE BusinessDate = @D0Date AND IndexName = @IndexName) L1
        CROSS JOIN (SELECT LabelName, LabelValue FROM StrategyLabels WHERE BusinessDate = @D0Date AND IndexName = @IndexName) L2
        WHERE L1.LabelName <> L2.LabelName
    ) AllPatterns
) FilteredPatterns
ORDER BY ErrorPct;

PRINT '';
PRINT '✅ Pattern discovery complete!';
PRINT '================================================================================';

GO

