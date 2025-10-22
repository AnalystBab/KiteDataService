using System.ComponentModel.DataAnnotations;

namespace KiteMarketDataService.Worker.Models
{
    public class SpotData
    {
        [Key]
        public long Id { get; set; }
        
        public string IndexName { get; set; } = string.Empty;
        
        public DateTime TradingDate { get; set; }
        
        public DateTime QuoteTimestamp { get; set; }
        
        public decimal OpenPrice { get; set; }
        
        public decimal HighPrice { get; set; }
        
        public decimal LowPrice { get; set; }
        
        public decimal ClosePrice { get; set; }
        
        public decimal LastPrice { get; set; }
        
        public long Volume { get; set; }
        
        public decimal Change { get; set; }
        
        public decimal ChangePercent { get; set; }
        
        public DateTime CreatedDate { get; set; }
        
        public DateTime LastUpdated { get; set; }
        
        public string DataSource { get; set; } = string.Empty;
        
        public bool IsMarketOpen { get; set; }
    }
}




