-- Diagnostic query to check what data actually exists
-- Let's see what dates, expiries, and PE UC values are available

-- 1. Check what dates have data
SELECT DISTINCT 
    BusinessDate, 
    COUNT(*) as RecordCount
FROM MarketQuotes 
GROUP BY BusinessDate 
ORDER BY BusinessDate DESC;

-- 2. Check what expiries exist for recent dates
SELECT DISTINCT 
    BusinessDate,
    ExpiryDate,
    COUNT(*) as RecordCount
FROM MarketQuotes 
WHERE BusinessDate >= '2025-10-10'
GROUP BY BusinessDate, ExpiryDate 
ORDER BY BusinessDate DESC, ExpiryDate;

-- 3. Check PE UC values for recent dates
SELECT DISTINCT 
    BusinessDate,
    ExpiryDate,
    OptionType,
    UpperCircuitLimit,
    COUNT(*) as Count
FROM MarketQuotes 
WHERE BusinessDate >= '2025-10-10'
    AND OptionType = 'PE'
GROUP BY BusinessDate, ExpiryDate, OptionType, UpperCircuitLimit
ORDER BY BusinessDate DESC, ExpiryDate, UpperCircuitLimit;

-- 4. Check if there's any data for 15th Oct 2025 specifically
SELECT 
    COUNT(*) as TotalRecords,
    MIN(UpperCircuitLimit) as MinPE_UC,
    MAX(UpperCircuitLimit) as MaxPE_UC,
    COUNT(DISTINCT Strike) as UniqueStrikes,
    COUNT(DISTINCT ExpiryDate) as UniqueExpiries
FROM MarketQuotes 
WHERE BusinessDate = '2025-10-15'
    AND OptionType = 'PE';

-- 5. Check if there's any data for 16th Oct expiry
SELECT 
    BusinessDate,
    COUNT(*) as TotalRecords,
    MIN(UpperCircuitLimit) as MinPE_UC,
    MAX(UpperCircuitLimit) as MaxPE_UC,
    COUNT(DISTINCT Strike) as UniqueStrikes
FROM MarketQuotes 
WHERE ExpiryDate = '2025-10-16'
    AND OptionType = 'PE'
GROUP BY BusinessDate
ORDER BY BusinessDate DESC;








