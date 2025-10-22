-- SENSEX Call and Put Options with LC/UC Changes - Enhanced Version
-- Shows last 2 max sequence data for each strike when LC/UC changes
-- Call strikes in ASC order, Put strikes in DESC order

-- Get SENSEX data with LC/UC changes (sequence > 1)
WITH SENSEX_LC_UC_Changes AS (
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
        -- Get the max sequence for each strike/option type
        MAX(mq.InsertionSequence) OVER (
            PARTITION BY mq.Strike, mq.OptionType
        ) as MaxSequence,
        -- Get the second max sequence for each strike/option type
        LAG(mq.InsertionSequence, 1) OVER (
            PARTITION BY mq.Strike, mq.OptionType 
            ORDER BY mq.InsertionSequence DESC
        ) as SecondMaxSequence
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        i.TradingSymbol LIKE 'SENSEX%'
        AND i.InstrumentType IN ('CE', 'PE')
        AND mq.BusinessDate = CAST(GETDATE() AS DATE) -- Today's data
        AND mq.InsertionSequence > 1 -- Only changes (sequence > 1)
        AND (mq.LowerCircuitLimit > 0 OR mq.UpperCircuitLimit > 0) -- Has circuit limits
),
-- Get the last 2 sequence records for each strike
SENSEX_LastTwoSequences AS (
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
        InsertionSequence,
        ROW_NUMBER() OVER (
            PARTITION BY Strike, OptionType 
            ORDER BY InsertionSequence DESC
        ) as rn
    FROM SENSEX_LC_UC_Changes
    WHERE InsertionSequence IN (MaxSequence, SecondMaxSequence)
       OR InsertionSequence = MaxSequence
),
-- Separate Calls and Puts
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
    FROM SENSEX_LastTwoSequences
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
    FROM SENSEX_LastTwoSequences
    WHERE OptionType = 'PE' AND rn <= 2
)

-- Final Result: SENSEX CALLS (Strike ASC) + SENSEX PUTS (Strike DESC)
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


