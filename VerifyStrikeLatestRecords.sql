-- Verify StrikeLatestRecords Table Integration
-- Run this after the service has been running for a while

-- 1. Check if table exists
SELECT 'Table Exists' AS Status, COUNT(*) AS RecordCount
FROM StrikeLatestRecords;

-- 2. Get statistics
SELECT 
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT CONCAT(TradingSymbol, '_', Strike, '_', OptionType, '_', ExpiryDate)) AS UniqueStrikes,
    COUNT(CASE WHEN RecordOrder = 1 THEN 1 END) AS LatestRecords,
    COUNT(CASE WHEN RecordOrder = 2 THEN 1 END) AS SecondLatestRecords,
    COUNT(CASE WHEN RecordOrder = 3 THEN 1 END) AS OldestRecords
FROM StrikeLatestRecords;

-- 3. Check if any strike has more than 3 records (should be 0)
SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    COUNT(*) AS RecordCount
FROM StrikeLatestRecords
GROUP BY TradingSymbol, Strike, OptionType, ExpiryDate
HAVING COUNT(*) > 3
ORDER BY RecordCount DESC;

-- 4. Sample latest records (RecordOrder = 1)
SELECT TOP 10
    TradingSymbol,
    Strike,
    OptionType,
    UpperCircuitLimit AS Latest_UC,
    LowerCircuitLimit AS Latest_LC,
    BusinessDate,
    RecordDateTime,
    RecordOrder
FROM StrikeLatestRecords
WHERE RecordOrder = 1
ORDER BY RecordDateTime DESC;

-- 5. Example: Get UC change history for SENSEX 83400 CE
SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    UpperCircuitLimit AS UC,
    LowerCircuitLimit AS LC,
    RecordDateTime,
    RecordOrder,
    CASE 
        WHEN RecordOrder = 1 THEN 'Latest'
        WHEN RecordOrder = 2 THEN 'Second Latest'
        WHEN RecordOrder = 3 THEN 'Oldest'
    END AS RecordType
FROM StrikeLatestRecords
WHERE TradingSymbol LIKE 'SENSEX%'
  AND Strike = 83400
  AND OptionType = 'CE'
ORDER BY RecordOrder;

-- 6. Check for strikes with UC changes (compare Record 1 vs Record 2)
WITH UCChanges AS (
    SELECT 
        r1.TradingSymbol,
        r1.Strike,
        r1.OptionType,
        r1.UpperCircuitLimit AS Latest_UC,
        r2.UpperCircuitLimit AS Previous_UC,
        r1.UpperCircuitLimit - r2.UpperCircuitLimit AS UC_Change,
        r1.RecordDateTime AS Latest_Time,
        r2.RecordDateTime AS Previous_Time
    FROM StrikeLatestRecords r1
    INNER JOIN StrikeLatestRecords r2
        ON r1.TradingSymbol = r2.TradingSymbol
        AND r1.Strike = r2.Strike
        AND r1.OptionType = r2.OptionType
        AND r1.ExpiryDate = r2.ExpiryDate
        AND r1.RecordOrder = 1
        AND r2.RecordOrder = 2
)
SELECT TOP 10 *
FROM UCChanges
WHERE UC_Change <> 0
ORDER BY ABS(UC_Change) DESC;

-- 7. Latest UC values for all SENSEX strikes
SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    UpperCircuitLimit AS Latest_UC,
    BusinessDate,
    RecordDateTime
FROM StrikeLatestRecords
WHERE RecordOrder = 1
  AND TradingSymbol LIKE 'SENSEX%'
ORDER BY Strike, OptionType;








