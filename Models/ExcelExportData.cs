using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Flexible table to store Excel export data with dynamic LC/UC time columns
    /// </summary>
    public class ExcelExportData
    {
        [Key]
        public long Id { get; set; }

        [Required]
        public DateTime BusinessDate { get; set; }

        [Required]
        public DateTime ExpiryDate { get; set; }

        [Required]
        public int Strike { get; set; }

        [Required]
        [MaxLength(2)]
        public string OptionType { get; set; } = string.Empty; // CE or PE

        // Basic OHLC data
        public decimal OpenPrice { get; set; }
        public decimal HighPrice { get; set; }
        public decimal LowPrice { get; set; }
        public decimal ClosePrice { get; set; }
        public decimal LastPrice { get; set; }

        // Flexible JSON columns for dynamic LC/UC data
        [Column(TypeName = "nvarchar(max)")]
        public string LCUCTimeData { get; set; } = string.Empty; // JSON: {"0915": {"time": "09:15:00", "lc": 0.05, "uc": 23.40}, "1130": {"time": "11:30:00", "lc": 0.05, "uc": 25.10}}

        [Column(TypeName = "nvarchar(max)")]
        public string AdditionalData { get; set; } = string.Empty; // JSON for any future dynamic columns

        // Metadata
        public DateTime ExportDateTime { get; set; }
        public string ExportType { get; set; } = string.Empty; // "ConsolidatedLCUC" or "Traditional"
        public string FilePath { get; set; } = string.Empty;

        // Indexes for performance
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow.AddHours(5.5); // IST
    }
}


