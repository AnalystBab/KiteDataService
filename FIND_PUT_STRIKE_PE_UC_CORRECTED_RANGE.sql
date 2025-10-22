-- CORRECTED QUERY: PE UC values are much higher (0 to 11,464.75)
-- Find PUT strikes with PE UC values around 350-400 for TODAY (15th Oct)
-- But first let's see what PE UC ranges actually exist for 16th Oct expiry

-- 1. Check what PE UC ranges exist for 16th Oct expiry today
SELECT DISTINCT 
    UpperCircuitLimit AS PE_UC,
    COUNT(*) as RecordCount,
    MIN(Strike) as MinStrike,
    MAX(Strike) as MaxStrike
FROM MarketQuotes 
WHERE BusinessDate = '2025-10-15'
    AND ExpiryDate = '2025-10-16'
    AND OptionType = 'PE'
GROUP BY UpperCircuitLimit
ORDER BY UpperCircuitLimit;

-- 2. If you want PE UC around 350-400, try this:
SELECT 
    mq.BusinessDate,
    mq.TradingSymbol,
    mq.Strike,
    mq.OptionType,
    mq.ExpiryDate,
    mq.UpperCircuitLimit AS PE_UC,
    mq.LowerCircuitLimit AS PE_LC,
    mq.OpenPrice AS [Open],
    mq.HighPrice AS High,
    mq.LowPrice AS Low,
    mq.ClosePrice AS [Close],
    mq.LastPrice,
    mq.InstrumentToken,
    mq.LastTradeTime,
    CAST(mq.LastTradeTime AS TIME) AS TradeTime
FROM MarketQuotes mq
WHERE 
    mq.BusinessDate = '2025-10-15'
    AND mq.ExpiryDate = '2025-10-16'
    AND mq.OptionType = 'PE'
    AND mq.UpperCircuitLimit BETWEEN 350 AND 400
ORDER BY 
    mq.UpperCircuitLimit ASC,
    mq.Strike ASC;

-- 3. Alternative: Look for PE UC values in different ranges
-- PE UC between 500-1000:
-- AND mq.UpperCircuitLimit BETWEEN 500 AND 1000

-- PE UC between 1000-2000:
-- AND mq.UpperCircuitLimit BETWEEN 1000 AND 2000

-- PE UC between 2000-3000:
-- AND mq.UpperCircuitLimit BETWEEN 2000 AND 3000

-- 4. Check what's the typical PE UC range for 16th Oct expiry
SELECT 
    'PE UC Statistics for 16th Oct Expiry' as Description,
    MIN(UpperCircuitLimit) as MinPE_UC,
    MAX(UpperCircuitLimit) as MaxPE_UC,
    AVG(UpperCircuitLimit) as AvgPE_UC,
    COUNT(*) as TotalRecords
FROM MarketQuotes 
WHERE BusinessDate = '2025-10-15'
    AND ExpiryDate = '2025-10-16'
    AND OptionType = 'PE';








