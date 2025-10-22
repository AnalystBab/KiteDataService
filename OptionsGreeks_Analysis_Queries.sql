-- =============================================
-- ADVANCED OPTIONS GREEKS ANALYSIS QUERIES
-- =============================================
-- Based on Black-Scholes implementation from: https://gist.github.com/vishnus/860a53021bd047d4b7e5d1b7a0808743
-- Provides comprehensive Greeks analysis for NIFTY, SENSEX, BANKNIFTY options

-- =============================================
-- 1. LIVE GREEKS DASHBOARD (Current Session)
-- =============================================
SELECT 
    'LIVE GREEKS DASHBOARD' as Analysis,
    IndexName,
    COUNT(*) as TotalOptions,
    AVG(Delta) as AvgDelta,
    AVG(Gamma) as AvgGamma,
    AVG(Theta) as AvgTheta,
    AVG(Vega) as AvgVega,
    AVG(ImpliedVolatility) as AvgIV,
    AVG(ConfidenceScore) as AvgConfidence
FROM OptionsGreeks 
WHERE BusinessDate = CAST(GETDATE() AS DATE)
GROUP BY IndexName
ORDER BY IndexName;

-- =============================================
-- 2. NIFTY OPTIONS CHAIN WITH GREEKS (Like Sensibull)
-- =============================================
SELECT 
    'NIFTY OPTIONS CHAIN' as Analysis,
    Strike,
    OptionType,
    LastPrice as LTP,
    Delta,
    Gamma,
    Theta,
    Vega,
    ImpliedVolatility as IV,
    TheoreticalPrice,
    PriceDeviationPercent,
    StrikeType,
    PredictedLow,
    PredictedHigh,
    ConfidenceScore
FROM OptionsGreeks 
WHERE IndexName = 'NIFTY' 
    AND BusinessDate = CAST(GETDATE() AS DATE)
    AND ExpiryDate = (
        SELECT MIN(ExpiryDate) 
        FROM OptionsGreeks 
        WHERE IndexName = 'NIFTY' 
            AND BusinessDate = CAST(GETDATE() AS DATE)
            AND ExpiryDate >= CAST(GETDATE() AS DATE)
    )
ORDER BY Strike, OptionType;

-- =============================================
-- 3. HIGH CONFIDENCE TRADING OPPORTUNITIES
-- =============================================
SELECT 
    'HIGH CONFIDENCE OPPORTUNITIES' as Analysis,
    TradingSymbol,
    Strike,
    OptionType,
    LastPrice,
    TheoreticalPrice,
    PriceDeviationPercent,
    Delta,
    Gamma,
    Theta,
    PredictedLow,
    PredictedHigh,
    ConfidenceScore,
    MarketSentiment,
    Volume,
    OpenInterest
FROM OptionsGreeks 
WHERE BusinessDate = CAST(GETDATE() AS DATE)
    AND ConfidenceScore >= 80
    AND ABS(PriceDeviationPercent) >= 10  -- 10% deviation from theoretical
    AND Volume >= 1000
ORDER BY ConfidenceScore DESC, ABS(PriceDeviationPercent) DESC;

-- =============================================
-- 4. VOLATILITY ANALYSIS BY STRIKE
-- =============================================
SELECT 
    'VOLATILITY ANALYSIS' as Analysis,
    IndexName,
    Strike,
    OptionType,
    ImpliedVolatility,
    HistoricalVolatility,
    (ImpliedVolatility - HistoricalVolatility) as VolatilitySkew,
    StrikeType,
    LastPrice,
    TheoreticalPrice,
    PriceDeviationPercent
FROM OptionsGreeks 
WHERE BusinessDate = CAST(GETDATE() AS DATE)
    AND StrikeType = 'ATM'  -- Focus on ATM options
ORDER BY IndexName, Strike;

-- =============================================
-- 5. TIME DECAY ANALYSIS (THETA)
-- =============================================
SELECT 
    'TIME DECAY ANALYSIS' as Analysis,
    IndexName,
    ExpiryDate,
    DATEDIFF(day, CAST(GETDATE() AS DATE), ExpiryDate) as DaysToExpiry,
    COUNT(*) as OptionsCount,
    AVG(Theta) as AvgTheta,
    AVG(LastPrice) as AvgPrice,
    AVG(TimeValue) as AvgTimeValue,
    AVG(IntrinsicValue) as AvgIntrinsicValue
FROM OptionsGreeks 
WHERE BusinessDate = CAST(GETDATE() AS DATE)
    AND ExpiryDate >= CAST(GETDATE() AS DATE)
GROUP BY IndexName, ExpiryDate, DATEDIFF(day, CAST(GETDATE() AS DATE), ExpiryDate)
ORDER BY IndexName, DaysToExpiry;

-- =============================================
-- 6. DELTA NEUTRAL STRATEGIES
-- =============================================
SELECT 
    'DELTA NEUTRAL STRATEGIES' as Analysis,
    IndexName,
    Strike,
    CE_Delta,
    PE_Delta,
    CE_LastPrice,
    PE_LastPrice,
    (CE_Delta + PE_Delta) as CombinedDelta,
    ABS(CE_Delta + PE_Delta) as DeltaNeutralScore
FROM (
    SELECT 
        IndexName,
        Strike,
        MAX(CASE WHEN OptionType = 'CE' THEN Delta END) as CE_Delta,
        MAX(CASE WHEN OptionType = 'PE' THEN Delta END) as PE_Delta,
        MAX(CASE WHEN OptionType = 'CE' THEN LastPrice END) as CE_LastPrice,
        MAX(CASE WHEN OptionType = 'PE' THEN LastPrice END) as PE_LastPrice
    FROM OptionsGreeks 
    WHERE BusinessDate = CAST(GETDATE() AS DATE)
    GROUP BY IndexName, Strike
) DeltaData
WHERE CE_Delta IS NOT NULL AND PE_Delta IS NOT NULL
ORDER BY DeltaNeutralScore ASC, IndexName, Strike;

-- =============================================
-- 7. PREDICTION ACCURACY ANALYSIS
-- =============================================
SELECT 
    'PREDICTION ACCURACY' as Analysis,
    IndexName,
    StrikeType,
    COUNT(*) as SampleSize,
    AVG(ConfidenceScore) as AvgConfidence,
    AVG(ABS(PriceDeviationPercent)) as AvgAbsDeviation,
    STDEV(PriceDeviationPercent) as DeviationStdDev,
    MIN(PriceDeviationPercent) as MinDeviation,
    MAX(PriceDeviationPercent) as MaxDeviation
FROM OptionsGreeks 
WHERE BusinessDate = CAST(GETDATE() AS DATE)
    AND ConfidenceScore >= 70
GROUP BY IndexName, StrikeType
ORDER BY IndexName, StrikeType;

-- =============================================
-- 8. RISK METRICS BY STRIKE
-- =============================================
SELECT 
    'RISK METRICS ANALYSIS' as Analysis,
    TradingSymbol,
    Strike,
    OptionType,
    LastPrice,
    MaximumLoss,
    MaximumGain,
    BreakEvenPoint,
    Delta,
    Gamma,
    Vega,
    RiskRewardRatio = CASE 
        WHEN MaximumLoss > 0 THEN MaximumGain / MaximumLoss 
        ELSE NULL 
    END,
    StrikeType,
    MarketSentiment
FROM OptionsGreeks 
WHERE BusinessDate = CAST(GETDATE() AS DATE)
    AND Strike BETWEEN 25000 AND 26000  -- NIFTY range
    AND IndexName = 'NIFTY'
ORDER BY Strike, OptionType;

-- =============================================
-- 9. CIRCUIT LIMITS WITH GREEKS
-- =============================================
SELECT 
    'CIRCUIT LIMITS WITH GREEKS' as Analysis,
    og.TradingSymbol,
    og.Strike,
    og.OptionType,
    og.LastPrice,
    og.LowerCircuitLimit,
    og.UpperCircuitLimit,
    og.Delta,
    og.Gamma,
    og.Theta,
    og.ImpliedVolatility,
    og.PredictedLow,
    og.PredictedHigh,
    og.ConfidenceScore,
    -- Circuit limit analysis
    (og.LastPrice - og.LowerCircuitLimit) / og.LastPrice * 100 as LC_Distance_Percent,
    (og.UpperCircuitLimit - og.LastPrice) / og.LastPrice * 100 as UC_Distance_Percent,
    -- Greeks at circuit limits
    CASE 
        WHEN og.LastPrice = og.LowerCircuitLimit THEN 'AT_LC'
        WHEN og.LastPrice = og.UpperCircuitLimit THEN 'AT_UC'
        WHEN (og.LastPrice - og.LowerCircuitLimit) / og.LastPrice < 0.05 THEN 'NEAR_LC'
        WHEN (og.UpperCircuitLimit - og.LastPrice) / og.LastPrice < 0.05 THEN 'NEAR_UC'
        ELSE 'NORMAL'
    END as CircuitStatus
FROM OptionsGreeks og
WHERE og.BusinessDate = CAST(GETDATE() AS DATE)
    AND og.IndexName = 'NIFTY'
    AND og.LastPrice > 0
ORDER BY og.Strike, og.OptionType;

-- =============================================
-- 10. ADVANCED ANALYTICS SUMMARY
-- =============================================
SELECT 
    'ADVANCED ANALYTICS SUMMARY' as Analysis,
    IndexName,
    COUNT(*) as TotalOptions,
    AVG(ImpliedVolatility) as AvgIV,
    AVG(HistoricalVolatility) as AvgHV,
    AVG(ImpliedVolatility - HistoricalVolatility) as AvgVolSkew,
    AVG(ConfidenceScore) as AvgConfidence,
    AVG(ABS(PriceDeviationPercent)) as AvgPriceDeviation,
    COUNT(CASE WHEN MarketSentiment = 'BULLISH' THEN 1 END) as BullishCount,
    COUNT(CASE WHEN MarketSentiment = 'BEARISH' THEN 1 END) as BearishCount,
    COUNT(CASE WHEN MarketSentiment = 'NEUTRAL' THEN 1 END) as NeutralCount,
    COUNT(CASE WHEN StrikeType = 'ITM' THEN 1 END) as ITMCount,
    COUNT(CASE WHEN StrikeType = 'ATM' THEN 1 END) as ATMCount,
    COUNT(CASE WHEN StrikeType = 'OTM' THEN 1 END) as OTMCount
FROM OptionsGreeks 
WHERE BusinessDate = CAST(GETDATE() AS DATE)
GROUP BY IndexName
ORDER BY IndexName;

-- =============================================
-- USAGE NOTES:
-- =============================================
-- 1. These queries provide comprehensive Greeks analysis similar to Sensibull
-- 2. All calculations are based on Black-Scholes model with real-time data
-- 3. Greeks are calculated every minute for all 6,369 options
-- 4. Includes advanced features like prediction accuracy and risk metrics
-- 5. Circuit limits are integrated with Greeks for complete risk analysis
-- 6. Confidence scores help identify high-probability trading opportunities


