-- Simple SENSEX LC/UC Changes Query - Copy and Paste Ready
-- Shows last 2 max sequence data for each strike when LC/UC changes

SELECT 
    mq.BusinessDate,
    mq.RecordDateTime AS TradeDate,
    mq.ExpiryDate AS Expiry,
    mq.Strike,
    mq.OptionType,
    mq.OpenPrice,
    mq.HighPrice,
    mq.LowPrice,
    mq.ClosePrice,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.RecordDateTime AS RECORDDATE,
    mq.LastPrice,
    mq.InsertionSequence
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    i.TradingSymbol LIKE 'SENSEX%'
    AND i.InstrumentType IN ('CE', 'PE')
    AND mq.BusinessDate = CAST(GETDATE() AS DATE)
    AND mq.InsertionSequence > 1
    AND (mq.LowerCircuitLimit > 0 OR mq.UpperCircuitLimit > 0)
    AND mq.InsertionSequence IN (
        SELECT TOP 2 MAX(InsertionSequence)
        FROM MarketQuotes mq2
        INNER JOIN Instruments i2 ON mq2.InstrumentToken = i2.InstrumentToken
        WHERE i2.TradingSymbol LIKE 'SENSEX%'
        AND i2.InstrumentType = i.InstrumentType
        AND mq2.Strike = mq.Strike
        AND mq2.BusinessDate = CAST(GETDATE() AS DATE)
        AND mq2.InsertionSequence > 1
        GROUP BY mq2.Strike, i2.InstrumentType
        ORDER BY MAX(InsertionSequence) DESC
    )
ORDER BY 
    CASE WHEN mq.OptionType = 'CE' THEN 1 ELSE 2 END, -- Calls first
    CASE WHEN mq.OptionType = 'CE' THEN mq.Strike ELSE -mq.Strike END, -- ASC for calls, DESC for puts
    mq.InsertionSequence DESC;


