using System;
using System.ComponentModel.DataAnnotations;

namespace KiteMarketDataService.Worker.Models
{
    public class DailyMarketSnapshot
    {
        [Key]
        public long Id { get; set; }
        
        // Trading Information
        public DateTime TradingDate { get; set; }
        public DateTime SnapshotTime { get; set; }
        
        // Instrument Information
        public long InstrumentToken { get; set; }
        public string TradingSymbol { get; set; } = string.Empty;
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty;
        public string Exchange { get; set; } = string.Empty;
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
        public decimal OpenInterest { get; set; }
        public decimal NetChange { get; set; }
        
        // Snapshot Type
        public string SnapshotType { get; set; } = string.Empty; // 'MARKET_OPEN', 'MARKET_CLOSE', 'POST_MARKET'
        
        // Metadata
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}
