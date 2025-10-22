-- Monitor script to check when SENSEX spot data becomes available for 2025-10-13
-- Run this periodically to see when data is collected

SELECT 
    'SPOT_DATA_CHECK' as CheckType,
    IndexName,
    TradingDate,
    OpenPrice as [Open],
    HighPrice as [High], 
    LowPrice as [Low],
    ClosePrice as [Close],
    Volume,
    DataSource,
    CreatedDate,
    LastUpdated
FROM HistoricalSpotData 
WHERE IndexName = 'SENSEX'
  AND TradingDate = '2025-10-13'
ORDER BY TradingDate DESC;

-- Also check the latest available spot data
SELECT 
    'LATEST_SPOT_DATA' as CheckType,
    IndexName,
    TradingDate,
    OpenPrice as [Open],
    HighPrice as [High],
    LowPrice as [Low], 
    ClosePrice as [Close],
    Volume,
    DataSource,
    CreatedDate,
    LastUpdated
FROM HistoricalSpotData 
WHERE IndexName = 'SENSEX'
ORDER BY TradingDate DESC;
