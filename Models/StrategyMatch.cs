using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Stores matches found when scanning D0 strikes for UC/LC values
    /// that match calculated label values
    /// </summary>
    public class StrategyMatch
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string StrategyName { get; set; } = string.Empty;

        [Required]
        public DateTime BusinessDate { get; set; }

        [Required]
        [MaxLength(20)]
        public string IndexName { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string CalculatedLabelName { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal CalculatedValue { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal MatchedStrike { get; set; }

        [Required]
        [MaxLength(2)]
        public string MatchedOptionType { get; set; } = string.Empty;

        [Required]
        [MaxLength(10)]
        public string MatchedFieldType { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal MatchedValue { get; set; }

        public DateTime? MatchedExpiryDate { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Difference { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal MatchQuality { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal Tolerance { get; set; } = 50.00m;

        [MaxLength(1000)]
        public string? Hypothesis { get; set; }

        [MaxLength(50)]
        public string? PredictionType { get; set; }

        public int? ConfidenceLevel { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow.AddHours(5.5);

        [Column(TypeName = "nvarchar(max)")]
        public string? Notes { get; set; }
    }
}

