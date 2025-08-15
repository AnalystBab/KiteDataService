-- Restructure Database for Better Trading Data Storage
-- This script creates optimized tables for trading data

USE KiteMarketData;
GO

-- Drop existing tables (after backup)
IF OBJECT_ID('dbo.MarketQuotes', 'U') IS NOT NULL
    DROP TABLE dbo.MarketQuotes;
GO

IF OBJECT_ID('dbo.CircuitLimits', 'U') IS NOT NULL
    DROP TABLE dbo.CircuitLimits;
GO

IF OBJECT_ID('dbo.CircuitLimitChanges', 'U') IS NOT NULL
    DROP TABLE dbo.CircuitLimitChanges;
GO

IF OBJECT_ID('dbo.DailyMarketSnapshots', 'U') IS NOT NULL
    DROP TABLE dbo.DailyMarketSnapshots;
GO

-- Create new optimized MarketQuotes table
CREATE TABLE dbo.MarketQuotes (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Trading Information
    TradingDate DATE NOT NULL,
    TradeTime TIME NOT NULL,
    QuoteTimestamp DATETIME2 NOT NULL,
    
    -- Instrument Information
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    Exchange NVARCHAR(20) NOT NULL,
    Strike DECIMAL(10,2) NOT NULL,
    OptionType NVARCHAR(2) NOT NULL, -- 'CE' or 'PE'
    ExpiryDate DATE NOT NULL,
    
    -- Price Data (OHLC + Last)
    OpenPrice DECIMAL(10,2) NOT NULL,
    HighPrice DECIMAL(10,2) NOT NULL,
    LowPrice DECIMAL(10,2) NOT NULL,
    ClosePrice DECIMAL(10,2) NOT NULL,
    LastPrice DECIMAL(10,2) NOT NULL,
    
    -- Circuit Limits
    LowerCircuitLimit DECIMAL(10,2) NOT NULL,
    UpperCircuitLimit DECIMAL(10,2) NOT NULL,
    
    -- Volume and Trading Data
    Volume BIGINT NOT NULL,
    LastQuantity BIGINT NOT NULL,
    BuyQuantity BIGINT NOT NULL,
    SellQuantity BIGINT NOT NULL,
    AveragePrice DECIMAL(10,2) NOT NULL,
    
    -- Open Interest
    OpenInterest DECIMAL(15,2) NOT NULL,
    OiDayHigh DECIMAL(15,2) NOT NULL,
    OiDayLow DECIMAL(15,2) NOT NULL,
    NetChange DECIMAL(10,2) NOT NULL,
    
    -- Market Depth (Top 5 levels)
    BuyPrice1 DECIMAL(10,2) NULL,
    BuyQuantity1 BIGINT NULL,
    BuyOrders1 INT NULL,
    BuyPrice2 DECIMAL(10,2) NULL,
    BuyQuantity2 BIGINT NULL,
    BuyOrders2 INT NULL,
    BuyPrice3 DECIMAL(10,2) NULL,
    BuyQuantity3 BIGINT NULL,
    BuyOrders3 INT NULL,
    BuyPrice4 DECIMAL(10,2) NULL,
    BuyQuantity4 BIGINT NULL,
    BuyOrders4 INT NULL,
    BuyPrice5 DECIMAL(10,2) NULL,
    BuyQuantity5 BIGINT NULL,
    BuyOrders5 INT NULL,
    
    SellPrice1 DECIMAL(10,2) NULL,
    SellQuantity1 BIGINT NULL,
    SellOrders1 INT NULL,
    SellPrice2 DECIMAL(10,2) NULL,
    SellQuantity2 BIGINT NULL,
    SellOrders2 INT NULL,
    SellPrice3 DECIMAL(10,2) NULL,
    SellQuantity3 BIGINT NULL,
    SellOrders3 INT NULL,
    SellPrice4 DECIMAL(10,2) NULL,
    SellQuantity4 BIGINT NULL,
    SellOrders4 INT NULL,
    SellPrice5 DECIMAL(10,2) NULL,
    SellQuantity5 BIGINT NULL,
    SellOrders5 INT NULL,
    
    -- Metadata
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    -- Indexes for performance
    INDEX IX_MarketQuotes_TradingDate (TradingDate),
    INDEX IX_MarketQuotes_InstrumentToken (InstrumentToken),
    INDEX IX_MarketQuotes_QuoteTimestamp (QuoteTimestamp),
    INDEX IX_MarketQuotes_TradingSymbol (TradingSymbol),
    INDEX IX_MarketQuotes_Strike_OptionType (Strike, OptionType),
    INDEX IX_MarketQuotes_ExpiryDate (ExpiryDate),
    INDEX IX_MarketQuotes_Composite (TradingDate, TradingSymbol, QuoteTimestamp)
);
GO

-- Create CircuitLimits table (simplified)
CREATE TABLE dbo.CircuitLimits (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    TradingDate DATE NOT NULL,
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    Strike DECIMAL(10,2) NOT NULL,
    OptionType NVARCHAR(2) NOT NULL,
    LowerCircuitLimit DECIMAL(10,2) NOT NULL,
    UpperCircuitLimit DECIMAL(10,2) NOT NULL,
    Source NVARCHAR(50) NOT NULL DEFAULT 'QUOTE_API',
    LastUpdated DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    INDEX IX_CircuitLimits_TradingDate (TradingDate),
    INDEX IX_CircuitLimits_InstrumentToken (InstrumentToken),
    INDEX IX_CircuitLimits_Composite (TradingDate, TradingSymbol)
);
GO

-- Create CircuitLimitChanges table (comprehensive)
CREATE TABLE dbo.CircuitLimitChanges (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Trading Information
    TradingDate DATE NOT NULL,
    ChangeTime DATETIME2 NOT NULL,
    
    -- Instrument Information
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    Strike DECIMAL(10,2) NOT NULL,
    OptionType NVARCHAR(2) NOT NULL,
    Exchange NVARCHAR(20) NOT NULL,
    ExpiryDate DATE NOT NULL,
    
    -- Change Information
    ChangeType NVARCHAR(20) NOT NULL, -- 'LC_CHANGE', 'UC_CHANGE', 'BOTH_CHANGE'
    
    -- Previous Values
    PreviousLC DECIMAL(10,2) NULL,
    PreviousUC DECIMAL(10,2) NULL,
    PreviousOpenPrice DECIMAL(10,2) NULL,
    PreviousHighPrice DECIMAL(10,2) NULL,
    PreviousLowPrice DECIMAL(10,2) NULL,
    PreviousClosePrice DECIMAL(10,2) NULL,
    PreviousLastPrice DECIMAL(10,2) NULL,
    
    -- New Values
    NewLC DECIMAL(10,2) NULL,
    NewUC DECIMAL(10,2) NULL,
    NewOpenPrice DECIMAL(10,2) NULL,
    NewHighPrice DECIMAL(10,2) NULL,
    NewLowPrice DECIMAL(10,2) NULL,
    NewClosePrice DECIMAL(10,2) NULL,
    NewLastPrice DECIMAL(10,2) NULL,
    
    -- Index Data at Change Time
    IndexOpenPrice DECIMAL(10,2) NULL,
    IndexHighPrice DECIMAL(10,2) NULL,
    IndexLowPrice DECIMAL(10,2) NULL,
    IndexClosePrice DECIMAL(10,2) NULL,
    IndexLastPrice DECIMAL(10,2) NULL,
    
    -- Metadata
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    INDEX IX_CircuitLimitChanges_TradingDate (TradingDate),
    INDEX IX_CircuitLimitChanges_ChangeTime (ChangeTime),
    INDEX IX_CircuitLimitChanges_InstrumentToken (InstrumentToken),
    INDEX IX_CircuitLimitChanges_ChangeType (ChangeType)
);
GO

-- Create DailyMarketSnapshots table (comprehensive)
CREATE TABLE dbo.DailyMarketSnapshots (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Trading Information
    TradingDate DATE NOT NULL,
    SnapshotTime DATETIME2 NOT NULL,
    
    -- Instrument Information
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    Strike DECIMAL(10,2) NOT NULL,
    OptionType NVARCHAR(2) NOT NULL,
    Exchange NVARCHAR(20) NOT NULL,
    ExpiryDate DATE NOT NULL,
    
    -- Price Data (OHLC + Last)
    OpenPrice DECIMAL(10,2) NOT NULL,
    HighPrice DECIMAL(10,2) NOT NULL,
    LowPrice DECIMAL(10,2) NOT NULL,
    ClosePrice DECIMAL(10,2) NOT NULL,
    LastPrice DECIMAL(10,2) NOT NULL,
    
    -- Circuit Limits
    LowerCircuitLimit DECIMAL(10,2) NOT NULL,
    UpperCircuitLimit DECIMAL(10,2) NOT NULL,
    
    -- Volume and Trading Data
    Volume BIGINT NOT NULL,
    OpenInterest DECIMAL(15,2) NOT NULL,
    NetChange DECIMAL(10,2) NOT NULL,
    
    -- Snapshot Type
    SnapshotType NVARCHAR(20) NOT NULL, -- 'MARKET_OPEN', 'MARKET_CLOSE', 'POST_MARKET'
    
    -- Metadata
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    
    INDEX IX_DailyMarketSnapshots_TradingDate (TradingDate),
    INDEX IX_DailyMarketSnapshots_SnapshotTime (SnapshotTime),
    INDEX IX_DailyMarketSnapshots_InstrumentToken (InstrumentToken),
    INDEX IX_DailyMarketSnapshots_SnapshotType (SnapshotType)
);
GO

-- Create view for easy querying with column aliases
CREATE VIEW dbo.TradingData AS
SELECT 
    TradingDate,
    TradeTime,
    QuoteTimestamp,
    InstrumentToken,
    TradingSymbol,
    Exchange,
    Strike AS StrkPric,
    OptionType,
    ExpiryDate,
    OpenPrice AS OpnPric,
    HighPrice AS HghPric,
    LowPrice AS LwPric,
    ClosePrice AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS lowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    NetChange
FROM dbo.MarketQuotes;
GO

-- Create view for NIFTY options specifically
CREATE VIEW dbo.NIFTYOptions AS
SELECT 
    TradingDate,
    TradeTime,
    QuoteTimestamp,
    InstrumentToken,
    TradingSymbol,
    Strike AS StrkPric,
    OptionType,
    ExpiryDate,
    OpenPrice AS OpnPric,
    HighPrice AS HghPric,
    LowPrice AS LwPric,
    ClosePrice AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS lowerLimit,
    UpperCircuitLimit AS UpperLimit,
    Volume,
    OpenInterest,
    NetChange
FROM dbo.MarketQuotes
WHERE TradingSymbol LIKE 'NIFTY%';
GO

PRINT 'Database restructured successfully!';
PRINT 'New tables created with optimized columns:';
PRINT '- MarketQuotes (main trading data)';
PRINT '- CircuitLimits (circuit limit data)';
PRINT '- CircuitLimitChanges (comprehensive change tracking)';
PRINT '- DailyMarketSnapshots (comprehensive EOD data)';
PRINT 'Views created:';
PRINT '- TradingData (easy querying with aliases)';
PRINT '- NIFTYOptions (NIFTY-specific data)';
GO
