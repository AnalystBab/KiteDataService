-- Add Settlement Price field to MarketQuote table
-- This will store official NSE settlement prices

USE KiteMarketData;
GO

-- Add SettlementPrice field
ALTER TABLE [dbo].[MarketQuotes] 
ADD [SettlementPrice] DECIMAL(10,2) NULL;
GO

-- Add comment
EXEC sp_addextendedproperty 
    @name = N'MS_Description', 
    @value = N'Official NSE settlement price (not available from Kite API)', 
    @level0type = N'SCHEMA', @level0name = N'dbo', 
    @level1type = N'TABLE', @level1name = N'MarketQuotes', 
    @level2type = N'COLUMN', @level2name = N'SettlementPrice';
GO

PRINT 'SettlementPrice field added to MarketQuotes table';
PRINT 'Note: This field needs to be populated from NSE official sources';
GO





