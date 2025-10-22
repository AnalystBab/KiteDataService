-- =====================================================
-- SENSEX 82500 CE (16th Oct Expiry ONLY) - LC/UC Changes
-- From 10-10-2025 to 13-10-2025
-- =====================================================

SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    BusinessDate,
    RecordDateTime,
    LastPrice,
    OpenPrice,
    HighPrice,
    LowPrice,
    ClosePrice,
    LowerCircuitLimit as LC,
    UpperCircuitLimit as UC,
    InsertionSequence as [IS],
    LastTradeTime,
    InstrumentToken,
    GlobalSequence
FROM MarketQuotes
WHERE 
    TradingSymbol = 'SENSEX25O1682500CE'
    AND BusinessDate BETWEEN '2025-10-10' AND '2025-10-13'
ORDER BY 
    BusinessDate,
    RecordDateTime;

