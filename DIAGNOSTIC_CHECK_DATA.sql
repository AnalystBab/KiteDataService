-- COMPREHENSIVE DIAGNOSTIC QUERY
-- This will tell us exactly what data exists and why no records are returned

-- 1. Check if ANY data exists in MarketQuotes table
SELECT 'Total Records' as CheckType, COUNT(*) as Count FROM MarketQuotes;

-- 2. Check what dates have data (most recent first)
SELECT 'Available Dates' as CheckType, BusinessDate, COUNT(*) as RecordCount
FROM MarketQuotes 
GROUP BY BusinessDate 
ORDER BY BusinessDate DESC;

-- 3. Check what expiries exist
SELECT 'Available Expiries' as CheckType, ExpiryDate, COUNT(*) as RecordCount
FROM MarketQuotes 
GROUP BY ExpiryDate 
ORDER BY ExpiryDate DESC;

-- 4. Check what option types exist
SELECT 'Option Types' as CheckType, OptionType, COUNT(*) as RecordCount
FROM MarketQuotes 
GROUP BY OptionType;

-- 5. Check PE UC value ranges
SELECT 'PE UC Ranges' as CheckType, 
    MIN(UpperCircuitLimit) as MinPE_UC,
    MAX(UpperCircuitLimit) as MaxPE_UC,
    AVG(UpperCircuitLimit) as AvgPE_UC,
    COUNT(*) as RecordCount
FROM MarketQuotes 
WHERE OptionType = 'PE';

-- 6. Check specific dates we're looking for
SELECT '15th Oct Check' as CheckType,
    CASE WHEN COUNT(*) > 0 THEN 'DATA EXISTS' ELSE 'NO DATA' END as Status,
    COUNT(*) as RecordCount
FROM MarketQuotes 
WHERE BusinessDate = '2025-10-15';

SELECT '16th Oct Expiry Check' as CheckType,
    CASE WHEN COUNT(*) > 0 THEN 'DATA EXISTS' ELSE 'NO DATA' END as Status,
    COUNT(*) as RecordCount
FROM MarketQuotes 
WHERE ExpiryDate = '2025-10-16';

-- 7. Check if there are any PE options with UC between 350-400
SELECT 'PE UC 350-400 Check' as CheckType,
    CASE WHEN COUNT(*) > 0 THEN 'DATA EXISTS' ELSE 'NO DATA' END as Status,
    COUNT(*) as RecordCount,
    MIN(UpperCircuitLimit) as MinUC,
    MAX(UpperCircuitLimit) as MaxUC
FROM MarketQuotes 
WHERE OptionType = 'PE' 
    AND UpperCircuitLimit BETWEEN 350 AND 400;

-- 8. Show sample of recent PE data
SELECT TOP 10 'Sample PE Data' as CheckType,
    BusinessDate,
    ExpiryDate,
    Strike,
    UpperCircuitLimit,
    TradingSymbol
FROM MarketQuotes 
WHERE OptionType = 'PE'
ORDER BY BusinessDate DESC, UpperCircuitLimit DESC;








