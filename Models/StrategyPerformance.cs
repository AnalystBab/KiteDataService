using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Aggregated performance metrics for each strategy
    /// Tracks success rate, accuracy, and overall performance
    /// </summary>
    public class StrategyPerformance
    {
        [Key]
        public long Id { get; set; }

        [Required]
        [MaxLength(100)]
        public string StrategyName { get; set; } = string.Empty;

        [Column(TypeName = "decimal(3,1)")]
        public decimal StrategyVersion { get; set; }

        public int TotalPredictions { get; set; }

        public int SuccessfulPredictions { get; set; }

        public int FailedPredictions { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? AverageAccuracy { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? BestAccuracy { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? WorstAccuracy { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? AverageError { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? MedianError { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal? SuccessRate { get; set; }

        public DateTime? FirstPredictionDate { get; set; }

        public DateTime? LastPredictionDate { get; set; }

        public int? DaysTested { get; set; }

        [MaxLength(20)]
        public string StrategyStatus { get; set; } = "TESTING";

        public bool IsProduction { get; set; } = false;

        public DateTime LastUpdated { get; set; } = DateTime.UtcNow.AddHours(5.5);

        [Column(TypeName = "nvarchar(max)")]
        public string? Notes { get; set; }
    }
}

