using System;

namespace KiteMarketDataService.Worker.WebApi.Models
{
    /// <summary>
    /// Response model for live market data
    /// </summary>
    public class LiveMarketResponse
    {
        public string IndexName { get; set; }
        public DateTime TradingDate { get; set; }
        
        // OHLC data
        public decimal OpenPrice { get; set; }
        public decimal HighPrice { get; set; }
        public decimal LowPrice { get; set; }
        public decimal ClosePrice { get; set; }
        
        // Change metrics
        public decimal ChangePercent { get; set; }
        public decimal ChangeValue { get; set; }
        
        // Additional info
        public DateTime LastUpdated { get; set; }
        public string MarketStatus { get; set; }
    }
}



