-- EOD Validation Query for SENSEX Predictions - 2025-10-13
-- Compare our predictions with actual market data

-- 1. Get actual SENSEX spot data for 2025-10-13
SELECT 
    'SENSEX_ACTUAL_EOD' as DataType,
    '2025-10-13' as BusinessDate,
    'SENSEX' as [Index],
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol = 'SENSEX' 
  AND BusinessDate = '2025-10-13'
  AND OptionType IS NULL  -- Spot data only

UNION ALL

-- 2. Get our reference data (2025-10-10) for comparison
SELECT 
    'SENSEX_REFERENCE_D0' as DataType,
    '2025-10-10' as BusinessDate,
    'SENSEX' as [Index],
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol = 'SENSEX' 
  AND BusinessDate = '2025-10-10'
  AND OptionType IS NULL

UNION ALL

-- 3. Get actual option data for key strikes on 2025-10-13
SELECT 
    'OPTION_ACTUAL_EOD' as DataType,
    '2025-10-13' as BusinessDate,
    TradingSymbol as Index,
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    Strike,
    OptionType,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%' 
  AND BusinessDate = '2025-10-13'
  AND OptionType IN ('CE', 'PE')
  AND Strike IN (82000, 82100, 82200, 82400, 82500, 82600)  -- Key strikes around our predictions
GROUP BY TradingSymbol, Strike, OptionType

ORDER BY DataType, BusinessDate, Strike, OptionType;

-- 4. Get our prediction reference data (TARGET_CE_PREMIUM from 2025-10-10)
SELECT 
    'PREDICTION_REFERENCE' as DataType,
    '2025-10-10' as BusinessDate,
    LabelName,
    LabelValue,
    Description
FROM StrategyLabels 
WHERE BusinessDate = '2025-10-10' 
  AND IndexName = 'SENSEX'
  AND LabelName IN (
    'TARGET_CE_PREMIUM',
    'CALL_MINUS_TO_CALL_BASE_DISTANCE', 
    'BOUNDARY_UPPER',
    'BOUNDARY_LOWER',
    'SPOT_CLOSE_D0',
    'CLOSE_STRIKE',
    'CALL_BASE_STRIKE',
    'PUT_BASE_STRIKE'
  )

ORDER BY LabelName;
