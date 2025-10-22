-- Find PUT strikes with PE UC values around 250-270 for 14-10-2025, expiry 16/10/2025
-- CORRECTED with actual column names from MarketQuote model

SELECT 
    mq.BusinessDate,
    mq.TradingSymbol,
    mq.Strike,
    mq.OptionType,
    mq.ExpiryDate,
    mq.UpperCircuitLimit AS PE_UC,          -- PE Upper Circuit value
    mq.LowerCircuitLimit AS PE_LC,          -- PE Lower Circuit value
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
    mq.BusinessDate = '2025-10-14'                    -- Date: 14-10-2025
    AND mq.ExpiryDate = '2025-10-16'                  -- Expiry: 16/10/2025
    AND mq.OptionType = 'PE'                          -- PUT options only
    AND mq.UpperCircuitLimit BETWEEN 250 AND 270      -- PE UC value between 250-270
ORDER BY 
    mq.UpperCircuitLimit ASC,                         -- Order by UC value
    mq.Strike ASC;                                    -- Then by strike price

-- Alternative: Search for specific indices only
-- Add this condition to the WHERE clause:
-- AND (mq.TradingSymbol LIKE '%SENSEX%' OR mq.TradingSymbol LIKE '%NIFTY%' OR mq.TradingSymbol LIKE '%BANKNIFTY%')

-- Alternative: Get exact matches
-- AND mq.UpperCircuitLimit IN (250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270)

-- Alternative: Broader range if no results
-- AND mq.UpperCircuitLimit BETWEEN 240 AND 280








