-- =====================================================
-- Insert CALL_MINUS Strategy Labels (9th Oct SENSEX)
-- =====================================================

-- CALL_MINUS Process Labels
INSERT INTO StrategyLabels 
(BusinessDate, IndexName, ProcessType, LabelName, LabelValue, Formula, [Description], StepNumber, SourceLabels)
VALUES 
('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_VALUE', 80179.15, 
 'CLOSE_STRIKE - CLOSE_CE_UC_D0', 'Base level from CE UC subtraction', 1, 
 'CLOSE_STRIKE,CLOSE_CE_UC_D0'),

('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_TO_CALL_BASE_DISTANCE', 579.15, 
 'CALL_MINUS_VALUE - CALL_BASE_STRIKE', 'Gap between CALL_MINUS and Call Base Strike (PREDICTED RANGE!)', 2, 
 'CALL_MINUS_VALUE,CALL_BASE_STRIKE'),

('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_TARGET_CE_PREMIUM_ALT1', 1341.70, 
 'CLOSE_CE_UC_D0 - CALL_MINUS_TO_CALL_BASE_DISTANCE', 'CE premium target for low strike identification', 3, 
 'CLOSE_CE_UC_D0,CALL_MINUS_TO_CALL_BASE_DISTANCE'),

('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_TARGET_PE_PREMIUM_ALT2', 860.25, 
 'CLOSE_PE_UC_D0 - CALL_MINUS_TO_CALL_BASE_DISTANCE', 'PE premium target for low strike identification', 4, 
 'CLOSE_PE_UC_D0,CALL_MINUS_TO_CALL_BASE_DISTANCE'),

('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_PE_UC_MATCH_1341', 82000.00, 
 'PE UC ≈ 1341.70 (Actual: 1341.25, Diff: 0.45)', 'Strike where PE UC matches target premium (PRIMARY LOW)', 5, 
 'CALL_MINUS_TARGET_CE_PREMIUM_ALT1'),

('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_PE_UC_MATCH_860', 81400.00, 
 'PE UC ≈ 860.25 (Actual: 865.50, Diff: 5.25)', 'Strike where PE UC matches target premium (SECONDARY LOW)', 6, 
 'CALL_MINUS_TARGET_PE_PREMIUM_ALT2'),

('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_PE_UC_MATCH_579', 80900.00, 
 'PE UC ≈ 579.15 (Actual: 574.70, Diff: 4.45)', 'Strike where PE UC matches distance value (TERTIARY LOW)', 7, 
 'CALL_MINUS_TO_CALL_BASE_DISTANCE'),

('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_SPOT_LOW_PRIMARY', 82000.00, 
 'First matched strike (82000 PE)', 'Primary SPOT LOW prediction for Day 1', 8, 
 'CALL_MINUS_PE_UC_MATCH_1341'),

('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_SPOT_LOW_SECONDARY', 81400.00, 
 'Second matched strike (81400 PE)', 'Secondary SPOT LOW prediction (deeper support)', 9, 
 'CALL_MINUS_PE_UC_MATCH_860'),

('2025-10-09', 'SENSEX', 'CALL_MINUS', 'CALL_MINUS_SPOT_LOW_TERTIARY', 80900.00, 
 'Third matched strike (80900 PE)', 'Tertiary SPOT LOW prediction (deepest support)', 10, 
 'CALL_MINUS_PE_UC_MATCH_579');

PRINT '✅ CALL_MINUS strategy labels inserted!';
GO

-- =====================================================
-- Insert VALIDATION Labels (10th Oct Actual)
-- =====================================================

-- Day 1 Actual Data
INSERT INTO StrategyLabels 
(BusinessDate, IndexName, ProcessType, LabelName, LabelValue, Formula, [Description], StepNumber)
VALUES 
('2025-10-09', 'SENSEX', 'VALIDATION', 'ACTUAL_SPOT_OPEN_D1', 82075.45, 
 'HistoricalSpotData.OpenPrice', 'Actual SENSEX open on Day 1 (10th Oct)', 0),

('2025-10-09', 'SENSEX', 'VALIDATION', 'ACTUAL_SPOT_HIGH_D1', 82654.11, 
 'HistoricalSpotData.HighPrice', 'Actual SENSEX high on Day 1 (10th Oct)', 0),

('2025-10-09', 'SENSEX', 'VALIDATION', 'ACTUAL_SPOT_LOW_D1', 82072.93, 
 'HistoricalSpotData.LowPrice', 'Actual SENSEX low on Day 1 (10th Oct)', 0),

('2025-10-09', 'SENSEX', 'VALIDATION', 'ACTUAL_SPOT_CLOSE_D1', 82500.82, 
 'HistoricalSpotData.ClosePrice', 'Actual SENSEX close on Day 1 (10th Oct)', 0),

('2025-10-09', 'SENSEX', 'VALIDATION', 'ACTUAL_DAY_RANGE_D1', 581.18, 
 'ACTUAL_SPOT_HIGH_D1 - ACTUAL_SPOT_LOW_D1', 'Actual day range on 10th Oct', 0);

PRINT '✅ Validation data inserted!';
GO

-- =====================================================
-- Insert ACCURACY Metrics
-- =====================================================

INSERT INTO StrategyLabels 
(BusinessDate, IndexName, ProcessType, LabelName, LabelValue, Formula, [Description], StepNumber, SourceLabels)
VALUES 
('2025-10-09', 'SENSEX', 'ACCURACY', 'HIGH_PREDICTION_ERROR', 75.41, 
 'ACTUAL_SPOT_HIGH_D1 - PUT_MINUS_PREDICTED_LEVEL', 'Difference between predicted and actual high', 0, 
 'ACTUAL_SPOT_HIGH_D1,PUT_MINUS_PREDICTED_LEVEL'),

('2025-10-09', 'SENSEX', 'ACCURACY', 'HIGH_PREDICTION_ACCURACY_PCT', 99.09, 
 '(1 - (75.41 / 82654.11)) * 100', 'Percentage accuracy of high prediction', 0, 
 'HIGH_PREDICTION_ERROR,ACTUAL_SPOT_HIGH_D1'),

('2025-10-09', 'SENSEX', 'ACCURACY', 'LOW_PREDICTION_ERROR', 72.93, 
 'ACTUAL_SPOT_LOW_D1 - CALL_MINUS_SPOT_LOW_PRIMARY', 'Difference between predicted and actual low', 0, 
 'ACTUAL_SPOT_LOW_D1,CALL_MINUS_SPOT_LOW_PRIMARY'),

('2025-10-09', 'SENSEX', 'ACCURACY', 'LOW_PREDICTION_ACCURACY_PCT', 99.11, 
 '(1 - (72.93 / 82072.93)) * 100', 'Percentage accuracy of low prediction', 0, 
 'LOW_PREDICTION_ERROR,ACTUAL_SPOT_LOW_D1'),

('2025-10-09', 'SENSEX', 'ACCURACY', 'RANGE_PREDICTION_ERROR', 2.03, 
 'ACTUAL_DAY_RANGE_D1 - CALL_MINUS_TO_CALL_BASE_DISTANCE', 'Difference between predicted and actual range', 0, 
 'ACTUAL_DAY_RANGE_D1,CALL_MINUS_TO_CALL_BASE_DISTANCE'),

('2025-10-09', 'SENSEX', 'ACCURACY', 'RANGE_PREDICTION_ACCURACY_PCT', 99.65, 
 '(1 - (2.03 / 581.18)) * 100', 'Percentage accuracy of range prediction', 0, 
 'RANGE_PREDICTION_ERROR,ACTUAL_DAY_RANGE_D1');

PRINT '✅ Accuracy metrics inserted!';
GO

-- =====================================================
-- View Complete Strategy Analysis
-- =====================================================

SELECT 
    ProcessType,
    StepNumber,
    LabelName,
    LabelValue,
    [Description]
FROM StrategyLabels
WHERE BusinessDate = '2025-10-09' 
  AND IndexName = 'SENSEX'
  AND ProcessType IN ('CALL_MINUS', 'VALIDATION', 'ACCURACY')
ORDER BY ProcessType, StepNumber;

PRINT '✅ CALL_MINUS strategy complete and validated!';

