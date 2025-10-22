using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Historical daily OHLC spot data for indices (NIFTY, SENSEX, BANKNIFTY)
    /// One row per index per trading date - no duplicates
    /// Used for: BusinessDate calculation, historical analysis, previous day's close
    /// </summary>
    [Table("HistoricalSpotData")]
    public class HistoricalSpotData
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
        /// Daily open price
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal OpenPrice { get; set; }

        /// <summary>
        /// Daily high price
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal HighPrice { get; set; }

        /// <summary>
        /// Daily low price
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal LowPrice { get; set; }

        /// <summary>
        /// Daily close price
        /// </summary>
        [Required]
        [Column(TypeName = "decimal(18,2)")]
        public decimal ClosePrice { get; set; }

        /// <summary>
        /// Daily volume (optional)
        /// </summary>
        public long? Volume { get; set; }

        /// <summary>
        /// Data source: 'Kite Historical API'
        /// </summary>
        [Required]
        [StringLength(100)]
        public string DataSource { get; set; } = string.Empty;

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
