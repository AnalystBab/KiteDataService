-- ================================================================================
-- BANKNIFTY LC/UC REPORT - CLEAR FORMAT
-- 09-Oct Baseline → 10-Oct Final
-- ================================================================================

PRINT '';
PRINT '╔════════════════════════════════════════════════════════════════════════╗';
PRINT '║                    BANKNIFTY CALLS (CE)                                ║';
PRINT '║              09-Oct Baseline → 10-Oct Final Values                     ║';
PRINT '╚════════════════════════════════════════════════════════════════════════╝';
PRINT '';

SELECT 
    c.Strike AS Strike,
    CONVERT(VARCHAR(10), c.ExpiryDate, 105) AS Expiry,
    
    -- ===== 09-OCT BASELINE (Last record) =====
    ISNULL(b.Baseline_LC, 0) AS [09_Oct_LC],
    ISNULL(b.Baseline_UC, 0) AS [09_Oct_UC],
    
    -- ===== 10-OCT FINAL (Last record) =====
    c.Changes_10th AS [10_Changes],
    c.Final_LC AS [10_Oct_LC],
    c.Final_UC AS [10_Oct_UC],
    
    -- ===== CHANGE ANALYSIS =====
    (c.Final_LC - ISNULL(b.Baseline_LC, 0)) AS [LC_Change],
    (c.Final_UC - ISNULL(b.Baseline_UC, 0)) AS [UC_Change]

FROM (
    -- 10th Oct FINAL values (last record per strike)
    SELECT 
        Strike,
        ExpiryDate,
        COUNT(*) AS Changes_10th,
        MAX(LowerCircuitLimit) AS Final_LC,
        MAX(UpperCircuitLimit) AS Final_UC
    FROM (
        SELECT 
            Strike,
            ExpiryDate,
            LowerCircuitLimit,
            UpperCircuitLimit,
            ROW_NUMBER() OVER (PARTITION BY Strike, ExpiryDate ORDER BY InsertionSequence DESC, RecordDateTime DESC) AS rn
        FROM MarketQuotes
        WHERE TradingSymbol LIKE 'BANKNIFTY%'
          AND OptionType = 'CE'
          AND BusinessDate = '2025-10-10'
    ) ranked
    WHERE rn = 1
    GROUP BY Strike, ExpiryDate
) c
LEFT JOIN (
    -- 9th Oct BASELINE (last record per strike)
    SELECT 
        Strike,
        ExpiryDate,
        LowerCircuitLimit AS Baseline_LC,
        UpperCircuitLimit AS Baseline_UC
    FROM (
        SELECT 
            Strike,
            ExpiryDate,
            LowerCircuitLimit,
            UpperCircuitLimit,
            ROW_NUMBER() OVER (PARTITION BY Strike, ExpiryDate ORDER BY InsertionSequence DESC, RecordDateTime DESC) AS rn
        FROM MarketQuotes
        WHERE TradingSymbol LIKE 'BANKNIFTY%'
          AND OptionType = 'CE'
          AND BusinessDate = '2025-10-09'
    ) ranked
    WHERE rn = 1
) b ON c.Strike = b.Strike AND c.ExpiryDate = b.ExpiryDate
ORDER BY c.Strike, c.ExpiryDate;

PRINT '';
PRINT '';
PRINT '╔════════════════════════════════════════════════════════════════════════╗';
PRINT '║                    BANKNIFTY PUTS (PE)                                 ║';
PRINT '║              09-Oct Baseline → 10-Oct Final Values                     ║';
PRINT '╚════════════════════════════════════════════════════════════════════════╝';
PRINT '';

SELECT 
    c.Strike AS Strike,
    CONVERT(VARCHAR(10), c.ExpiryDate, 105) AS Expiry,
    
    -- ===== 09-OCT BASELINE (Last record) =====
    ISNULL(b.Baseline_LC, 0) AS [09_Oct_LC],
    ISNULL(b.Baseline_UC, 0) AS [09_Oct_UC],
    
    -- ===== 10-OCT FINAL (Last record) =====
    c.Changes_10th AS [10_Changes],
    c.Final_LC AS [10_Oct_LC],
    c.Final_UC AS [10_Oct_UC],
    
    -- ===== CHANGE ANALYSIS =====
    (c.Final_LC - ISNULL(b.Baseline_LC, 0)) AS [LC_Change],
    (c.Final_UC - ISNULL(b.Baseline_UC, 0)) AS [UC_Change]

FROM (
    -- 10th Oct FINAL values (last record per strike)
    SELECT 
        Strike,
        ExpiryDate,
        COUNT(*) AS Changes_10th,
        MAX(LowerCircuitLimit) AS Final_LC,
        MAX(UpperCircuitLimit) AS Final_UC
    FROM (
        SELECT 
            Strike,
            ExpiryDate,
            LowerCircuitLimit,
            UpperCircuitLimit,
            ROW_NUMBER() OVER (PARTITION BY Strike, ExpiryDate ORDER BY InsertionSequence DESC, RecordDateTime DESC) AS rn
        FROM MarketQuotes
        WHERE TradingSymbol LIKE 'BANKNIFTY%'
          AND OptionType = 'PE'
          AND BusinessDate = '2025-10-10'
    ) ranked
    WHERE rn = 1
    GROUP BY Strike, ExpiryDate
) c
LEFT JOIN (
    -- 9th Oct BASELINE (last record per strike)
    SELECT 
        Strike,
        ExpiryDate,
        LowerCircuitLimit AS Baseline_LC,
        UpperCircuitLimit AS Baseline_UC
    FROM (
        SELECT 
            Strike,
            ExpiryDate,
            LowerCircuitLimit,
            UpperCircuitLimit,
            ROW_NUMBER() OVER (PARTITION BY Strike, ExpiryDate ORDER BY InsertionSequence DESC, RecordDateTime DESC) AS rn
        FROM MarketQuotes
        WHERE TradingSymbol LIKE 'BANKNIFTY%'
          AND OptionType = 'PE'
          AND BusinessDate = '2025-10-09'
    ) ranked
    WHERE rn = 1
) b ON c.Strike = b.Strike AND c.ExpiryDate = b.ExpiryDate
ORDER BY c.Strike, c.ExpiryDate;

PRINT '';
PRINT '╔════════════════════════════════════════════════════════════════════════╗';
PRINT '║                         LEGEND                                         ║';
PRINT '╚════════════════════════════════════════════════════════════════════════╝';
PRINT 'CALLS (CE) = Above table shows Call options';
PRINT 'PUTS (PE) = Below table shows Put options';
PRINT '';
PRINT 'COLUMNS:';
PRINT '  Strike       = Strike price';
PRINT '  Expiry       = Expiry date';
PRINT '  09_Oct_LC/UC = Baseline from 9th Oct (last record)';
PRINT '  10_Changes   = Number of records on 10th Oct';
PRINT '  10_Oct_LC/UC = Final values on 10th Oct (last record)';
PRINT '  LC_Change    = Difference in Lower Circuit (10th - 9th)';
PRINT '  UC_Change    = Difference in Upper Circuit (10th - 9th)';
PRINT '';
PRINT '✅ Report Complete!';

