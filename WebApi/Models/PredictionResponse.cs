using System;

namespace KiteMarketDataService.Worker.WebApi.Models
{
    /// <summary>
    /// Response model for D1 predictions
    /// </summary>
    public class PredictionResponse
    {
        public string IndexName { get; set; }
        public DateTime BusinessDate { get; set; }
        public DateTime PredictionDate { get; set; }
        
        // Predictions
        public decimal PredictedLow { get; set; }
        public decimal PredictedHigh { get; set; }
        public decimal PredictedClose { get; set; }
        
        // Accuracy metrics
        public decimal AccuracyLow { get; set; }
        public decimal AccuracyHigh { get; set; }
        public decimal AccuracyClose { get; set; }
        
        // Formulas used
        public string LowFormula { get; set; }
        public string HighFormula { get; set; }
        public string CloseFormula { get; set; }
        
        // Confidence scores
        public decimal ConfidenceLow { get; set; }
        public decimal ConfidenceHigh { get; set; }
        public decimal ConfidenceClose { get; set; }
    }
}


