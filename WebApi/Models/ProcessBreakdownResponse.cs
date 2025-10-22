using System;
using System.Collections.Generic;

namespace KiteMarketDataService.Worker.WebApi.Models
{
    /// <summary>
    /// Response model for C-/P-/C+/P+ process breakdown
    /// </summary>
    public class ProcessBreakdownResponse
    {
        public DateTime BusinessDate { get; set; }
        public string IndexName { get; set; }
        
        // Base data
        public decimal SpotClose { get; set; }
        public int CloseStrike { get; set; }
        public decimal CloseCeUc { get; set; }
        public decimal ClosePeUc { get; set; }
        
        // Base strikes
        public int CallBaseStrike { get; set; }
        public int PutBaseStrike { get; set; }
        public decimal CallBaseLc { get; set; }
        public decimal PutBaseLc { get; set; }
        public decimal CallBaseUc { get; set; }
        public decimal PutBaseUc { get; set; }
        
        // Processes
        public ProcessDetail CallMinus { get; set; }
        public ProcessDetail PutMinus { get; set; }
        public ProcessDetail CallPlus { get; set; }
        public ProcessDetail PutPlus { get; set; }
        
        // Related labels
        public List<StrategyLabelResponse> RelatedLabels { get; set; }
    }
    
    public class ProcessDetail
    {
        public string ProcessName { get; set; }
        public decimal Value { get; set; }
        public string Formula { get; set; }
        public string Description { get; set; }
        public decimal Distance { get; set; }
        public List<string> RelatedLabelNames { get; set; }
    }
}



