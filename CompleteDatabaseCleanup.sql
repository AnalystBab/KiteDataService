-- Complete Database Cleanup - Remove ALL duplicate LC/UC records
-- This script will clean up the entire MarketQuotes table, keeping only unique LC/UC combinations

USE KiteMarketData;

-- First, let's see the current state
PRINT '=== BEFORE COMPLETE CLEANUP ===';
SELECT 
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT CONCAT(InstrumentToken, '|', ExpiryDate, '|', LowerCircuitLimit, '|', UpperCircuitLimit)) as UniqueLCUCCombinations
FROM MarketQuotes;

-- Show breakdown by instrument type
PRINT '=== RECORDS BY INSTRUMENT TYPE ===';
SELECT 
    i.Name as IndexName,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT CONCAT(mq.InstrumentToken, '|', mq.ExpiryDate, '|', mq.LowerCircuitLimit, '|', mq.UpperCircuitLimit)) as UniqueLCUCCombinations
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
GROUP BY i.Name
ORDER BY TotalRecords DESC;

-- Cleanup: Remove ALL duplicate records, keeping only the first occurrence of each unique LC/UC combination
PRINT '=== STARTING COMPLETE CLEANUP ===';
WITH DuplicateRecords AS (
    SELECT 
        Id,
        ROW_NUMBER() OVER (
            PARTITION BY InstrumentToken, ExpiryDate, LowerCircuitLimit, UpperCircuitLimit
            ORDER BY InsertionSequence
        ) as rn
    FROM MarketQuotes
)
DELETE FROM MarketQuotes 
WHERE Id IN (
    SELECT Id FROM DuplicateRecords WHERE rn > 1
);

-- Show results after cleanup
PRINT '=== AFTER COMPLETE CLEANUP ===';
SELECT 
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT CONCAT(InstrumentToken, '|', ExpiryDate, '|', LowerCircuitLimit, '|', UpperCircuitLimit)) as UniqueLCUCCombinations
FROM MarketQuotes;

-- Show breakdown by instrument type after cleanup
PRINT '=== RECORDS BY INSTRUMENT TYPE (AFTER CLEANUP) ===';
SELECT 
    i.Name as IndexName,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT CONCAT(mq.InstrumentToken, '|', mq.ExpiryDate, '|', mq.LowerCircuitLimit, '|', mq.UpperCircuitLimit)) as UniqueLCUCCombinations
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
GROUP BY i.Name
ORDER BY TotalRecords DESC;

-- Verify specific instruments that had many duplicates
PRINT '=== VERIFICATION: SENSEX 77700 CE ===';
SELECT 
    mq.InsertionSequence,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.LastPrice,
    mq.CreatedAt
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.Name = 'SENSEX'
AND i.Strike = 77700
AND i.InstrumentType = 'CE'
AND CAST(i.Expiry AS DATE) = '2025-09-04'
ORDER BY mq.InsertionSequence;

PRINT '=== VERIFICATION: NIFTY 24700 CE ===';
SELECT 
    mq.InsertionSequence,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.LastPrice,
    mq.CreatedAt
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.Name = 'NIFTY'
AND i.Strike = 24700
AND i.InstrumentType = 'CE'
AND CAST(i.Expiry AS DATE) = '2025-08-28'
ORDER BY mq.InsertionSequence;

PRINT '=== COMPLETE CLEANUP FINISHED ===';
PRINT 'All duplicate LC/UC records have been removed from the entire database.';
PRINT 'Only records with unique circuit limit combinations have been kept.';
PRINT 'Each instrument+expiry+LC+UC combination now has only one record.';






