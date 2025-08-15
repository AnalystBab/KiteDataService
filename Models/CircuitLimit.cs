using System;
using System.ComponentModel.DataAnnotations;

namespace KiteMarketDataService.Worker.Models
{
    public class CircuitLimit
    {
        [Key]
        public long Id { get; set; }
        
        public DateTime TradingDate { get; set; }
        public long InstrumentToken { get; set; }
        public string TradingSymbol { get; set; } = string.Empty;
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty;
        public decimal LowerCircuitLimit { get; set; }
        public decimal UpperCircuitLimit { get; set; }
        public string Source { get; set; } = "QUOTE_API";
        public DateTime LastUpdated { get; set; } = DateTime.UtcNow;
    }

    public class CircuitLimitChangeRecord
    {
        [Key]
        public long Id { get; set; }
        
        // Trading Information
        public DateTime TradingDate { get; set; }
        public DateTime ChangeTime { get; set; }
        
        // Instrument Information
        public long InstrumentToken { get; set; }
        public string TradingSymbol { get; set; } = string.Empty;
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty;
        public string Exchange { get; set; } = string.Empty;
        public DateTime ExpiryDate { get; set; }
        
        // Change Information
        public string ChangeType { get; set; } = string.Empty; // 'LC_CHANGE', 'UC_CHANGE', 'BOTH_CHANGE'
        
        // Previous Values
        public decimal? PreviousLC { get; set; }
        public decimal? PreviousUC { get; set; }
        public decimal? PreviousOpenPrice { get; set; }
        public decimal? PreviousHighPrice { get; set; }
        public decimal? PreviousLowPrice { get; set; }
        public decimal? PreviousClosePrice { get; set; }
        public decimal? PreviousLastPrice { get; set; }
        
        // New Values
        public decimal? NewLC { get; set; }
        public decimal? NewUC { get; set; }
        public decimal? NewOpenPrice { get; set; }
        public decimal? NewHighPrice { get; set; }
        public decimal? NewLowPrice { get; set; }
        public decimal? NewClosePrice { get; set; }
        public decimal? NewLastPrice { get; set; }
        
        // Index Data at Change Time
        public decimal? IndexOpenPrice { get; set; }
        public decimal? IndexHighPrice { get; set; }
        public decimal? IndexLowPrice { get; set; }
        public decimal? IndexClosePrice { get; set; }
        public decimal? IndexLastPrice { get; set; }
        
        // Metadata
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
} 