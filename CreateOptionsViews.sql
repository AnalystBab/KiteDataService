-- Create SQL Server Views for Options Data Analysis
-- BusinessDate, ExpiryDate, TickerSymbol, StrikePrice, OHLC, LC/UC
-- Ordered by: Calls ASC, Puts DESC by Strike

USE KiteMarketData;
GO

-- =============================================
-- 1. MAIN OPTIONS VIEW - All Expiries Combined
-- =============================================

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_OptionsData')
    DROP VIEW vw_OptionsData;
GO

CREATE VIEW vw_OptionsData AS
SELECT 
    BusinessDate,
    ExpiryDate,
    TradingSymbol as TickerSymbol,
    Strike as StrikePrice,
    OptionType,
    OpenPrice as [Open],
    HighPrice as [High],
    LowPrice as [Low],
    ClosePrice as [Close],
    LastPrice,
    LowerCircuitLimit as LC,
    UpperCircuitLimit as UC,
    Volume,
    OpenInterest,
    LastTradeTime,
    QuoteTimestamp,
    -- Add ordering columns for easy sorting
    CASE WHEN OptionType = 'CE' THEN 1 ELSE 2 END as SortOrder,
    CASE WHEN OptionType = 'CE' THEN Strike ELSE -Strike END as SortStrike
FROM MarketQuotes
WHERE BusinessDate IS NOT NULL
    AND TradingSymbol LIKE 'NIFTY%'
    AND TradingSymbol != 'NIFTY' -- Exclude spot
GO

-- =============================================
-- 2. EXPIRY-WISE VIEWS - Individual Expiry Analysis
-- =============================================

-- December 2025 Expiry
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_NIFTY_Dec2025_Options')
    DROP VIEW vw_NIFTY_Dec2025_Options;
GO

CREATE VIEW vw_NIFTY_Dec2025_Options AS
SELECT 
    BusinessDate,
    ExpiryDate,
    TradingSymbol as TickerSymbol,
    Strike as StrikePrice,
    OptionType,
    OpenPrice as [Open],
    HighPrice as [High],
    LowPrice as [Low],
    ClosePrice as [Close],
    LastPrice,
    LowerCircuitLimit as LC,
    UpperCircuitLimit as UC,
    Volume,
    OpenInterest,
    LastTradeTime,
    QuoteTimestamp,
    CASE WHEN OptionType = 'CE' THEN Strike ELSE -Strike END as SortStrike
FROM MarketQuotes
WHERE BusinessDate IS NOT NULL
    AND TradingSymbol LIKE 'NIFTY%'
    AND TradingSymbol != 'NIFTY'
    AND ExpiryDate >= '2025-12-01'
    AND ExpiryDate <= '2025-12-31'
GO

-- June 2026 Expiry
IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_NIFTY_Jun2026_Options')
    DROP VIEW vw_NIFTY_Jun2026_Options;
GO

CREATE VIEW vw_NIFTY_Jun2026_Options AS
SELECT 
    BusinessDate,
    ExpiryDate,
    TradingSymbol as TickerSymbol,
    Strike as StrikePrice,
    OptionType,
    OpenPrice as [Open],
    HighPrice as [High],
    LowPrice as [Low],
    ClosePrice as [Close],
    LastPrice,
    LowerCircuitLimit as LC,
    UpperCircuitLimit as UC,
    Volume,
    OpenInterest,
    LastTradeTime,
    QuoteTimestamp,
    CASE WHEN OptionType = 'CE' THEN Strike ELSE -Strike END as SortStrike
FROM MarketQuotes
WHERE BusinessDate IS NOT NULL
    AND TradingSymbol LIKE 'NIFTY%'
    AND TradingSymbol != 'NIFTY'
    AND ExpiryDate >= '2026-06-01'
    AND ExpiryDate <= '2026-06-30'
GO

-- =============================================
-- 3. LC/UC CHANGE TRACKING VIEW
-- =============================================

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_LC_UC_Changes')
    DROP VIEW vw_LC_UC_Changes;
GO

CREATE VIEW vw_LC_UC_Changes AS
WITH ChangeData AS (
    SELECT 
        BusinessDate,
        TradingSymbol,
        Strike,
        OptionType,
        ExpiryDate,
        LowerCircuitLimit as LC,
        UpperCircuitLimit as UC,
        QuoteTimestamp,
        LastTradeTime,
        ROW_NUMBER() OVER (PARTITION BY TradingSymbol ORDER BY QuoteTimestamp) as ChangeNumber,
        LAG(LowerCircuitLimit) OVER (PARTITION BY TradingSymbol ORDER BY QuoteTimestamp) as PrevLC,
        LAG(UpperCircuitLimit) OVER (PARTITION BY TradingSymbol ORDER BY QuoteTimestamp) as PrevUC
    FROM MarketQuotes
    WHERE BusinessDate IS NOT NULL
        AND TradingSymbol LIKE 'NIFTY%'
        AND TradingSymbol != 'NIFTY'
)
SELECT 
    BusinessDate,
    ExpiryDate,
    TradingSymbol as TickerSymbol,
    Strike as StrikePrice,
    OptionType,
    LC,
    UC,
    PrevLC,
    PrevUC,
    CASE 
        WHEN LC != PrevLC AND UC != PrevUC THEN 'BOTH_CHANGED'
        WHEN LC != PrevLC THEN 'LC_CHANGED'
        WHEN UC != PrevUC THEN 'UC_CHANGED'
        ELSE 'NO_CHANGE'
    END as ChangeType,
    QuoteTimestamp as ChangeTime,
    LastTradeTime,
    ChangeNumber
FROM ChangeData
WHERE (LC != PrevLC OR UC != PrevUC OR PrevLC IS NULL)
GO

-- =============================================
-- 4. STRIKE-WISE SUMMARY VIEW
-- =============================================

IF EXISTS (SELECT * FROM sys.views WHERE name = 'vw_StrikeSummary')
    DROP VIEW vw_StrikeSummary;
GO

CREATE VIEW vw_StrikeSummary AS
SELECT 
    BusinessDate,
    ExpiryDate,
    StrikePrice,
    -- Call Data
    MAX(CASE WHEN OptionType = 'CE' THEN TickerSymbol END) as CallSymbol,
    MAX(CASE WHEN OptionType = 'CE' THEN [Open] END) as CallOpen,
    MAX(CASE WHEN OptionType = 'CE' THEN [High] END) as CallHigh,
    MAX(CASE WHEN OptionType = 'CE' THEN [Low] END) as CallLow,
    MAX(CASE WHEN OptionType = 'CE' THEN [Close] END) as CallClose,
    MAX(CASE WHEN OptionType = 'CE' THEN LC END) as CallLC,
    MAX(CASE WHEN OptionType = 'CE' THEN UC END) as CallUC,
    MAX(CASE WHEN OptionType = 'CE' THEN Volume END) as CallVolume,
    MAX(CASE WHEN OptionType = 'CE' THEN OpenInterest END) as CallOI,
    
    -- Put Data
    MAX(CASE WHEN OptionType = 'PE' THEN TickerSymbol END) as PutSymbol,
    MAX(CASE WHEN OptionType = 'PE' THEN [Open] END) as PutOpen,
    MAX(CASE WHEN OptionType = 'PE' THEN [High] END) as PutHigh,
    MAX(CASE WHEN OptionType = 'PE' THEN [Low] END) as PutLow,
    MAX(CASE WHEN OptionType = 'PE' THEN [Close] END) as PutClose,
    MAX(CASE WHEN OptionType = 'PE' THEN LC END) as PutLC,
    MAX(CASE WHEN OptionType = 'PE' THEN UC END) as PutUC,
    MAX(CASE WHEN OptionType = 'PE' THEN Volume END) as PutVolume,
    MAX(CASE WHEN OptionType = 'PE' THEN OpenInterest END) as PutOI
FROM vw_OptionsData
GROUP BY BusinessDate, ExpiryDate, StrikePrice
GO

-- =============================================
-- 5. CREATE INDEXES FOR PERFORMANCE
-- =============================================

-- Index on BusinessDate for faster filtering
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MarketQuotes_BusinessDate')
    CREATE INDEX IX_MarketQuotes_BusinessDate ON MarketQuotes(BusinessDate);

-- Index on ExpiryDate for expiry-wise analysis
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MarketQuotes_ExpiryDate')
    CREATE INDEX IX_MarketQuotes_ExpiryDate ON MarketQuotes(ExpiryDate);

-- Composite index for better performance
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_MarketQuotes_BusinessExpiry')
    CREATE INDEX IX_MarketQuotes_BusinessExpiry ON MarketQuotes(BusinessDate, ExpiryDate, Strike, OptionType);

PRINT '=============================================';
PRINT 'OPTIONS VIEWS CREATED SUCCESSFULLY';
PRINT '=============================================';
PRINT 'Available Views:';
PRINT '1. vw_OptionsData - All options data';
PRINT '2. vw_NIFTY_Dec2025_Options - December 2025 expiry';
PRINT '3. vw_NIFTY_Jun2026_Options - June 2026 expiry';
PRINT '4. vw_LC_UC_Changes - LC/UC change tracking';
PRINT '5. vw_StrikeSummary - Strike-wise summary';
PRINT '=============================================';
GO
