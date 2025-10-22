using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Stores validation results when D1 actual data arrives
    /// Compares predictions against reality
    /// </summary>
    public class StrategyValidation
    {
        [Key]
        public long Id { get; set; }

        public long PredictionId { get; set; }

        [Required]
        public DateTime ActualDate { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal ActualValue { get; set; }

        [Column(TypeName = "decimal(10,2)")]
        public decimal? ActualStrike { get; set; }

        [MaxLength(2)]
        public string? ActualOptionType { get; set; }

        [Column(TypeName = "decimal(18,2)")]
        public decimal Error { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal ErrorPercentage { get; set; }

        [Column(TypeName = "decimal(5,2)")]
        public decimal AccuracyPercentage { get; set; }

        [Required]
        [MaxLength(20)]
        public string Status { get; set; } = string.Empty;

        public bool WithinTolerance { get; set; }

        [Column(TypeName = "nvarchar(max)")]
        public string? ValidationNotes { get; set; }

        [MaxLength(1000)]
        public string? PatternObserved { get; set; }

        public DateTime ValidatedAt { get; set; } = DateTime.UtcNow.AddHours(5.5);
    }
}

