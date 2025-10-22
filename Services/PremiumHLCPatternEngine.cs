using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Premium HLC Pattern Engine - Predicts individual strike premium High, Low, Close
    /// Similar to Spot HLC prediction but for option premium movements
    /// </summary>
    public class PremiumHLCPatternEngine
    {
        private readonly ILogger<PremiumHLCPatternEngine> _logger;
        private readonly MarketDataContext _context;

        public PremiumHLCPatternEngine(ILogger<PremiumHLCPatternEngine> logger, MarketDataContext context)
        {
            _logger = logger;
            _context = context;
        }

        /// <summary>
        /// Predict Premium HLC for a specific strike and option type
        /// </summary>
        public async Task<PremiumHLCPrediction> PredictPremiumHLCAsync(
            string index, 
            DateTime targetDate, 
            decimal strike, 
            string optionType, 
            DateTime referenceDate)
        {
            try
            {
                _logger.LogInformation($"🎯 Predicting Premium HLC for {index} {strike} {optionType} on {targetDate:yyyy-MM-dd}");

                // Get reference data (D0)
                var referenceData = await GetReferencePremiumDataAsync(index, referenceDate, strike, optionType);
                if (referenceData == null)
                {
                    _logger.LogWarning($"No reference data found for {index} {strike} {optionType} on {referenceDate:yyyy-MM-dd}");
                    return null;
                }

                // Get current market data (D1)
                var currentData = await GetCurrentPremiumDataAsync(index, targetDate, strike, optionType);
                if (currentData == null)
                {
                    _logger.LogWarning($"No current data found for {index} {strike} {optionType} on {targetDate:yyyy-MM-dd}");
                    return null;
                }

                // Calculate Premium HLC predictions
                var prediction = new PremiumHLCPrediction
                {
                    Index = index,
                    Strike = strike,
                    OptionType = optionType,
                    TargetDate = targetDate,
                    ReferenceDate = referenceDate,
                    
                    // Current premium data
                    CurrentPremium = currentData.ClosePrice,
                    CurrentLC = currentData.LowerCircuitLimit,
                    CurrentUC = currentData.UpperCircuitLimit,
                    
                    // Predictions based on patterns
                    PredictedPremiumHigh = CalculatePremiumHigh(referenceData, currentData),
                    PredictedPremiumLow = CalculatePremiumLow(referenceData, currentData),
                    PredictedPremiumClose = CalculatePremiumClose(referenceData, currentData),
                    
                    // Pattern analysis
                    PatternMatches = await FindPremiumPatternsAsync(referenceData, currentData),
                    ConfidenceLevel = CalculateConfidenceLevel(referenceData, currentData),
                    
                    // Analysis timestamp
                    AnalysisTime = DateTime.Now
                };

                _logger.LogInformation($"✅ Premium HLC prediction completed for {index} {strike} {optionType}");
                return prediction;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error predicting Premium HLC for {index} {strike} {optionType}");
                return null;
            }
        }

        /// <summary>
        /// Predict Premium HLC for all active strikes
        /// </summary>
        public async Task<List<PremiumHLCPrediction>> PredictAllStrikesPremiumHLCAsync(
            string index, 
            DateTime targetDate, 
            DateTime referenceDate)
        {
            try
            {
                _logger.LogInformation($"🎯 Predicting Premium HLC for ALL {index} strikes on {targetDate:yyyy-MM-dd}");

                var predictions = new List<PremiumHLCPrediction>();

                // Get all active strikes for the index
                var activeStrikes = await GetActiveStrikesAsync(index, targetDate);
                
                foreach (var strike in activeStrikes)
                {
                    // Predict for both CE and PE
                    var cePrediction = await PredictPremiumHLCAsync(index, targetDate, strike, "CE", referenceDate);
                    var pePrediction = await PredictPremiumHLCAsync(index, targetDate, strike, "PE", referenceDate);
                    
                    if (cePrediction != null) predictions.Add(cePrediction);
                    if (pePrediction != null) predictions.Add(pePrediction);
                }

                _logger.LogInformation($"✅ Generated {predictions.Count} Premium HLC predictions for {index}");
                return predictions;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error predicting all strikes Premium HLC for {index}");
                return new List<PremiumHLCPrediction>();
            }
        }

        #region Private Methods

        /// <summary>
        /// Get reference premium data (D0)
        /// </summary>
        private async Task<MarketQuote> GetReferencePremiumDataAsync(string index, DateTime referenceDate, decimal strike, string optionType)
        {
            var tradingSymbol = $"{index}{strike:0}{optionType}";
            
            var quote = await _context.MarketQuotes
                .Where(q => q.TradingSymbol == tradingSymbol && 
                           q.BusinessDate == referenceDate &&
                           q.OptionType == optionType &&
                           q.Strike == strike)
                .OrderByDescending(q => q.InsertionSequence)
                .FirstOrDefaultAsync();

            return quote;
        }

        /// <summary>
        /// Get current premium data (D1)
        /// </summary>
        private async Task<MarketQuote> GetCurrentPremiumDataAsync(string index, DateTime targetDate, decimal strike, string optionType)
        {
            var tradingSymbol = $"{index}{strike:0}{optionType}";
            
            var quote = await _context.MarketQuotes
                .Where(q => q.TradingSymbol == tradingSymbol && 
                           q.BusinessDate == targetDate &&
                           q.OptionType == optionType &&
                           q.Strike == strike)
                .OrderByDescending(q => q.InsertionSequence)
                .FirstOrDefaultAsync();

            return quote;
        }

        /// <summary>
        /// Get all active strikes for an index
        /// </summary>
        private async Task<List<decimal>> GetActiveStrikesAsync(string index, DateTime targetDate)
        {
            var strikes = await _context.MarketQuotes
                .Where(q => q.TradingSymbol.StartsWith(index) && 
                           q.BusinessDate == targetDate)
                .Select(q => q.Strike)
                .Distinct()
                .OrderBy(s => s)
                .ToListAsync();

            return strikes;
        }

        /// <summary>
        /// Calculate predicted Premium High
        /// </summary>
        private decimal CalculatePremiumHigh(MarketQuote referenceData, MarketQuote currentData)
        {
            // Pattern 1: Premium High ≈ Reference High * (Current UC / Reference UC)
            var pattern1 = referenceData.HighPrice * (currentData.UpperCircuitLimit / referenceData.UpperCircuitLimit);
            
            // Pattern 2: Premium High ≈ Current UC * 0.95 (95% of upper circuit)
            var pattern2 = currentData.UpperCircuitLimit * 0.95m;
            
            // Pattern 3: Premium High ≈ Current Premium * 1.2 (20% increase from current)
            var pattern3 = currentData.ClosePrice * 1.2m;
            
            // Use the most conservative estimate (minimum of the three)
            var predictedHigh = Math.Min(Math.Min(pattern1, pattern2), pattern3);
            
            // Ensure it doesn't exceed upper circuit
            predictedHigh = Math.Min(predictedHigh, currentData.UpperCircuitLimit);
            
            return Math.Round(predictedHigh, 2);
        }

        /// <summary>
        /// Calculate predicted Premium Low
        /// </summary>
        private decimal CalculatePremiumLow(MarketQuote referenceData, MarketQuote currentData)
        {
            // Pattern 1: Premium Low ≈ Reference Low * (Current LC / Reference LC)
            var pattern1 = referenceData.LowPrice * (currentData.LowerCircuitLimit / referenceData.LowerCircuitLimit);
            
            // Pattern 2: Premium Low ≈ Current LC * 1.05 (5% above lower circuit)
            var pattern2 = currentData.LowerCircuitLimit * 1.05m;
            
            // Pattern 3: Premium Low ≈ Current Premium * 0.8 (20% decrease from current)
            var pattern3 = currentData.ClosePrice * 0.8m;
            
            // Use the most conservative estimate (maximum of the three)
            var predictedLow = Math.Max(Math.Max(pattern1, pattern2), pattern3);
            
            // Ensure it doesn't go below lower circuit
            predictedLow = Math.Max(predictedLow, currentData.LowerCircuitLimit);
            
            return Math.Round(predictedLow, 2);
        }

        /// <summary>
        /// Calculate predicted Premium Close
        /// </summary>
        private decimal CalculatePremiumClose(MarketQuote referenceData, MarketQuote currentData)
        {
            // Pattern 1: Premium Close ≈ Average of predicted High and Low
            var predictedHigh = CalculatePremiumHigh(referenceData, currentData);
            var predictedLow = CalculatePremiumLow(referenceData, currentData);
            var pattern1 = (predictedHigh + predictedLow) / 2;
            
            // Pattern 2: Premium Close ≈ Current Premium * (Reference Close / Reference Open)
            var pattern2 = currentData.ClosePrice * (referenceData.ClosePrice / referenceData.OpenPrice);
            
            // Pattern 3: Premium Close ≈ Current Premium (no change)
            var pattern3 = currentData.ClosePrice;
            
            // Use weighted average (40% pattern1, 30% pattern2, 30% pattern3)
            var predictedClose = (pattern1 * 0.4m) + (pattern2 * 0.3m) + (pattern3 * 0.3m);
            
            return Math.Round(predictedClose, 2);
        }

        /// <summary>
        /// Find premium patterns
        /// </summary>
        private async Task<List<PremiumPattern>> FindPremiumPatternsAsync(MarketQuote referenceData, MarketQuote currentData)
        {
            var patterns = new List<PremiumPattern>();

            // Pattern 1: UC/LC Ratio Pattern
            var referenceRatio = referenceData.UpperCircuitLimit / referenceData.LowerCircuitLimit;
            var currentRatio = currentData.UpperCircuitLimit / currentData.LowerCircuitLimit;
            var ratioChange = Math.Abs(currentRatio - referenceRatio) / referenceRatio * 100;
            
            if (ratioChange < 5) // Less than 5% change
            {
                patterns.Add(new PremiumPattern
                {
                    PatternName = "UC/LC Ratio Stability",
                    Confidence = 95 - (int)ratioChange,
                    Description = $"UC/LC ratio stable (change: {ratioChange:F2}%)"
                });
            }

            // Pattern 2: Premium Volatility Pattern
            var referenceVolatility = (referenceData.HighPrice - referenceData.LowPrice) / referenceData.ClosePrice * 100;
            var currentVolatility = (currentData.HighPrice - currentData.LowPrice) / currentData.ClosePrice * 100;
            
            if (Math.Abs(referenceVolatility - currentVolatility) < 10) // Similar volatility
            {
                patterns.Add(new PremiumPattern
                {
                    PatternName = "Volatility Consistency",
                    Confidence = 85,
                    Description = $"Similar volatility pattern (ref: {referenceVolatility:F1}%, current: {currentVolatility:F1}%)"
                });
            }

            // Pattern 3: Premium Trend Pattern
            var referenceTrend = referenceData.ClosePrice - referenceData.OpenPrice;
            var currentTrend = currentData.ClosePrice - currentData.OpenPrice;
            
            if ((referenceTrend > 0 && currentTrend > 0) || (referenceTrend < 0 && currentTrend < 0))
            {
                patterns.Add(new PremiumPattern
                {
                    PatternName = "Trend Continuation",
                    Confidence = 80,
                    Description = $"Trend continuation pattern (ref: {referenceTrend:F2}, current: {currentTrend:F2})"
                });
            }

            return patterns;
        }

        /// <summary>
        /// Calculate confidence level
        /// </summary>
        private int CalculateConfidenceLevel(MarketQuote referenceData, MarketQuote currentData)
        {
            var confidence = 50; // Base confidence

            // Factor 1: Data quality (20 points)
            if (referenceData != null && currentData != null)
                confidence += 20;

            // Factor 2: Pattern matches (30 points)
            var patterns = FindPremiumPatternsAsync(referenceData, currentData).Result;
            confidence += Math.Min(30, patterns.Count * 10);

            // Factor 3: Circuit limit stability (20 points)
            var ucChange = Math.Abs(currentData.UpperCircuitLimit - referenceData.UpperCircuitLimit) / referenceData.UpperCircuitLimit * 100;
            var lcChange = Math.Abs(currentData.LowerCircuitLimit - referenceData.LowerCircuitLimit) / referenceData.LowerCircuitLimit * 100;
            
            if (ucChange < 5 && lcChange < 5) confidence += 20;
            else if (ucChange < 10 && lcChange < 10) confidence += 10;

            // Factor 4: Premium movement consistency (10 points)
            var premiumChange = Math.Abs(currentData.ClosePrice - referenceData.ClosePrice) / referenceData.ClosePrice * 100;
            if (premiumChange < 20) confidence += 10;

            return Math.Min(100, confidence);
        }

        #endregion
    }

    /// <summary>
    /// Premium HLC Prediction Model
    /// </summary>
    public class PremiumHLCPrediction
    {
        public string Index { get; set; }
        public decimal Strike { get; set; }
        public string OptionType { get; set; }
        public DateTime TargetDate { get; set; }
        public DateTime ReferenceDate { get; set; }
        
        // Current premium data
        public decimal CurrentPremium { get; set; }
        public decimal CurrentLC { get; set; }
        public decimal CurrentUC { get; set; }
        
        // Predictions
        public decimal PredictedPremiumHigh { get; set; }
        public decimal PredictedPremiumLow { get; set; }
        public decimal PredictedPremiumClose { get; set; }
        
        // Analysis
        public List<PremiumPattern> PatternMatches { get; set; } = new List<PremiumPattern>();
        public int ConfidenceLevel { get; set; }
        public DateTime AnalysisTime { get; set; }
        
        // Calculated properties
        public decimal PremiumHighRange => PredictedPremiumHigh - CurrentPremium;
        public decimal PremiumLowRange => CurrentPremium - PredictedPremiumLow;
        public decimal PremiumCloseRange => Math.Abs(PredictedPremiumClose - CurrentPremium);
        public decimal PremiumVolatility => (PredictedPremiumHigh - PredictedPremiumLow) / CurrentPremium * 100;
    }

    /// <summary>
    /// Premium Pattern Model
    /// </summary>
    public class PremiumPattern
    {
        public string PatternName { get; set; }
        public int Confidence { get; set; }
        public string Description { get; set; }
    }
}
