-- =============================================
-- LC/UC CHANGES ANALYSIS - COPYABLE SQL QUERY
-- =============================================
-- This query shows all strikes with LC/UC changes
-- and compares the values between InsertionSequence 1 and 2

WITH LCUCChanges AS (
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
    ExpiryDate,
    InsertionSequence,
    LowerCircuitLimit as CurrentLC,
    UpperCircuitLimit as CurrentUC,
    PrevLC,
    PrevUC,
    QuoteTimestamp,
    BusinessDate,
    CASE 
        WHEN LowerCircuitLimit != PrevLC THEN 'LC_CHANGED'
        WHEN UpperCircuitLimit != PrevUC THEN 'UC_CHANGED'
        WHEN LowerCircuitLimit = PrevLC AND UpperCircuitLimit = PrevUC THEN 'NO_CHANGE'
        ELSE 'INITIAL_RECORD'
    END as ChangeType,
    CASE 
        WHEN LowerCircuitLimit != PrevLC THEN 
            CAST((LowerCircuitLimit - PrevLC) AS VARCHAR(20)) + 
            ' (' + 
            CAST(ROUND(((LowerCircuitLimit - PrevLC) / PrevLC * 100), 2) AS VARCHAR(20)) + 
            '%)'
        WHEN UpperCircuitLimit != PrevUC THEN 
            CAST((UpperCircuitLimit - PrevUC) AS VARCHAR(20)) + 
            ' (' + 
            CAST(ROUND(((UpperCircuitLimit - PrevUC) / PrevUC * 100), 2) AS VARCHAR(20)) + 
            '%)'
        ELSE 'NO_CHANGE'
    END as ChangeAmount
FROM LCUCChanges 
WHERE InsertionSequence = 2
ORDER BY TradingSymbol;




