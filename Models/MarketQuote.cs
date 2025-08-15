using System;
using System.ComponentModel.DataAnnotations;

namespace KiteMarketDataService.Worker.Models
{
    public class MarketQuote
    {
        [Key]
        public long Id { get; set; }
        
        // Trading Information
        public DateTime TradingDate { get; set; }
        public TimeSpan TradeTime { get; set; }
        public DateTime QuoteTimestamp { get; set; }
        
        // Instrument Information
        public long InstrumentToken { get; set; }
        public string TradingSymbol { get; set; } = string.Empty;
        public string Exchange { get; set; } = string.Empty;
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty; // 'CE' or 'PE'
        public DateTime ExpiryDate { get; set; }
        
        // Price Data (OHLC + Last)
        public decimal OpenPrice { get; set; }
        public decimal HighPrice { get; set; }
        public decimal LowPrice { get; set; }
        public decimal ClosePrice { get; set; }
        public decimal LastPrice { get; set; }
        
        // Circuit Limits
        public decimal LowerCircuitLimit { get; set; }
        public decimal UpperCircuitLimit { get; set; }
        
        // Volume and Trading Data
        public long Volume { get; set; }
        public long LastQuantity { get; set; }
        public long BuyQuantity { get; set; }
        public long SellQuantity { get; set; }
        public decimal AveragePrice { get; set; }
        
        // Open Interest
        public decimal OpenInterest { get; set; }
        public decimal OiDayHigh { get; set; }
        public decimal OiDayLow { get; set; }
        public decimal NetChange { get; set; }
        
        // Market Depth (Top 5 levels)
        public decimal? BuyPrice1 { get; set; }
        public long? BuyQuantity1 { get; set; }
        public int? BuyOrders1 { get; set; }
        public decimal? BuyPrice2 { get; set; }
        public long? BuyQuantity2 { get; set; }
        public int? BuyOrders2 { get; set; }
        public decimal? BuyPrice3 { get; set; }
        public long? BuyQuantity3 { get; set; }
        public int? BuyOrders3 { get; set; }
        public decimal? BuyPrice4 { get; set; }
        public long? BuyQuantity4 { get; set; }
        public int? BuyOrders4 { get; set; }
        public decimal? BuyPrice5 { get; set; }
        public long? BuyQuantity5 { get; set; }
        public int? BuyOrders5 { get; set; }
        
        public decimal? SellPrice1 { get; set; }
        public long? SellQuantity1 { get; set; }
        public int? SellOrders1 { get; set; }
        public decimal? SellPrice2 { get; set; }
        public long? SellQuantity2 { get; set; }
        public int? SellOrders2 { get; set; }
        public decimal? SellPrice3 { get; set; }
        public long? SellQuantity3 { get; set; }
        public int? SellOrders3 { get; set; }
        public decimal? SellPrice4 { get; set; }
        public long? SellQuantity4 { get; set; }
        public int? SellOrders4 { get; set; }
        public decimal? SellPrice5 { get; set; }
        public long? SellQuantity5 { get; set; }
        public int? SellOrders5 { get; set; }
        
        // Metadata
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        // Navigation property
        public virtual Instrument? Instrument { get; set; }
    }
} 