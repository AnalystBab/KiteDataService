-- Test query for options data format
-- Run this to see the column structure

SELECT 
    -- Trading Information
    FORMAT(mq.TradingDate, 'dd-MM-yyyy') AS TradDt,
    FORMAT(mq.ExpiryDate, 'dd-MM-yyyy') AS XpryDt,
    
    -- Strike and Prices
    mq.Strike AS StrkPric,
    mq.OpenPrice AS OpnPric,
    mq.HighPrice AS HghPric,
    mq.LowPrice AS LwPric,
    mq.ClosePrice AS ClsPric,
    mq.LastPrice AS LastPric,
    
    -- Previous Closing Price (simplified - using LAG)
    LAG(mq.ClosePrice) OVER (ORDER BY mq.QuoteTimestamp) AS PrvsClsgPric,
    
    -- Underlying Price (placeholder - should be current index value)
    81548.73 AS UndrlygPric,
    
    -- Settlement Price (NULL until populated from NSE official sources)
    -- Note: Kite Connect API does NOT provide settlement price
    -- Must be obtained from NSE official settlement price files
    mq.SettlementPrice AS SttlmPric,  -- NULL until NSE data is loaded
    
    -- Intrinsic Value = UndrlygPric - StrkPric
    81548.73 - mq.Strike AS INTINSIC,
    
    -- Settlement Intrinsic Value = SttlmPric - StrkPric  
    -- Note: This will be NULL until settlement price is loaded from NSE
    CASE 
        WHEN mq.SettlementPrice IS NOT NULL THEN mq.SettlementPrice - mq.Strike
        ELSE NULL  -- Cannot calculate without settlement price
    END AS [SETTLE-INTRINSIC],
    
    -- Circuit Limits
    mq.LowerCircuitLimit AS LC,
    mq.UpperCircuitLimit AS UC

FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingDate IS NOT NULL
    AND i.Exchange = 'NFO'
    AND i.Segment = 'NFO-OPT'
    AND i.InstrumentType IN ('CE', 'PE')
ORDER BY 
    i.Name,
    mq.Strike,
    i.InstrumentType;
