using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Stores labeled calculation components for options strategy analysis
    /// Like OHLC for candles, but for strategy calculations
    /// </summary>
    public class StrategyLabel
    {
        [Key]
        public long Id { get; set; }

        /// <summary>
        /// Business date when strategy was calculated (D0 = prediction day)
        /// </summary>
        [Required]
        public DateTime BusinessDate { get; set; }

        /// <summary>
        /// Index name (NIFTY, SENSEX, BANKNIFTY)
        /// </summary>
        [Required]
        [MaxLength(20)]
        public string IndexName { get; set; } = string.Empty;

        /// <summary>
        /// Strategy process type (PUT_MINUS, CALL_MINUS)
        /// </summary>
        [Required]
        [MaxLength(50)]
        public string ProcessType { get; set; } = string.Empty;

        /// <summary>
        /// Label name (e.g., SPOT_CLOSE_D0, PUT_MINUS_VALUE, CALL_MINUS_TARGET_STRIKE)
        /// </summary>
        [Required]
        [MaxLength(100)]
        public string LabelName { get; set; } = string.Empty;

        /// <summary>
        /// Calculated value for this label
        /// </summary>
        [Column(TypeName = "decimal(18,2)")]
        public decimal LabelValue { get; set; }

        /// <summary>
        /// Formula used to calculate this value
        /// </summary>
        [MaxLength(500)]
        public string Formula { get; set; } = string.Empty;

        /// <summary>
        /// Meaning/interpretation of this label
        /// </summary>
        [MaxLength(1000)]
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// Calculation step number in the process
        /// </summary>
        public int StepNumber { get; set; }

        /// <summary>
        /// Source labels used in this calculation (comma-separated)
        /// </summary>
        [MaxLength(500)]
        public string? SourceLabels { get; set; }

        /// <summary>
        /// Target strike if applicable
        /// </summary>
        [Column(TypeName = "decimal(10,2)")]
        public decimal? TargetStrike { get; set; }

        /// <summary>
        /// Expiry date if applicable
        /// </summary>
        public DateTime? ExpiryDate { get; set; }

        /// <summary>
        /// Option type if applicable (CE, PE)
        /// </summary>
        [MaxLength(2)]
        public string? OptionType { get; set; }

        /// <summary>
        /// When this label was calculated
        /// </summary>
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow.AddHours(5.5);

        /// <summary>
        /// Notes or additional context
        /// </summary>
        [MaxLength(1000)]
        public string? Notes { get; set; }
    }
}

