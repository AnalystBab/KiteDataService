-- Recreate Circuit Limit Changes Table
-- This table tracks detailed circuit limit changes with before/after data

IF OBJECT_ID('dbo.CircuitLimitChanges', 'U') IS NOT NULL
    DROP TABLE dbo.CircuitLimitChanges;
GO

CREATE TABLE dbo.CircuitLimitChanges (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Trading Information
    TradingDate DATE NOT NULL,
    ChangeTime DATETIME2 NOT NULL,
    
    -- Instrument Information
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    Strike DECIMAL(10,2) NOT NULL,
    OptionType NVARCHAR(2) NOT NULL, -- CE, PE
    Exchange NVARCHAR(20) NOT NULL,
    ExpiryDate DATE NOT NULL,
    
    -- Change Information
    ChangeType NVARCHAR(20) NOT NULL, -- 'LC_CHANGE', 'UC_CHANGE', 'BOTH_CHANGE'
    
    -- Previous Values (Nullable)
    PreviousLC DECIMAL(10,2) NULL,
    PreviousUC DECIMAL(10,2) NULL,
    PreviousOpenPrice DECIMAL(10,2) NULL,
    PreviousHighPrice DECIMAL(10,2) NULL,
    PreviousLowPrice DECIMAL(10,2) NULL,
    PreviousClosePrice DECIMAL(10,2) NULL,
    PreviousLastPrice DECIMAL(10,2) NULL,
    
    -- New Values (Nullable)
    NewLC DECIMAL(10,2) NULL,
    NewUC DECIMAL(10,2) NULL,
    NewOpenPrice DECIMAL(10,2) NULL,
    NewHighPrice DECIMAL(10,2) NULL,
    NewLowPrice DECIMAL(10,2) NULL,
    NewClosePrice DECIMAL(10,2) NULL,
    NewLastPrice DECIMAL(10,2) NULL,
    
    -- Index Data at Change Time (Nullable)
    IndexOpenPrice DECIMAL(10,2) NULL,
    IndexHighPrice DECIMAL(10,2) NULL,
    IndexLowPrice DECIMAL(10,2) NULL,
    IndexClosePrice DECIMAL(10,2) NULL,
    IndexLastPrice DECIMAL(10,2) NULL,
    
    -- Metadata
    CreatedAt DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    -- Indexes for performance
    INDEX IX_CircuitLimitChanges_TradingDate (TradingDate),
    INDEX IX_CircuitLimitChanges_ChangeTime (ChangeTime),
    INDEX IX_CircuitLimitChanges_InstrumentToken (InstrumentToken),
    INDEX IX_CircuitLimitChanges_ChangeType (ChangeType),
    INDEX IX_CircuitLimitChanges_TradingSymbol (TradingSymbol),
    INDEX IX_CircuitLimitChanges_Composite (TradingDate, InstrumentToken, ChangeTime)
);

GO

PRINT 'CircuitLimitChanges table recreated successfully!';


