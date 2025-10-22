-- ================================================================================
-- BANKNIFTY LC/UC REPORT - 09 & 10 OCT 2025 (CONSOLIDATED FORMAT)
-- Shows: 9th Oct BASELINE vs 10th Oct FINAL VALUES
-- Format: Similar to Consolidated Excel Report
-- ================================================================================

-- ============== BANKNIFTY CALLS (CE) ==============
PRINT '========================================================================';
PRINT 'BANKNIFTY CALLS (CE) - LC/UC CHANGES (09-Oct Baseline vs 10-Oct Final)';
PRINT '========================================================================';
PRINT '';

WITH Baseline_09 AS (
    -- Last record from 9th Oct (max GlobalSequence per strike)
    SELECT 
        Strike,
        ExpiryDate,
        MAX(GlobalSequence) AS MaxGlobalSeq
    FROM MarketQuotes
    WHERE TradingSymbol LIKE 'BANKNIFTY%'
      AND OptionType = 'CE'
      AND BusinessDate = '2025-10-09'
    GROUP BY Strike, ExpiryDate
),
Final_10 AS (
    -- Last record from 10th Oct (max GlobalSequence per strike)
    SELECT 
        Strike,
        ExpiryDate,
        MAX(GlobalSequence) AS MaxGlobalSeq,
        COUNT(*) AS TotalChanges
    FROM MarketQuotes
    WHERE TradingSymbol LIKE 'BANKNIFTY%'
      AND OptionType = 'CE'
      AND BusinessDate = '2025-10-10'
    GROUP BY Strike, ExpiryDate
)
SELECT 
    b09.Strike,
    b09.ExpiryDate,
    
    -- 9th Oct BASELINE (Last record)
    m09.RecordDateTime AS Baseline_Time_09,
    m09.LowerCircuitLimit AS Baseline_LC_09,
    m09.UpperCircuitLimit AS Baseline_UC_09,
    
    -- 10th Oct FINAL (Last record)
    f10.TotalChanges AS Changes_10th,
    m10.RecordDateTime AS Final_Time_10,
    m10.LowerCircuitLimit AS Final_LC_10,
    m10.UpperCircuitLimit AS Final_UC_10,
    
    -- Change Analysis
    (m10.LowerCircuitLimit - m09.LowerCircuitLimit) AS LC_Change,
    (m10.UpperCircuitLimit - m09.UpperCircuitLimit) AS UC_Change

FROM Baseline_09 b09
INNER JOIN MarketQuotes m09 ON b09.Strike = m09.Strike 
                           AND b09.ExpiryDate = m09.ExpiryDate 
                           AND b09.MaxGlobalSeq = m09.GlobalSequence
                           AND m09.OptionType = 'CE'
                           AND m09.BusinessDate = '2025-10-09'
LEFT JOIN Final_10 f10 ON b09.Strike = f10.Strike AND b09.ExpiryDate = f10.ExpiryDate
LEFT JOIN MarketQuotes m10 ON f10.Strike = m10.Strike 
                          AND f10.ExpiryDate = m10.ExpiryDate 
                          AND f10.MaxGlobalSeq = m10.GlobalSequence
                          AND m10.OptionType = 'CE'
                          AND m10.BusinessDate = '2025-10-10'
ORDER BY b09.Strike, b09.ExpiryDate;

PRINT '';
PRINT '========================================================================';
PRINT 'BANKNIFTY PUTS (PE) - LC/UC CHANGES (09-Oct Baseline vs 10-Oct Final)';
PRINT '========================================================================';
PRINT '';

-- ============== BANKNIFTY PUTS (PE) ==============

WITH Baseline_09 AS (
    -- Last record from 9th Oct (max GlobalSequence per strike)
    SELECT 
        Strike,
        ExpiryDate,
        MAX(GlobalSequence) AS MaxGlobalSeq
    FROM MarketQuotes
    WHERE TradingSymbol LIKE 'BANKNIFTY%'
      AND OptionType = 'PE'
      AND BusinessDate = '2025-10-09'
    GROUP BY Strike, ExpiryDate
),
Final_10 AS (
    -- Last record from 10th Oct (max GlobalSequence per strike)
    SELECT 
        Strike,
        ExpiryDate,
        MAX(GlobalSequence) AS MaxGlobalSeq,
        COUNT(*) AS TotalChanges
    FROM MarketQuotes
    WHERE TradingSymbol LIKE 'BANKNIFTY%'
      AND OptionType = 'PE'
      AND BusinessDate = '2025-10-10'
    GROUP BY Strike, ExpiryDate
)
SELECT 
    b09.Strike,
    b09.ExpiryDate,
    
    -- 9th Oct BASELINE (Last record)
    m09.RecordDateTime AS Baseline_Time_09,
    m09.LowerCircuitLimit AS Baseline_LC_09,
    m09.UpperCircuitLimit AS Baseline_UC_09,
    
    -- 10th Oct FINAL (Last record)
    f10.TotalChanges AS Changes_10th,
    m10.RecordDateTime AS Final_Time_10,
    m10.LowerCircuitLimit AS Final_LC_10,
    m10.UpperCircuitLimit AS Final_UC_10,
    
    -- Change Analysis
    (m10.LowerCircuitLimit - m09.LowerCircuitLimit) AS LC_Change,
    (m10.UpperCircuitLimit - m09.UpperCircuitLimit) AS UC_Change

FROM Baseline_09 b09
INNER JOIN MarketQuotes m09 ON b09.Strike = m09.Strike 
                           AND b09.ExpiryDate = m09.ExpiryDate 
                           AND b09.MaxGlobalSeq = m09.GlobalSequence
                           AND m09.OptionType = 'PE'
                           AND m09.BusinessDate = '2025-10-09'
LEFT JOIN Final_10 f10 ON b09.Strike = f10.Strike AND b09.ExpiryDate = f10.ExpiryDate
LEFT JOIN MarketQuotes m10 ON f10.Strike = m10.Strike 
                          AND f10.ExpiryDate = m10.ExpiryDate 
                          AND f10.MaxGlobalSeq = m10.GlobalSequence
                          AND m10.OptionType = 'PE'
                          AND m10.BusinessDate = '2025-10-10'
ORDER BY b09.Strike, b09.ExpiryDate;

PRINT '';
PRINT '✅ Report Complete!';
PRINT '';
PRINT 'COLUMN DEFINITIONS:';
PRINT '  Baseline_*_09 = Last record from 9th Oct (max GlobalSequence)';
PRINT '  Final_*_10 = Last record from 10th Oct (max GlobalSequence)';
PRINT '  Changes_10th = Total LC/UC changes on 10th Oct';
PRINT '  *_Change = Difference from baseline to final value';

