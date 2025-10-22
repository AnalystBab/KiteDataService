-- =====================================================
-- Create StrategyLabels Table
-- Stores labeled calculation components for strategy analysis
-- Like OHLC for candles, but for PUT_MINUS/CALL_MINUS calculations
-- =====================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StrategyLabels')
BEGIN
    CREATE TABLE StrategyLabels (
        Id BIGINT PRIMARY KEY IDENTITY(1,1),
        
        -- Date and Index Information
        BusinessDate DATE NOT NULL,
        IndexName NVARCHAR(20) NOT NULL,
        
        -- Strategy Process Information
        ProcessType NVARCHAR(50) NOT NULL, -- 'PUT_MINUS', 'CALL_MINUS', 'BASE_DATA'
        LabelName NVARCHAR(100) NOT NULL, -- 'SPOT_CLOSE_D0', 'PUT_MINUS_VALUE', etc.
        
        -- Calculation Details
        LabelValue DECIMAL(18,2) NOT NULL,
        Formula NVARCHAR(500) NOT NULL,
        [Description] NVARCHAR(1000) NOT NULL,
        StepNumber INT NOT NULL,
        SourceLabels NVARCHAR(500) NULL, -- Comma-separated source labels
        
        -- Optional Context
        TargetStrike DECIMAL(10,2) NULL,
        ExpiryDate DATE NULL,
        OptionType NVARCHAR(2) NULL, -- 'CE', 'PE'
        
        -- Metadata
        CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
        Notes NVARCHAR(1000) NULL,
        
        -- Indexes for fast querying
        INDEX IX_StrategyLabels_BusinessDate NONCLUSTERED (BusinessDate),
        INDEX IX_StrategyLabels_IndexName NONCLUSTERED (IndexName),
        INDEX IX_StrategyLabels_ProcessType NONCLUSTERED (ProcessType),
        INDEX IX_StrategyLabels_LabelName NONCLUSTERED (LabelName),
        INDEX IX_StrategyLabels_BusinessDate_IndexName_ProcessType NONCLUSTERED 
            (BusinessDate, IndexName, ProcessType)
    );
    
    PRINT '✅ StrategyLabels table created successfully!';
END
ELSE
BEGIN
    PRINT '⚠️ StrategyLabels table already exists.';
END
GO

-- =====================================================
-- Sample Data Insert (9th Oct SENSEX PUT_MINUS)
-- =====================================================

-- Base Data Labels
INSERT INTO StrategyLabels (BusinessDate, IndexName, ProcessType, LabelName, LabelValue, Formula, [Description], StepNumber)
VALUES 
('2025-10-09', 'SENSEX', 'BASE_DATA', 'SPOT_CLOSE_D0', 82172.10, 
 'Historical Spot Close', 'SENSEX closing price on Day 0 (prediction day)', 0),

('2025-10-09', 'SENSEX', 'BASE_DATA', 'CLOSE_STRIKE', 82100.00, 
 'Nearest lower strike from SPOT_CLOSE_D0', 'Selected close strike (nearest lower to spot)', 0),

('2025-10-09', 'SENSEX', 'BASE_DATA', 'CLOSE_CE_UC_D0', 1920.85, 
 'MarketQuotes.UpperCircuitLimit', '82100 CE Upper Circuit on Day 0', 0),

('2025-10-09', 'SENSEX', 'BASE_DATA', 'CLOSE_PE_UC_D0', 1439.40, 
 'MarketQuotes.UpperCircuitLimit', '82100 PE Upper Circuit on Day 0', 0),

('2025-10-09', 'SENSEX', 'BASE_DATA', 'CALL_BASE_STRIKE', 79600.00, 
 'First strike with LC > 0.05 (moving down)', 'Call base strike for PUT_MINUS calculation', 0),

('2025-10-09', 'SENSEX', 'BASE_DATA', 'CALL_BASE_LC_D0', 193.10, 
 'MarketQuotes.LowerCircuitLimit', '79600 CE Lower Circuit on Day 0', 0),

('2025-10-09', 'SENSEX', 'BASE_DATA', 'PUT_BASE_STRIKE', 84700.00, 
 'First strike with LC > 0.05 (moving up)', 'Put base strike for CALL_MINUS calculation', 0),

('2025-10-09', 'SENSEX', 'BASE_DATA', 'PUT_BASE_LC_D0', 68.10, 
 'MarketQuotes.LowerCircuitLimit', '84700 PE Lower Circuit on Day 0', 0);

-- PUT_MINUS Process Labels
INSERT INTO StrategyLabels (BusinessDate, IndexName, ProcessType, LabelName, LabelValue, Formula, [Description], StepNumber, SourceLabels)
VALUES 
('2025-10-09', 'SENSEX', 'PUT_MINUS', 'PUT_MINUS_VALUE', 80660.60, 
 'CLOSE_STRIKE - CLOSE_PE_UC_D0', 'Downward protection level from PE UC', 1, 
 'CLOSE_STRIKE,CLOSE_PE_UC_D0'),

('2025-10-09', 'SENSEX', 'PUT_MINUS', 'PUT_MINUS_TO_CALL_BASE_DISTANCE', 1060.60, 
 'PUT_MINUS_VALUE - CALL_BASE_STRIKE', 'How far PUT_MINUS extends beyond Call Base', 2, 
 'PUT_MINUS_VALUE,CALL_BASE_STRIKE'),

('2025-10-09', 'SENSEX', 'PUT_MINUS', 'PUT_MINUS_TARGET_CE_PREMIUM', 860.25, 
 'CLOSE_CE_UC_D0 - PUT_MINUS_TO_CALL_BASE_DISTANCE', 'CE premium needed at target strike for upward move', 3, 
 'CLOSE_CE_UC_D0,PUT_MINUS_TO_CALL_BASE_DISTANCE'),

('2025-10-09', 'SENSEX', 'PUT_MINUS', 'PUT_MINUS_TARGET_STRIKE', 81200.00, 
 'CLOSE_STRIKE - PUT_MINUS_TARGET_CE_PREMIUM', 'Strike where CE should maintain premium for upward potential', 4, 
 'CLOSE_STRIKE,PUT_MINUS_TARGET_CE_PREMIUM'),

('2025-10-09', 'SENSEX', 'PUT_MINUS', 'CLOSE_CE_UC_CHANGE', 518.45, 
 'CLOSE_CE_UC_D1 - CLOSE_CE_UC_D0', 'Increase in CE upper circuit on Day 1 (upward pressure)', 5, 
 'CLOSE_CE_UC_D1,CLOSE_CE_UC_D0'),

('2025-10-09', 'SENSEX', 'PUT_MINUS', 'PUT_MINUS_PREDICTED_LEVEL', 82578.70, 
 'PUT_MINUS_TARGET_STRIKE + PUT_MINUS_TARGET_CE_PREMIUM + CLOSE_CE_UC_CHANGE', 
 'Predicted market level on Day 1 (upward bias)', 6, 
 'PUT_MINUS_TARGET_STRIKE,PUT_MINUS_TARGET_CE_PREMIUM,CLOSE_CE_UC_CHANGE');

PRINT '✅ Sample strategy labels inserted for 9th Oct SENSEX PUT_MINUS!';
GO

-- =====================================================
-- Query to view all labels for a strategy
-- =====================================================

SELECT 
    BusinessDate,
    IndexName,
    ProcessType,
    StepNumber,
    LabelName,
    LabelValue,
    Formula,
    [Description],
    SourceLabels
FROM StrategyLabels
WHERE BusinessDate = '2025-10-09' 
  AND IndexName = 'SENSEX'
ORDER BY ProcessType, StepNumber;

PRINT '✅ StrategyLabels table ready for strategy analysis!';

