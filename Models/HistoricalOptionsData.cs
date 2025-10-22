using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Historical options data archive - preserves complete options data after expiry
    /// Since Kite API discontinues data after expiry, we archive it here for analysis
    /// </summary>
    public class HistoricalOptionsData
    {
        [Key]
        public long Id { get; set; }

        // Instrument Identification
        [Required]
        public long InstrumentToken { get; set; }

        [Required]
        [MaxLength(100)]
        public string TradingSymbol { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string IndexName { get; set; } = string.Empty;  // NIFTY, SENSEX, BANKNIFTY

        // Option Details
        [Required]
        public decimal Strike { get; set; }

        [Required]
        [MaxLength(2)]
        public string OptionType { get; set; } = string.Empty;  // CE or PE

        [Required]
        [Column(TypeName = "date")]
        public DateTime ExpiryDate { get; set; }

        // Trading Date
        [Required]
        [Column(TypeName = "date")]
        public DateTime TradingDate { get; set; }

        // OHLC Data (from Kite Historical API or current MarketQuotes)
        [Column(TypeName = "decimal(10,2)")]
        public decimal OpenPrice { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal HighPrice { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal LowPrice { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal ClosePrice { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal LastPrice { get; set; }

        // Volume
        public long Volume { get; set; }

        // Circuit Limits (from MarketQuotes - last record of business date)
        // These will be NULL for old data if not available
        [Column(TypeName = "decimal(10,2)")]
        public decimal? LowerCircuitLimit { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? UpperCircuitLimit { get; set; }

        // Open Interest
        [Column(TypeName = "decimal(15,2)")]
        public decimal? OpenInterest { get; set; }

        // Data Source Information
        [Required]
        [MaxLength(50)]
        public string DataSource { get; set; } = string.Empty;  // "KiteHistoricalAPI", "MarketQuotes", "Manual"

        // Archival Information
        [Required]
        public DateTime ArchivedDate { get; set; }  // When this data was archived

        [Required]
        public bool IsExpired { get; set; }  // Whether the option has expired

        // Last Trade Time (if available)
        public DateTime? LastTradeTime { get; set; }

        // Metadata
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow.AddHours(5.5);  // IST
        public DateTime LastUpdated { get; set; } = DateTime.UtcNow.AddHours(5.5);  // IST

        // Notes field for any additional information
        [MaxLength(500)]
        public string? Notes { get; set; }
    }
}

