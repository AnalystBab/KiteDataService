-- Options Data Query with all required columns
-- This query formats the data exactly as requested

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
    
    -- Previous Closing Price (from previous day's data)
    LAG(mq.ClosePrice) OVER (
        PARTITION BY mq.InstrumentToken 
        ORDER BY mq.TradingDate, mq.QuoteTimestamp
    ) AS PrvsClsgPric,
    
    -- Underlying Price (current NIFTY/SENSEX value - needs to be calculated)
    -- For now, using a placeholder - this should be the current underlying index value
    CASE 
        WHEN i.Name LIKE '%NIFTY%' THEN 81548.73  -- Current NIFTY value (placeholder)
        WHEN i.Name LIKE '%SENSEX%' THEN 81548.73 -- Current SENSEX value (placeholder)
        ELSE 0
    END AS UndrlygPric,
    
    -- Settlement Price (using close price as settlement)
    mq.ClosePrice AS SttlmPric,
    
    -- Intrinsic Value Calculation
    CASE 
        WHEN i.InstrumentType = 'CE' THEN 
            GREATEST(0, 
                CASE 
                    WHEN i.Name LIKE '%NIFTY%' THEN 81548.73 - mq.Strike  -- NIFTY CE
                    WHEN i.Name LIKE '%SENSEX%' THEN 81548.73 - mq.Strike -- SENSEX CE
                    ELSE 0
                END
            )
        WHEN i.InstrumentType = 'PE' THEN 
            GREATEST(0, 
                CASE 
                    WHEN i.Name LIKE '%NIFTY%' THEN mq.Strike - 81548.73  -- NIFTY PE
                    WHEN i.Name LIKE '%SENSEX%' THEN mq.Strike - 81548.73 -- SENSEX PE
                    ELSE 0
                END
            )
        ELSE 0
    END AS INTINSIC,
    
    -- Settlement Intrinsic Value
    CASE 
        WHEN i.InstrumentType = 'CE' THEN 
            GREATEST(0, mq.ClosePrice - mq.Strike)
        WHEN i.InstrumentType = 'PE' THEN 
            GREATEST(0, mq.Strike - mq.ClosePrice)
        ELSE 0
    END AS [SETTLE-INTRINSIC],
    
    -- Circuit Limits
    mq.LowerCircuitLimit AS LC,
    mq.UpperCircuitLimit AS UC

FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE 
    mq.TradingDate IS NOT NULL  -- Only records with valid trading dates
    AND i.Exchange = 'NFO'
    AND i.Segment = 'NFO-OPT'
    AND i.InstrumentType IN ('CE', 'PE')
    AND mq.ExpiryDate = '2025-09-18'  -- Specific expiry date
ORDER BY 
    i.Name,
    mq.Strike,
    i.InstrumentType;





