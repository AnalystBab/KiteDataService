using System;

namespace KiteMarketDataService.Worker.WebApi.Models
{
    /// <summary>
    /// Response model for strategy labels
    /// </summary>
    public class StrategyLabelResponse
    {
        public int LabelNumber { get; set; }
        public string LabelName { get; set; }
        public decimal LabelValue { get; set; }
        public string Formula { get; set; }
        public string Description { get; set; }
        public string Category { get; set; }
        public DateTime BusinessDate { get; set; }
        public string IndexName { get; set; }
    }
}



