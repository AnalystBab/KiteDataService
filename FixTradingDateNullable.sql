-- Fix TradingDate and TradeTime to be nullable
-- This ensures TradingDate is only set when there's valid LTT (Last Trade Time)

USE KiteMarketData;
GO

-- Make TradingDate nullable
ALTER TABLE [dbo].[MarketQuotes] 
ALTER COLUMN [TradingDate] DATE NULL;
GO

-- Make TradeTime nullable  
ALTER TABLE [dbo].[MarketQuotes] 
ALTER COLUMN [TradeTime] TIME NULL;
GO

-- Update existing records where TradingDate is today but there's no valid LTT
-- Set TradingDate to NULL for records where LastTradeTime is NULL or invalid
UPDATE [dbo].[MarketQuotes] 
SET [TradingDate] = NULL, [TradeTime] = NULL
WHERE [LastTradeTime] IS NULL 
   OR [LastTradeTime] = '1900-01-01 00:00:00.000'
   OR [LastTradeTime] < '2020-01-01'; -- Invalid old dates
GO

-- Also update records where TradingDate is today but LastTradeTime is from a different day
UPDATE [dbo].[MarketQuotes] 
SET [TradingDate] = NULL, [TradeTime] = NULL
WHERE [TradingDate] = CAST(GETDATE() AS DATE) 
  AND [LastTradeTime] IS NOT NULL 
  AND CAST([LastTradeTime] AS DATE) != [TradingDate];
GO

PRINT 'TradingDate and TradeTime are now nullable and cleaned up for invalid data';
GO





