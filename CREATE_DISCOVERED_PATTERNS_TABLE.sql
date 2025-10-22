-- ================================================================================
-- CREATE TABLE FOR STORING AUTOMATICALLY DISCOVERED PATTERNS
-- ================================================================================

USE KiteMarketData;
GO

-- Drop table if exists (for clean recreation)
IF OBJECT_ID('dbo.DiscoveredPatterns', 'U') IS NOT NULL
    DROP TABLE dbo.DiscoveredPatterns;
GO

-- Create the table
CREATE TABLE dbo.DiscoveredPatterns (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Pattern Details
    Formula NVARCHAR(500) NOT NULL,
    TargetType NVARCHAR(50) NOT NULL,  -- LOW, HIGH, CLOSE, LOW_UC, HIGH_UC
    IndexName NVARCHAR(50) NOT NULL,
    
    -- Performance Metrics
    AvgErrorPercentage DECIMAL(18,4) NOT NULL,
    MinErrorPercentage DECIMAL(18,4) NOT NULL,
    MaxErrorPercentage DECIMAL(18,4) NOT NULL,
    ConsistencyScore DECIMAL(18,4) NOT NULL,  -- 0-100, higher is better
    OccurrenceCount INT NOT NULL,
    
    -- Pattern Metadata
    Complexity INT NOT NULL,  -- Number of labels used (1, 2, 3, etc.)
    LabelsUsed NVARCHAR(MAX),  -- Comma-separated list
    
    -- Dates
    FirstDiscovered DATETIME2 NOT NULL DEFAULT GETDATE(),
    LastOccurrence DATETIME2 NOT NULL DEFAULT GETDATE(),
    LastValidated DATETIME2 NULL,
    
    -- Status
    IsActive BIT NOT NULL DEFAULT 1,
    IsRecommended BIT NOT NULL DEFAULT 0,  -- Top patterns
    ValidationStatus NVARCHAR(50) DEFAULT 'PENDING',  -- PENDING, VALIDATED, FAILED
    
    -- Performance Tracking
    SuccessRate DECIMAL(18,4) NULL,  -- % of times it predicted correctly
    TotalPredictions INT DEFAULT 0,
    SuccessfulPredictions INT DEFAULT 0,
    
    -- Notes
    Notes NVARCHAR(MAX) NULL,
    
    -- Index for fast querying
    INDEX IX_DiscoveredPatterns_TargetType_Index (TargetType, IndexName, IsActive),
    INDEX IX_DiscoveredPatterns_ErrorPercentage (AvgErrorPercentage, ConsistencyScore),
    INDEX IX_DiscoveredPatterns_Formula (Formula)
);
GO

-- Create view for best patterns
CREATE VIEW vw_BestPatterns AS
SELECT 
    TargetType,
    IndexName,
    Formula,
    AvgErrorPercentage,
    ConsistencyScore,
    OccurrenceCount,
    SuccessRate,
    ValidationStatus,
    CASE 
        WHEN AvgErrorPercentage < 0.5 AND ConsistencyScore > 80 THEN '★★★★★ EXCELLENT'
        WHEN AvgErrorPercentage < 1.0 AND ConsistencyScore > 70 THEN '★★★★☆ VERY GOOD'
        WHEN AvgErrorPercentage < 2.0 AND ConsistencyScore > 60 THEN '★★★☆☆ GOOD'
        WHEN AvgErrorPercentage < 5.0 AND ConsistencyScore > 50 THEN '★★☆☆☆ FAIR'
        ELSE '★☆☆☆☆ POOR'
    END AS Rating,
    LastOccurrence,
    IsRecommended
FROM DiscoveredPatterns
WHERE IsActive = 1
  AND OccurrenceCount >= 3;  -- At least 3 occurrences
GO

-- Create stored procedure to get recommended patterns
CREATE PROCEDURE sp_GetRecommendedPatterns
    @IndexName NVARCHAR(50),
    @TargetType NVARCHAR(50)
AS
BEGIN
    SELECT TOP 10
        Formula,
        AvgErrorPercentage,
        ConsistencyScore,
        SuccessRate,
        OccurrenceCount,
        LabelsUsed
    FROM DiscoveredPatterns
    WHERE IndexName = @IndexName
      AND TargetType = @TargetType
      AND IsActive = 1
      AND OccurrenceCount >= 5
    ORDER BY 
        (CASE WHEN IsRecommended = 1 THEN 0 ELSE 1 END),
        AvgErrorPercentage ASC,
        ConsistencyScore DESC;
END;
GO

-- Create stored procedure to update pattern performance
CREATE PROCEDURE sp_UpdatePatternPerformance
    @Formula NVARCHAR(500),
    @TargetType NVARCHAR(50),
    @IndexName NVARCHAR(50),
    @WasSuccessful BIT
AS
BEGIN
    UPDATE DiscoveredPatterns
    SET 
        TotalPredictions = TotalPredictions + 1,
        SuccessfulPredictions = SuccessfulPredictions + (CASE WHEN @WasSuccessful = 1 THEN 1 ELSE 0 END),
        SuccessRate = CAST((SuccessfulPredictions + (CASE WHEN @WasSuccessful = 1 THEN 1 ELSE 0 END)) AS DECIMAL(18,4)) 
                      / (TotalPredictions + 1) * 100,
        LastValidated = GETDATE()
    WHERE Formula = @Formula
      AND TargetType = @TargetType
      AND IndexName = @IndexName;
END;
GO

PRINT '✅ DiscoveredPatterns table created successfully!';
PRINT '✅ View vw_BestPatterns created!';
PRINT '✅ Stored procedures created!';
GO

-- Show table structure
EXEC sp_help 'DiscoveredPatterns';
GO

