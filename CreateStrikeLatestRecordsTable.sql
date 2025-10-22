-- Create table to maintain only the latest 3 records for each strike
-- Any given time, only last 3 records for each strike

CREATE TABLE StrikeLatestRecords (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    TradingSymbol NVARCHAR(50) NOT NULL,
    Strike DECIMAL(10,2) NOT NULL,
    OptionType NVARCHAR(10) NOT NULL,
    ExpiryDate DATE NOT NULL,
    BusinessDate DATE NOT NULL,
    
    -- OHLC Data
    OpenPrice DECIMAL(10,2),
    HighPrice DECIMAL(10,2),
    LowPrice DECIMAL(10,2),
    ClosePrice DECIMAL(10,2),
    LastPrice DECIMAL(10,2),
    
    -- Circuit Limits
    LowerCircuitLimit DECIMAL(10,2),
    UpperCircuitLimit DECIMAL(10,2),
    
    -- Timestamps
    RecordDateTime DATETIME2 NOT NULL,
    InsertionSequence INT NOT NULL,
    
    -- Record Management
    RecordOrder INT NOT NULL, -- 1=Latest, 2=Second Latest, 3=Oldest
    
    -- Metadata
    CreatedAt DATETIME2 DEFAULT GETUTCDATE(),
    
    -- Unique constraint to ensure only 3 records per strike
    CONSTRAINT UK_StrikeLatestRecords_Strike_Type_Expiry_Order 
        UNIQUE (TradingSymbol, Strike, OptionType, ExpiryDate, RecordOrder)
);

-- Indexes for performance
CREATE INDEX IX_StrikeLatestRecords_Strike_Type_Expiry 
    ON StrikeLatestRecords (TradingSymbol, Strike, OptionType, ExpiryDate);

CREATE INDEX IX_StrikeLatestRecords_BusinessDate 
    ON StrikeLatestRecords (BusinessDate);

CREATE INDEX IX_StrikeLatestRecords_RecordDateTime 
    ON StrikeLatestRecords (RecordDateTime);

CREATE INDEX IX_StrikeLatestRecords_RecordOrder 
    ON StrikeLatestRecords (TradingSymbol, Strike, OptionType, ExpiryDate, RecordOrder);








