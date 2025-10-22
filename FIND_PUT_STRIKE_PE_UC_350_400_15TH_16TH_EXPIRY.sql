-- Find PUT strikes with PE UC values around 350-400 for TODAY (15th Oct)
-- Expiry: 16-10-2025

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
    mq.RecordDateTime,
    mq.InsertionSequence,
    mq.GlobalSequence,
    CAST(mq.LastTradeTime AS TIME) AS TradeTime
FROM MarketQuotes mq
WHERE 
    mq.BusinessDate = '2025-10-15'                     -- TODAY (15th Oct)
    AND mq.ExpiryDate = '2025-10-16'                  -- Expiry: 16-10-2025
    AND mq.OptionType = 'PE'                          -- PUT options only
    AND mq.UpperCircuitLimit BETWEEN 350 AND 400      -- PE UC between 350-400
ORDER BY 
    mq.UpperCircuitLimit ASC,                         -- Order by UC value
    mq.Strike ASC;                                    -- Then by strike price

-- Alternative: Exact range around 350-400
-- AND mq.UpperCircuitLimit BETWEEN 345 AND 405

-- Alternative: Specific values
-- AND mq.UpperCircuitLimit IN (350, 360, 370, 380, 390, 400)

-- Alternative: Search specific indices only
-- AND (mq.TradingSymbol LIKE '%SENSEX%' OR mq.TradingSymbol LIKE '%NIFTY%' OR mq.TradingSymbol LIKE '%BANKNIFTY%')

-- Alternative: If you want to see all PE UC values for today to find the exact range
-- SELECT DISTINCT mq.UpperCircuitLimit, COUNT(*) as Count
-- FROM MarketQuotes mq
-- WHERE mq.BusinessDate = '2025-10-15' 
--   AND mq.ExpiryDate = '2025-10-16' 
--   AND mq.OptionType = 'PE'
-- GROUP BY mq.UpperCircuitLimit
-- ORDER BY mq.UpperCircuitLimit;








