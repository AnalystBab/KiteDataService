using KiteMarketDataService.Worker.Models;
using KiteMarketDataService.Worker.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace KiteMarketDataService.Worker.Services
{
    public class PatternEngine
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<PatternEngine> _logger;

        public PatternEngine(IServiceScopeFactory scopeFactory, ILogger<PatternEngine> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Find all pattern matches for a given set of strategy labels
        /// </summary>
        public async Task<List<PatternMatch>> FindPatternMatchesAsync(
            DateTime businessDate,
            string indexName,
            DateTime expiryDate,
            List<StrategyLabel> labels)
        {
            _logger.LogInformation($"{indexName} - PatternEngine: Starting pattern analysis for {businessDate:yyyy-MM-dd}");

            var matches = new List<PatternMatch>();

            // Get historical HLC data for comparison
            var historicalData = await GetHistoricalHLCDataset(businessDate, indexName);

            // Get all UC values from current data
            var allUcValues = await GetAllUcValues(businessDate, indexName, expiryDate);

            // Pattern 1: Premium Matching Patterns
            matches.AddRange(FindPremiumMatchingPatterns(labels, allUcValues, historicalData));

            // Pattern 2: Distance Correlation Patterns
            matches.AddRange(FindDistanceCorrelationPatterns(labels, historicalData));

            // Pattern 3: Cross-Reference Patterns
            matches.AddRange(FindCrossReferencePatterns(labels, allUcValues));

            // Pattern 4: Strike Level Convergence
            matches.AddRange(FindStrikeConvergencePatterns(labels, allUcValues, historicalData));

            _logger.LogInformation($"{indexName} - PatternEngine: Found {matches.Count} pattern matches");

            return matches;
        }

        /// <summary>
        /// Pattern 1: Check if Target Premiums match any UC values
        /// </summary>
        private List<PatternMatch> FindPremiumMatchingPatterns(
            List<StrategyLabel> labels,
            List<UcValue> allUcValues,
            List<HistoricalHLCDataset> historicalData)
        {
            var matches = new List<PatternMatch>();
            
            // Dynamic tolerance based on close strike (1.2% of close strike)
            var closeStrike = GetLabelValue(labels, "CLOSE_STRIKE");
            var tolerance = closeStrike * 0.012m; // 1.2% tolerance

            var targetCePremium = GetLabelValue(labels, "TARGET_CE_PREMIUM");
            var targetPePremium = GetLabelValue(labels, "TARGET_PE_PREMIUM");

            // Check Target CE Premium matches
            if (targetCePremium > 0)
            {
                foreach (var uc in allUcValues)
                {
                    if (uc.OptionType == "PE" && Math.Abs(targetCePremium - uc.UpperCircuitLimit) <= tolerance)
                    {
                        var confidence = CalculateConfidence(targetCePremium, uc.UpperCircuitLimit, tolerance);
                        var prediction = PredictSpotLevel("Low", uc.Strike, confidence, "Target CE Premium ≈ PE UC");

                        matches.Add(new PatternMatch
                        {
                            PatternType = "Premium Match",
                            Description = $"Target CE Premium ({targetCePremium:F2}) ≈ {uc.Strike} PE UC ({uc.UpperCircuitLimit:F2})",
                            Prediction = prediction,
                            Confidence = confidence,
                            Strike = uc.Strike,
                            OptionType = uc.OptionType,
                            PatternStrength = GetPatternStrength(confidence),
                            HistoricalAccuracy = GetHistoricalAccuracy("PremiumMatch", uc.Strike, historicalData),
                            Reason = "When CE premium equals PE UC, both options have similar risk levels, suggesting strong support/resistance"
                        });

                        _logger.LogInformation($"Premium Match Found: CE Premium {targetCePremium:F2} ≈ PE {uc.Strike} UC {uc.UpperCircuitLimit:F2} (Confidence: {confidence:F1}%)");
                    }
                }
            }

            // Check Target PE Premium matches
            if (targetPePremium > 0)
            {
                foreach (var uc in allUcValues)
                {
                    if (uc.OptionType == "CE" && Math.Abs(targetPePremium - uc.UpperCircuitLimit) <= tolerance)
                    {
                        var confidence = CalculateConfidence(targetPePremium, uc.UpperCircuitLimit, tolerance);
                        var prediction = PredictSpotLevel("High", uc.Strike, confidence, "PE Premium ≈ CE UC");

                        matches.Add(new PatternMatch
                        {
                            PatternType = "Premium Match",
                            Description = $"Target PE Premium ({targetPePremium:F2}) ≈ {uc.Strike} CE UC ({uc.UpperCircuitLimit:F2})",
                            Prediction = prediction,
                            Confidence = confidence,
                            Strike = uc.Strike,
                            OptionType = uc.OptionType,
                            PatternStrength = GetPatternStrength(confidence),
                            HistoricalAccuracy = GetHistoricalAccuracy("PremiumMatch", uc.Strike, historicalData),
                            Reason = "When PE premium equals CE UC, both options have similar risk levels, suggesting strong resistance"
                        });
                    }
                }
            }

            return matches;
        }

        /// <summary>
        /// Pattern 2: Check if calculated values match historical HLC (Your Key Pattern!)
        /// </summary>
        private List<PatternMatch> FindDistanceCorrelationPatterns(
            List<StrategyLabel> labels,
            List<HistoricalHLCDataset> historicalData)
        {
            var matches = new List<PatternMatch>();
            
            // Dynamic tolerance based on close strike (2% of close strike)
            var closeStrike = GetLabelValue(labels, "CLOSE_STRIKE");
            var tolerance = closeStrike * 0.02m; // 2% tolerance

            var distance = GetLabelValue(labels, "CALL_MINUS_TO_CALL_BASE_DISTANCE");
            var callMinus = GetLabelValue(labels, "CALL_MINUS");
            var putMinus = GetLabelValue(labels, "PUT_MINUS");
            var callPlus = GetLabelValue(labels, "CALL_PLUS");
            var putPlus = GetLabelValue(labels, "PUT_PLUS");
            var targetCePremium = GetLabelValue(labels, "TARGET_CE_PREMIUM");
            var targetPePremium = GetLabelValue(labels, "TARGET_PE_PREMIUM");

            foreach (var historical in historicalData)
            {
                // Check distance against historical high
                if (Math.Abs(distance - historical.High) <= tolerance)
                {
                    matches.Add(new PatternMatch
                    {
                        PatternType = "Distance Match",
                        Description = $"Distance ({distance:F2}) ≈ Historical High ({historical.High:F2})",
                        Prediction = $"Spot High could reach {historical.High:F2}",
                        Confidence = CalculateConfidence(distance, historical.High, tolerance),
                        Strike = 0,
                        OptionType = "",
                        PatternStrength = GetPatternStrength(CalculateConfidence(distance, historical.High, tolerance)),
                        HistoricalAccuracy = GetHistoricalAccuracy("DistanceMatch", historical.High, historicalData),
                        Reason = "Distance matching historical high suggests similar market conditions"
                    });
                }

                // Check C- value against historical low
                if (Math.Abs(callMinus - historical.Low) <= tolerance)
                {
                    matches.Add(new PatternMatch
                    {
                        PatternType = "Process Value Match",
                        Description = $"C- Value ({callMinus:F2}) ≈ Historical Low ({historical.Low:F2})",
                        Prediction = $"Spot Low could reach {historical.Low:F2}",
                        Confidence = CalculateConfidence(callMinus, historical.Low, tolerance),
                        Strike = 0,
                        OptionType = "",
                        PatternStrength = GetPatternStrength(CalculateConfidence(callMinus, historical.Low, tolerance)),
                        HistoricalAccuracy = GetHistoricalAccuracy("ProcessValueMatch", historical.Low, historicalData),
                        Reason = "C- value matching historical low suggests strong support level"
                    });
                }

                // Check C+ value against historical high
                if (Math.Abs(callPlus - historical.High) <= tolerance)
                {
                    matches.Add(new PatternMatch
                    {
                        PatternType = "Process Value Match",
                        Description = $"C+ Value ({callPlus:F2}) ≈ Historical High ({historical.High:F2})",
                        Prediction = $"Spot High could reach {historical.High:F2}",
                        Confidence = CalculateConfidence(callPlus, historical.High, tolerance),
                        Strike = 0,
                        OptionType = "",
                        PatternStrength = GetPatternStrength(CalculateConfidence(callPlus, historical.High, tolerance)),
                        HistoricalAccuracy = GetHistoricalAccuracy("ProcessValueMatch", historical.High, historicalData),
                        Reason = "C+ value matching historical high suggests strong resistance level"
                    });
                }

                // YOUR KEY PATTERN: Check if Target CE Premium matches historical low
                if (Math.Abs(targetCePremium - historical.Low) <= tolerance)
                {
                    matches.Add(new PatternMatch
                    {
                        PatternType = "Target Premium Low Match",
                        Description = $"Target CE Premium ({targetCePremium:F2}) ≈ Historical Low ({historical.Low:F2})",
                        Prediction = $"Spot Low likely to form around {targetCePremium:F2}",
                        Confidence = CalculateConfidence(targetCePremium, historical.Low, tolerance),
                        Strike = 0,
                        OptionType = "",
                        PatternStrength = GetPatternStrength(CalculateConfidence(targetCePremium, historical.Low, tolerance)),
                        HistoricalAccuracy = GetHistoricalAccuracy("TargetPremiumLowMatch", historical.Low, historicalData),
                        Reason = "Target CE Premium matching historical low suggests this level often becomes support"
                    });
                }

                // YOUR KEY PATTERN: Check if Distance matches historical low
                if (Math.Abs(distance - historical.Low) <= tolerance)
                {
                    matches.Add(new PatternMatch
                    {
                        PatternType = "Distance Low Match",
                        Description = $"Distance ({distance:F2}) ≈ Historical Low ({historical.Low:F2})",
                        Prediction = $"Spot Low likely to form around {distance:F2}",
                        Confidence = CalculateConfidence(distance, historical.Low, tolerance),
                        Strike = 0,
                        OptionType = "",
                        PatternStrength = GetPatternStrength(CalculateConfidence(distance, historical.Low, tolerance)),
                        HistoricalAccuracy = GetHistoricalAccuracy("DistanceLowMatch", historical.Low, historicalData),
                        Reason = "Distance matching historical low suggests this gap often becomes support"
                    });
                }
            }

            return matches;
        }

        /// <summary>
        /// Pattern 3: Cross-Reference Patterns (C+ ≈ P-, etc.)
        /// </summary>
        private List<PatternMatch> FindCrossReferencePatterns(
            List<StrategyLabel> labels,
            List<UcValue> allUcValues)
        {
            var matches = new List<PatternMatch>();
            var tolerance = 150m;

            var callPlus = GetLabelValue(labels, "CALL_PLUS");
            var putMinus = GetLabelValue(labels, "PUT_MINUS");
            var callMinus = GetLabelValue(labels, "CALL_MINUS");
            var putPlus = GetLabelValue(labels, "PUT_PLUS");

            // Check C+ ≈ P- (Upper and Lower boundaries converge)
            if (Math.Abs(callPlus - putMinus) <= tolerance)
            {
                var midPoint = (callPlus + putMinus) / 2;
                matches.Add(new PatternMatch
                {
                    PatternType = "Cross Reference",
                    Description = $"C+ ({callPlus:F2}) ≈ P- ({putMinus:F2})",
                    Prediction = $"Market may consolidate around {midPoint:F2}",
                    Confidence = CalculateConfidence(callPlus, putMinus, tolerance),
                    Strike = 0,
                    OptionType = "",
                    PatternStrength = GetPatternStrength(CalculateConfidence(callPlus, putMinus, tolerance)),
                    HistoricalAccuracy = 0,
                    Reason = "When upper and lower boundaries converge, market often consolidates"
                });
            }

            return matches;
        }

        /// <summary>
        /// Pattern 4: Strike Level Convergence (Multiple strikes pointing to same level)
        /// </summary>
        private List<PatternMatch> FindStrikeConvergencePatterns(
            List<StrategyLabel> labels,
            List<UcValue> allUcValues,
            List<HistoricalHLCDataset> historicalData)
        {
            var matches = new List<PatternMatch>();
            var convergenceTolerance = 100m;

            // Find strikes where UC values are similar (convergence)
            var ucGroups = allUcValues
                .GroupBy(u => Math.Round(u.UpperCircuitLimit / convergenceTolerance) * convergenceTolerance)
                .Where(g => g.Count() >= 2)
                .ToList();

            foreach (var group in ucGroups)
            {
                var avgUc = group.Average(u => u.UpperCircuitLimit);
                var strikes = string.Join(", ", group.Select(u => $"{u.Strike}{u.OptionType}"));
                
                matches.Add(new PatternMatch
                {
                    PatternType = "Strike Convergence",
                    Description = $"Multiple strikes converge at UC ~{avgUc:F2}: {strikes}",
                    Prediction = $"Strong support/resistance at {avgUc:F2} level",
                    Confidence = group.Count() * 15, // More strikes = higher confidence
                    Strike = 0,
                    OptionType = "",
                    PatternStrength = group.Count() >= 3 ? "High" : "Medium",
                    HistoricalAccuracy = GetHistoricalAccuracy("StrikeConvergence", avgUc, historicalData),
                    Reason = "Multiple strikes converging suggests strong market level"
                });
            }

            return matches;
        }

        #region Helper Methods

        private decimal GetLabelValue(List<StrategyLabel> labels, string labelName)
        {
            return labels.FirstOrDefault(l => l.LabelName == labelName)?.LabelValue ?? 0m;
        }

        private decimal CalculateConfidence(decimal value1, decimal value2, decimal tolerance)
        {
            var difference = Math.Abs(value1 - value2);
            var confidence = Math.Max(0, 100 - (difference / tolerance * 50));
            return Math.Min(100, confidence);
        }

        private string PredictSpotLevel(string direction, decimal strike, decimal confidence, string reason)
        {
            return $"Spot {direction} likely around {strike:F0} (Confidence: {confidence:F1}%) - {reason}";
        }

        private string GetPatternStrength(decimal confidence)
        {
            if (confidence >= 80) return "High";
            if (confidence >= 60) return "Medium";
            return "Low";
        }

        private decimal GetHistoricalAccuracy(string patternType, decimal value, List<HistoricalHLCDataset> historicalData)
        {
            // Simplified - in real implementation, this would check historical pattern accuracy
            return 75m; // Placeholder
        }

        private async Task<List<HistoricalHLCDataset>> GetHistoricalHLCDataset(DateTime businessDate, string indexName)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            // Get last 30 days of historical data
            var historicalData = await context.HistoricalSpotData
                .Where(h => h.IndexName == indexName 
                    && h.TradingDate < businessDate 
                    && h.TradingDate >= businessDate.AddDays(-30))
                .Select(h => new HistoricalHLCDataset
                {
                    Date = h.TradingDate,
                    High = h.HighPrice,
                    Low = h.LowPrice,
                    Close = h.ClosePrice
                })
                .ToListAsync();

            return historicalData;
        }

        private async Task<List<UcValue>> GetAllUcValues(DateTime businessDate, string indexName, DateTime expiryDate)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            var allQuotes = await context.MarketQuotes
                .Where(q => q.BusinessDate == businessDate
                    && q.TradingSymbol.StartsWith(indexName)
                    && q.ExpiryDate == expiryDate)
                .ToListAsync();

            var ucValues = allQuotes
                .GroupBy(q => new { q.Strike, q.OptionType })
                .Select(g => g.OrderByDescending(x => x.InsertionSequence).First())
                .Where(q => q.UpperCircuitLimit > 0)
                .Select(q => new UcValue
                {
                    Strike = q.Strike,
                    OptionType = q.OptionType,
                    UpperCircuitLimit = q.UpperCircuitLimit
                })
                .ToList();

            return ucValues;
        }

        #endregion
    }

    #region Data Models

    public class PatternMatch
    {
        public string PatternType { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string Prediction { get; set; } = string.Empty;
        public decimal Confidence { get; set; }
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty;
        public string PatternStrength { get; set; } = string.Empty;
        public decimal HistoricalAccuracy { get; set; }
        public string Reason { get; set; } = string.Empty;
    }

    public class HistoricalHLCDataset
    {
        public DateTime Date { get; set; }
        public decimal High { get; set; }
        public decimal Low { get; set; }
        public decimal Close { get; set; }
    }

    public class UcValue
    {
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty;
        public decimal UpperCircuitLimit { get; set; }
    }

    #endregion
}
