-- Final cleanup and rename MarketQuotes table columns
USE KiteMarketData;
GO

-- Remove remaining unwanted columns
ALTER TABLE MarketQuotes DROP COLUMN Id, TradingDate, TradeTime, QuoteTimestamp, InstrumentToken, Exchange, Volume, CreatedAt, SettlementPrice;
GO

-- Add new primary key on remaining columns
ALTER TABLE MarketQuotes ADD CONSTRAINT PK_MarketQuotes PRIMARY KEY (BusinessDate, TradingSymbol, InsertionSequence);
GO

PRINT 'MarketQuotes cleanup completed - kept only required columns with new primary key';


