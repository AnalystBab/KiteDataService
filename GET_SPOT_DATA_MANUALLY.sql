-- Manual query to check if we can get spot data from other sources
-- Check if there are any SENSEX spot entries in MarketQuotes

-- 1. Check for any SENSEX entries in MarketQuotes (not just options)
SELECT 
    'MARKETQUOTES_SENSEX' as Source,
    TradingSymbol,
    Strike,
    OptionType,
    MAX(OpenPrice) as [Open],
    MAX(HighPrice) as [High], 
    MIN(LowPrice) as [Low],
    MAX(ClosePrice) as [Close],
    MAX(LastPrice) as LastPrice,
    COUNT(*) as Records
FROM MarketQuotes 
WHERE BusinessDate = '2025-10-13'
  AND TradingSymbol LIKE '%SENSEX%'
  AND (OptionType IS NULL OR OptionType = '')  -- Spot data
GROUP BY TradingSymbol, Strike, OptionType
ORDER BY TradingSymbol;

-- 2. Check all SENSEX-related entries for 2025-10-13
SELECT 
    'ALL_SENSEX_DATA' as Source,
    TradingSymbol,
    Strike,
    OptionType,
    MAX(OpenPrice) as [Open],
    MAX(HighPrice) as [High],
    MIN(LowPrice) as [Low], 
    MAX(ClosePrice) as [Close],
    MAX(LastPrice) as LastPrice,
    COUNT(*) as Records
FROM MarketQuotes 
WHERE BusinessDate = '2025-10-13'
  AND TradingSymbol LIKE '%SENSEX%'
GROUP BY TradingSymbol, Strike, OptionType
HAVING COUNT(*) > 0
ORDER BY TradingSymbol, Strike, OptionType;

-- 3. Check if we have any FUTURES data that might give us spot prices
SELECT 
    'SENSEX_FUTURES' as Source,
    TradingSymbol,
    Strike,
    OptionType,
    MAX(OpenPrice) as [Open],
    MAX(HighPrice) as [High],
    MIN(LowPrice) as [Low],
    MAX(ClosePrice) as [Close], 
    MAX(LastPrice) as LastPrice,
    COUNT(*) as Records
FROM MarketQuotes 
WHERE BusinessDate = '2025-10-13'
  AND TradingSymbol LIKE '%SENSEX%'
  AND OptionType = 'FUT'  -- Futures
GROUP BY TradingSymbol, Strike, OptionType
ORDER BY TradingSymbol;

-- 4. Check HistoricalSpotData for any recent entries
SELECT 
    'HISTORICAL_SPOT' as Source,
    IndexName,
    TradingDate,
    OpenPrice as [Open],
    HighPrice as [High],
    LowPrice as [Low],
    ClosePrice as [Close],
    Volume,
    DataSource
FROM HistoricalSpotData 
WHERE IndexName = 'SENSEX'
  AND TradingDate >= '2025-10-10'
ORDER BY TradingDate DESC;
