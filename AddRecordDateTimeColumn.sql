-- Add RecordDateTime column to MarketQuotes table
-- This column will store when the LC/UC change was actually detected and recorded
-- Separate from BusinessDate and LastTradeTime

USE KiteMarketData;
GO

-- Add RecordDateTime column
ALTER TABLE MarketQuotes ADD RecordDateTime DATETIME2 NULL;
GO

-- Update existing records with current timestamp as record datetime
UPDATE MarketQuotes 
SET RecordDateTime = GETDATE() 
WHERE RecordDateTime IS NULL;
GO

-- Make RecordDateTime NOT NULL after updating existing records
ALTER TABLE MarketQuotes ALTER COLUMN RecordDateTime DATETIME2 NOT NULL;
GO

-- Create index on RecordDateTime for efficient querying
CREATE INDEX IX_MarketQuotes_RecordDateTime ON MarketQuotes (RecordDateTime);
GO

-- Create composite index for LC/UC change queries
CREATE INDEX IX_MarketQuotes_LC_UC_Changes ON MarketQuotes (TradingSymbol, BusinessDate, RecordDateTime);
GO

PRINT 'RecordDateTime column added successfully with indexes';


