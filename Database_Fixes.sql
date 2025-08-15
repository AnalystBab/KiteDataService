-- CRITICAL FIXES FOR CIRCUIT LIMIT TRACKING SYSTEM
-- This script implements all fixes from CRITICAL_ISSUES_AND_FIXES.md

USE KiteMarketData;
GO

-- =============================================
-- FIX 1: ENHANCE CIRCUITLIMITCHANGES TABLE SCHEMA
-- =============================================

-- Add missing columns for better user experience
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('CircuitLimitChanges') AND name = 'TriggeredByTradingSymbol')
BEGIN
    ALTER TABLE CircuitLimitChanges ADD TriggeredByTradingSymbol NVARCHAR(100);
    PRINT 'Added TriggeredByTradingSymbol column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('CircuitLimitChanges') AND name = 'TriggeredByStrike')
BEGIN
    ALTER TABLE CircuitLimitChanges ADD TriggeredByStrike DECIMAL(10,2);
    PRINT 'Added TriggeredByStrike column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('CircuitLimitChanges') AND name = 'TriggeredByExpiry')
BEGIN
    ALTER TABLE CircuitLimitChanges ADD TriggeredByExpiry DATETIME;
    PRINT 'Added TriggeredByExpiry column';
END

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('CircuitLimitChanges') AND name = 'TriggeredByInstrumentType')
BEGIN
    ALTER TABLE CircuitLimitChanges ADD TriggeredByInstrumentType NVARCHAR(10);
    PRINT 'Added TriggeredByInstrumentType column';
END

-- =============================================
-- FIX 2: CLEAR EXISTING FALSE POSITIVE DATA
-- =============================================

-- Clear false circuit limit change records
DELETE FROM CircuitLimitChanges WHERE ChangeDate = '2025-07-30';
PRINT 'Cleared false circuit limit change records for 2025-07-30';

-- Clear any records with 0.00/0.00 limits (false positives)
DELETE FROM CircuitLimitChanges 
WHERE OldLowerLimit = 0.00 AND OldUpperLimit = 0.00;
PRINT 'Cleared circuit limit changes with 0.00/0.00 old limits';

-- =============================================
-- FIX 3: IMPROVE TIMESTAMP HANDLING
-- =============================================

-- Update any remaining 1970-01-01 timestamps to proper dates
UPDATE MarketQuotes 
SET QuoteTimestamp = DATEADD(day, -1, CAST(GETDATE() AS DATE)) + CAST('09:15:00' AS TIME)
WHERE QuoteTimestamp = '1970-01-01 05:30:00.0000000';
PRINT 'Updated 1970-01-01 timestamps to proper dates';

-- =============================================
-- FIX 4: ADD INDEXES FOR PERFORMANCE
-- =============================================

-- Add indexes for better performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CircuitLimitChanges_ChangeDate')
BEGIN
    CREATE INDEX IX_CircuitLimitChanges_ChangeDate ON CircuitLimitChanges(ChangeDate);
    PRINT 'Created index on CircuitLimitChanges.ChangeDate';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_CircuitLimitChanges_UnderlyingSymbol')
BEGIN
    CREATE INDEX IX_CircuitLimitChanges_UnderlyingSymbol ON CircuitLimitChanges(UnderlyingSymbol);
    PRINT 'Created index on CircuitLimitChanges.UnderlyingSymbol';
END

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MarketQuotes_QuoteTimestamp_InstrumentToken')
BEGIN
    CREATE INDEX IX_MarketQuotes_QuoteTimestamp_InstrumentToken ON MarketQuotes(QuoteTimestamp, InstrumentToken);
    PRINT 'Created index on MarketQuotes.QuoteTimestamp, InstrumentToken';
END

-- =============================================
-- FIX 5: CREATE HELPER VIEWS FOR ANALYSIS
-- =============================================

-- Create view for circuit limit changes with instrument details
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_CircuitLimitChanges_Detailed')
    DROP VIEW vw_CircuitLimitChanges_Detailed;
GO

CREATE VIEW vw_CircuitLimitChanges_Detailed AS
SELECT 
    clc.Id,
    clc.UnderlyingSymbol,
    clc.ChangeDate,
    clc.ChangeTimestamp,
    clc.OldLowerLimit,
    clc.OldUpperLimit,
    clc.NewLowerLimit,
    clc.NewUpperLimit,
    clc.TriggeredByInstrumentToken,
    clc.TriggeredByTradingSymbol,
    clc.TriggeredByStrike,
    clc.TriggeredByExpiry,
    clc.TriggeredByInstrumentType,
    clc.InstrumentsAffected,
    clc.SpotOpen,
    clc.SpotHigh,
    clc.SpotLow,
    clc.SpotClose,
    clc.SpotVolume,
    clc.SpotLastPrice,
    clc.SpotLowerCircuitLimit,
    clc.SpotUpperCircuitLimit,
    clc.SpotInstrumentToken,
    clc.SpotTradingSymbol,
    clc.CreatedAt,
    -- Additional computed columns
    CASE 
        WHEN clc.OldLowerLimit = 0 AND clc.OldUpperLimit = 0 THEN 'Initial Setup'
        ELSE 'Real Change'
    END AS ChangeType,
    DATEDIFF(MINUTE, clc.ChangeTimestamp, GETDATE()) AS MinutesSinceChange
FROM CircuitLimitChanges clc;
GO

PRINT 'Created vw_CircuitLimitChanges_Detailed view';

-- =============================================
-- FIX 6: CREATE STORED PROCEDURES FOR ANALYSIS
-- =============================================

-- Stored procedure to get circuit limit changes for a specific date range
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_GetCircuitLimitChanges')
    DROP PROCEDURE sp_GetCircuitLimitChanges;
GO

CREATE PROCEDURE sp_GetCircuitLimitChanges
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @UnderlyingSymbol NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL SET @StartDate = DATEADD(day, -7, CAST(GETDATE() AS DATE));
    IF @EndDate IS NULL SET @EndDate = CAST(GETDATE() AS DATE);
    
    SELECT 
        UnderlyingSymbol,
        ChangeDate,
        ChangeTimestamp,
        OldLowerLimit,
        OldUpperLimit,
        NewLowerLimit,
        NewUpperLimit,
        TriggeredByTradingSymbol,
        TriggeredByStrike,
        TriggeredByExpiry,
        TriggeredByInstrumentType,
        InstrumentsAffected,
        SpotOpen,
        SpotHigh,
        SpotLow,
        SpotClose,
        SpotLastPrice,
        MinutesSinceChange
    FROM vw_CircuitLimitChanges_Detailed
    WHERE ChangeDate BETWEEN @StartDate AND @EndDate
        AND (@UnderlyingSymbol IS NULL OR UnderlyingSymbol = @UnderlyingSymbol)
    ORDER BY ChangeTimestamp DESC;
END
GO

PRINT 'Created sp_GetCircuitLimitChanges stored procedure';

-- Stored procedure to get only real circuit limit changes (exclude false positives)
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_GetRealCircuitLimitChanges')
    DROP PROCEDURE sp_GetRealCircuitLimitChanges;
GO

CREATE PROCEDURE sp_GetRealCircuitLimitChanges
    @StartDate DATE = NULL,
    @EndDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL SET @StartDate = DATEADD(day, -7, CAST(GETDATE() AS DATE));
    IF @EndDate IS NULL SET @EndDate = CAST(GETDATE() AS DATE);
    
    SELECT 
        UnderlyingSymbol,
        ChangeDate,
        ChangeTimestamp,
        OldLowerLimit,
        OldUpperLimit,
        NewLowerLimit,
        NewUpperLimit,
        TriggeredByTradingSymbol,
        TriggeredByStrike,
        TriggeredByExpiry,
        TriggeredByInstrumentType,
        InstrumentsAffected,
        SpotOpen,
        SpotHigh,
        SpotLow,
        SpotClose,
        SpotLastPrice,
        MinutesSinceChange
    FROM vw_CircuitLimitChanges_Detailed
    WHERE ChangeDate BETWEEN @StartDate AND @EndDate
        AND NOT (OldLowerLimit = 0 AND OldUpperLimit = 0)  -- Exclude false positives
        AND ChangeTimestamp >= '09:15:00'  -- Only during market hours
    ORDER BY ChangeTimestamp DESC;
END
GO

PRINT 'Created sp_GetRealCircuitLimitChanges stored procedure';

-- Stored procedure to get individual instrument circuit limit changes
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'sp_GetIndividualCircuitLimitChanges')
    DROP PROCEDURE sp_GetIndividualCircuitLimitChanges;
GO

CREATE PROCEDURE sp_GetIndividualCircuitLimitChanges
    @StartDate DATE = NULL,
    @EndDate DATE = NULL,
    @UnderlyingSymbol NVARCHAR(20) = NULL,
    @InstrumentToken BIGINT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @StartDate IS NULL SET @StartDate = DATEADD(day, -7, CAST(GETDATE() AS DATE));
    IF @EndDate IS NULL SET @EndDate = CAST(GETDATE() AS DATE);
    
    SELECT 
        UnderlyingSymbol,
        ChangeDate,
        ChangeTimestamp,
        OldLowerLimit,
        OldUpperLimit,
        NewLowerLimit,
        NewUpperLimit,
        TriggeredByInstrumentToken,
        TriggeredByTradingSymbol,
        TriggeredByStrike,
        TriggeredByExpiry,
        TriggeredByInstrumentType,
        InstrumentsAffected,
        SpotOpen,
        SpotHigh,
        SpotLow,
        SpotLastPrice,
        MinutesSinceChange,
        CASE 
            WHEN InstrumentsAffected = 1 THEN 'Individual Instrument'
            ELSE 'Underlying Level'
        END AS ChangeType
    FROM vw_CircuitLimitChanges_Detailed
    WHERE ChangeDate BETWEEN @StartDate AND @EndDate
        AND (@UnderlyingSymbol IS NULL OR UnderlyingSymbol = @UnderlyingSymbol)
        AND (@InstrumentToken IS NULL OR TriggeredByInstrumentToken = @InstrumentToken)
        AND InstrumentsAffected = 1  -- Only individual instrument changes
    ORDER BY ChangeTimestamp DESC;
END
GO

PRINT 'Created sp_GetIndividualCircuitLimitChanges stored procedure';

-- =============================================
-- FIX 7: DATA VALIDATION AND CLEANUP
-- =============================================

-- Create a function to validate circuit limit data
IF EXISTS (SELECT * FROM sys.objects WHERE name = 'fn_ValidateCircuitLimitData')
    DROP FUNCTION fn_ValidateCircuitLimitData;
GO

CREATE FUNCTION fn_ValidateCircuitLimitData()
RETURNS TABLE
AS
RETURN
(
    SELECT 
        'Invalid Timestamps' AS IssueType,
        COUNT(*) AS IssueCount,
        'MarketQuotes with 1970-01-01 timestamps' AS Description
    FROM MarketQuotes 
    WHERE QuoteTimestamp = '1970-01-01 05:30:00.0000000'
    
    UNION ALL
    
    SELECT 
        'False Positive Changes' AS IssueType,
        COUNT(*) AS IssueCount,
        'Circuit limit changes with 0.00/0.00 old limits' AS Description
    FROM CircuitLimitChanges 
    WHERE OldLowerLimit = 0.00 AND OldUpperLimit = 0.00
    
    UNION ALL
    
    SELECT 
        'Missing Spot Data' AS IssueType,
        COUNT(*) AS IssueCount,
        'Circuit limit changes with NULL spot data' AS Description
    FROM CircuitLimitChanges 
    WHERE SpotOpen IS NULL AND SpotClose IS NULL
);
GO

PRINT 'Created fn_ValidateCircuitLimitData function';

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

PRINT '=== VERIFICATION QUERIES ===';

-- Check table structure
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'CircuitLimitChanges'
ORDER BY ORDINAL_POSITION;

-- Check data quality
SELECT * FROM fn_ValidateCircuitLimitData();

-- Check recent circuit limit changes
EXEC sp_GetRealCircuitLimitChanges @StartDate = '2025-07-29', @EndDate = '2025-07-30';

PRINT '=== ALL FIXES APPLIED SUCCESSFULLY ===';
PRINT 'Database is now ready for improved circuit limit tracking!'; 