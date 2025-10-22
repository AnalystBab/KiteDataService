-- SENSEX Call and Put Options with LC/UC Changes
-- Shows last 2 max sequence data for each strike when LC/UC changes
-- Call strikes in ASC order, Put strikes in DESC order

WITH SENSEX_Data AS (
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
        mq.InsertionSequence,
        -- Add row number to get last 2 records per strike
        ROW_NUMBER() OVER (
            PARTITION BY mq.Strike, mq.OptionType 
            ORDER BY mq.InsertionSequence DESC
        ) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        i.TradingSymbol LIKE 'SENSEX%'
        AND i.InstrumentType IN ('CE', 'PE')
        AND mq.BusinessDate = CAST(GETDATE() AS DATE) -- Today's data
        AND mq.InsertionSequence > 1 -- Only changes (sequence > 1)
        AND (mq.LowerCircuitLimit > 0 OR mq.UpperCircuitLimit > 0) -- Has circuit limits
),
SENSEX_Calls AS (
    SELECT 
        BusinessDate,
        TradeDate,
        Expiry,
        Strike,
        OptionType,
        OpenPrice,
        HighPrice,
        LowPrice,
        ClosePrice,
        LowerCircuitLimit,
        UpperCircuitLimit,
        RECORDDATE,
        LastPrice,
        InsertionSequence
    FROM SENSEX_Data
    WHERE OptionType = 'CE' AND rn <= 2
),
SENSEX_Puts AS (
    SELECT 
        BusinessDate,
        TradeDate,
        Expiry,
        Strike,
        OptionType,
        OpenPrice,
        HighPrice,
        LowPrice,
        ClosePrice,
        LowerCircuitLimit,
        UpperCircuitLimit,
        RECORDDATE,
        LastPrice,
        InsertionSequence
    FROM SENSEX_Data
    WHERE OptionType = 'PE' AND rn <= 2
)

-- SENSEX CALLS (Strike ASC)
SELECT 
    BusinessDate,
    TradeDate,
    Expiry,
    Strike,
    OptionType,
    OpenPrice,
    HighPrice,
    LowPrice,
    ClosePrice,
    LowerCircuitLimit,
    UpperCircuitLimit,
    RECORDDATE,
    LastPrice,
    InsertionSequence
FROM SENSEX_Calls
ORDER BY Strike ASC, InsertionSequence DESC

UNION ALL

-- SENSEX PUTS (Strike DESC)
SELECT 
    BusinessDate,
    TradeDate,
    Expiry,
    Strike,
    OptionType,
    OpenPrice,
    HighPrice,
    LowPrice,
    ClosePrice,
    LowerCircuitLimit,
    UpperCircuitLimit,
    RECORDDATE,
    LastPrice,
    InsertionSequence
FROM SENSEX_Puts
ORDER BY Strike DESC, InsertionSequence DESC;


