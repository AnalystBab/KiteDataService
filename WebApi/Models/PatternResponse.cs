using System;

namespace KiteMarketDataService.Worker.WebApi.Models
{
    /// <summary>
    /// Response model for discovered patterns
    /// </summary>
    public class PatternResponse
    {
        public int Id { get; set; }
        public string Formula { get; set; }
        public string TargetType { get; set; }
        public string IndexName { get; set; }
        
        // Performance metrics
        public decimal AvgErrorPercentage { get; set; }
        public decimal MinErrorPercentage { get; set; }
        public decimal MaxErrorPercentage { get; set; }
        public decimal ConsistencyScore { get; set; }
        public int OccurrenceCount { get; set; }
        
        // Pattern metadata
        public int Complexity { get; set; }
        public string LabelsUsed { get; set; }
        public string Rating { get; set; }
        
        // Dates
        public DateTime FirstDiscovered { get; set; }
        public DateTime LastOccurrence { get; set; }
        
        // Status
        public bool IsActive { get; set; }
        public bool IsRecommended { get; set; }
        public string ValidationStatus { get; set; }
    }
}



