-- Cleanup MarketQuotes table - Remove all unwanted columns in batches
USE KiteMarketData;
GO

-- Batch 1: Drop all Buy/Sell price columns
ALTER TABLE MarketQuotes DROP COLUMN BuyQuantity1, BuyQuantity2, BuyQuantity3, BuyQuantity4, BuyQuantity5;
GO

-- Batch 2: Drop all Buy/Sell orders columns  
ALTER TABLE MarketQuotes DROP COLUMN BuyOrders1, BuyOrders2, BuyOrders3, BuyOrders4, BuyOrders5;
GO

-- Batch 3: Drop all Sell price columns
ALTER TABLE MarketQuotes DROP COLUMN SellPrice1, SellPrice2, SellPrice3, SellPrice4, SellPrice5;
GO

-- Batch 4: Drop all Sell quantity columns
ALTER TABLE MarketQuotes DROP COLUMN SellQuantity1, SellQuantity2, SellQuantity3, SellQuantity4, SellQuantity5;
GO

-- Batch 5: Drop all Sell orders columns
ALTER TABLE MarketQuotes DROP COLUMN SellOrders1, SellOrders2, SellOrders3, SellOrders4, SellOrders5;
GO

-- Batch 6: Drop trading and volume columns
ALTER TABLE MarketQuotes DROP COLUMN BuyQuantity, SellQuantity, LastQuantity, AveragePrice, OpenInterest, OiDayHigh, OiDayLow, NetChange;
GO

-- Batch 7: Drop metadata columns
ALTER TABLE MarketQuotes DROP COLUMN TradingDate, TradeTime, QuoteTimestamp, InstrumentToken, Exchange, CreatedAt, SettlementPrice;
GO

PRINT 'MarketQuotes cleanup completed - removed unwanted columns';


