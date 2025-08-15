-- Working NIFTY AUG 14 CALL OPTIONS Query with EOD Comparison
-- No ambiguous column references

USE KiteMarketData;
GO

WITH LatestCALLQuotes AS (
    SELECT 
        mq.InstrumentToken,
        mq.TradingSymbol,
        mq.Exchange,
        mq.Expiry,
        mq.OHLC_Open,
        mq.OHLC_High,
        mq.OHLC_Low,
        mq.OHLC_Close,
        mq.LastPrice,
        mq.Volume,
        mq.OpenInterest,
        mq.LowerCircuitLimit,
        mq.UpperCircuitLimit,
        mq.QuoteTimestamp,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'NIFTY%' 
        AND CAST(mq.Expiry AS DATE) = '2025-08-14'
        AND i.InstrumentType = 'CE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    lq.Strike AS StrkPric,
    lq.OHLC_Open AS OpnPric,
    lq.OHLC_High AS HghPric,
    lq.OHLC_Low AS LwPric,
    lq.OHLC_Close AS ClsPric,
    lq.LastPrice AS LastPric,
    lq.LowerCircuitLimit AS lowerLimit,
    lq.UpperCircuitLimit AS UpperLimit,
    
    -- EOD comparison columns
    eod.LowerCircuitLimit as EOD_LC,
    eod.UpperCircuitLimit as EOD_UC,
    eod.OHLC_Close as EOD_Close,
    eod.LastPrice as EOD_LastPrice,
    
    CASE 
        WHEN eod.LowerCircuitLimit != lq.LowerCircuitLimit THEN 'LC_CHANGED'
        WHEN eod.UpperCircuitLimit != lq.UpperCircuitLimit THEN 'UC_CHANGED'
        ELSE 'NO_CHANGE'
    END as CircuitChange
FROM LatestCALLQuotes lq
LEFT JOIN EODMarketData eod ON lq.TradingSymbol = eod.TradingSymbol 
    AND eod.TradingDate = CAST(GETDATE() AS DATE)
WHERE lq.rn = 1
ORDER BY lq.Strike ASC;
