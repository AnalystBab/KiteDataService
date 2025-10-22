-- Simple EOD Validation for SENSEX 2025-10-13
-- Get actual market data

-- 1. Actual SENSEX spot data for 2025-10-13
SELECT 
    'ACTUAL_EOD' as Type,
    '2025-10-13' as Date,
    TradingSymbol,
    MAX(OpenPrice) as [Open],
    MAX(HighPrice) as [High],
    MIN(LowPrice) as [Low],
    MAX(ClosePrice) as [Close],
    MAX(LastPrice) as LastPrice,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol = 'SENSEX' 
  AND BusinessDate = '2025-10-13'
GROUP BY TradingSymbol

UNION ALL

-- 2. Reference data for 2025-10-10
SELECT 
    'REFERENCE_D0' as Type,
    '2025-10-10' as Date,
    TradingSymbol,
    MAX(OpenPrice) as [Open],
    MAX(HighPrice) as [High],
    MIN(LowPrice) as [Low],
    MAX(ClosePrice) as [Close],
    MAX(LastPrice) as LastPrice,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol = 'SENSEX' 
  AND BusinessDate = '2025-10-10'
GROUP BY TradingSymbol

ORDER BY Type, Date;
