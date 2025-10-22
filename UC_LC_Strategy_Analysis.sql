-- ========================================
-- UC/LC CONSTRAINT STRATEGY ANALYSIS
-- Analyzing how UC/LC values constrain spot movement
-- ========================================

USE KiteMarketData;
GO

-- Get current SENSEX spot price
DECLARE @CurrentSpot DECIMAL(10,2) = (SELECT TOP 1 LastPrice FROM SpotData WHERE IndexName = 'SENSEX' ORDER BY QuoteTimestamp DESC);

PRINT '========================================';
PRINT 'CURRENT SENSEX SPOT: ' + CAST(@CurrentSpot AS VARCHAR);
PRINT '========================================';
PRINT '';

-- Analyze UC/LC constraints for 09-OCT expiry (tomorrow)
PRINT '📊 UC/LC CONSTRAINT ANALYSIS - 09-OCT-2025 EXPIRY';
PRINT '========================================';
PRINT '';

SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    LastPrice AS Premium,
    LowerCircuitLimit AS LC,
    UpperCircuitLimit AS UC,
    -- Calculate spot levels if option hits UC
    CASE 
        WHEN OptionType = 'CE' THEN Strike - UpperCircuitLimit  -- If CE hits UC, spot is deep ITM
        WHEN OptionType = 'PE' THEN Strike + UpperCircuitLimit  -- If PE hits UC, spot is deep ITM
    END AS SpotIfHitsUC,
    -- Calculate spot levels if option hits LC
    CASE 
        WHEN OptionType = 'CE' THEN Strike - LowerCircuitLimit  -- If CE hits LC, spot is OTM
        WHEN OptionType = 'PE' THEN Strike + LowerCircuitLimit  -- If PE hits LC, spot is OTM
    END AS SpotIfHitsLC,
    -- UC/LC Range
    (UpperCircuitLimit - LowerCircuitLimit) AS UC_LC_Range,
    -- Distance from current spot
    (Strike - @CurrentSpot) AS DistanceFromSpot,
    -- ITM/OTM/ATM
    CASE 
        WHEN OptionType = 'CE' AND Strike < @CurrentSpot THEN 'ITM'
        WHEN OptionType = 'CE' AND Strike > @CurrentSpot THEN 'OTM'
        WHEN OptionType = 'PE' AND Strike > @CurrentSpot THEN 'ITM'
        WHEN OptionType = 'PE' AND Strike < @CurrentSpot THEN 'OTM'
        ELSE 'ATM'
    END AS Moneyness,
    FORMAT(RecordDateTime, 'HH:mm:ss') AS Time
FROM MarketQuotes
WHERE TradingSymbol LIKE 'SENSEX25O09%'
  AND Strike BETWEEN (@CurrentSpot - 2000) AND (@CurrentSpot + 2000)  -- Focus on near strikes
  AND InsertionSequence = (SELECT MAX(InsertionSequence) FROM MarketQuotes WHERE TradingSymbol LIKE 'SENSEX25O09%')
ORDER BY Strike, OptionType;

PRINT '';
PRINT '========================================';
PRINT '🎯 KEY INSIGHTS:';
PRINT '========================================';
PRINT '';
PRINT '1. SpotIfHitsUC: Where spot would be if option premium reaches UC';
PRINT '2. SpotIfHitsLC: Where spot would be if option premium reaches LC';
PRINT '3. UC_LC_Range: How much room option has to move';
PRINT '4. DistanceFromSpot: How far strike is from current spot';
PRINT '';

-- Find specific strike constraints
PRINT '========================================';
PRINT '🔍 81900 STRIKE ANALYSIS:';
PRINT '========================================';
PRINT '';

SELECT 
    TradingSymbol,
    Strike,
    OptionType,
    LastPrice AS Premium,
    LowerCircuitLimit AS LC,
    UpperCircuitLimit AS UC,
    CASE 
        WHEN OptionType = 'CE' THEN Strike - UpperCircuitLimit
        WHEN OptionType = 'PE' THEN Strike + UpperCircuitLimit
    END AS MaxSpotMovement,
    CASE 
        WHEN OptionType = 'CE' THEN Strike - LowerCircuitLimit
        WHEN OptionType = 'PE' THEN Strike + LowerCircuitLimit
    END AS MinSpotMovement
FROM MarketQuotes
WHERE TradingSymbol IN ('SENSEX25O0981900CE', 'SENSEX25O0981900PE')
  AND InsertionSequence = (SELECT MAX(InsertionSequence) FROM MarketQuotes WHERE TradingSymbol = 'SENSEX25O0981900CE');

PRINT '';
PRINT '========================================';
PRINT '💡 STRATEGY IMPLICATIONS:';
PRINT '========================================';
PRINT '';
PRINT 'If 81900 CE UC allows spot down to ~80,200';
PRINT 'And 81900 PE UC allows spot up to ~83,300';
PRINT 'Then spot is CONSTRAINED to this range by NSE limits!';
PRINT '';
PRINT 'Higher UC = NSE expects bigger moves = Opportunity!';
PRINT '';

GO

