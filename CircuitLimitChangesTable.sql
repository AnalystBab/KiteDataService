-- Create Circuit Limit Change History Table
-- This table tracks when LC/UC values change for any strike

IF OBJECT_ID('dbo.CircuitLimitChangeHistory', 'U') IS NOT NULL
    DROP TABLE dbo.CircuitLimitChangeHistory;
GO

CREATE TABLE dbo.CircuitLimitChangeHistory (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    TradingDate DATE NOT NULL,
    TradedTime TIME NOT NULL,
    ExpiryDate DATE NOT NULL,
    IndexName NVARCHAR(20) NOT NULL, -- NIFTY, SENSEX, BANKNIFTY
    Strike DECIMAL(10,2) NOT NULL,
    OptionType NVARCHAR(2) NOT NULL, -- CE, PE
    [Open] DECIMAL(10,2) NOT NULL,
    High DECIMAL(10,2) NOT NULL,
    Low DECIMAL(10,2) NOT NULL,
    [Close] DECIMAL(10,2) NOT NULL,
    LastTradedPrice DECIMAL(10,2) NOT NULL,
    LowerCircuit DECIMAL(10,2) NOT NULL,
    UpperCircuit DECIMAL(10,2) NOT NULL,
    MarketHourFlag NVARCHAR(20) NOT NULL, -- 'MARKET_HOUR', 'AFTER_MARKET'
    -- Spot/Index OHLC Data
    SpotOpen DECIMAL(10,2) NOT NULL,
    SpotHigh DECIMAL(10,2) NOT NULL,
    SpotLow DECIMAL(10,2) NOT NULL,
    SpotClose DECIMAL(10,2) NOT NULL,
    SpotLastPrice DECIMAL(10,2) NOT NULL,
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    ChangeTimestamp DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    -- Indexes for performance
    INDEX IX_CircuitLimitChangeHistory_TradingDate (TradingDate),
    INDEX IX_CircuitLimitChangeHistory_Index (IndexName),
    INDEX IX_CircuitLimitChangeHistory_Strike (Strike),
    INDEX IX_CircuitLimitChangeHistory_Expiry (ExpiryDate),
    INDEX IX_CircuitLimitChangeHistory_InstrumentToken (InstrumentToken),
    INDEX IX_CircuitLimitChangeHistory_ChangeTimestamp (ChangeTimestamp),
    INDEX IX_CircuitLimitChangeHistory_Composite (TradingDate, IndexName, Strike, OptionType, ExpiryDate)
);

GO

PRINT 'CircuitLimitChangeHistory table created successfully!';
