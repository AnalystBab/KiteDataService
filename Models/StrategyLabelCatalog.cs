using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Master catalog of all strategy label definitions
    /// Each label represents a specific calculation or data point
    /// </summary>
    public class StrategyLabelCatalog
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int LabelNumber { get; set; }

        [Required]
        [MaxLength(100)]
        public string LabelName { get; set; } = string.Empty;

        [Required]
        [MaxLength(50)]
        public string LabelCategory { get; set; } = string.Empty;

        public int StepNumber { get; set; }

        public int ImportanceLevel { get; set; }

        [MaxLength(500)]
        public string? Formula { get; set; }

        [MaxLength(2000)]
        public string? Description { get; set; }

        [MaxLength(2000)]
        public string? Purpose { get; set; }

        [MaxLength(2000)]
        public string? Meaning { get; set; }

        [MaxLength(50)]
        public string? DataType { get; set; }

        [MaxLength(50)]
        public string? UnitType { get; set; }

        [MaxLength(200)]
        public string? ValueRange { get; set; }

        [MaxLength(100)]
        public string? SourceTable { get; set; }

        [MaxLength(100)]
        public string? SourceColumn { get; set; }

        [Column(TypeName = "nvarchar(max)")]
        public string? SourceQuery { get; set; }

        [MaxLength(500)]
        public string? DependsOn { get; set; }

        [MaxLength(500)]
        public string? UsedBy { get; set; }

        [Column(TypeName = "nvarchar(max)")]
        public string? ValidationRules { get; set; }

        public int? ProcessingTimeMs { get; set; }

        public DateTime CreatedDate { get; set; } = DateTime.UtcNow.AddHours(5.5);

        public DateTime LastUpdated { get; set; } = DateTime.UtcNow.AddHours(5.5);

        [Column(TypeName = "nvarchar(max)")]
        public string? Notes { get; set; }
    }
}

