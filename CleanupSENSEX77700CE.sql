-- Cleanup duplicate records for SENSEX 77700 CE - keep only LC/UC changes
USE KiteMarketData;

-- First, let's see what we have before cleanup
PRINT '=== BEFORE CLEANUP FOR SENSEX 77700 CE ===';
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

-- Cleanup: Keep only records where LC or UC actually changed
-- Delete duplicate records keeping only the first occurrence of each LC/UC combination
WITH DuplicateRecords AS (
    SELECT 
        mq.Id,
        ROW_NUMBER() OVER (
            PARTITION BY mq.InstrumentToken, mq.ExpiryDate, mq.LowerCircuitLimit, mq.UpperCircuitLimit
            ORDER BY mq.InsertionSequence
        ) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.Name = 'SENSEX'
    AND i.Strike = 77700
    AND i.InstrumentType = 'CE'
    AND CAST(i.Expiry AS DATE) = '2025-09-04'
)
DELETE FROM MarketQuotes 
WHERE Id IN (
    SELECT Id FROM DuplicateRecords WHERE rn > 1
);

-- Show results after cleanup
PRINT '=== AFTER CLEANUP FOR SENSEX 77700 CE ===';
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

PRINT '=== CLEANUP COMPLETE ===';
PRINT 'Only records with unique LC/UC combinations have been kept.';
PRINT 'Duplicate records with same circuit limits have been removed.';






