-- Circuit Limit Change Tracking System
-- Tracks LC/UC changes and stores EOD data for comparison
-- Includes OHLC and LastPrice tracking for complete instrument data

USE KiteMarketData;
GO

-- =============================================
-- 1. EOD DATA STORAGE TABLE (Complete Instrument Data)
-- =============================================
IF OBJECT_ID('EODMarketData', 'U') IS NOT NULL
    DROP TABLE EODMarketData;
GO

CREATE TABLE EODMarketData (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TradingDate DATE NOT NULL,
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    Strike DECIMAL(10,2),
    InstrumentType NVARCHAR(10),
    Exchange NVARCHAR(20),
    Expiry DATETIME,
    OHLC_Open DECIMAL(10,2),
    OHLC_High DECIMAL(10,2),
    OHLC_Low DECIMAL(10,2),
    OHLC_Close DECIMAL(10,2),
    LastPrice DECIMAL(10,2),
    Volume BIGINT,
    OpenInterest DECIMAL(10,2),
    LowerCircuitLimit DECIMAL(10,2),
    UpperCircuitLimit DECIMAL(10,2),
    QuoteTimestamp DATETIME,
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Create indexes
CREATE INDEX IX_EOD_TradingDate ON EODMarketData(TradingDate);
CREATE INDEX IX_EOD_TradingSymbol ON EODMarketData(TradingSymbol);
CREATE INDEX IX_EOD_InstrumentToken ON EODMarketData(InstrumentToken);
CREATE INDEX IX_EOD_Strike ON EODMarketData(Strike);
CREATE INDEX IX_EOD_Expiry ON EODMarketData(Expiry);
GO

-- =============================================
-- 2. CIRCUIT LIMIT CHANGE TRACKING TABLE (Daily Comparison)
-- =============================================
IF OBJECT_ID('CircuitLimitChanges', 'U') IS NOT NULL
    DROP TABLE CircuitLimitChanges;
GO

CREATE TABLE CircuitLimitChanges (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    TradingDate DATE NOT NULL,
    InstrumentToken BIGINT NOT NULL,
    TradingSymbol NVARCHAR(100) NOT NULL,
    Strike DECIMAL(10,2),
    InstrumentType NVARCHAR(10),
    Exchange NVARCHAR(20),
    Expiry DATETIME,
    ChangeType NVARCHAR(20) NOT NULL, -- 'LC_CHANGE', 'UC_CHANGE', 'BOTH_CHANGE'
    
    -- Previous Day Values (Yesterday)
    PreviousLC DECIMAL(10,2),
    PreviousUC DECIMAL(10,2),
    PreviousOHLC_Open DECIMAL(10,2),
    PreviousOHLC_High DECIMAL(10,2),
    PreviousOHLC_Low DECIMAL(10,2),
    PreviousOHLC_Close DECIMAL(10,2),
    PreviousLastPrice DECIMAL(10,2),
    
    -- Current Day Values (Today)
    NewLC DECIMAL(10,2),
    NewUC DECIMAL(10,2),
    NewOHLC_Open DECIMAL(10,2),
    NewOHLC_High DECIMAL(10,2),
    NewOHLC_Low DECIMAL(10,2),
    NewOHLC_Close DECIMAL(10,2),
    NewLastPrice DECIMAL(10,2),
    
    -- Change Details
    ChangeTime DATETIME NOT NULL,
    
    -- NIFTY Index Data at Change Time
    IndexOHLC_Open DECIMAL(10,2),
    IndexOHLC_High DECIMAL(10,2),
    IndexOHLC_Low DECIMAL(10,2),
    IndexOHLC_Close DECIMAL(10,2),
    IndexLastPrice DECIMAL(10,2),
    
    CreatedAt DATETIME DEFAULT GETDATE()
);
GO

-- Create indexes
CREATE INDEX IX_Changes_TradingDate ON CircuitLimitChanges(TradingDate);
CREATE INDEX IX_Changes_TradingSymbol ON CircuitLimitChanges(TradingSymbol);
CREATE INDEX IX_Changes_ChangeType ON CircuitLimitChanges(ChangeType);
CREATE INDEX IX_Changes_Strike ON CircuitLimitChanges(Strike);
CREATE INDEX IX_Changes_Expiry ON CircuitLimitChanges(Expiry);
GO

-- =============================================
-- 3. STORED PROCEDURE: STORE EOD DATA (Daily Snapshot)
-- =============================================
IF OBJECT_ID('StoreEODData', 'P') IS NOT NULL
    DROP PROCEDURE StoreEODData;
GO

CREATE PROCEDURE StoreEODData
    @TradingDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Use current date if not provided
    IF @TradingDate IS NULL
        SET @TradingDate = CAST(GETDATE() AS DATE);
    
    -- Clear any existing data for the date
    DELETE FROM EODMarketData WHERE TradingDate = @TradingDate;
    
    -- Insert latest data for each instrument
    WITH LatestQuotes AS (
        SELECT 
            mq.InstrumentToken,
            mq.TradingSymbol,
            mq.Exchange,
            mq.Expiry,
            mq.OHLC_Open,
            mq.OHLC_High,
            mq.OHLC_Low,
            mq.OHLC_Close,
            mq.LastPrice,
            mq.Volume,
            mq.OpenInterest,
            mq.LowerCircuitLimit,
            mq.UpperCircuitLimit,
            mq.QuoteTimestamp,
            i.Strike,
            i.InstrumentType,
            ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
        FROM MarketQuotes mq
        INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
        WHERE CAST(mq.QuoteTimestamp AS DATE) = @TradingDate
    )
    INSERT INTO EODMarketData (
        TradingDate, InstrumentToken, TradingSymbol, Strike, InstrumentType, 
        Exchange, Expiry, OHLC_Open, OHLC_High, OHLC_Low, OHLC_Close, 
        LastPrice, Volume, OpenInterest, LowerCircuitLimit, UpperCircuitLimit, 
        QuoteTimestamp
    )
    SELECT 
        @TradingDate,
        InstrumentToken,
        TradingSymbol,
        Strike,
        InstrumentType,
        Exchange,
        Expiry,
        OHLC_Open,
        OHLC_High,
        OHLC_Low,
        OHLC_Close,
        LastPrice,
        Volume,
        OpenInterest,
        LowerCircuitLimit,
        UpperCircuitLimit,
        QuoteTimestamp
    FROM LatestQuotes
    WHERE rn = 1;
    
    PRINT 'EOD data stored for ' + CAST(@TradingDate AS VARCHAR(10)) + '. Records: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
END;
GO

-- =============================================
-- 4. STORED PROCEDURE: DETECT CIRCUIT LIMIT CHANGES (Daily Comparison)
-- =============================================
IF OBJECT_ID('DetectCircuitLimitChanges', 'P') IS NOT NULL
    DROP PROCEDURE DetectCircuitLimitChanges;
GO

CREATE PROCEDURE DetectCircuitLimitChanges
    @TradingDate DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Use current date if not provided
    IF @TradingDate IS NULL
        SET @TradingDate = CAST(GETDATE() AS DATE);
    
    -- Get previous trading date (yesterday)
    DECLARE @PreviousDate DATE = DATEADD(DAY, -1, @TradingDate);
    
    -- Check if we have EOD data for previous date
    IF NOT EXISTS (SELECT 1 FROM EODMarketData WHERE TradingDate = @PreviousDate)
    BEGIN
        PRINT 'No EOD data found for previous date: ' + CAST(@PreviousDate AS VARCHAR(10));
        PRINT 'Please run StoreEODData for ' + CAST(@PreviousDate AS VARCHAR(10)) + ' first.';
        RETURN;
    END;
    
    -- Clear any existing changes for today
    DELETE FROM CircuitLimitChanges WHERE TradingDate = @TradingDate;
    
    -- Get current day's latest data and compare with previous day
    WITH CurrentDayData AS (
        SELECT 
            mq.InstrumentToken,
            mq.TradingSymbol,
            mq.Exchange,
            mq.Expiry,
            mq.OHLC_Open,
            mq.OHLC_High,
            mq.OHLC_Low,
            mq.OHLC_Close,
            mq.LastPrice,
            mq.Volume,
            mq.OpenInterest,
            mq.LowerCircuitLimit,
            mq.UpperCircuitLimit,
            mq.QuoteTimestamp,
            i.Strike,
            i.InstrumentType,
            ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
        FROM MarketQuotes mq
        INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
        WHERE CAST(mq.QuoteTimestamp AS DATE) = @TradingDate
    ),
    -- Get NIFTY spot data for index OHLC at change time
    NiftySpotData AS (
        SELECT TOP 1
            OHLC_Open, OHLC_High, OHLC_Low, OHLC_Close, LastPrice, QuoteTimestamp
        FROM MarketQuotes
        WHERE TradingSymbol = 'NIFTY' AND Exchange = 'NSE'
        ORDER BY QuoteTimestamp DESC
    )
    INSERT INTO CircuitLimitChanges (
        TradingDate, InstrumentToken, TradingSymbol, Strike, InstrumentType, Exchange, Expiry,
        ChangeType, 
        PreviousLC, PreviousUC, PreviousOHLC_Open, PreviousOHLC_High, PreviousOHLC_Low, PreviousOHLC_Close, PreviousLastPrice,
        NewLC, NewUC, NewOHLC_Open, NewOHLC_High, NewOHLC_Low, NewOHLC_Close, NewLastPrice,
        ChangeTime, IndexOHLC_Open, IndexOHLC_High, IndexOHLC_Low, IndexOHLC_Close, IndexLastPrice
    )
    SELECT 
        @TradingDate,
        c.InstrumentToken,
        c.TradingSymbol,
        c.Strike,
        c.InstrumentType,
        c.Exchange,
        c.Expiry,
        CASE 
            WHEN p.LowerCircuitLimit != c.LowerCircuitLimit AND p.UpperCircuitLimit != c.UpperCircuitLimit THEN 'BOTH_CHANGE'
            WHEN p.LowerCircuitLimit != c.LowerCircuitLimit THEN 'LC_CHANGE'
            WHEN p.UpperCircuitLimit != c.UpperCircuitLimit THEN 'UC_CHANGE'
        END as ChangeType,
        
        -- Previous Day Values (Yesterday)
        p.LowerCircuitLimit as PreviousLC,
        p.UpperCircuitLimit as PreviousUC,
        p.OHLC_Open as PreviousOHLC_Open,
        p.OHLC_High as PreviousOHLC_High,
        p.OHLC_Low as PreviousOHLC_Low,
        p.OHLC_Close as PreviousOHLC_Close,
        p.LastPrice as PreviousLastPrice,
        
        -- Current Day Values (Today)
        c.LowerCircuitLimit as NewLC,
        c.UpperCircuitLimit as NewUC,
        c.OHLC_Open as NewOHLC_Open,
        c.OHLC_High as NewOHLC_High,
        c.OHLC_Low as NewOHLC_Low,
        c.OHLC_Close as NewOHLC_Close,
        c.LastPrice as NewLastPrice,
        
        c.QuoteTimestamp as ChangeTime,
        n.OHLC_Open, n.OHLC_High, n.OHLC_Low, n.OHLC_Close, n.LastPrice
    FROM CurrentDayData c
    INNER JOIN EODMarketData p ON c.TradingSymbol = p.TradingSymbol 
        AND p.TradingDate = @PreviousDate
    CROSS JOIN NiftySpotData n
    WHERE c.rn = 1
        AND (p.LowerCircuitLimit != c.LowerCircuitLimit OR p.UpperCircuitLimit != c.UpperCircuitLimit);
    
    PRINT 'Circuit limit changes detected for ' + CAST(@TradingDate AS VARCHAR(10)) + '. Records: ' + CAST(@@ROWCOUNT AS VARCHAR(10));
END;
GO

PRINT 'All tables and stored procedures created successfully!';
GO

-- =============================================
-- 5. QUERY: GET TODAY'S CIRCUIT LIMIT CHANGES (Complete View)
-- =============================================
SELECT 
    TradingSymbol,
    Strike,
    InstrumentType,
    Expiry,
    ChangeType,
    
    -- Previous Day Values
    PreviousLC, PreviousUC,
    PreviousOHLC_Open, PreviousOHLC_High, PreviousOHLC_Low, PreviousOHLC_Close, PreviousLastPrice,
    
    -- Current Day Values
    NewLC, NewUC,
    NewOHLC_Open, NewOHLC_High, NewOHLC_Low, NewOHLC_Close, NewLastPrice,
    
    -- Change Details
    ChangeTime,
    IndexOHLC_Close as NiftyClose,
    IndexLastPrice as NiftyLastPrice
FROM CircuitLimitChanges
WHERE TradingDate = CAST(GETDATE() AS DATE)
ORDER BY ChangeTime DESC;

-- =============================================
-- 6. QUERY: COMPARE TODAY vs YESTERDAY EOD DATA (Strike-wise)
-- =============================================
SELECT 
    t.TradingSymbol,
    t.Strike,
    t.InstrumentType,
    t.Expiry,
    
    -- LC Comparison
    t.LowerCircuitLimit as TodayLC,
    y.LowerCircuitLimit as YesterdayLC,
    CASE 
        WHEN t.LowerCircuitLimit != y.LowerCircuitLimit THEN 'LC_CHANGED'
        ELSE 'NO_CHANGE'
    END as LC_ChangeStatus,
    
    -- UC Comparison
    t.UpperCircuitLimit as TodayUC,
    y.UpperCircuitLimit as YesterdayUC,
    CASE 
        WHEN t.UpperCircuitLimit != y.UpperCircuitLimit THEN 'UC_CHANGED'
        ELSE 'NO_CHANGE'
    END as UC_ChangeStatus,
    
    -- OHLC Comparison
    t.OHLC_Close as TodayClose,
    y.OHLC_Close as YesterdayClose,
    t.LastPrice as TodayLastPrice,
    y.LastPrice as YesterdayLastPrice
FROM EODMarketData t
LEFT JOIN EODMarketData y ON t.TradingSymbol = y.TradingSymbol 
    AND y.TradingDate = DATEADD(DAY, -1, t.TradingDate)
WHERE t.TradingDate = CAST(GETDATE() AS DATE)
    AND (t.LowerCircuitLimit != y.LowerCircuitLimit OR t.UpperCircuitLimit != y.UpperCircuitLimit)
ORDER BY t.Strike, t.TradingSymbol;

-- =============================================
-- 7. QUERY: NIFTY AUG 14 CALL OPTIONS WITH EOD COMPARISON (Your Format)
-- =============================================
WITH LatestCALLQuotes AS (
    SELECT 
        mq.*,
        i.Strike,
        i.InstrumentType,
        ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE 
        mq.TradingSymbol LIKE 'NIFTY%' 
        AND CAST(mq.Expiry AS DATE) = '2025-08-14'
        AND i.InstrumentType = 'CE'
        AND mq.Expiry IS NOT NULL
)
SELECT 
    Strike AS StrkPric,
    OHLC_Open AS OpnPric,
    OHLC_High AS HghPric,
    OHLC_Low AS LwPric,
    OHLC_Close AS ClsPric,
    LastPrice AS LastPric,
    LowerCircuitLimit AS lowerLimit,
    UpperCircuitLimit AS UpperLimit,
    
    -- EOD comparison columns
    eod.LowerCircuitLimit as EOD_LC,
    eod.UpperCircuitLimit as EOD_UC,
    eod.OHLC_Close as EOD_Close,
    eod.LastPrice as EOD_LastPrice,
    
    CASE 
        WHEN eod.LowerCircuitLimit != LowerCircuitLimit THEN 'LC_CHANGED'
        WHEN eod.UpperCircuitLimit != UpperCircuitLimit THEN 'UC_CHANGED'
        ELSE 'NO_CHANGE'
    END as CircuitChange
FROM LatestCALLQuotes lq
LEFT JOIN EODMarketData eod ON lq.TradingSymbol = eod.TradingSymbol 
    AND eod.TradingDate = CAST(GETDATE() AS DATE)
WHERE lq.rn = 1
ORDER BY Strike ASC;

-- =============================================
-- 8. AUTOMATION SCRIPT: DAILY EOD PROCESS
-- =============================================
-- Run this daily after market hours:
-- EXEC StoreEODData;           -- Store today's EOD data
-- EXEC DetectCircuitLimitChanges;  -- Compare with yesterday and detect changes

-- =============================================
-- 9. TEST QUERY: VERIFY EOD DATA STORAGE
-- =============================================
SELECT 
    TradingDate,
    COUNT(*) as InstrumentCount,
    MIN(QuoteTimestamp) as EarliestQuote,
    MAX(QuoteTimestamp) as LatestQuote
FROM EODMarketData
GROUP BY TradingDate
ORDER BY TradingDate DESC;

-- =============================================
-- 10. TEST QUERY: VERIFY CHANGE TRACKING
-- =============================================
SELECT 
    TradingDate,
    ChangeType,
    COUNT(*) as ChangeCount
FROM CircuitLimitChanges
GROUP BY TradingDate, ChangeType
ORDER BY TradingDate DESC, ChangeType;
