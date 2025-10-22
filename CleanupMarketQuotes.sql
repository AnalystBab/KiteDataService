-- Cleanup MarketQuotes table - Remove unwanted columns
-- Keep only: BusinessDate, LastTradeDate, Expiry, Strike, OptionType, OHLC, LC/UC, TradingSymbol, LastPrice, InsertionSequence

USE KiteMarketData;
GO

-- Drop unwanted columns from MarketQuotes table
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS Id;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS TradingDate;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS TradeTime;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS QuoteTimestamp;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS InstrumentToken;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS Exchange;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS LastQuantity;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyQuantity;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellQuantity;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS AveragePrice;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS OpenInterest;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS OiDayHigh;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS OiDayLow;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS NetChange;

-- Drop all Buy/Sell price/quantity/orders columns
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyPrice1;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyQuantity1;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyOrders1;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyPrice2;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyQuantity2;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyOrders2;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyPrice3;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyQuantity3;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyOrders3;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyPrice4;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyQuantity4;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyOrders4;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyPrice5;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyQuantity5;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS BuyOrders5;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellPrice1;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellQuantity1;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellOrders1;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellPrice2;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellQuantity2;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellOrders2;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellPrice3;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellQuantity3;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellOrders3;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellPrice4;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellQuantity4;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellOrders4;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellPrice5;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellQuantity5;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SellOrders5;

-- Drop other unwanted columns
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS CreatedAt;
ALTER TABLE MarketQuotes DROP COLUMN IF EXISTS SettlementPrice;

PRINT 'MarketQuotes table cleanup completed - removed 47 unwanted columns';


