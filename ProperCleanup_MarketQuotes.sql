-- Proper cleanup of MarketQuotes table with index handling
USE KiteMarketData;
GO

-- Drop all indexes first
DROP INDEX IF EXISTS IX_MarketQuotes_QuoteTimestamp ON MarketQuotes;
DROP INDEX IF EXISTS IX_MarketQuotes_BusinessDate ON MarketQuotes;
DROP INDEX IF EXISTS IX_MarketQuotes_InstrumentToken ON MarketQuotes;
DROP INDEX IF EXISTS IX_MarketQuotes_TradingSymbol ON MarketQuotes;
DROP INDEX IF EXISTS IX_MarketQuotes_ExpiryDate ON MarketQuotes;
DROP INDEX IF EXISTS IX_MarketQuotes_Strike ON MarketQuotes;
DROP INDEX IF EXISTS IX_MarketQuotes_OptionType ON MarketQuotes;
DROP INDEX IF EXISTS IX_MarketQuotes_IndexName ON MarketQuotes;
GO

-- Remove unwanted columns (one by one to avoid constraint issues)
ALTER TABLE MarketQuotes DROP COLUMN Id;
ALTER TABLE MarketQuotes DROP COLUMN TradingDate;
ALTER TABLE MarketQuotes DROP COLUMN TradeTime;
ALTER TABLE MarketQuotes DROP COLUMN QuoteTimestamp;
ALTER TABLE MarketQuotes DROP COLUMN InstrumentToken;
ALTER TABLE MarketQuotes DROP COLUMN Exchange;
ALTER TABLE MarketQuotes DROP COLUMN Volume;
ALTER TABLE MarketQuotes DROP COLUMN CreatedAt;
ALTER TABLE MarketQuotes DROP COLUMN SettlementPrice;
GO

-- Make nullable columns NOT NULL
UPDATE MarketQuotes SET BusinessDate = '2025-01-01' WHERE BusinessDate IS NULL;
UPDATE MarketQuotes SET InsertionSequence = 1 WHERE InsertionSequence IS NULL;
GO

ALTER TABLE MarketQuotes ALTER COLUMN BusinessDate DATE NOT NULL;
ALTER TABLE MarketQuotes ALTER COLUMN InsertionSequence INT NOT NULL;
GO

-- Create new primary key
ALTER TABLE MarketQuotes ADD CONSTRAINT PK_MarketQuotes PRIMARY KEY (BusinessDate, TradingSymbol, InsertionSequence);
GO

PRINT 'MarketQuotes properly cleaned up with new primary key';


