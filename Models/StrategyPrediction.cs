using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Stores predictions for D1 (target day) generated from D0 (prediction day) data
    /// </summary>
    public class StrategyPrediction
    {
        [Key]
        public long Id { get; set; }

        public long? MatchId { get; set; }

        [Required]
        [MaxLength(100)]
        public string StrategyName { get; set; } = string.Empty;

        [Required]
        public DateTime PredictionDate { get; set; }

        [Required]
        public DateTime TargetDate { get; set; }

        [Required]
        [MaxLength(20)]
        public string IndexName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string PredictionType { get; set; } = string.Empty;

        [Column(TypeName = "decimal(18,2)")]
        public decimal PredictedValue { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? PredictedStrike { get; set; }

        [MaxLength(2)]
        public string? PredictedOptionType { get; set; }

        public int? ConfidenceLevel { get; set; }

        [MaxLength(500)]
        public string? SourceCalculation { get; set; }

        [MaxLength(500)]
        public string? SourceLabels { get; set; }

        [MaxLength(1000)]
        public string? PredictionNotes { get; set; }

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow.AddHours(5.5);
    }
}

