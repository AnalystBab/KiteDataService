-- Cleanup Duplicate Market Quotes
-- This script removes duplicate records where OHLC, LC, UC, and LastPrice are identical
-- Keeps only the latest record for each instrument with identical data

USE KiteMarketData;
GO

-- First, let's see how many duplicates we have
SELECT 
    InstrumentToken,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT CONCAT(
        ISNULL(CAST(OHLC_Open AS VARCHAR(20)), 'NULL'), '|',
        ISNULL(CAST(OHLC_High AS VARCHAR(20)), 'NULL'), '|',
        ISNULL(CAST(OHLC_Low AS VARCHAR(20)), 'NULL'), '|',
        ISNULL(CAST(OHLC_Close AS VARCHAR(20)), 'NULL'), '|',
        ISNULL(CAST(LowerCircuitLimit AS VARCHAR(20)), 'NULL'), '|',
        ISNULL(CAST(UpperCircuitLimit AS VARCHAR(20)), 'NULL'), '|',
        ISNULL(CAST(LastPrice AS VARCHAR(20)), 'NULL')
    )) as UniqueDataRecords
FROM MarketQuotes 
WHERE CAST(QuoteTimestamp AS DATE) = CAST(GETDATE() AS DATE)
GROUP BY InstrumentToken
HAVING COUNT(*) > COUNT(DISTINCT CONCAT(
    ISNULL(CAST(OHLC_Open AS VARCHAR(20)), 'NULL'), '|',
    ISNULL(CAST(OHLC_High AS VARCHAR(20)), 'NULL'), '|',
    ISNULL(CAST(OHLC_Low AS VARCHAR(20)), 'NULL'), '|',
    ISNULL(CAST(OHLC_Close AS VARCHAR(20)), 'NULL'), '|',
    ISNULL(CAST(LowerCircuitLimit AS VARCHAR(20)), 'NULL'), '|',
    ISNULL(CAST(UpperCircuitLimit AS VARCHAR(20)), 'NULL'), '|',
    ISNULL(CAST(LastPrice AS VARCHAR(20)), 'NULL')
))
ORDER BY TotalRecords DESC;
GO

-- Create a CTE to identify duplicates and keep only the latest record
WITH DuplicateData AS (
    SELECT 
        Id,
        InstrumentToken,
        QuoteTimestamp,
        OHLC_Open,
        OHLC_High,
        OHLC_Low,
        OHLC_Close,
        LowerCircuitLimit,
        UpperCircuitLimit,
        LastPrice,
        ROW_NUMBER() OVER (
            PARTITION BY 
                InstrumentToken,
                ISNULL(CAST(OHLC_Open AS VARCHAR(20)), 'NULL'),
                ISNULL(CAST(OHLC_High AS VARCHAR(20)), 'NULL'),
                ISNULL(CAST(OHLC_Low AS VARCHAR(20)), 'NULL'),
                ISNULL(CAST(OHLC_Close AS VARCHAR(20)), 'NULL'),
                ISNULL(CAST(LowerCircuitLimit AS VARCHAR(20)), 'NULL'),
                ISNULL(CAST(UpperCircuitLimit AS VARCHAR(20)), 'NULL'),
                ISNULL(CAST(LastPrice AS VARCHAR(20)), 'NULL')
            ORDER BY QuoteTimestamp DESC
        ) as RowNum
    FROM MarketQuotes
    WHERE CAST(QuoteTimestamp AS DATE) = CAST(GETDATE() AS DATE)
)
-- Delete duplicates (keep only the latest record for each unique data combination)
DELETE FROM MarketQuotes 
WHERE Id IN (
    SELECT Id 
    FROM DuplicateData 
    WHERE RowNum > 1
);
GO

-- Verify cleanup results
SELECT 
    'After Cleanup' as Status,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT InstrumentToken) as UniqueInstruments
FROM MarketQuotes 
WHERE CAST(QuoteTimestamp AS DATE) = CAST(GETDATE() AS DATE);
GO

-- Show sample of remaining records
SELECT TOP 10
    InstrumentToken,
    TradingSymbol,
    QuoteTimestamp,
    OHLC_Open,
    OHLC_High,
    OHLC_Low,
    OHLC_Close,
    LastPrice,
    LowerCircuitLimit,
    UpperCircuitLimit
FROM MarketQuotes 
WHERE CAST(QuoteTimestamp AS DATE) = CAST(GETDATE() AS DATE)
ORDER BY QuoteTimestamp DESC;
GO
