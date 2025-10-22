-- 🎯 FINAL PREDICTION VALIDATION FOR 2025-10-13
-- Comparing our predictions vs actual SENSEX data

PRINT '============================================'
PRINT '🎯 PREDICTION VALIDATION - SENSEX 2025-10-13'
PRINT '============================================'
PRINT ''

-- Get actual SENSEX data for 2025-10-13
DECLARE @ActualOpen DECIMAL(18,2)
DECLARE @ActualHigh DECIMAL(18,2)
DECLARE @ActualLow DECIMAL(18,2)
DECLARE @ActualClose DECIMAL(18,2)

SELECT 
    @ActualOpen = OpenPrice,
    @ActualHigh = HighPrice,
    @ActualLow = LowPrice,
    @ActualClose = ClosePrice
FROM HistoricalSpotData
WHERE IndexName = 'SENSEX' 
  AND TradingDate = '2025-10-13'

-- Our predictions
DECLARE @PredictedLow DECIMAL(18,2) = 80400
DECLARE @PredictedHigh DECIMAL(18,2) = 82650
DECLARE @PredictedClose DECIMAL(18,2) = 82500

PRINT '📊 ACTUAL DATA (2025-10-13):'
PRINT '   Open:  ' + CAST(@ActualOpen AS VARCHAR(20))
PRINT '   High:  ' + CAST(@ActualHigh AS VARCHAR(20))
PRINT '   Low:   ' + CAST(@ActualLow AS VARCHAR(20))
PRINT '   Close: ' + CAST(@ActualClose AS VARCHAR(20))
PRINT ''

PRINT '🎯 OUR PREDICTIONS:'
PRINT '   Low:   ' + CAST(@PredictedLow AS VARCHAR(20))
PRINT '   High:  ' + CAST(@PredictedHigh AS VARCHAR(20))
PRINT '   Close: ' + CAST(@PredictedClose AS VARCHAR(20))
PRINT ''

PRINT '📈 PREDICTION ACCURACY:'
PRINT ''

-- LOW PREDICTION ACCURACY
DECLARE @LowError DECIMAL(18,2) = ABS(@ActualLow - @PredictedLow)
DECLARE @LowErrorPct DECIMAL(18,4) = (@LowError / @ActualLow) * 100
DECLARE @LowStatus VARCHAR(10) = CASE 
    WHEN @LowErrorPct < 0.5 THEN '✅ EXCELLENT'
    WHEN @LowErrorPct < 1.0 THEN '✅ GOOD'
    WHEN @LowErrorPct < 2.0 THEN '⚠️ MODERATE'
    ELSE '❌ POOR'
END

PRINT '   LOW Prediction:'
PRINT '      Predicted: ' + CAST(@PredictedLow AS VARCHAR(20))
PRINT '      Actual:    ' + CAST(@ActualLow AS VARCHAR(20))
PRINT '      Error:     ' + CAST(@LowError AS VARCHAR(20)) + ' points'
PRINT '      Error %:   ' + CAST(@LowErrorPct AS VARCHAR(20)) + '%'
PRINT '      Status:    ' + @LowStatus
PRINT ''

-- HIGH PREDICTION ACCURACY
DECLARE @HighError DECIMAL(18,2) = ABS(@ActualHigh - @PredictedHigh)
DECLARE @HighErrorPct DECIMAL(18,4) = (@HighError / @ActualHigh) * 100
DECLARE @HighStatus VARCHAR(10) = CASE 
    WHEN @HighErrorPct < 0.5 THEN '✅ EXCELLENT'
    WHEN @HighErrorPct < 1.0 THEN '✅ GOOD'
    WHEN @HighErrorPct < 2.0 THEN '⚠️ MODERATE'
    ELSE '❌ POOR'
END

PRINT '   HIGH Prediction:'
PRINT '      Predicted: ' + CAST(@PredictedHigh AS VARCHAR(20))
PRINT '      Actual:    ' + CAST(@ActualHigh AS VARCHAR(20))
PRINT '      Error:     ' + CAST(@HighError AS VARCHAR(20)) + ' points'
PRINT '      Error %:   ' + CAST(@HighErrorPct AS VARCHAR(20)) + '%'
PRINT '      Status:    ' + @HighStatus
PRINT ''

-- CLOSE PREDICTION ACCURACY
DECLARE @CloseError DECIMAL(18,2) = ABS(@ActualClose - @PredictedClose)
DECLARE @CloseErrorPct DECIMAL(18,4) = (@CloseError / @ActualClose) * 100
DECLARE @CloseStatus VARCHAR(10) = CASE 
    WHEN @CloseErrorPct < 0.5 THEN '✅ EXCELLENT'
    WHEN @CloseErrorPct < 1.0 THEN '✅ GOOD'
    WHEN @CloseErrorPct < 2.0 THEN '⚠️ MODERATE'
    ELSE '❌ POOR'
END

PRINT '   CLOSE Prediction:'
PRINT '      Predicted: ' + CAST(@PredictedClose AS VARCHAR(20))
PRINT '      Actual:    ' + CAST(@ActualClose AS VARCHAR(20))
PRINT '      Error:     ' + CAST(@CloseError AS VARCHAR(20)) + ' points'
PRINT '      Error %:   ' + CAST(@CloseErrorPct AS VARCHAR(20)) + '%'
PRINT '      Status:    ' + @CloseStatus
PRINT ''

-- OVERALL ACCURACY
DECLARE @OverallErrorPct DECIMAL(18,4) = (@LowErrorPct + @HighErrorPct + @CloseErrorPct) / 3
PRINT '🎯 OVERALL ACCURACY:'
PRINT '   Average Error: ' + CAST(@OverallErrorPct AS VARCHAR(20)) + '%'
PRINT '   Overall Status: ' + CASE 
    WHEN @OverallErrorPct < 0.5 THEN '✅✅✅ EXCELLENT - Pattern engine working perfectly!'
    WHEN @OverallErrorPct < 1.0 THEN '✅✅ VERY GOOD - High accuracy achieved'
    WHEN @OverallErrorPct < 2.0 THEN '✅ GOOD - Acceptable accuracy'
    ELSE '⚠️ NEEDS REFINEMENT'
END
PRINT ''

PRINT '============================================'
PRINT '🔍 PATTERN ANALYSIS'
PRINT '============================================'

-- Check if our KEY pattern worked: Target CE Premium ≈ PE UC at LOW
PRINT ''
PRINT '📌 KEY PATTERN: Target CE Premium ≈ PE UC at LOW Strike'
PRINT ''

-- Get 10th Oct reference data
DECLARE @D0_TargetCePremium DECIMAL(18,2)
SELECT @D0_TargetCePremium = LabelValue
FROM StrategyLabels
WHERE IndexName = 'SENSEX'
  AND BusinessDate = '2025-10-10'
  AND ExpiryDate = '2025-10-16'
  AND LabelName = 'TARGET_CE_PREMIUM'

PRINT '   D0 (10th Oct) Target CE Premium: ' + CAST(@D0_TargetCePremium AS VARCHAR(20))

-- Check what PE UC was at the actual LOW strike
DECLARE @LowStrike DECIMAL(18,2) = ROUND(@ActualLow / 100, 0) * 100
DECLARE @PeUcAtLow DECIMAL(18,2)

SELECT @PeUcAtLow = UpperCircuitLimit
FROM MarketQuotes
WHERE TradingSymbol LIKE 'SENSEX%PE'
  AND Strike = @LowStrike
  AND BusinessDate = '2025-10-13'
  AND InsertionSequence = (
      SELECT MAX(InsertionSequence)
      FROM MarketQuotes
      WHERE TradingSymbol LIKE 'SENSEX%PE'
        AND Strike = @LowStrike
        AND BusinessDate = '2025-10-13'
  )

PRINT '   Actual LOW: ' + CAST(@ActualLow AS VARCHAR(20))
PRINT '   Low Strike: ' + CAST(@LowStrike AS VARCHAR(20))
PRINT '   PE UC at Low Strike (D1): ' + CAST(ISNULL(@PeUcAtLow, 0) AS VARCHAR(20))
PRINT ''

IF @PeUcAtLow IS NOT NULL
BEGIN
    DECLARE @PatternMatch DECIMAL(18,4) = ABS(@D0_TargetCePremium - @PeUcAtLow)
    DECLARE @PatternMatchPct DECIMAL(18,4) = (@PatternMatch / @D0_TargetCePremium) * 100
    
    PRINT '   Pattern Match Analysis:'
    PRINT '      Target CE Premium: ' + CAST(@D0_TargetCePremium AS VARCHAR(20))
    PRINT '      PE UC at Low:      ' + CAST(@PeUcAtLow AS VARCHAR(20))
    PRINT '      Difference:        ' + CAST(@PatternMatch AS VARCHAR(20))
    PRINT '      Match %:           ' + CAST((100 - @PatternMatchPct) AS VARCHAR(20)) + '%'
    PRINT ''
    PRINT '   Pattern Status: ' + CASE 
        WHEN @PatternMatchPct < 5 THEN '✅✅✅ EXCELLENT MATCH - Pattern confirmed!'
        WHEN @PatternMatchPct < 10 THEN '✅✅ VERY GOOD MATCH'
        WHEN @PatternMatchPct < 20 THEN '✅ GOOD MATCH'
        ELSE '⚠️ PATTERN NEEDS REFINEMENT'
    END
END
ELSE
BEGIN
    PRINT '   ⚠️ No PE UC data available at Low Strike for validation'
END

PRINT ''
PRINT '============================================'
PRINT '✅ VALIDATION COMPLETE'
PRINT '============================================'

