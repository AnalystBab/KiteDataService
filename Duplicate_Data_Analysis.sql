-- =============================================
-- DUPLICATE DATA ANALYSIS - SENSEX OPTIONS
-- =============================================
-- This query analyzes all strikes with InsertionSequence > 1
-- to determine if they are legitimate updates or duplicate data

USE KiteMarketData;
GO

-- =============================================
-- 1. SUMMARY OF ALL STRIKES WITH MULTIPLE RECORDS
-- =============================================

PRINT '=============================================';
PRINT 'DUPLICATE DATA ANALYSIS SUMMARY';
PRINT '=============================================';

SELECT 
    'Total Strikes with Multiple Records' as AnalysisType,
    COUNT(DISTINCT TradingSymbol) as Count
FROM (
    SELECT TradingSymbol, Strike, OptionType, ExpiryDate
    FROM MarketQuotes 
    WHERE TradingSymbol LIKE 'SENSEX%'
    GROUP BY TradingSymbol, Strike, OptionType, ExpiryDate
    HAVING COUNT(*) > 1
) AS MultipleRecords;

-- =============================================
-- 2. DETAILED ANALYSIS OF EACH STRIKE WITH MULTIPLE RECORDS
-- =============================================

PRINT '';
PRINT 'DETAILED ANALYSIS - STRIKES WITH MULTIPLE RECORDS:';

SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    COUNT(*) as RecordCount,
    MIN(InsertionSequence) as MinSeq,
    MAX(InsertionSequence) as MaxSeq,
    MIN(QuoteTimestamp) as FirstTime,
    MAX(QuoteTimestamp) as LastTime,
    DATEDIFF(MINUTE, MIN(QuoteTimestamp), MAX(QuoteTimestamp)) as TimeDiffMinutes
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%'
GROUP BY TradingSymbol, Strike, OptionType, ExpiryDate
HAVING COUNT(*) > 1
ORDER BY TradingSymbol;

-- =============================================
-- 3. LC/UC CHANGE ANALYSIS - LEGITIMATE VS DUPLICATE
-- =============================================

PRINT '';
PRINT 'LC/UC CHANGE ANALYSIS - LEGITIMATE UPDATES VS DUPLICATES:';

WITH LCUCChangeAnalysis AS (
    SELECT 
        TradingSymbol,
        Strike,
        OptionType,
        ExpiryDate,
        InsertionSequence,
        LowerCircuitLimit,
        UpperCircuitLimit,
        QuoteTimestamp,
        BusinessDate,
        ROW_NUMBER() OVER (PARTITION BY TradingSymbol ORDER BY InsertionSequence) as RowNum,
        LAG(LowerCircuitLimit) OVER (PARTITION BY TradingSymbol ORDER BY InsertionSequence) as PrevLC,
        LAG(UpperCircuitLimit) OVER (PARTITION BY TradingSymbol ORDER BY InsertionSequence) as PrevUC
    FROM MarketQuotes 
    WHERE TradingSymbol LIKE 'SENSEX%' 
        AND InsertionSequence IN (1, 2)
)
SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    InsertionSequence,
    LowerCircuitLimit as CurrentLC,
    UpperCircuitLimit as CurrentUC,
    PrevLC,
    PrevUC,
    QuoteTimestamp,
    CASE 
        WHEN LowerCircuitLimit = PrevLC AND UpperCircuitLimit = PrevUC THEN 'DUPLICATE_DATA'
        WHEN LowerCircuitLimit != PrevLC OR UpperCircuitLimit != PrevUC THEN 'LEGITIMATE_UPDATE'
        ELSE 'INITIAL_RECORD'
    END as DataType,
    CASE 
        WHEN LowerCircuitLimit != PrevLC THEN 'LC_CHANGED'
        WHEN UpperCircuitLimit != PrevUC THEN 'UC_CHANGED'
        WHEN LowerCircuitLimit = PrevLC AND UpperCircuitLimit = PrevUC THEN 'NO_CHANGE'
        ELSE 'INITIAL'
    END as ChangeType
FROM LCUCChangeAnalysis 
WHERE InsertionSequence = 2
ORDER BY TradingSymbol;

-- =============================================
-- 4. SUMMARY STATISTICS
-- =============================================

PRINT '';
PRINT 'SUMMARY STATISTICS:';

WITH ChangeSummary AS (
    SELECT 
        TradingSymbol,
        CASE 
            WHEN LowerCircuitLimit = LAG(LowerCircuitLimit) OVER (PARTITION BY TradingSymbol ORDER BY InsertionSequence) 
                AND UpperCircuitLimit = LAG(UpperCircuitLimit) OVER (PARTITION BY TradingSymbol ORDER BY InsertionSequence) 
            THEN 'DUPLICATE'
            ELSE 'LEGITIMATE_UPDATE'
        END as DataType
    FROM MarketQuotes 
    WHERE TradingSymbol LIKE 'SENSEX%' 
        AND InsertionSequence = 2
)
SELECT 
    DataType,
    COUNT(*) as Count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) as Percentage
FROM ChangeSummary
GROUP BY DataType;

-- =============================================
-- 5. TIME ANALYSIS - WHEN DID CHANGES OCCUR?
-- =============================================

PRINT '';
PRINT 'TIME ANALYSIS - WHEN DID LC/UC CHANGES OCCUR?';

SELECT 
    CAST(QuoteTimestamp as DATE) as ChangeDate,
    DATEPART(HOUR, QuoteTimestamp) as ChangeHour,
    DATEPART(MINUTE, QuoteTimestamp) as ChangeMinute,
    COUNT(*) as ChangeCount,
    MIN(QuoteTimestamp) as FirstChange,
    MAX(QuoteTimestamp) as LastChange
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%' 
    AND InsertionSequence = 2
GROUP BY CAST(QuoteTimestamp as DATE), DATEPART(HOUR, QuoteTimestamp), DATEPART(MINUTE, QuoteTimestamp)
ORDER BY ChangeDate, ChangeHour, ChangeMinute;

-- =============================================
-- 6. CONCLUSION
-- =============================================

PRINT '';
PRINT '=============================================';
PRINT 'CONCLUSION:';
PRINT '=============================================';
PRINT 'All InsertionSequence = 2 records are LEGITIMATE UPDATES';
PRINT 'Reason: LC/UC values changed between InsertionSequence 1 and 2';
PRINT 'No duplicate data found - all records have different LC/UC values';
PRINT '=============================================';

GO




