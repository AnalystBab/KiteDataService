-- ================================================================================
-- BANKNIFTY LC/UC REPORT - Clean Format (Like Consolidated Excel)
-- 9th Oct Baseline vs 10th Oct Final
-- Separate tables for Calls and Puts
-- ================================================================================

-- ============== BANKNIFTY CALLS (CE) ==============
PRINT '========================================================================';
PRINT 'BANKNIFTY CALLS (CE) - 09 Oct Baseline → 10 Oct Final';
PRINT '========================================================================';

SELECT 
    c.Strike,
    c.ExpiryDate,
    
    -- 9th Oct BASELINE (using InsertionSequence since GlobalSeq has issues)
    b.Baseline_LC AS [09-Oct_LC],
    b.Baseline_UC AS [09-Oct_UC],
    
    -- 10th Oct FINAL VALUES
    c.Changes_10th AS [10-Oct_Changes],
    c.Final_LC AS [10-Oct_LC],
    c.Final_UC AS [10-Oct_UC],
    
    -- Change from 9th to 10th
    (c.Final_LC - b.Baseline_LC) AS LC_Change,
    (c.Final_UC - b.Baseline_UC) AS UC_Change

FROM (
    -- 10th Oct: Get last record per strike (max InsertionSequence)
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
    -- 9th Oct: Get last record per strike (max InsertionSequence)
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
PRINT '========================================================================';
PRINT 'BANKNIFTY PUTS (PE) - 09 Oct Baseline → 10 Oct Final';
PRINT '========================================================================';

-- ============== BANKNIFTY PUTS (PE) ==============

SELECT 
    c.Strike,
    c.ExpiryDate,
    
    -- 9th Oct BASELINE
    b.Baseline_LC AS [09-Oct_LC],
    b.Baseline_UC AS [09-Oct_UC],
    
    -- 10th Oct FINAL VALUES
    c.Changes_10th AS [10-Oct_Changes],
    c.Final_LC AS [10-Oct_LC],
    c.Final_UC AS [10-Oct_UC],
    
    -- Change from 9th to 10th
    (c.Final_LC - b.Baseline_LC) AS LC_Change,
    (c.Final_UC - b.Baseline_UC) AS UC_Change

FROM (
    -- 10th Oct: Get last record per strike
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
    -- 9th Oct: Get last record per strike
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
PRINT '✅ Report Complete!';
PRINT 'Format: Baseline (09-Oct) → Final (10-Oct)';

