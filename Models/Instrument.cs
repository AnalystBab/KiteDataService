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
        
        /// <summary>
        /// DEPRECATED: Use FirstSeenDate instead
        /// The business date when this instrument was loaded from API
        /// </summary>
        public DateTime LoadDate { get; set; } = DateTime.UtcNow.AddHours(5.5).Date; // IST date (kept for backward compatibility)
        
        /// <summary>
        /// When we FIRST discovered this instrument in Kite API
        /// This is our best approximation of when NSE introduced this strike
        /// Note: This is when WE first saw it, not necessarily when NSE created it
        /// </summary>
        public DateTime FirstSeenDate { get; set; } = DateTime.UtcNow.AddHours(5.5).Date;
        
        /// <summary>
        /// When we LAST fetched this instrument from Kite API
        /// Updated every time we refresh instruments and this instrument is still present
        /// </summary>
        public DateTime LastFetchedDate { get; set; } = DateTime.UtcNow.AddHours(5.5).Date;
        
        /// <summary>
        /// Flag indicating if this instrument has expired
        /// Calculated based on: Expiry date < Current date
        /// </summary>
        public bool IsExpired { get; set; } = false;
        
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow.AddHours(5.5); // Use IST time by default
        
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
} 