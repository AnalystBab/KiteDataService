using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Real-time intraday spot data for indices (NIFTY, SENSEX, BANKNIFTY)
    /// Multiple rows per index per day - real-time quotes
    /// Used for: Real-time monitoring, current spot prices, intraday analysis
    /// </summary>
    [Table("IntradaySpotData")]
    public class IntradaySpotData
    {
        [Key]
        public long Id { get; set; }

        /// <summary>
        /// Index name: NIFTY, SENSEX, BANKNIFTY
        /// </summary>
        [Required]
        [StringLength(50)]
        public string IndexName { get; set; } = string.Empty;

        /// <summary>
        /// Trading date (business date) - YYYY-MM-DD
        /// </summary>
        [Required]
        public DateTime TradingDate { get; set; }

        /// <summary>
        /// Real-time quote timestamp
        /// </summary>
        [Required]
        public DateTime QuoteTimestamp { get; set; }

        /// <summary>
        /// Intraday open price
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal OpenPrice { get; set; }

        /// <summary>
        /// Intraday high price
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal HighPrice { get; set; }

        /// <summary>
        /// Intraday low price
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal LowPrice { get; set; }

        /// <summary>
        /// Intraday close price
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal ClosePrice { get; set; }

        /// <summary>
        /// Current last price (most important for spot calculation)
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal LastPrice { get; set; }

        /// <summary>
        /// Intraday volume (optional)
        /// </summary>
        public long? Volume { get; set; }

        /// <summary>
        /// Price change from previous close
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal? Change { get; set; }

        /// <summary>
        /// Percentage change from previous close
        /// </summary>
        [Column(TypeName = "decimal(10,4)")]
        public decimal? ChangePercent { get; set; }

        /// <summary>
        /// Data source: 'KiteConnect (Derived from Options)'
        /// </summary>
        [Required]
        [StringLength(100)]
        public string DataSource { get; set; } = string.Empty;

        /// <summary>
        /// Market status at time of quote
        /// </summary>
        [Required]
        public bool IsMarketOpen { get; set; }

        /// <summary>
        /// Record creation timestamp
        /// </summary>
        [Required]
        public DateTime CreatedDate { get; set; } = DateTime.Now;

        /// <summary>
        /// Last update timestamp
        /// </summary>
        [Required]
        public DateTime LastUpdated { get; set; } = DateTime.Now;
    }
}
