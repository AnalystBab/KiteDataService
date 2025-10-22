-- ================================================================================
-- CREATE HISTORICAL OPTIONS DATA TABLE
-- Preserves complete options data after expiry (Kite API discontinues it)
-- ================================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'HistoricalOptionsData')
BEGIN
    CREATE TABLE [dbo].[HistoricalOptionsData](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        
        -- Instrument Identification
        [InstrumentToken] [bigint] NOT NULL,
        [TradingSymbol] [nvarchar](100) NOT NULL,
        [IndexName] [nvarchar](20) NOT NULL,  -- NIFTY, SENSEX, BANKNIFTY
        
        -- Option Details
        [Strike] [decimal](10, 2) NOT NULL,
        [OptionType] [nvarchar](2) NOT NULL,  -- CE or PE
        [ExpiryDate] [date] NOT NULL,
        
        -- Trading Date
        [TradingDate] [date] NOT NULL,
        
        -- OHLC Data
        [OpenPrice] [decimal](10, 2) NOT NULL,
        [HighPrice] [decimal](10, 2) NOT NULL,
        [LowPrice] [decimal](10, 2) NOT NULL,
        [ClosePrice] [decimal](10, 2) NOT NULL,
        [LastPrice] [decimal](10, 2) NOT NULL,
        
        -- Volume
        [Volume] [bigint] NOT NULL,
        
        -- Circuit Limits (from MarketQuotes - can be NULL for old data)
        [LowerCircuitLimit] [decimal](10, 2) NULL,
        [UpperCircuitLimit] [decimal](10, 2) NULL,
        
        -- Open Interest
        [OpenInterest] [decimal](15, 2) NULL,
        
        -- Data Source
        [DataSource] [nvarchar](50) NOT NULL,  -- KiteHistoricalAPI, MarketQuotes, Manual
        
        -- Archival Information
        [ArchivedDate] [datetime2](7) NOT NULL,
        [IsExpired] [bit] NOT NULL,
        
        -- Last Trade Time
        [LastTradeTime] [datetime2](7) NULL,
        
        -- Metadata
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT (GETDATE()),
        [LastUpdated] [datetime2](7) NOT NULL DEFAULT (GETDATE()),
        [Notes] [nvarchar](500) NULL,
        
        CONSTRAINT [PK_HistoricalOptionsData] PRIMARY KEY CLUSTERED ([Id] ASC)
    );

    -- Create UNIQUE index to prevent duplicates (one record per instrument per date)
    CREATE UNIQUE NONCLUSTERED INDEX [IX_HistoricalOptionsData_Unique_InstrumentToken_TradingDate]
        ON [dbo].[HistoricalOptionsData]([InstrumentToken] ASC, [TradingDate] ASC);

    -- Create indexes for efficient querying
    CREATE NONCLUSTERED INDEX [IX_HistoricalOptionsData_IndexName]
        ON [dbo].[HistoricalOptionsData]([IndexName] ASC);

    CREATE NONCLUSTERED INDEX [IX_HistoricalOptionsData_ExpiryDate]
        ON [dbo].[HistoricalOptionsData]([ExpiryDate] ASC);

    CREATE NONCLUSTERED INDEX [IX_HistoricalOptionsData_TradingDate]
        ON [dbo].[HistoricalOptionsData]([TradingDate] ASC);

    CREATE NONCLUSTERED INDEX [IX_HistoricalOptionsData_Strike]
        ON [dbo].[HistoricalOptionsData]([Strike] ASC);

    CREATE NONCLUSTERED INDEX [IX_HistoricalOptionsData_IsExpired]
        ON [dbo].[HistoricalOptionsData]([IsExpired] ASC);

    CREATE NONCLUSTERED INDEX [IX_HistoricalOptionsData_ArchivedDate]
        ON [dbo].[HistoricalOptionsData]([ArchivedDate] ASC);

    CREATE NONCLUSTERED INDEX [IX_HistoricalOptionsData_IndexName_ExpiryDate]
        ON [dbo].[HistoricalOptionsData]([IndexName] ASC, [ExpiryDate] ASC);

    CREATE NONCLUSTERED INDEX [IX_HistoricalOptionsData_Full]
        ON [dbo].[HistoricalOptionsData]([IndexName] ASC, [ExpiryDate] ASC, [Strike] ASC, [OptionType] ASC);

    CREATE NONCLUSTERED INDEX [IX_HistoricalOptionsData_TradingDate_IndexName]
        ON [dbo].[HistoricalOptionsData]([TradingDate] ASC, [IndexName] ASC);

    PRINT '✅ HistoricalOptionsData table created successfully!';
    PRINT '📦 This table will preserve options data after expiry';
    PRINT '🎯 LC/UC values from MarketQuotes, OHLC from Kite API';
END
ELSE
BEGIN
    PRINT '⚠️ HistoricalOptionsData table already exists.';
END
GO

-- Display table info
SELECT 
    'HistoricalOptionsData' AS TableName,
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT IndexName) AS UniqueIndices,
    COUNT(DISTINCT ExpiryDate) AS UniqueExpiries,
    MIN(TradingDate) AS EarliestData,
    MAX(TradingDate) AS LatestData
FROM HistoricalOptionsData;
GO

