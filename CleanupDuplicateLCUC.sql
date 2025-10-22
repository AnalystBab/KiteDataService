-- Cleanup Duplicate LC/UC Records
-- This script removes records with duplicate circuit limit values, keeping only the first occurrence

USE KiteMarketData;

-- First, let's see what we have before cleanup
PRINT '=== BEFORE CLEANUP ===';
SELECT 
    TradingSymbol,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT CONCAT(LowerCircuitLimit, '|', UpperCircuitLimit)) as UniqueLCUCCombinations
FROM MarketQuotes 
GROUP BY TradingSymbol
ORDER BY TotalRecords DESC;

-- Create a temporary table to identify records to keep
WITH RankedRecords AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY InstrumentToken, ExpiryDate, LowerCircuitLimit, UpperCircuitLimit 
            ORDER BY InsertionSequence
        ) as rn
    FROM MarketQuotes
)
DELETE FROM MarketQuotes 
WHERE Id IN (
    SELECT Id FROM RankedRecords WHERE rn > 1
);

-- Show results after cleanup
PRINT '=== AFTER CLEANUP ===';
SELECT 
    TradingSymbol,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT CONCAT(LowerCircuitLimit, '|', UpperCircuitLimit)) as UniqueLCUCCombinations
FROM MarketQuotes 
GROUP BY TradingSymbol
ORDER BY TotalRecords DESC;

-- Verify specific instrument cleanup
PRINT '=== NIFTY 24700 CE CLEANUP VERIFICATION ===';
SELECT 
    InsertionSequence,
    LowerCircuitLimit,
    UpperCircuitLimit,
    LastPrice,
    CreatedAt
FROM MarketQuotes 
WHERE TradingSymbol = 'NIFTY25AUG24700CE'
ORDER BY InsertionSequence;

PRINT '=== CLEANUP COMPLETE ===';
PRINT 'Only records with unique LC/UC combinations have been kept.';
PRINT 'Duplicate records with same circuit limits have been removed.';






