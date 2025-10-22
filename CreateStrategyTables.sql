-- =====================================================
-- CREATE STRATEGY SYSTEM TABLES
-- Complete table structure for options strategy analysis
-- =====================================================

USE KiteMarketData;
GO

PRINT '🚀 Creating Strategy System Tables...';
PRINT '';

-- =====================================================
-- TABLE 1: StrategyLabelsCatalog
-- Master catalog of all label definitions (26+ labels)
-- =====================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StrategyLabelsCatalog')
BEGIN
    CREATE TABLE StrategyLabelsCatalog (
        LabelNumber INT PRIMARY KEY,
        LabelName NVARCHAR(100) NOT NULL UNIQUE,
        LabelCategory NVARCHAR(50) NOT NULL,  -- BASE_DATA, BOUNDARY, QUADRANT, DISTANCE, TARGET, etc.
        StepNumber INT NOT NULL,               -- 1=Collect, 2=Calculate, 3=Match, etc.
        ImportanceLevel INT NOT NULL,          -- 1-6 stars (6=GOLDEN)
        
        -- Formula and Description
        Formula NVARCHAR(500),
        [Description] NVARCHAR(2000),
        Purpose NVARCHAR(2000),
        Meaning NVARCHAR(2000),
        
        -- Data Type Information
        DataType NVARCHAR(50),
        UnitType NVARCHAR(50),
        ValueRange NVARCHAR(200),
        
        -- Source Information
        SourceTable NVARCHAR(100),
        SourceColumn NVARCHAR(100),
        SourceQuery NVARCHAR(MAX),
        
        -- Dependencies
        DependsOn NVARCHAR(500),  -- Comma-separated label numbers
        UsedBy NVARCHAR(500),     -- Comma-separated label numbers
        
        -- Validation
        ValidationRules NVARCHAR(MAX),
        ProcessingTimeMs INT,
        
        -- Metadata
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        LastUpdated DATETIME2 DEFAULT GETDATE(),
        Notes NVARCHAR(MAX)
    );
    
    CREATE INDEX IX_StrategyLabelsCatalog_Category ON StrategyLabelsCatalog(LabelCategory);
    CREATE INDEX IX_StrategyLabelsCatalog_Importance ON StrategyLabelsCatalog(ImportanceLevel DESC);
    
    PRINT '✅ StrategyLabelsCatalog table created';
END
ELSE
    PRINT '⚠️  StrategyLabelsCatalog already exists';

GO

-- =====================================================
-- TABLE 2: StrategyLabels
-- Daily label values (23-27 labels per day per index)
-- =====================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StrategyLabels')
BEGIN
    CREATE TABLE StrategyLabels (
        Id BIGINT PRIMARY KEY IDENTITY(1,1),
        
        -- Strategy Information
        StrategyName NVARCHAR(100) NOT NULL,
        StrategyVersion DECIMAL(3,1) NOT NULL,
        
        -- Date and Index
        BusinessDate DATE NOT NULL,
        IndexName NVARCHAR(20) NOT NULL,
        ExpiryDate DATE,
        
        -- Label Information
        LabelNumber INT NOT NULL,
        LabelName NVARCHAR(100) NOT NULL,
        LabelValue DECIMAL(18,2) NOT NULL,
        
        -- Metadata
        Formula NVARCHAR(500),
        [Description] NVARCHAR(1000),
        ProcessType NVARCHAR(50),
        StepNumber INT,
        SourceLabels NVARCHAR(500),
        
        -- Optional Context
        RelatedStrike DECIMAL(10,2),
        RelatedOptionType NVARCHAR(2),
        
        -- Timestamps
        CreatedAt DATETIME2 DEFAULT GETDATE(),
        Notes NVARCHAR(MAX),
        
        -- Indexes
        INDEX IX_StrategyLabels_BusinessDate NONCLUSTERED (BusinessDate),
        INDEX IX_StrategyLabels_IndexName NONCLUSTERED (IndexName),
        INDEX IX_StrategyLabels_LabelName NONCLUSTERED (LabelName),
        INDEX IX_StrategyLabels_Date_Index NONCLUSTERED (BusinessDate, IndexName)
    );
    
    PRINT '✅ StrategyLabels table created';
END
ELSE
    PRINT '⚠️  StrategyLabels already exists';

GO

-- =====================================================
-- TABLE 3: StrategyMatches
-- Strike UC/LC matches found during scanning
-- =====================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StrategyMatches')
BEGIN
    CREATE TABLE StrategyMatches (
        Id BIGINT PRIMARY KEY IDENTITY(1,1),
        
        -- Strategy Information
        StrategyName NVARCHAR(100) NOT NULL,
        BusinessDate DATE NOT NULL,
        IndexName NVARCHAR(20) NOT NULL,
        
        -- Calculated Label that we're matching
        CalculatedLabelName NVARCHAR(100) NOT NULL,
        CalculatedValue DECIMAL(18,2) NOT NULL,
        
        -- Matched Strike Information
        MatchedStrike DECIMAL(10,2) NOT NULL,
        MatchedOptionType NVARCHAR(2) NOT NULL,  -- 'CE' or 'PE'
        MatchedFieldType NVARCHAR(10) NOT NULL,  -- 'UC' or 'LC'
        MatchedValue DECIMAL(18,2) NOT NULL,
        MatchedExpiryDate DATE,
        
        -- Match Quality
        [Difference] DECIMAL(18,2) NOT NULL,     -- Abs difference
        MatchQuality DECIMAL(5,2) NOT NULL,      -- Percentage (0-100)
        Tolerance DECIMAL(10,2) DEFAULT 50.00,   -- Matching tolerance used
        
        -- Prediction Information
        Hypothesis NVARCHAR(1000),               -- What we think this predicts
        PredictionType NVARCHAR(50),             -- 'SPOT_HIGH', 'SPOT_LOW', 'PREMIUM', etc.
        ConfidenceLevel INT,                     -- 1-5 stars
        
        -- Metadata
        CreatedAt DATETIME2 DEFAULT GETDATE(),
        Notes NVARCHAR(MAX),
        
        -- Indexes
        INDEX IX_StrategyMatches_BusinessDate NONCLUSTERED (BusinessDate),
        INDEX IX_StrategyMatches_Quality NONCLUSTERED (MatchQuality DESC),
        INDEX IX_StrategyMatches_Label NONCLUSTERED (CalculatedLabelName)
    );
    
    PRINT '✅ StrategyMatches table created';
END
ELSE
    PRINT '⚠️  StrategyMatches already exists';

GO

-- =====================================================
-- TABLE 4: StrategyPredictions
-- Predictions generated from matches for D1
-- =====================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StrategyPredictions')
BEGIN
    CREATE TABLE StrategyPredictions (
        Id BIGINT PRIMARY KEY IDENTITY(1,1),
        
        -- Link to Match (optional, some predictions from direct calculation)
        MatchId BIGINT,  -- FK to StrategyMatches
        
        -- Strategy and Date
        StrategyName NVARCHAR(100) NOT NULL,
        PredictionDate DATE NOT NULL,     -- D0 (when prediction made)
        TargetDate DATE NOT NULL,         -- D1 (what we're predicting)
        IndexName NVARCHAR(20) NOT NULL,
        
        -- Prediction Details
        PredictionType NVARCHAR(50) NOT NULL,  -- 'SPOT_HIGH', 'SPOT_LOW', 'SPOT_CLOSE', 'PREMIUM', 'BOUNDARY'
        PredictedValue DECIMAL(18,2) NOT NULL,
        PredictedStrike DECIMAL(10,2),         -- If predicting specific strike
        PredictedOptionType NVARCHAR(2),       -- If predicting specific option
        
        -- Confidence and Source
        ConfidenceLevel INT,                   -- 1-5 stars
        SourceCalculation NVARCHAR(500),       -- Formula used
        SourceLabels NVARCHAR(500),            -- Labels involved
        
        -- Metadata
        PredictionNotes NVARCHAR(1000),
        CreatedAt DATETIME2 DEFAULT GETDATE(),
        
        -- Indexes
        INDEX IX_StrategyPredictions_PredictionDate NONCLUSTERED (PredictionDate),
        INDEX IX_StrategyPredictions_TargetDate NONCLUSTERED (TargetDate),
        INDEX IX_StrategyPredictions_Type NONCLUSTERED (PredictionType)
    );
    
    PRINT '✅ StrategyPredictions table created';
END
ELSE
    PRINT '⚠️  StrategyPredictions already exists';

GO

-- =====================================================
-- TABLE 5: StrategyValidations
-- Validation results when D1 actual data arrives
-- =====================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StrategyValidations')
BEGIN
    CREATE TABLE StrategyValidations (
        Id BIGINT PRIMARY KEY IDENTITY(1,1),
        
        -- Link to Prediction
        PredictionId BIGINT NOT NULL,  -- FK to StrategyPredictions
        
        -- Actual Data from D1
        ActualDate DATE NOT NULL,
        ActualValue DECIMAL(18,2) NOT NULL,
        ActualStrike DECIMAL(10,2),
        ActualOptionType NVARCHAR(2),
        
        -- Validation Metrics
        [Error] DECIMAL(18,2) NOT NULL,           -- Abs(Predicted - Actual)
        ErrorPercentage DECIMAL(5,2) NOT NULL,    -- Error / Actual * 100
        AccuracyPercentage DECIMAL(5,2) NOT NULL, -- 100 - ErrorPercentage
        
        -- Status
        [Status] NVARCHAR(20) NOT NULL,  -- 'SUCCESS' (>95%), 'PARTIAL' (90-95%), 'FAIL' (<90%)
        WithinTolerance BIT NOT NULL,    -- TRUE if error < tolerance
        
        -- Learning Data
        ValidationNotes NVARCHAR(MAX),
        PatternObserved NVARCHAR(1000),
        
        -- Metadata
        ValidatedAt DATETIME2 DEFAULT GETDATE(),
        
        -- Indexes
        INDEX IX_StrategyValidations_PredictionId NONCLUSTERED (PredictionId),
        INDEX IX_StrategyValidations_Accuracy NONCLUSTERED (AccuracyPercentage DESC),
        INDEX IX_StrategyValidations_Status NONCLUSTERED ([Status])
    );
    
    PRINT '✅ StrategyValidations table created';
END
ELSE
    PRINT '⚠️  StrategyValidations already exists';

GO

-- =====================================================
-- TABLE 6: StrategyPerformance
-- Aggregated performance metrics by strategy
-- =====================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StrategyPerformance')
BEGIN
    CREATE TABLE StrategyPerformance (
        Id BIGINT PRIMARY KEY IDENTITY(1,1),
        
        StrategyName NVARCHAR(100) NOT NULL,
        StrategyVersion DECIMAL(3,1) NOT NULL,
        
        -- Performance Metrics
        TotalPredictions INT NOT NULL DEFAULT 0,
        SuccessfulPredictions INT NOT NULL DEFAULT 0,
        FailedPredictions INT NOT NULL DEFAULT 0,
        
        AverageAccuracy DECIMAL(5,2),
        BestAccuracy DECIMAL(5,2),
        WorstAccuracy DECIMAL(5,2),
        
        AverageError DECIMAL(10,2),
        MedianError DECIMAL(10,2),
        
        SuccessRate DECIMAL(5,2),  -- Percentage
        
        -- Date Range
        FirstPredictionDate DATE,
        LastPredictionDate DATE,
        DaysTested INT,
        
        -- Status
        StrategyStatus NVARCHAR(20),  -- 'ACTIVE', 'TESTING', 'RETIRED'
        IsProduction BIT DEFAULT 0,
        
        -- Metadata
        LastUpdated DATETIME2 DEFAULT GETDATE(),
        Notes NVARCHAR(MAX),
        
        -- Indexes
        INDEX IX_StrategyPerformance_Strategy NONCLUSTERED (StrategyName, StrategyVersion),
        INDEX IX_StrategyPerformance_Accuracy NONCLUSTERED (AverageAccuracy DESC)
    );
    
    PRINT '✅ StrategyPerformance table created';
END
ELSE
    PRINT '⚠️  StrategyPerformance already exists';

GO

PRINT '';
PRINT '✅ All strategy system tables created successfully!';
PRINT '';
PRINT 'Tables created:';
PRINT '  1. StrategyLabelsCatalog - Label definitions';
PRINT '  2. StrategyLabels - Daily label values';
PRINT '  3. StrategyMatches - Strike UC/LC matches';
PRINT '  4. StrategyPredictions - D1 predictions';
PRINT '  5. StrategyValidations - Validation results';
PRINT '  6. StrategyPerformance - Aggregate metrics';
PRINT '';
PRINT '🎯 Ready for strategy implementation!';

