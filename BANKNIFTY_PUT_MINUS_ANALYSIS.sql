-- ================================================================================
-- BANKNIFTY PUT MINUS PROCESS ANALYSIS
-- Analyze the exact steps and why distance went negative
-- Date: 9th October 2025
-- ================================================================================

DECLARE @BusinessDate DATE = '2025-10-09';
DECLARE @IndexName VARCHAR(20) = 'BANKNIFTY';

-- Get the expiry date for BANKNIFTY
DECLARE @ExpiryDate DATE;
SELECT TOP 1 @ExpiryDate = ExpiryDate
FROM MarketQuotes
WHERE BusinessDate = @BusinessDate 
  AND TradingSymbol LIKE @IndexName + '%'
ORDER BY ExpiryDate;

PRINT '=== BANKNIFTY PUT MINUS PROCESS ANALYSIS ===';
PRINT 'Business Date: ' + CAST(@BusinessDate AS VARCHAR);
PRINT 'Expiry Date: ' + CAST(@ExpiryDate AS VARCHAR);
PRINT '';

-- STEP 1: Get Spot Close
PRINT 'STEP 1: GET SPOT CLOSE';
DECLARE @SpotClose DECIMAL(18,2);
SELECT @SpotClose = ClosePrice
FROM HistoricalSpotData
WHERE TradingDate = @BusinessDate 
  AND IndexName = @IndexName;

DECLARE @CloseStrike DECIMAL(18,2) = ROUND(@SpotClose / 100, 0) * 100;

PRINT 'Spot Close: ' + CAST(@SpotClose AS VARCHAR);
PRINT 'Close Strike: ' + CAST(@CloseStrike AS VARCHAR);
PRINT '';

-- STEP 2: Get CALL Base Strike (First CE with LC > 0.05)
PRINT 'STEP 2: GET CALL BASE STRIKE (First CE with LC > 0.05)';

-- Get all CE quotes with max InsertionSequence
WITH LatestCEQuotes AS (
    SELECT 
        Strike,
        OptionType,
        LowerCircuitLimit,
        UpperCircuitLimit,
        ROW_NUMBER() OVER (ORDER BY Strike DESC) AS RowNum
    FROM (
        SELECT 
            Strike,
            OptionType,
            LowerCircuitLimit,
            UpperCircuitLimit,
            ROW_NUMBER() OVER (PARTITION BY Strike ORDER BY InsertionSequence DESC) AS SeqRank
        FROM MarketQuotes
        WHERE BusinessDate = @BusinessDate
          AND ExpiryDate = @ExpiryDate
          AND TradingSymbol LIKE @IndexName + '%'
          AND OptionType = 'CE'
    ) SubQ
    WHERE SeqRank = 1 
      AND LowerCircuitLimit > 0.05
)
SELECT TOP 1
    @CallBaseStrike = Strike,
    @CallBaseLc = LowerCircuitLimit,
    @CallBaseUc = UpperCircuitLimit
FROM LatestCEQuotes
ORDER BY Strike DESC;

DECLARE @CallBaseStrike DECIMAL(18,2);
DECLARE @CallBaseLc DECIMAL(18,2);
DECLARE @CallBaseUc DECIMAL(18,2);

-- Rerun the query to populate variables
WITH LatestCEQuotes AS (
    SELECT 
        Strike,
        OptionType,
        LowerCircuitLimit,
        UpperCircuitLimit,
        ROW_NUMBER() OVER (ORDER BY Strike DESC) AS RowNum
    FROM (
        SELECT 
            Strike,
            OptionType,
            LowerCircuitLimit,
            UpperCircuitLimit,
            ROW_NUMBER() OVER (PARTITION BY Strike ORDER BY InsertionSequence DESC) AS SeqRank
        FROM MarketQuotes
        WHERE BusinessDate = @BusinessDate
          AND ExpiryDate = @ExpiryDate
          AND TradingSymbol LIKE @IndexName + '%'
          AND OptionType = 'CE'
    ) SubQ
    WHERE SeqRank = 1 
      AND LowerCircuitLimit > 0.05
)
SELECT TOP 1
    @CallBaseStrike = Strike,
    @CallBaseLc = LowerCircuitLimit,
    @CallBaseUc = UpperCircuitLimit
FROM LatestCEQuotes
ORDER BY Strike DESC;

PRINT 'CALL Base Strike: ' + CAST(@CallBaseStrike AS VARCHAR) + ' CE';
PRINT 'CALL Base Strike LC: ' + CAST(@CallBaseLc AS VARCHAR);
PRINT 'CALL Base Strike UC: ' + CAST(@CallBaseUc AS VARCHAR);
PRINT '';

-- STEP 3: Get Close Strike PE UC (max InsertionSequence)
PRINT 'STEP 3: GET CLOSE STRIKE PE UC';

DECLARE @CloseStrikePeUc DECIMAL(18,2);
DECLARE @CloseStrikePeLc DECIMAL(18,2);

SELECT @CloseStrikePeUc = UpperCircuitLimit,
       @CloseStrikePeLc = LowerCircuitLimit
FROM (
    SELECT 
        UpperCircuitLimit,
        LowerCircuitLimit,
        ROW_NUMBER() OVER (ORDER BY InsertionSequence DESC) AS SeqRank
    FROM MarketQuotes
    WHERE BusinessDate = @BusinessDate
      AND ExpiryDate = @ExpiryDate
      AND Strike = @CloseStrike
      AND OptionType = 'PE'
) SubQ
WHERE SeqRank = 1;

PRINT 'Close Strike: ' + CAST(@CloseStrike AS VARCHAR);
PRINT CAST(@CloseStrike AS VARCHAR) + ' PE UC: ' + CAST(@CloseStrikePeUc AS VARCHAR);
PRINT CAST(@CloseStrike AS VARCHAR) + ' PE LC: ' + CAST(@CloseStrikePeLc AS VARCHAR);
PRINT '';

-- STEP 4: Calculate PUT MINUS (P-)
PRINT 'STEP 4: CALCULATE PUT MINUS (P-)';

DECLARE @PutMinus DECIMAL(18,2) = @CloseStrike - @CloseStrikePeUc;

PRINT 'P- = Close Strike - PE UC';
PRINT 'P- = ' + CAST(@CloseStrike AS VARCHAR) + ' - ' + CAST(@CloseStrikePeUc AS VARCHAR);
PRINT 'P- = ' + CAST(@PutMinus AS VARCHAR);
PRINT '';

IF @PutMinus < 0
    PRINT '⚠️ PUT MINUS IS NEGATIVE!';
ELSE
    PRINT '✅ PUT MINUS IS POSITIVE';
PRINT '';

-- STEP 5: Calculate Distance
PRINT 'STEP 5: CALCULATE DISTANCE';

DECLARE @Distance DECIMAL(18,2) = @PutMinus - @CallBaseStrike;

PRINT 'Distance = P- - CALL Base Strike';
PRINT 'Distance = ' + CAST(@PutMinus AS VARCHAR) + ' - ' + CAST(@CallBaseStrike AS VARCHAR);
PRINT 'Distance = ' + CAST(@Distance AS VARCHAR);
PRINT '';

IF @Distance < 0
    PRINT '⚠️ DISTANCE IS NEGATIVE!';
ELSE
    PRINT '✅ DISTANCE IS POSITIVE';
PRINT '';

-- STEP 6: Calculate Target PE Premium
PRINT 'STEP 6: CALCULATE TARGET PE PREMIUM';

DECLARE @TargetPePremium DECIMAL(18,2) = @CloseStrikePeUc - @Distance;

PRINT 'Target PE Premium = PE UC - Distance';
PRINT 'Target PE Premium = ' + CAST(@CloseStrikePeUc AS VARCHAR) + ' - (' + CAST(@Distance AS VARCHAR) + ')';
PRINT 'Target PE Premium = ' + CAST(@TargetPePremium AS VARCHAR);
PRINT '';

-- ANALYSIS
PRINT '=== ANALYSIS ===';
PRINT '';

IF @PutMinus < 0
BEGIN
    PRINT 'WHY IS PUT MINUS NEGATIVE?';
    PRINT '• PE UC (' + CAST(@CloseStrikePeUc AS VARCHAR) + ') > Close Strike (' + CAST(@CloseStrike AS VARCHAR) + ')';
    PRINT '• This means PUT option is very expensive';
    PRINT '• Market expects significant downward movement';
    PRINT '';
    
    DECLARE @ExcessPremium DECIMAL(18,2) = ABS(@PutMinus);
    PRINT 'EXCESS PUT PREMIUM: ' + CAST(@ExcessPremium AS VARCHAR);
    PRINT '';
    
    PRINT 'YOUR PROPOSED REDISTRIBUTION:';
    DECLARE @AdjustedCallUc DECIMAL(18,2) = @CallBaseUc - @ExcessPremium;
    DECLARE @AdjustedPutUc DECIMAL(18,2) = @CloseStrikePeUc + @ExcessPremium;
    
    PRINT '• Adjusted CALL UC = ' + CAST(@CallBaseUc AS VARCHAR) + ' - ' + CAST(@ExcessPremium AS VARCHAR) + ' = ' + CAST(@AdjustedCallUc AS VARCHAR);
    PRINT '• Adjusted PUT UC = ' + CAST(@CloseStrikePeUc AS VARCHAR) + ' + ' + CAST(@ExcessPremium AS VARCHAR) + ' = ' + CAST(@AdjustedPutUc AS VARCHAR);
    PRINT '';
    
    -- Recalculate with adjusted values
    DECLARE @NewPutMinus DECIMAL(18,2) = @CloseStrike - @AdjustedPutUc;
    DECLARE @NewDistance DECIMAL(18,2) = @NewPutMinus - @CallBaseStrike;
    DECLARE @NewTargetPePremium DECIMAL(18,2) = @AdjustedPutUc - @NewDistance;
    
    PRINT 'RECALCULATED VALUES WITH REDISTRIBUTION:';
    PRINT '• New P- = ' + CAST(@NewPutMinus AS VARCHAR);
    PRINT '• New Distance = ' + CAST(@NewDistance AS VARCHAR);
    PRINT '• New Target PE Premium = ' + CAST(@NewTargetPePremium AS VARCHAR);
END
ELSE
BEGIN
    PRINT '✅ No redistribution needed - PUT MINUS is positive';
END

PRINT '';
PRINT '=== VALIDATION WITH D1 DATA (10th Oct) ===';

-- Get D1 data
DECLARE @D1Date DATE = DATEADD(DAY, 1, @BusinessDate);
DECLARE @D1Low DECIMAL(18,2);
DECLARE @D1High DECIMAL(18,2);
DECLARE @D1Close DECIMAL(18,2);

SELECT 
    @D1Low = LowPrice,
    @D1High = HighPrice,
    @D1Close = ClosePrice
FROM HistoricalSpotData
WHERE TradingDate = @D1Date 
  AND IndexName = @IndexName;

PRINT 'D1 (10th Oct) Actual Values:';
PRINT '• Low: ' + CAST(@D1Low AS VARCHAR);
PRINT '• High: ' + CAST(@D1High AS VARCHAR);
PRINT '• Close: ' + CAST(@D1Close AS VARCHAR);
PRINT '';

-- Compare predictions
IF @Distance IS NOT NULL
BEGIN
    PRINT 'PREDICTION COMPARISON:';
    PRINT '• Predicted Range (using Distance): ' + CAST(@Distance AS VARCHAR);
    PRINT '• Actual Movement: Low=' + CAST(@D1Low - @SpotClose AS VARCHAR) + ', High=' + CAST(@D1High - @SpotClose AS VARCHAR);
END

PRINT '';
PRINT '✅ Analysis Complete!';

