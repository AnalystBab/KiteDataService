-- ENHANCED CIRCUIT LIMIT TRACKING SYSTEM
-- Comprehensive solution for tracking LC/UC changes across all expiries

USE KiteMarketData;
GO

-- =============================================
-- 1. ENHANCED EOD DATA TABLE (Daily Snapshots)
-- =============================================

IF OBJECT_ID('DailyMarketSnapshots', 'U') IS NOT NULL
    DROP TABLE DailyMarketSnapshots;
GO

CREATE TABLE DailyMarketSnapshots (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    TradingDate DATE NOT NULL,
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    Strike DECIMAL(10,2),
    InstrumentType NVARCHAR(10),
    Exchange NVARCHAR(20),
    Expiry DATETIME,
    
    -- OHLC Data
    OHLC_Open DECIMAL(10,2),
    OHLC_High DECIMAL(10,2),
    OHLC_Low DECIMAL(10,2),
    OHLC_Close DECIMAL(10,2),
    LastPrice DECIMAL(10,2),
    Volume BIGINT,
    
    -- Circuit Limits (CRITICAL)
    LowerCircuitLimit DECIMAL(10,2),
    UpperCircuitLimit DECIMAL(10,2),
    
    -- Metadata
    SnapshotType NVARCHAR(20) NOT NULL, -- 'MARKET_OPEN', 'MARKET_CLOSE', 'POST_MARKET', 'LC_UC_CHANGE'
    SnapshotTime DATETIME NOT NULL,
    CreatedAt DATETIME DEFAULT GETUTCDATE(),
    
    -- Indexes for performance
    INDEX IX_DailyMarketSnapshots_Date (TradingDate),
    INDEX IX_DailyMarketSnapshots_Symbol (TradingSymbol),
    INDEX IX_DailyMarketSnapshots_Expiry (Expiry),
    INDEX IX_DailyMarketSnapshots_Type (SnapshotType),
    INDEX IX_DailyMarketSnapshots_Time (SnapshotTime)
);
GO

-- =============================================
-- 2. ENHANCED CIRCUIT LIMIT CHANGES TABLE
-- =============================================

IF OBJECT_ID('CircuitLimitChangeHistory', 'U') IS NOT NULL
    DROP TABLE CircuitLimitChangeHistory;
GO

CREATE TABLE CircuitLimitChangeHistory (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    TradingDate DATE NOT NULL,
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    Strike DECIMAL(10,2),
    InstrumentType NVARCHAR(10),
    Exchange NVARCHAR(20),
    Expiry DATETIME,
    
    -- Change Details
    ChangeType NVARCHAR(20) NOT NULL, -- 'LC_CHANGE', 'UC_CHANGE', 'BOTH_CHANGE'
    PreviousLC DECIMAL(10,2),
    PreviousUC DECIMAL(10,2),
    NewLC DECIMAL(10,2),
    NewUC DECIMAL(10,2),
    
    -- OHLC at Change Time
    OHLC_Open DECIMAL(10,2),
    OHLC_High DECIMAL(10,2),
    OHLC_Low DECIMAL(10,2),
    OHLC_Close DECIMAL(10,2),
    LastPrice DECIMAL(10,2),
    
    -- Index OHLC at Change Time (for correlation)
    IndexOHLC_Open DECIMAL(10,2),
    IndexOHLC_High DECIMAL(10,2),
    IndexOHLC_Low DECIMAL(10,2),
    IndexOHLC_Close DECIMAL(10,2),
    IndexLastPrice DECIMAL(10,2),
    
    -- Timestamps
    ChangeTime DATETIME NOT NULL,
    CreatedAt DATETIME DEFAULT GETUTCDATE(),
    
    -- Indexes
    INDEX IX_CircuitLimitChangeHistory_Date (TradingDate),
    INDEX IX_CircuitLimitChangeHistory_Symbol (TradingSymbol),
    INDEX IX_CircuitLimitChangeHistory_ChangeType (ChangeType),
    INDEX IX_CircuitLimitChangeHistory_Time (ChangeTime)
);
GO

-- =============================================
-- 3. MARKET SESSION TRACKING TABLE
-- =============================================

IF OBJECT_ID('MarketSessions', 'U') IS NOT NULL
    DROP TABLE MarketSessions;
GO

CREATE TABLE MarketSessions (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY,
    TradingDate DATE NOT NULL,
    SessionType NVARCHAR(20) NOT NULL, -- 'MARKET_OPEN', 'MARKET_CLOSE', 'POST_MARKET'
    StartTime DATETIME NOT NULL,
    EndTime DATETIME,
    Status NVARCHAR(20) DEFAULT 'ACTIVE', -- 'ACTIVE', 'COMPLETED', 'FAILED'
    RecordsProcessed INT DEFAULT 0,
    CreatedAt DATETIME DEFAULT GETUTCDATE(),
    
    INDEX IX_MarketSessions_Date (TradingDate),
    INDEX IX_MarketSessions_Type (SessionType),
    INDEX IX_MarketSessions_Status (Status)
);
GO

-- =============================================
-- 4. STORED PROCEDURE: STORE DAILY SNAPSHOT
-- =============================================

IF OBJECT_ID('StoreDailySnapshot', 'P') IS NOT NULL
    DROP PROCEDURE StoreDailySnapshot;
GO

CREATE PROCEDURE StoreDailySnapshot
    @TradingDate DATE,
    @SnapshotType NVARCHAR(20),
    @SnapshotTime DATETIME
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SessionId BIGINT;
    
    -- Create or update market session
    INSERT INTO MarketSessions (TradingDate, SessionType, StartTime, Status)
    VALUES (@TradingDate, @SnapshotType, @SnapshotTime, 'ACTIVE');
    
    SET @SessionId = SCOPE_IDENTITY();
    
    -- Store snapshot data for all instruments with current LC/UC values
    INSERT INTO DailyMarketSnapshots (
        TradingDate, InstrumentToken, TradingSymbol, Strike, InstrumentType, 
        Exchange, Expiry, OHLC_Open, OHLC_High, OHLC_Low, OHLC_Close, LastPrice, 
        Volume, LowerCircuitLimit, UpperCircuitLimit, SnapshotType, SnapshotTime
    )
    SELECT 
        @TradingDate,
        mq.InstrumentToken,
        mq.TradingSymbol,
        i.Strike,
        i.InstrumentType,
        mq.Exchange,
        mq.Expiry,
        mq.OHLC_Open,
        mq.OHLC_High,
        mq.OHLC_Low,
        mq.OHLC_Close,
        mq.LastPrice,
        mq.Volume,
        mq.LowerCircuitLimit,
        mq.UpperCircuitLimit,
        @SnapshotType,
        @SnapshotTime
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE CAST(mq.QuoteTimestamp AS DATE) = @TradingDate
    AND mq.QuoteTimestamp = (
        SELECT MAX(QuoteTimestamp) 
        FROM MarketQuotes mq2 
        WHERE mq2.InstrumentToken = mq.InstrumentToken 
        AND CAST(mq2.QuoteTimestamp AS DATE) = @TradingDate
    );
    
    -- Update session with record count
    UPDATE MarketSessions 
    SET RecordsProcessed = @@ROWCOUNT, 
        EndTime = GETUTCDATE(), 
        Status = 'COMPLETED'
    WHERE Id = @SessionId;
    
    PRINT 'Daily snapshot stored successfully for ' + CAST(@TradingDate AS NVARCHAR(10)) + 
          ' with ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' records';
END;
GO

-- =============================================
-- 5. STORED PROCEDURE: DETECT LC/UC CHANGES
-- =============================================

IF OBJECT_ID('DetectCircuitLimitChanges', 'P') IS NOT NULL
    DROP PROCEDURE DetectCircuitLimitChanges;
GO

CREATE PROCEDURE DetectCircuitLimitChanges
    @TradingDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get index OHLC data for correlation
    DECLARE @IndexOHLC TABLE (
        IndexSymbol NVARCHAR(20),
        OHLC_Open DECIMAL(10,2),
        OHLC_High DECIMAL(10,2),
        OHLC_Low DECIMAL(10,2),
        OHLC_Close DECIMAL(10,2),
        LastPrice DECIMAL(10,2)
    );
    
    -- Get NIFTY and SENSEX current OHLC
    INSERT INTO @IndexOHLC
    SELECT 
        TradingSymbol,
        OHLC_Open,
        OHLC_High,
        OHLC_Low,
        OHLC_Close,
        LastPrice
    FROM MarketQuotes 
    WHERE TradingSymbol IN ('NIFTY', 'SENSEX')
    AND CAST(QuoteTimestamp AS DATE) = @TradingDate
    AND QuoteTimestamp = (
        SELECT MAX(QuoteTimestamp) 
        FROM MarketQuotes mq2 
        WHERE mq2.TradingSymbol = MarketQuotes.TradingSymbol 
        AND CAST(mq2.QuoteTimestamp AS DATE) = @TradingDate
    );
    
    -- Detect changes by comparing with previous snapshot
    INSERT INTO CircuitLimitChangeHistory (
        TradingDate, InstrumentToken, TradingSymbol, Strike, InstrumentType,
        Exchange, Expiry, ChangeType, PreviousLC, PreviousUC, NewLC, NewUC,
        OHLC_Open, OHLC_High, OHLC_Low, OHLC_Close, LastPrice,
        IndexOHLC_Open, IndexOHLC_High, IndexOHLC_Low, IndexOHLC_Close, IndexLastPrice,
        ChangeTime
    )
    SELECT 
        @TradingDate,
        mq.InstrumentToken,
        mq.TradingSymbol,
        i.Strike,
        i.InstrumentType,
        mq.Exchange,
        mq.Expiry,
        CASE 
            WHEN prev.LowerCircuitLimit != mq.LowerCircuitLimit AND prev.UpperCircuitLimit != mq.UpperCircuitLimit THEN 'BOTH_CHANGE'
            WHEN prev.LowerCircuitLimit != mq.LowerCircuitLimit THEN 'LC_CHANGE'
            WHEN prev.UpperCircuitLimit != mq.UpperCircuitLimit THEN 'UC_CHANGE'
        END as ChangeType,
        prev.LowerCircuitLimit as PreviousLC,
        prev.UpperCircuitLimit as PreviousUC,
        mq.LowerCircuitLimit as NewLC,
        mq.UpperCircuitLimit as NewUC,
        mq.OHLC_Open,
        mq.OHLC_High,
        mq.OHLC_Low,
        mq.OHLC_Close,
        mq.LastPrice,
        idx.OHLC_Open as IndexOHLC_Open,
        idx.OHLC_High as IndexOHLC_High,
        idx.OHLC_Low as IndexOHLC_Low,
        idx.OHLC_Close as IndexOHLC_Close,
        idx.LastPrice as IndexLastPrice,
        mq.QuoteTimestamp as ChangeTime
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    LEFT JOIN DailyMarketSnapshots prev ON 
        prev.InstrumentToken = mq.InstrumentToken 
        AND prev.TradingDate = @TradingDate
        AND prev.SnapshotType = 'MARKET_OPEN'
    LEFT JOIN @IndexOHLC idx ON 
        (mq.TradingSymbol LIKE 'NIFTY%' AND idx.IndexSymbol = 'NIFTY')
        OR (mq.TradingSymbol LIKE 'SENSEX%' AND idx.IndexSymbol = 'SENSEX')
    WHERE CAST(mq.QuoteTimestamp AS DATE) = @TradingDate
    AND mq.QuoteTimestamp = (
        SELECT MAX(QuoteTimestamp) 
        FROM MarketQuotes mq2 
        WHERE mq2.InstrumentToken = mq.InstrumentToken 
        AND CAST(mq2.QuoteTimestamp AS DATE) = @TradingDate
    )
    AND (
        (prev.LowerCircuitLimit IS NOT NULL AND prev.LowerCircuitLimit != mq.LowerCircuitLimit)
        OR (prev.UpperCircuitLimit IS NOT NULL AND prev.UpperCircuitLimit != mq.UpperCircuitLimit)
    );
    
    PRINT 'Circuit limit changes detected: ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + ' changes';
END;
GO

-- =============================================
-- 6. STORED PROCEDURE: DAILY DATA BACKUP
-- =============================================

IF OBJECT_ID('CreateDailyBackup', 'P') IS NOT NULL
    DROP PROCEDURE CreateDailyBackup;
GO

CREATE PROCEDURE CreateDailyBackup
    @TradingDate DATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @BackupFileName NVARCHAR(500);
    SET @BackupFileName = 'C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\DatabaseBackups\KiteMarketData_Daily_' + 
                         CAST(@TradingDate AS NVARCHAR(10)) + '_' + 
                         REPLACE(CAST(GETDATE() AS NVARCHAR(20)), ':', '') + '.bak';
    
    -- Create backup
    BACKUP DATABASE KiteMarketData 
    TO DISK = @BackupFileName 
    WITH FORMAT, COMPRESSION, 
    DESCRIPTION = 'Daily backup for ' + CAST(@TradingDate AS NVARCHAR(10));
    
    PRINT 'Daily backup created: ' + @BackupFileName;
END;
GO

-- =============================================
-- 7. VIEW: DAILY SUMMARY
-- =============================================

IF OBJECT_ID('DailyMarketSummary', 'V') IS NOT NULL
    DROP VIEW DailyMarketSummary;
GO

CREATE VIEW DailyMarketSummary AS
SELECT 
    TradingDate,
    COUNT(DISTINCT TradingSymbol) as TotalInstruments,
    COUNT(DISTINCT CAST(Expiry AS DATE)) as TotalExpiryDates,
    COUNT(CASE WHEN SnapshotType = 'MARKET_OPEN' THEN 1 END) as MarketOpenRecords,
    COUNT(CASE WHEN SnapshotType = 'MARKET_CLOSE' THEN 1 END) as MarketCloseRecords,
    COUNT(CASE WHEN SnapshotType = 'POST_MARKET' THEN 1 END) as PostMarketRecords,
    COUNT(CASE WHEN SnapshotType = 'LC_UC_CHANGE' THEN 1 END) as ChangeRecords,
    MIN(SnapshotTime) as FirstSnapshot,
    MAX(SnapshotTime) as LastSnapshot
FROM DailyMarketSnapshots
GROUP BY TradingDate;
GO

PRINT 'Enhanced Circuit Limit Tracking System created successfully!';
GO
