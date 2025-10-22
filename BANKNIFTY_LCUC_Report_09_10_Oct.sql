-- ================================================================================
-- BANKNIFTY LC/UC CHANGES REPORT - 09 & 10 OCT 2025
-- Similar to Consolidated Excel Report Format
-- Shows: 9th Oct BASELINE (max sequence) vs 10th Oct CHANGES
-- ================================================================================

-- ============== BANKNIFTY CALLS (CE) ==============
PRINT '========================================';
PRINT 'BANKNIFTY CALLS (CE) - LC/UC CHANGES';
PRINT '========================================';
PRINT '';

SELECT 
    c.Strike,
    c.ExpiryDate,
    
    -- 9th Oct BASELINE (Last record of BusinessDate 2025-10-09)
    b.RecordDateTime AS Baseline_Time,
    b.GlobalSequence AS Baseline_GlobalSeq,
    b.LowerCircuitLimit AS Baseline_LC,
    b.UpperCircuitLimit AS Baseline_UC,
    
    -- 10th Oct CHANGES (All changes from BusinessDate 2025-10-10)
    c.TotalChanges_10th,
    c.First_LC_10th,
    c.First_UC_10th,
    c.Last_LC_10th,
    c.Last_UC_10th,
    c.LastRecordTime_10th,
    c.MaxGlobalSeq_10th,
    
    -- LC/UC Change Analysis
    (c.Last_LC_10th - b.LowerCircuitLimit) AS LC_Change,
    (c.Last_UC_10th - b.UpperCircuitLimit) AS UC_Change,
    CASE 
        WHEN b.LowerCircuitLimit > 0 THEN 
            CAST((c.Last_LC_10th - b.LowerCircuitLimit) * 100.0 / b.LowerCircuitLimit AS DECIMAL(10,2))
        ELSE 0 
    END AS LC_Change_Percent

FROM (
    -- Get 10th Oct data
    SELECT 
        Strike,
        ExpiryDate,
        COUNT(*) AS TotalChanges_10th,
        MIN(GlobalSequence) AS MinGlobalSeq_10th,
        MAX(GlobalSequence) AS MaxGlobalSeq_10th,
        (SELECT LowerCircuitLimit FROM MarketQuotes m2 
         WHERE m2.Strike = m1.Strike 
           AND m2.ExpiryDate = m1.ExpiryDate 
           AND m2.OptionType = m1.OptionType
           AND m2.BusinessDate = '2025-10-10'
           AND m2.GlobalSequence = (SELECT MIN(GlobalSequence) FROM MarketQuotes m3 
                                    WHERE m3.Strike = m1.Strike 
                                      AND m3.ExpiryDate = m1.ExpiryDate 
                                      AND m3.OptionType = m1.OptionType
                                      AND m3.BusinessDate = '2025-10-10')
        ) AS First_LC_10th,
        (SELECT UpperCircuitLimit FROM MarketQuotes m2 
         WHERE m2.Strike = m1.Strike 
           AND m2.ExpiryDate = m1.ExpiryDate 
           AND m2.OptionType = m1.OptionType
           AND m2.BusinessDate = '2025-10-10'
           AND m2.GlobalSequence = (SELECT MIN(GlobalSequence) FROM MarketQuotes m3 
                                    WHERE m3.Strike = m1.Strike 
                                      AND m3.ExpiryDate = m1.ExpiryDate 
                                      AND m3.OptionType = m1.OptionType
                                      AND m3.BusinessDate = '2025-10-10')
        ) AS First_UC_10th,
        MAX(LowerCircuitLimit) AS Last_LC_10th,
        MAX(UpperCircuitLimit) AS Last_UC_10th,
        MAX(RecordDateTime) AS LastRecordTime_10th
    FROM MarketQuotes m1
    WHERE TradingSymbol LIKE 'BANKNIFTY%'
      AND OptionType = 'CE'
      AND BusinessDate = '2025-10-10'
    GROUP BY Strike, ExpiryDate, OptionType
) c
LEFT JOIN (
    -- Get 9th Oct BASELINE (last record)
    SELECT 
        Strike,
        ExpiryDate,
        LowerCircuitLimit,
        UpperCircuitLimit,
        RecordDateTime,
        GlobalSequence
    FROM MarketQuotes m1
    WHERE TradingSymbol LIKE 'BANKNIFTY%'
      AND OptionType = 'CE'
      AND BusinessDate = '2025-10-09'
      AND GlobalSequence = (
          SELECT MAX(GlobalSequence) 
          FROM MarketQuotes m2 
          WHERE m2.Strike = m1.Strike 
            AND m2.ExpiryDate = m1.ExpiryDate
            AND m2.OptionType = m1.OptionType
            AND m2.BusinessDate = '2025-10-09'
      )
) b ON c.Strike = b.Strike AND c.ExpiryDate = b.ExpiryDate
ORDER BY c.Strike, c.ExpiryDate;

PRINT '';
PRINT '========================================';
PRINT 'BANKNIFTY PUTS (PE) - LC/UC CHANGES';
PRINT '========================================';
PRINT '';

-- ============== BANKNIFTY PUTS (PE) ==============

SELECT 
    c.Strike,
    c.ExpiryDate,
    
    -- 9th Oct BASELINE (Last record of BusinessDate 2025-10-09)
    b.RecordDateTime AS Baseline_Time,
    b.GlobalSequence AS Baseline_GlobalSeq,
    b.LowerCircuitLimit AS Baseline_LC,
    b.UpperCircuitLimit AS Baseline_UC,
    
    -- 10th Oct CHANGES (All changes from BusinessDate 2025-10-10)
    c.TotalChanges_10th,
    c.First_LC_10th,
    c.First_UC_10th,
    c.Last_LC_10th,
    c.Last_UC_10th,
    c.LastRecordTime_10th,
    c.MaxGlobalSeq_10th,
    
    -- LC/UC Change Analysis
    (c.Last_LC_10th - b.LowerCircuitLimit) AS LC_Change,
    (c.Last_UC_10th - b.UpperCircuitLimit) AS UC_Change,
    CASE 
        WHEN b.LowerCircuitLimit > 0 THEN 
            CAST((c.Last_LC_10th - b.LowerCircuitLimit) * 100.0 / b.LowerCircuitLimit AS DECIMAL(10,2))
        ELSE 0 
    END AS LC_Change_Percent

FROM (
    -- Get 10th Oct data
    SELECT 
        Strike,
        ExpiryDate,
        COUNT(*) AS TotalChanges_10th,
        MIN(GlobalSequence) AS MinGlobalSeq_10th,
        MAX(GlobalSequence) AS MaxGlobalSeq_10th,
        (SELECT LowerCircuitLimit FROM MarketQuotes m2 
         WHERE m2.Strike = m1.Strike 
           AND m2.ExpiryDate = m1.ExpiryDate 
           AND m2.OptionType = m1.OptionType
           AND m2.BusinessDate = '2025-10-10'
           AND m2.GlobalSequence = (SELECT MIN(GlobalSequence) FROM MarketQuotes m3 
                                    WHERE m3.Strike = m1.Strike 
                                      AND m3.ExpiryDate = m1.ExpiryDate 
                                      AND m3.OptionType = m1.OptionType
                                      AND m3.BusinessDate = '2025-10-10')
        ) AS First_LC_10th,
        (SELECT UpperCircuitLimit FROM MarketQuotes m2 
         WHERE m2.Strike = m1.Strike 
           AND m2.ExpiryDate = m1.ExpiryDate 
           AND m2.OptionType = m1.OptionType
           AND m2.BusinessDate = '2025-10-10'
           AND m2.GlobalSequence = (SELECT MIN(GlobalSequence) FROM MarketQuotes m3 
                                    WHERE m3.Strike = m1.Strike 
                                      AND m3.ExpiryDate = m1.ExpiryDate 
                                      AND m3.OptionType = m1.OptionType
                                      AND m3.BusinessDate = '2025-10-10')
        ) AS First_UC_10th,
        MAX(LowerCircuitLimit) AS Last_LC_10th,
        MAX(UpperCircuitLimit) AS Last_UC_10th,
        MAX(RecordDateTime) AS LastRecordTime_10th
    FROM MarketQuotes m1
    WHERE TradingSymbol LIKE 'BANKNIFTY%'
      AND OptionType = 'PE'
      AND BusinessDate = '2025-10-10'
    GROUP BY Strike, ExpiryDate, OptionType
) c
LEFT JOIN (
    -- Get 9th Oct BASELINE (last record)
    SELECT 
        Strike,
        ExpiryDate,
        LowerCircuitLimit,
        UpperCircuitLimit,
        RecordDateTime,
        GlobalSequence
    FROM MarketQuotes m1
    WHERE TradingSymbol LIKE 'BANKNIFTY%'
      AND OptionType = 'PE'
      AND BusinessDate = '2025-10-09'
      AND GlobalSequence = (
          SELECT MAX(GlobalSequence) 
          FROM MarketQuotes m2 
          WHERE m2.Strike = m1.Strike 
            AND m2.ExpiryDate = m1.ExpiryDate
            AND m2.OptionType = m1.OptionType
            AND m2.BusinessDate = '2025-10-09'
      )
) b ON c.Strike = b.Strike AND c.ExpiryDate = b.ExpiryDate
ORDER BY c.Strike, c.ExpiryDate;

PRINT '';
PRINT '✅ BANKNIFTY LC/UC Changes Report Complete!';
PRINT '';
PRINT 'LEGEND:';
PRINT '  Baseline_* = Last record from 9th Oct (max GlobalSequence)';
PRINT '  First_*_10th = First record from 10th Oct';
PRINT '  Last_*_10th = Last record from 10th Oct (max GlobalSequence)';
PRINT '  *_Change = Difference from baseline to last value on 10th';

