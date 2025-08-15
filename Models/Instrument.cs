using System;
using System.ComponentModel.DataAnnotations;

namespace KiteMarketDataService.Worker.Models
{
    public class Instrument
    {
        [Key]
        public long InstrumentToken { get; set; }
        
        public long ExchangeToken { get; set; }
        
        [Required]
        [MaxLength(50)]
        public string TradingSymbol { get; set; } = string.Empty;
        
        [MaxLength(200)]
        public string? Name { get; set; }
        
        public decimal LastPrice { get; set; }
        
        public DateTime? Expiry { get; set; }
        
        public decimal Strike { get; set; }
        
        public decimal TickSize { get; set; }
        
        public int LotSize { get; set; }
        
        [Required]
        [MaxLength(10)]
        public string InstrumentType { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(20)]
        public string Segment { get; set; } = string.Empty;
        
        [Required]
        [MaxLength(10)]
        public string Exchange { get; set; } = string.Empty;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
} 