-- Find PUT strikes with PE UC values around 250-270 for 14th and 15th Oct 2025
-- Expiry 16/10/2025, PRE-MARKET data only (before 9:15 AM)

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
    CASE 
        WHEN mq.BusinessDate = '2025-10-14' THEN '14th Oct'
        WHEN mq.BusinessDate = '2025-10-15' THEN '15th Oct'
    END AS DateLabel
FROM MarketQuotes mq
WHERE 
    mq.BusinessDate IN ('2025-10-14', '2025-10-15')    -- Both 14th and 15th Oct
    AND mq.ExpiryDate = '2025-10-16'                   -- Expiry: 16/10/2025
    AND mq.OptionType = 'PE'                           -- PUT options only
    AND mq.UpperCircuitLimit BETWEEN 250 AND 270       -- PE UC value between 250-270
    AND CAST(mq.LastTradeTime AS TIME) < '09:15:00'    -- PRE-MARKET: Before 9:15 AM
ORDER BY 
    mq.BusinessDate ASC,                               -- Order by date first
    mq.UpperCircuitLimit ASC,                          -- Then by UC value
    mq.Strike ASC;                                     -- Then by strike price

-- Alternative: If you want to include market opening time (9:15 AM)
-- AND CAST(mq.LastTradeTime AS TIME) <= '09:15:00'    -- Before or at 9:15 AM

-- Alternative: Broader time range for pre-market
-- AND CAST(mq.LastTradeTime AS TIME) BETWEEN '09:00:00' AND '09:15:00'  -- 9:00 AM to 9:15 AM

-- Alternative: Search specific indices only
-- AND (mq.TradingSymbol LIKE '%SENSEX%' OR mq.TradingSymbol LIKE '%NIFTY%' OR mq.TradingSymbol LIKE '%BANKNIFTY%')

-- Alternative: Get exact UC values
-- AND mq.UpperCircuitLimit IN (250, 251, 252, 253, 254, 255, 256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270)








