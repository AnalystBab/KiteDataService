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
    /// Premium Prediction Service - Integrates Premium HLC Pattern Engine with existing system
    /// </summary>
    public class PremiumPredictionService
    {
        private readonly ILogger<PremiumPredictionService> _logger;
        private readonly PremiumHLCPatternEngine _premiumHLCEngine;
        private readonly MarketDataContext _context;

        public PremiumPredictionService(
            ILogger<PremiumPredictionService> logger, 
            PremiumHLCPatternEngine premiumHLCEngine,
            MarketDataContext context)
        {
            _logger = logger;
            _premiumHLCEngine = premiumHLCEngine;
            _context = context;
        }

        /// <summary>
        /// Generate comprehensive premium predictions for all indices
        /// </summary>
        public async Task<PremiumPredictionReport> GeneratePremiumPredictionsAsync(DateTime targetDate)
        {
            try
            {
                _logger.LogInformation($"🎯 Generating Premium Predictions for {targetDate:yyyy-MM-dd}");

                var report = new PremiumPredictionReport
                {
                    TargetDate = targetDate,
                    GeneratedAt = DateTime.Now
                };

                // Get reference date (previous trading day)
                var referenceDate = await GetPreviousTradingDayAsync(targetDate);
                if (!referenceDate.HasValue)
                {
                    _logger.LogWarning($"No reference date found for {targetDate:yyyy-MM-dd}");
                    return report;
                }

                // Process each index
                var indices = new[] { "SENSEX", "BANKNIFTY", "NIFTY" };
                
                foreach (var index in indices)
                {
                    _logger.LogInformation($"Processing Premium HLC predictions for {index}");
                    
                    var indexPredictions = await _premiumHLCEngine.PredictAllStrikesPremiumHLCAsync(
                        index, targetDate, referenceDate.Value);
                    
                    if (indexPredictions.Any())
                    {
                        report.IndexPredictions[index] = indexPredictions;
                        
                        // Generate summary for this index
                        report.IndexSummaries[index] = GenerateIndexSummary(indexPredictions);
                        
                        _logger.LogInformation($"✅ Generated {indexPredictions.Count} Premium HLC predictions for {index}");
                    }
                }

                // Generate overall insights
                report.OverallInsights = GenerateOverallInsights(report.IndexPredictions);
                
                _logger.LogInformation($"✅ Premium Prediction Report completed for {targetDate:yyyy-MM-dd}");
                return report;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error generating Premium Predictions for {targetDate:yyyy-MM-dd}");
                return new PremiumPredictionReport { TargetDate = targetDate, GeneratedAt = DateTime.Now };
            }
        }

        /// <summary>
        /// Get premium predictions for specific strike
        /// </summary>
        public async Task<PremiumHLCPrediction> GetStrikePremiumPredictionAsync(
            string index, 
            decimal strike, 
            string optionType, 
            DateTime targetDate)
        {
            try
            {
                var referenceDate = await GetPreviousTradingDayAsync(targetDate);
                if (!referenceDate.HasValue)
                    return null;

                return await _premiumHLCEngine.PredictPremiumHLCAsync(
                    index, targetDate, strike, optionType, referenceDate.Value);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting Premium HLC prediction for {index} {strike} {optionType}");
                return null;
            }
        }

        /// <summary>
        /// Find premium patterns across all strikes
        /// </summary>
        public async Task<List<CrossStrikePremiumPattern>> FindCrossStrikePatternsAsync(
            string index, 
            DateTime targetDate)
        {
            try
            {
                _logger.LogInformation($"🔍 Finding Cross-Strike Premium Patterns for {index} on {targetDate:yyyy-MM-dd}");

                var patterns = new List<CrossStrikePremiumPattern>();
                
                // Get all premium predictions for the index
                var report = await GeneratePremiumPredictionsAsync(targetDate);
                if (!report.IndexPredictions.ContainsKey(index))
                    return patterns;

                var predictions = report.IndexPredictions[index];
                
                // Pattern 1: Premium Gradient Pattern
                var cePredictions = predictions.Where(p => p.OptionType == "CE").OrderBy(p => p.Strike).ToList();
                var pePredictions = predictions.Where(p => p.OptionType == "PE").OrderBy(p => p.Strike).ToList();
                
                // Analyze CE premium gradient
                if (cePredictions.Count >= 3)
                {
                    var ceGradient = AnalyzePremiumGradient(cePredictions);
                    if (ceGradient != null)
                        patterns.Add(ceGradient);
                }
                
                // Analyze PE premium gradient
                if (pePredictions.Count >= 3)
                {
                    var peGradient = AnalyzePremiumGradient(pePredictions);
                    if (peGradient != null)
                        patterns.Add(peGradient);
                }
                
                // Pattern 2: CE/PE Premium Ratio Pattern
                var ratioPattern = AnalyzeCEPERatioPattern(cePredictions, pePredictions);
                if (ratioPattern != null)
                    patterns.Add(ratioPattern);
                
                // Pattern 3: Strike Gap Premium Pattern
                var gapPattern = AnalyzeStrikeGapPattern(predictions);
                if (gapPattern != null)
                    patterns.Add(gapPattern);

                _logger.LogInformation($"✅ Found {patterns.Count} Cross-Strike Premium Patterns for {index}");
                return patterns;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error finding Cross-Strike Premium Patterns for {index}");
                return new List<CrossStrikePremiumPattern>();
            }
        }

        #region Private Methods

        /// <summary>
        /// Get previous trading day
        /// </summary>
        private async Task<DateTime?> GetPreviousTradingDayAsync(DateTime targetDate)
        {
            var previousDate = targetDate.AddDays(-1);
            
            // Check if we have data for the previous day
            var hasData = await _context.MarketQuotes
                .AnyAsync(q => q.BusinessDate == previousDate);
            
            if (hasData) return previousDate;
            
            // Go back further if needed
            for (int i = 2; i <= 5; i++)
            {
                var checkDate = targetDate.AddDays(-i);
                hasData = await _context.MarketQuotes
                    .AnyAsync(q => q.BusinessDate == checkDate);
                
                if (hasData) return checkDate;
            }
            
            return null;
        }

        /// <summary>
        /// Generate index summary
        /// </summary>
        private PremiumIndexSummary GenerateIndexSummary(List<PremiumHLCPrediction> predictions)
        {
            if (!predictions.Any()) return new PremiumIndexSummary();

            var summary = new PremiumIndexSummary
            {
                TotalStrikes = predictions.Count,
                AverageConfidence = (int)predictions.Average(p => p.ConfidenceLevel),
                HighestConfidence = predictions.Max(p => p.ConfidenceLevel),
                LowestConfidence = predictions.Min(p => p.ConfidenceLevel),
                
                // Premium statistics
                AveragePremiumHigh = predictions.Average(p => p.PredictedPremiumHigh),
                AveragePremiumLow = predictions.Average(p => p.PredictedPremiumLow),
                AveragePremiumClose = predictions.Average(p => p.PredictedPremiumClose),
                AverageVolatility = predictions.Average(p => p.PremiumVolatility),
                
                // Strike range
                MinStrike = predictions.Min(p => p.Strike),
                MaxStrike = predictions.Max(p => p.Strike),
                
                // Option type breakdown
                CEPredictions = predictions.Count(p => p.OptionType == "CE"),
                PEPredictions = predictions.Count(p => p.OptionType == "PE")
            };

            return summary;
        }

        /// <summary>
        /// Generate overall insights
        /// </summary>
        private List<PremiumInsight> GenerateOverallInsights(Dictionary<string, List<PremiumHLCPrediction>> allPredictions)
        {
            var insights = new List<PremiumInsight>();

            // Insight 1: Overall confidence level
            var allConfidences = allPredictions.Values.SelectMany(p => p.Select(x => x.ConfidenceLevel)).ToList();
            if (allConfidences.Any())
            {
                insights.Add(new PremiumInsight
                {
                    Type = "Confidence",
                    Title = "Overall Prediction Confidence",
                    Description = $"Average confidence: {allConfidences.Average():F1}% (Range: {allConfidences.Min()}-{allConfidences.Max()}%)",
                    Severity = allConfidences.Average() >= 80 ? "High" : allConfidences.Average() >= 60 ? "Medium" : "Low"
                });
            }

            // Insight 2: Volatility analysis
            var allVolatilities = allPredictions.Values.SelectMany(p => p.Select(x => x.PremiumVolatility)).ToList();
            if (allVolatilities.Any())
            {
                insights.Add(new PremiumInsight
                {
                    Type = "Volatility",
                    Title = "Premium Volatility Analysis",
                    Description = $"Average volatility: {allVolatilities.Average():F1}% (Range: {allVolatilities.Min():F1}-{allVolatilities.Max():F1}%)",
                    Severity = allVolatilities.Average() >= 50 ? "High" : allVolatilities.Average() >= 30 ? "Medium" : "Low"
                });
            }

            return insights;
        }

        /// <summary>
        /// Analyze premium gradient pattern
        /// </summary>
        private CrossStrikePremiumPattern AnalyzePremiumGradient(List<PremiumHLCPrediction> predictions)
        {
            if (predictions.Count < 3) return null;

            var gradients = new List<decimal>();
            for (int i = 1; i < predictions.Count; i++)
            {
                var gradient = (predictions[i].PredictedPremiumClose - predictions[i-1].PredictedPremiumClose) / 
                              (predictions[i].Strike - predictions[i-1].Strike);
                gradients.Add(gradient);
            }

            var avgGradient = gradients.Average();
            var gradientConsistency = gradients.All(g => Math.Abs(g - avgGradient) < Math.Abs(avgGradient) * 0.2m) ? "Consistent" : "Variable";

            return new CrossStrikePremiumPattern
            {
                PatternName = $"{predictions[0].OptionType} Premium Gradient",
                PatternType = "Gradient",
                Confidence = gradientConsistency == "Consistent" ? 85 : 60,
                Description = $"Premium gradient: {avgGradient:F4} per strike point ({gradientConsistency})",
                AffectedStrikes = predictions.Select(p => p.Strike).ToList(),
                PatternValue = avgGradient
            };
        }

        /// <summary>
        /// Analyze CE/PE ratio pattern
        /// </summary>
        private CrossStrikePremiumPattern AnalyzeCEPERatioPattern(
            List<PremiumHLCPrediction> cePredictions, 
            List<PremiumHLCPrediction> pePredictions)
        {
            if (!cePredictions.Any() || !pePredictions.Any()) return null;

            var ratios = new List<decimal>();
            var commonStrikes = cePredictions.Select(c => c.Strike)
                                           .Intersect(pePredictions.Select(p => p.Strike))
                                           .ToList();

            foreach (var strike in commonStrikes)
            {
                var cePred = cePredictions.First(c => c.Strike == strike);
                var pePred = pePredictions.First(p => p.Strike == strike);
                
                if (pePred.PredictedPremiumClose > 0)
                {
                    var ratio = cePred.PredictedPremiumClose / pePred.PredictedPremiumClose;
                    ratios.Add(ratio);
                }
            }

            if (!ratios.Any()) return null;

            var avgRatio = ratios.Average();
            var ratioConsistency = ratios.All(r => Math.Abs(r - avgRatio) < avgRatio * 0.3m) ? "Consistent" : "Variable";

            return new CrossStrikePremiumPattern
            {
                PatternName = "CE/PE Premium Ratio",
                PatternType = "Ratio",
                Confidence = ratioConsistency == "Consistent" ? 80 : 55,
                Description = $"Average CE/PE ratio: {avgRatio:F2} ({ratioConsistency})",
                AffectedStrikes = commonStrikes,
                PatternValue = avgRatio
            };
        }

        /// <summary>
        /// Analyze strike gap pattern
        /// </summary>
        private CrossStrikePremiumPattern AnalyzeStrikeGapPattern(List<PremiumHLCPrediction> predictions)
        {
            var groupedByStrike = predictions.GroupBy(p => p.Strike).ToList();
            if (groupedByStrike.Count < 3) return null;

            var gaps = new List<decimal>();
            var sortedStrikes = groupedByStrike.Select(g => g.Key).OrderBy(s => s).ToList();
            
            for (int i = 1; i < sortedStrikes.Count; i++)
            {
                gaps.Add(sortedStrikes[i] - sortedStrikes[i-1]);
            }

            var avgGap = gaps.Average();
            var gapConsistency = gaps.All(g => Math.Abs(g - avgGap) < avgGap * 0.1m) ? "Consistent" : "Variable";

            return new CrossStrikePremiumPattern
            {
                PatternName = "Strike Gap Pattern",
                PatternType = "Gap",
                Confidence = gapConsistency == "Consistent" ? 90 : 65,
                Description = $"Average strike gap: {avgGap:F0} points ({gapConsistency})",
                AffectedStrikes = sortedStrikes,
                PatternValue = avgGap
            };
        }

        #endregion
    }

    /// <summary>
    /// Premium Prediction Report Model
    /// </summary>
    public class PremiumPredictionReport
    {
        public DateTime TargetDate { get; set; }
        public DateTime GeneratedAt { get; set; }
        public Dictionary<string, List<PremiumHLCPrediction>> IndexPredictions { get; set; } = new Dictionary<string, List<PremiumHLCPrediction>>();
        public Dictionary<string, PremiumIndexSummary> IndexSummaries { get; set; } = new Dictionary<string, PremiumIndexSummary>();
        public List<PremiumInsight> OverallInsights { get; set; } = new List<PremiumInsight>();
    }

    /// <summary>
    /// Premium Index Summary Model
    /// </summary>
    public class PremiumIndexSummary
    {
        public int TotalStrikes { get; set; }
        public int AverageConfidence { get; set; }
        public int HighestConfidence { get; set; }
        public int LowestConfidence { get; set; }
        
        public decimal AveragePremiumHigh { get; set; }
        public decimal AveragePremiumLow { get; set; }
        public decimal AveragePremiumClose { get; set; }
        public decimal AverageVolatility { get; set; }
        
        public decimal MinStrike { get; set; }
        public decimal MaxStrike { get; set; }
        
        public int CEPredictions { get; set; }
        public int PEPredictions { get; set; }
    }

    /// <summary>
    /// Cross-Strike Premium Pattern Model
    /// </summary>
    public class CrossStrikePremiumPattern
    {
        public string PatternName { get; set; }
        public string PatternType { get; set; }
        public int Confidence { get; set; }
        public string Description { get; set; }
        public List<decimal> AffectedStrikes { get; set; } = new List<decimal>();
        public decimal PatternValue { get; set; }
    }

    /// <summary>
    /// Premium Insight Model
    /// </summary>
    public class PremiumInsight
    {
        public string Type { get; set; }
        public string Title { get; set; }
        public string Description { get; set; }
        public string Severity { get; set; }
    }
}
