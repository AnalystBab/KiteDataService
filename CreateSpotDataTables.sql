-- =============================================
-- CREATE SEPARATE TABLES FOR HISTORICAL AND INTRADAY SPOT DATA
-- =============================================

-- 1. CREATE HISTORICAL SPOT DATA TABLE (Daily OHLC - one row per date per index)
-- =============================================
CREATE TABLE HistoricalSpotData (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    IndexName NVARCHAR(50) NOT NULL,           -- NIFTY, SENSEX, BANKNIFTY
    TradingDate DATE NOT NULL,                 -- Business date (YYYY-MM-DD)
    OpenPrice DECIMAL(18,2) NOT NULL,          -- Daily open price
    HighPrice DECIMAL(18,2) NOT NULL,          -- Daily high price
    LowPrice DECIMAL(18,2) NOT NULL,           -- Daily low price
    ClosePrice DECIMAL(18,2) NOT NULL,         -- Daily close price
    Volume BIGINT NULL,                        -- Daily volume
    DataSource NVARCHAR(100) NOT NULL,         -- 'Kite Historical API'
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    LastUpdated DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    -- UNIQUE CONSTRAINT: One row per index per date
    CONSTRAINT UK_HistoricalSpotData_IndexDate UNIQUE (IndexName, TradingDate)
);

-- 2. CREATE INTRADAY SPOT DATA TABLE (Real-time quotes - multiple rows per day)
-- =============================================
CREATE TABLE IntradaySpotData (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    IndexName NVARCHAR(50) NOT NULL,           -- NIFTY, SENSEX, BANKNIFTY
    TradingDate DATE NOT NULL,                 -- Business date (YYYY-MM-DD)
    QuoteTimestamp DATETIME2 NOT NULL,         -- Real-time quote timestamp
    OpenPrice DECIMAL(18,2) NOT NULL,          -- Intraday open
    HighPrice DECIMAL(18,2) NOT NULL,          -- Intraday high
    LowPrice DECIMAL(18,2) NOT NULL,           -- Intraday low
    ClosePrice DECIMAL(18,2) NOT NULL,         -- Intraday close
    LastPrice DECIMAL(18,2) NOT NULL,          -- Current last price
    Volume BIGINT NULL,                        -- Intraday volume
    Change DECIMAL(18,2) NULL,                 -- Price change
    ChangePercent DECIMAL(10,4) NULL,          -- Percentage change
    DataSource NVARCHAR(100) NOT NULL,         -- 'KiteConnect (Derived from Options)'
    IsMarketOpen BIT NOT NULL,                 -- Market status at time of quote
    CreatedDate DATETIME2 NOT NULL DEFAULT GETDATE(),
    LastUpdated DATETIME2 NOT NULL DEFAULT GETDATE()
);

-- 3. CREATE INDEXES FOR PERFORMANCE
-- =============================================
CREATE INDEX IX_HistoricalSpotData_IndexDate ON HistoricalSpotData (IndexName, TradingDate DESC);
CREATE INDEX IX_HistoricalSpotData_TradingDate ON HistoricalSpotData (TradingDate DESC);

CREATE INDEX IX_IntradaySpotData_IndexDate ON IntradaySpotData (IndexName, TradingDate DESC);
CREATE INDEX IX_IntradaySpotData_QuoteTimestamp ON IntradaySpotData (QuoteTimestamp DESC);
CREATE INDEX IX_IntradaySpotData_IndexTimestamp ON IntradaySpotData (IndexName, QuoteTimestamp DESC);

-- 4. INSERT SAMPLE DATA STRUCTURE COMMENTS
-- =============================================
/*
HISTORICAL SPOT DATA (Daily OHLC):
- One row per index per trading date
- Example: SENSEX, 2025-10-08, Open: 81899.51, High: 82257.74, Low: 81646.08, Close: 81773.66
- Used for: BusinessDate calculation, historical analysis, previous day's close

INTRADAY SPOT DATA (Real-time quotes):
- Multiple rows per index per day (every few minutes)
- Example: SENSEX, 2025-10-08, 18:30:00, LastPrice: 81773.66
- Used for: Real-time monitoring, current spot prices, intraday analysis
*/

PRINT '✅ Spot data tables created successfully!';
PRINT '📊 HistoricalSpotData: For daily OHLC (one row per date per index)';
PRINT '📈 IntradaySpotData: For real-time quotes (multiple rows per day)';
