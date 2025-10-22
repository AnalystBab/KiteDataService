-- ========================================================================
-- LIVE PREDICTION VALIDATION FOR 2025-10-13
-- Using 2025-10-10 Patterns to Predict Today's Market
-- ========================================================================

-- Step 1: Get Reference Data from 2025-10-10 (D0)
SELECT '========== REFERENCE DATA: 2025-10-10 (D0) ==========' as Info;

SELECT 
    LabelName,
    LabelValue,
    Formula,
    Description
FROM StrategyLabels
WHERE BusinessDate = '2025-10-10'
    AND IndexName = 'SENSEX'
    AND LabelName IN (
        'SPOT_CLOSE_D0',
        'CLOSE_STRIKE',
        'CLOSE_CE_UC_D0',
        'CLOSE_PE_UC_D0',
        'CALL_BASE_STRIKE',
        'PUT_BASE_STRIKE',
        'CALL_MINUS_TO_CALL_BASE_DISTANCE',
        'TARGET_CE_PREMIUM',
        'TARGET_PE_PREMIUM',
        'ADJUSTED_LOW_PREDICTION_PREMIUM',
        'BOUNDARY_UPPER',
        'BOUNDARY_LOWER'
    )
ORDER BY LabelName;


-- Step 2: Get Today's Live Data (2025-10-13)
SELECT '========== LIVE DATA: 2025-10-13 (TODAY) ==========' as Info;

WITH LatestLiveData AS (
    SELECT 
        i.Strike,
        i.InstrumentType,
        mq.UpperCircuitLimit,
        mq.LowerCircuitLimit,
        mq.LastPrice,
        mq.RecordDateTime,
        ROW_NUMBER() OVER (PARTITION BY i.Strike, i.InstrumentType ORDER BY mq.InsertionSequence DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE mq.BusinessDate = '2025-10-13'
        AND i.TradingSymbol LIKE 'SENSEX%OCT%'
        AND i.Strike IN (82000, 82100, 82200)
        AND i.InstrumentType IN ('CE', 'PE')
)
SELECT 
    Strike,
    InstrumentType,
    UpperCircuitLimit as UC,
    LowerCircuitLimit as LC,
    LastPrice,
    CONVERT(VARCHAR(19), RecordDateTime, 120) as UpdateTime
FROM LatestLiveData
WHERE rn = 1
ORDER BY Strike, InstrumentType;


-- Step 3: Calculate Today's Strategy Labels (Live)
SELECT '========== CALCULATED LABELS FOR TODAY (2025-10-13) ==========' as Info;

WITH LiveSpot AS (
    -- Using live spot from user's platform: 82,151.66
    SELECT 82151.66 as SpotClose
),
CloseStrikeCalc AS (
    SELECT 
        SpotClose,
        FLOOR(SpotClose / 100) * 100 as CloseStrike
    FROM LiveSpot
),
LiveUC AS (
    SELECT 
        i.Strike,
        i.InstrumentType,
        mq.UpperCircuitLimit,
        ROW_NUMBER() OVER (PARTITION BY i.Strike, i.InstrumentType ORDER BY mq.InsertionSequence DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE mq.BusinessDate = '2025-10-13'
        AND i.TradingSymbol LIKE 'SENSEX%OCT%'
        AND i.Strike = (SELECT CloseStrike FROM CloseStrikeCalc)
        AND i.InstrumentType IN ('CE', 'PE')
),
BaseStrikes AS (
    SELECT 
        82000 as CallBaseStrike,  -- From live data verification
        82200 as PutBaseStrike    -- From live data verification
)
SELECT 
    'SPOT_CLOSE_LIVE' as LabelName,
    cs.SpotClose as LabelValue,
    'Live spot from trading platform' as Description
FROM CloseStrikeCalc cs

UNION ALL

SELECT 
    'CLOSE_STRIKE_LIVE' as LabelName,
    cs.CloseStrike as LabelValue,
    'FLOOR(SPOT_CLOSE / 100) * 100' as Description
FROM CloseStrikeCalc cs

UNION ALL

SELECT 
    'CLOSE_CE_UC_LIVE' as LabelName,
    uc.UpperCircuitLimit as LabelValue,
    'Live CE UC for close strike' as Description
FROM LiveUC uc
WHERE uc.InstrumentType = 'CE' AND uc.rn = 1

UNION ALL

SELECT 
    'CLOSE_PE_UC_LIVE' as LabelName,
    uc.UpperCircuitLimit as LabelValue,
    'Live PE UC for close strike' as Description
FROM LiveUC uc
WHERE uc.InstrumentType = 'PE' AND uc.rn = 1

UNION ALL

SELECT 
    'CALL_BASE_STRIKE_LIVE' as LabelName,
    CAST(bs.CallBaseStrike as decimal(18,2)) as LabelValue,
    'First CE < CLOSE_STRIKE with LC > 0.05' as Description
FROM BaseStrikes bs

UNION ALL

SELECT 
    'PUT_BASE_STRIKE_LIVE' as LabelName,
    CAST(bs.PutBaseStrike as decimal(18,2)) as LabelValue,
    'First PE > CLOSE_STRIKE with LC > 0.05' as Description
FROM BaseStrikes bs

UNION ALL

SELECT 
    'CALL_MINUS_VALUE_LIVE' as LabelName,
    (cs.CloseStrike - uc.UpperCircuitLimit) as LabelValue,
    'CLOSE_STRIKE - CLOSE_CE_UC (Live)' as Description
FROM CloseStrikeCalc cs
CROSS JOIN (SELECT UpperCircuitLimit FROM LiveUC WHERE InstrumentType = 'CE' AND rn = 1) uc

UNION ALL

SELECT 
    'CALL_MINUS_DISTANCE_LIVE' as LabelName,
    ((cs.CloseStrike - uc.UpperCircuitLimit) - bs.CallBaseStrike) as LabelValue,
    'CALL_MINUS - CALL_BASE_STRIKE (Live)' as Description
FROM CloseStrikeCalc cs
CROSS JOIN (SELECT UpperCircuitLimit FROM LiveUC WHERE InstrumentType = 'CE' AND rn = 1) uc
CROSS JOIN BaseStrikes bs

UNION ALL

SELECT 
    'TARGET_CE_PREMIUM_LIVE' as LabelName,
    (uc.UpperCircuitLimit - ((cs.CloseStrike - uc.UpperCircuitLimit) - bs.CallBaseStrike)) as LabelValue,
    'CLOSE_CE_UC - CALL_MINUS_DISTANCE (Live)' as Description
FROM CloseStrikeCalc cs
CROSS JOIN (SELECT UpperCircuitLimit FROM LiveUC WHERE InstrumentType = 'CE' AND rn = 1) uc
CROSS JOIN BaseStrikes bs;


-- Step 4: Pattern Matching - Find Strikes with UC ≈ TARGET_CE_PREMIUM
SELECT '========== PATTERN DISCOVERY: TARGET_CE_PREMIUM MATCHES ==========' as Info;

WITH ReferenceLabels AS (
    SELECT LabelValue as TargetCePremium
    FROM StrategyLabels
    WHERE BusinessDate = '2025-10-10'
        AND IndexName = 'SENSEX'
        AND LabelName = 'TARGET_CE_PREMIUM'
),
LiveOptions AS (
    SELECT 
        i.Strike,
        i.InstrumentType,
        mq.UpperCircuitLimit,
        mq.LowerCircuitLimit,
        mq.LastPrice,
        ROW_NUMBER() OVER (PARTITION BY i.Strike, i.InstrumentType ORDER BY mq.InsertionSequence DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE mq.BusinessDate = '2025-10-13'
        AND i.TradingSymbol LIKE 'SENSEX%OCT%'
        AND i.InstrumentType = 'PE'
)
SELECT 
    lo.Strike,
    lo.InstrumentType,
    lo.UpperCircuitLimit as PE_UC,
    rl.TargetCePremium as Target_From_2025_10_10,
    ABS(lo.UpperCircuitLimit - rl.TargetCePremium) as Difference,
    CAST((ABS(lo.UpperCircuitLimit - rl.TargetCePremium) / rl.TargetCePremium * 100) AS DECIMAL(10,2)) as Error_Pct,
    CASE 
        WHEN ABS(lo.UpperCircuitLimit - rl.TargetCePremium) < 50 THEN '🎯 STRONG MATCH - Potential Support Level'
        WHEN ABS(lo.UpperCircuitLimit - rl.TargetCePremium) < 100 THEN '✅ GOOD MATCH - Watch this level'
        ELSE '⚠️ No significant match'
    END as Pattern_Status
FROM LiveOptions lo
CROSS JOIN ReferenceLabels rl
WHERE lo.rn = 1
    AND ABS(lo.UpperCircuitLimit - rl.TargetCePremium) < 200
ORDER BY ABS(lo.UpperCircuitLimit - rl.TargetCePremium);


-- Step 5: Prediction Summary
SELECT '========== PREDICTION SUMMARY ==========' as Info;

WITH Reference2025_10_10 AS (
    SELECT 
        MAX(CASE WHEN LabelName = 'SPOT_CLOSE_D0' THEN LabelValue END) as D0_SpotClose,
        MAX(CASE WHEN LabelName = 'TARGET_CE_PREMIUM' THEN LabelValue END) as TargetCePremium,
        MAX(CASE WHEN LabelName = 'ADJUSTED_LOW_PREDICTION_PREMIUM' THEN LabelValue END) as LowPredictionPremium,
        MAX(CASE WHEN LabelName = 'BOUNDARY_UPPER' THEN LabelValue END) as BoundaryUpper,
        MAX(CASE WHEN LabelName = 'BOUNDARY_LOWER' THEN LabelValue END) as BoundaryLower
    FROM StrategyLabels
    WHERE BusinessDate = '2025-10-10'
        AND IndexName = 'SENSEX'
),
Live2025_10_13 AS (
    SELECT 
        82151.66 as CurrentSpot,
        82100 as CloseStrike,
        3660.60 as CloseCeUc,
        1766.40 as ClosePeUc,
        82000 as CallBaseStrike,
        82200 as PutBaseStrike
)
SELECT 
    '2025-10-10 Reference Spot' as Metric,
    CAST(r.D0_SpotClose AS VARCHAR(20)) as Reference_Value,
    CAST(l.CurrentSpot AS VARCHAR(20)) as Live_Value,
    CAST((l.CurrentSpot - r.D0_SpotClose) AS VARCHAR(20)) as Change,
    CAST(((l.CurrentSpot - r.D0_SpotClose) / r.D0_SpotClose * 100) AS VARCHAR(20)) as Change_Pct
FROM Reference2025_10_10 r
CROSS JOIN Live2025_10_13 l

UNION ALL

SELECT 
    'Predicted Low (TARGET_CE_PREMIUM)' as Metric,
    CAST(r.TargetCePremium AS VARCHAR(20)) as Reference_Value,
    'TBD (End of Day)' as Live_Value,
    'Pending' as Change,
    'Pending' as Change_Pct
FROM Reference2025_10_10 r

UNION ALL

SELECT 
    'Predicted Boundary Upper' as Metric,
    CAST(r.BoundaryUpper AS VARCHAR(20)) as Reference_Value,
    'TBD (End of Day)' as Live_Value,
    'Pending' as Change,
    'Pending' as Change_Pct
FROM Reference2025_10_10 r

UNION ALL

SELECT 
    'Predicted Boundary Lower' as Metric,
    CAST(r.BoundaryLower AS VARCHAR(20)) as Reference_Value,
    'TBD (End of Day)' as Live_Value,
    'Pending' as Change,
    'Pending' as Change_Pct
FROM Reference2025_10_10 r;


-- Step 6: Real-time Validation Notes
SELECT '========== VALIDATION NOTES ==========' as Info;

SELECT 
    'Current Time' as Note,
    CONVERT(VARCHAR(19), GETDATE(), 120) as Value
UNION ALL
SELECT 
    'Market Status' as Note,
    CASE 
        WHEN CAST(GETDATE() AS TIME) BETWEEN '09:15:00' AND '15:30:00' THEN 'OPEN'
        ELSE 'CLOSED'
    END as Value
UNION ALL
SELECT 
    'Live Spot (User Platform)' as Note,
    '82,151.66' as Value
UNION ALL
SELECT 
    'Pattern Engine Status' as Note,
    'ACTIVE - Monitoring TARGET_CE_PREMIUM matches' as Value
UNION ALL
SELECT 
    'Prediction Validation' as Note,
    'Will be confirmed at EOD when actual High/Low/Close are available' as Value;

