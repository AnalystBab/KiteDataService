-- ========================================
-- ADD INSTRUMENT TRACKING FIELDS MIGRATION
-- ========================================
-- Purpose: Add FirstSeenDate, LastFetchedDate, and IsExpired fields
-- to Instruments table for better historical tracking
-- ========================================

USE [KiteMarketData];
GO

-- Check if columns already exist before adding them
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Instruments]') AND name = 'FirstSeenDate')
BEGIN
    PRINT '📊 Adding FirstSeenDate column...';
    ALTER TABLE [dbo].[Instruments]
    ADD [FirstSeenDate] DATETIME2 NOT NULL DEFAULT GETDATE();
    PRINT '✅ FirstSeenDate column added successfully';
END
ELSE
BEGIN
    PRINT '⏭️ FirstSeenDate column already exists, skipping...';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Instruments]') AND name = 'LastFetchedDate')
BEGIN
    PRINT '📊 Adding LastFetchedDate column...';
    ALTER TABLE [dbo].[Instruments]
    ADD [LastFetchedDate] DATETIME2 NOT NULL DEFAULT GETDATE();
    PRINT '✅ LastFetchedDate column added successfully';
END
ELSE
BEGIN
    PRINT '⏭️ LastFetchedDate column already exists, skipping...';
END
GO

IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[Instruments]') AND name = 'IsExpired')
BEGIN
    PRINT '📊 Adding IsExpired column...';
    ALTER TABLE [dbo].[Instruments]
    ADD [IsExpired] BIT NOT NULL DEFAULT 0;
    PRINT '✅ IsExpired column added successfully';
END
ELSE
BEGIN
    PRINT '⏭️ IsExpired column already exists, skipping...';
END
GO

-- ========================================
-- INITIALIZE DATA FOR EXISTING RECORDS
-- ========================================

PRINT '🔄 Initializing data for existing instruments...';

-- Set FirstSeenDate = LoadDate for existing records (best approximation)
UPDATE [dbo].[Instruments]
SET [FirstSeenDate] = [LoadDate]
WHERE [FirstSeenDate] = CAST(GETDATE() AS DATE); -- Only update records with default value

PRINT '✅ FirstSeenDate initialized from LoadDate for existing records';

-- Set LastFetchedDate = LoadDate for existing records
UPDATE [dbo].[Instruments]
SET [LastFetchedDate] = [LoadDate]
WHERE [LastFetchedDate] = CAST(GETDATE() AS DATE); -- Only update records with default value

PRINT '✅ LastFetchedDate initialized from LoadDate for existing records';

-- Set IsExpired flag based on Expiry date
UPDATE [dbo].[Instruments]
SET [IsExpired] = CASE 
    WHEN [Expiry] IS NOT NULL AND CAST([Expiry] AS DATE) < CAST(GETDATE() AS DATE) 
    THEN 1 
    ELSE 0 
END
WHERE [IsExpired] = 0; -- Only update records with default value

PRINT '✅ IsExpired flag initialized based on expiry dates';

-- ========================================
-- CREATE INDEXES FOR PERFORMANCE
-- ========================================

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Instruments_FirstSeenDate' AND object_id = OBJECT_ID(N'[dbo].[Instruments]'))
BEGIN
    PRINT '📊 Creating index on FirstSeenDate...';
    CREATE NONCLUSTERED INDEX [IX_Instruments_FirstSeenDate]
    ON [dbo].[Instruments] ([FirstSeenDate] ASC)
    INCLUDE ([InstrumentToken], [TradingSymbol], [Strike], [InstrumentType]);
    PRINT '✅ Index IX_Instruments_FirstSeenDate created successfully';
END
ELSE
BEGIN
    PRINT '⏭️ Index IX_Instruments_FirstSeenDate already exists, skipping...';
END
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Instruments_IsExpired' AND object_id = OBJECT_ID(N'[dbo].[Instruments]'))
BEGIN
    PRINT '📊 Creating index on IsExpired...';
    CREATE NONCLUSTERED INDEX [IX_Instruments_IsExpired]
    ON [dbo].[Instruments] ([IsExpired] ASC)
    WHERE [IsExpired] = 0; -- Filtered index for active instruments
    PRINT '✅ Index IX_Instruments_IsExpired created successfully';
END
ELSE
BEGIN
    PRINT '⏭️ Index IX_Instruments_IsExpired already exists, skipping...';
END
GO

-- ========================================
-- VERIFICATION
-- ========================================

PRINT '';
PRINT '🔍 VERIFICATION:';
PRINT '================';

SELECT 
    'Total Instruments' as Metric,
    COUNT(*) as Count
FROM [dbo].[Instruments]
UNION ALL
SELECT 
    'Expired Instruments',
    COUNT(*)
FROM [dbo].[Instruments]
WHERE [IsExpired] = 1
UNION ALL
SELECT 
    'Active Instruments',
    COUNT(*)
FROM [dbo].[Instruments]
WHERE [IsExpired] = 0;

PRINT '';
PRINT '✅ MIGRATION COMPLETED SUCCESSFULLY!';
PRINT '';
PRINT '📋 WHAT CHANGED:';
PRINT '  • Added FirstSeenDate column (when we FIRST discovered this instrument)';
PRINT '  • Added LastFetchedDate column (when we LAST fetched this instrument)';
PRINT '  • Added IsExpired flag (for easy filtering of expired instruments)';
PRINT '  • Created performance indexes';
PRINT '  • Initialized data for existing records';
PRINT '';
PRINT '🎯 NEXT STEPS:';
PRINT '  1. Rebuild the service project';
PRINT '  2. Run the service - it will now refresh instruments every 30 minutes during market hours';
PRINT '  3. New strikes will be detected within 30 minutes of NSE introducing them';
PRINT '';

