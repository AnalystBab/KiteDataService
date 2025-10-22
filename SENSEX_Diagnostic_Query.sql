-- SENSEX Diagnostic Query - Check what data is available

-- 1. Check if we have any SENSEX data at all
SELECT 'SENSEX Instruments Count' as CheckType, COUNT(*) as Count
FROM Instruments 
WHERE TradingSymbol LIKE 'SENSEX%'

UNION ALL

-- 2. Check total SENSEX market quotes
SELECT 'SENSEX Market Quotes Count' as CheckType, COUNT(*) as Count
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.TradingSymbol LIKE 'SENSEX%'

UNION ALL

-- 3. Check today's SENSEX data
SELECT 'Today SENSEX Data' as CheckType, COUNT(*) as Count
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.TradingSymbol LIKE 'SENSEX%'
AND mq.BusinessDate = CAST(GETDATE() AS DATE)

UNION ALL

-- 4. Check SENSEX data with sequence > 1 (changes)
SELECT 'SENSEX Changes (Seq>1)' as CheckType, COUNT(*) as Count
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.TradingSymbol LIKE 'SENSEX%'
AND mq.BusinessDate = CAST(GETDATE() AS DATE)
AND mq.InsertionSequence > 1

UNION ALL

-- 5. Check SENSEX data with LC/UC > 0
SELECT 'SENSEX with LC/UC>0' as CheckType, COUNT(*) as Count
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.TradingSymbol LIKE 'SENSEX%'
AND mq.BusinessDate = CAST(GETDATE() AS DATE)
AND (mq.LowerCircuitLimit > 0 OR mq.UpperCircuitLimit > 0);

-- 6. Show sample SENSEX data (any sequence)
SELECT TOP 10
    mq.BusinessDate,
    mq.RecordDateTime AS TradeDate,
    mq.Strike,
    mq.OptionType,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.InsertionSequence,
    i.TradingSymbol
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.TradingSymbol LIKE 'SENSEX%'
ORDER BY mq.RecordDateTime DESC;


