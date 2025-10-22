-- Find PUT strikes with PE UC values around 250-270 for 14-10-2025, expiry 16/10/2025
-- This query searches for PUT options where PE UC (Put Upper Circuit) is between 250-270

SELECT 
    mq.InstrumentToken,
    mq.TradingSymbol,
    mq.InstrumentType,
    mq.StrikePrice,
    mq.OptionType,
    mq.ExpiryDate,
    mq.UC,                    -- Upper Circuit value
    mq.LC,                    -- Lower Circuit value
    mq.LastPrice,
    mq.Open,
    mq.High,
    mq.Low,
    mq.Close,
    mq.Volume,
    mq.OI,
    mq.TradingDate,
    mq.BusinessDate
FROM MarketQuotes mq
WHERE 
    mq.TradingDate = '2025-10-14'          -- Date: 14-10-2025
    AND mq.ExpiryDate = '2025-10-16'       -- Expiry: 16/10/2025
    AND mq.OptionType = 'PE'               -- PUT options only
    AND mq.UC BETWEEN 250 AND 270          -- PE UC value between 250-270
    AND mq.InstrumentType = 'CE'           -- This should be 'PE' for PUT options
ORDER BY 
    mq.UC ASC,                             -- Order by UC value
    mq.StrikePrice ASC;                    -- Then by strike price

-- Alternative query if InstrumentType field is different:
-- SELECT 
--     mq.InstrumentToken,
--     mq.TradingSymbol,
--     mq.InstrumentType,
--     mq.StrikePrice,
--     mq.OptionType,
--     mq.ExpiryDate,
--     mq.UC,
--     mq.LC,
--     mq.LastPrice,
--     mq.Open,
--     mq.High,
--     mq.Low,
--     mq.Close,
--     mq.Volume,
--     mq.OI,
--     mq.TradingDate,
--     mq.BusinessDate
-- FROM MarketQuotes mq
-- WHERE 
--     mq.TradingDate = '2025-10-14'
--     AND mq.ExpiryDate = '2025-10-16'
--     AND mq.OptionType = 'PE'
--     AND mq.UC BETWEEN 250 AND 270
-- ORDER BY 
--     mq.UC ASC,
--     mq.StrikePrice ASC;

-- If you want to search across multiple indices (SENSEX, NIFTY, BANKNIFTY):
-- Add this condition to the WHERE clause:
-- AND (mq.TradingSymbol LIKE '%SENSEX%' OR mq.TradingSymbol LIKE '%NIFTY%' OR mq.TradingSymbol LIKE '%BANKNIFTY%')

-- To get exact matches around 250-270, you can also use:
-- AND mq.UC IN (250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270)








