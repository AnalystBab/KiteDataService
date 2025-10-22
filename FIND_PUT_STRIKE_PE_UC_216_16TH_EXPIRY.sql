-- Find PUT strikes with PE UC values around 216 for 16th Oct expiry from yesterday
-- Yesterday = 14th Oct 2025 (Full day data)
-- Expiry = 16th Oct 2025

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
    mq.GlobalSequence
FROM MarketQuotes mq
WHERE 
    mq.BusinessDate = '2025-10-14'                     -- Yesterday (14th Oct)
    AND mq.ExpiryDate = '2025-10-16'                  -- 16th Oct expiry
    AND mq.OptionType = 'PE'                          -- PUT options only
    AND mq.UpperCircuitLimit BETWEEN 210 AND 225      -- PE UC around 216 (210-225 range)
ORDER BY 
    mq.UpperCircuitLimit ASC,                         -- Order by UC value closest to 216
    mq.Strike ASC;                                    -- Then by strike price

-- Alternative: Exact match around 216
-- AND mq.UpperCircuitLimit IN (214, 215, 216, 217, 218)

-- Alternative: Broader range if needed
-- AND mq.UpperCircuitLimit BETWEEN 200 AND 230

-- Alternative: Search specific indices only
-- AND (mq.TradingSymbol LIKE '%SENSEX%' OR mq.TradingSymbol LIKE '%NIFTY%' OR mq.TradingSymbol LIKE '%BANKNIFTY%')

-- Alternative: If you want to see all PE UC values for 16th expiry to find the exact one
-- SELECT DISTINCT mq.UpperCircuitLimit, COUNT(*) as Count
-- FROM MarketQuotes mq
-- WHERE mq.BusinessDate = '2025-10-14' 
--   AND mq.ExpiryDate = '2025-10-16' 
--   AND mq.OptionType = 'PE'
-- GROUP BY mq.UpperCircuitLimit
-- ORDER BY mq.UpperCircuitLimit;








