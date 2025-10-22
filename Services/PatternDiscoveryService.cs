using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Automatically discovers patterns by trying all mathematical combinations of labels
    /// to match target values (like D1 PE UC values)
    /// </summary>
    public class PatternDiscoveryService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<PatternDiscoveryService> _logger;

        public PatternDiscoveryService(
            IServiceScopeFactory scopeFactory,
            ILogger<PatternDiscoveryService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Discover patterns that match D1 PE UC values from D0 labels
        /// </summary>
        public async Task<List<DiscoveredPattern>> DiscoverPatternsAsync(
            DateTime d0Date,
            DateTime d1Date,
            string indexName)
        {
            _logger.LogInformation($"🔍 Starting pattern discovery for {indexName}: D0={d0Date:yyyy-MM-dd}, D1={d1Date:yyyy-MM-dd}");

            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            var discoveredPatterns = new List<DiscoveredPattern>();

            // STEP 1: Get D0 labels
            var d0Labels = await context.StrategyLabels
                .Where(l => l.BusinessDate == d0Date && l.IndexName == indexName)
                .ToListAsync();

            if (!d0Labels.Any())
            {
                _logger.LogWarning($"No D0 labels found for {indexName} on {d0Date:yyyy-MM-dd}");
                return discoveredPatterns;
            }

            _logger.LogInformation($"   Found {d0Labels.Count} D0 labels");

            // STEP 2: Get D1 actual spot data
            var d1Spot = await context.HistoricalSpotData
                .Where(s => s.TradingDate == d1Date && s.IndexName == indexName)
                .FirstOrDefaultAsync();

            if (d1Spot == null)
            {
                _logger.LogWarning($"No D1 spot data found for {indexName} on {d1Date:yyyy-MM-dd}");
                return discoveredPatterns;
            }

            _logger.LogInformation($"   D1 Spot: High={d1Spot.HighPrice:F2}, Low={d1Spot.LowPrice:F2}, Close={d1Spot.ClosePrice:F2}");

            // STEP 3: Get D1 option quotes
            var d1Expiry = await GetNearestExpiryAsync(context, d1Date, indexName);
            var d1Quotes = await context.MarketQuotes
                .Where(q => q.BusinessDate == d1Date
                    && q.TradingSymbol.StartsWith(indexName)
                    && q.ExpiryDate == d1Expiry)
                .ToListAsync();

            var d1LatestQuotes = d1Quotes
                .GroupBy(q => new { q.Strike, q.OptionType })
                .Select(g => g.OrderByDescending(x => x.InsertionSequence).First())
                .ToList();

            _logger.LogInformation($"   Found {d1LatestQuotes.Count} D1 option quotes");

            // STEP 4: Define target strikes to match
            var lowStrike = Math.Round(d1Spot.LowPrice / 100) * 100;
            var highStrike = Math.Round(d1Spot.HighPrice / 100) * 100;
            var closeStrike = Math.Round(d1Spot.ClosePrice / 100) * 100;

            var targetStrikes = new[] { lowStrike, highStrike, closeStrike }.Distinct().ToList();

            _logger.LogInformation($"   Target strikes: {string.Join(", ", targetStrikes)}");

            // STEP 5: For each target strike, find matching patterns
            foreach (var targetStrike in targetStrikes)
            {
                // Get PE UC for this strike
                var peQuote = d1LatestQuotes.FirstOrDefault(q => q.Strike == targetStrike && q.OptionType == "PE");
                if (peQuote == null) continue;

                var targetPeUc = peQuote.UpperCircuitLimit;
                _logger.LogInformation($"\n   🎯 Target: {targetStrike} PE UC = {targetPeUc:F2}");

                // Try all combinations
                var patterns = await TryAllCombinationsAsync(d0Labels, targetPeUc, targetStrike, indexName);
                discoveredPatterns.AddRange(patterns);

                // Log top 5 matches
                var top5 = patterns.OrderBy(p => p.ErrorPercentage).Take(5);
                foreach (var pattern in top5)
                {
                    _logger.LogInformation($"      ✅ {pattern.Formula} = {pattern.CalculatedValue:F2} (Error: {pattern.ErrorPercentage:F2}%)");
                }
            }

            _logger.LogInformation($"\n✅ Discovered {discoveredPatterns.Count} total patterns");
            return discoveredPatterns.OrderBy(p => p.ErrorPercentage).ToList();
        }

        /// <summary>
        /// Try all mathematical combinations of labels
        /// </summary>
        private async Task<List<DiscoveredPattern>> TryAllCombinationsAsync(
            List<StrategyLabel> labels,
            decimal targetValue,
            decimal targetStrike,
            string indexName)
        {
            var patterns = new List<DiscoveredPattern>();
            decimal tolerance = targetValue * 0.05m; // 5% tolerance

            // Operation 1: Single label (identity)
            foreach (var label in labels)
            {
                var result = label.LabelValue;
                var error = Math.Abs(result - targetValue);
                if (error <= tolerance)
                {
                    patterns.Add(new DiscoveredPattern
                    {
                        Formula = label.LabelName,
                        CalculatedValue = result,
                        TargetValue = targetValue,
                        TargetStrike = targetStrike,
                        ErrorAbsolute = error,
                        ErrorPercentage = (error / targetValue) * 100,
                        IndexName = indexName,
                        Complexity = 1,
                        LabelsUsed = new List<string> { label.LabelName }
                    });
                }
            }

            // Operation 2: Label + Label
            for (int i = 0; i < labels.Count; i++)
            {
                for (int j = i + 1; j < labels.Count; j++)
                {
                    var result = labels[i].LabelValue + labels[j].LabelValue;
                    var error = Math.Abs(result - targetValue);
                    if (error <= tolerance)
                    {
                        patterns.Add(new DiscoveredPattern
                        {
                            Formula = $"{labels[i].LabelName} + {labels[j].LabelName}",
                            CalculatedValue = result,
                            TargetValue = targetValue,
                            TargetStrike = targetStrike,
                            ErrorAbsolute = error,
                            ErrorPercentage = (error / targetValue) * 100,
                            IndexName = indexName,
                            Complexity = 2,
                            LabelsUsed = new List<string> { labels[i].LabelName, labels[j].LabelName }
                        });
                    }
                }
            }

            // Operation 3: Label - Label
            for (int i = 0; i < labels.Count; i++)
            {
                for (int j = 0; j < labels.Count; j++)
                {
                    if (i == j) continue;

                    var result = labels[i].LabelValue - labels[j].LabelValue;
                    var error = Math.Abs(result - targetValue);
                    if (error <= tolerance)
                    {
                        patterns.Add(new DiscoveredPattern
                        {
                            Formula = $"{labels[i].LabelName} - {labels[j].LabelName}",
                            CalculatedValue = result,
                            TargetValue = targetValue,
                            TargetStrike = targetStrike,
                            ErrorAbsolute = error,
                            ErrorPercentage = (error / targetValue) * 100,
                            IndexName = indexName,
                            Complexity = 2,
                            LabelsUsed = new List<string> { labels[i].LabelName, labels[j].LabelName }
                        });
                    }
                }
            }

            // Operation 4: ABS(Label)
            foreach (var label in labels)
            {
                var result = Math.Abs(label.LabelValue);
                var error = Math.Abs(result - targetValue);
                if (error <= tolerance && result != label.LabelValue) // Only if different from original
                {
                    patterns.Add(new DiscoveredPattern
                    {
                        Formula = $"ABS({label.LabelName})",
                        CalculatedValue = result,
                        TargetValue = targetValue,
                        TargetStrike = targetStrike,
                        ErrorAbsolute = error,
                        ErrorPercentage = (error / targetValue) * 100,
                        IndexName = indexName,
                        Complexity = 1,
                        LabelsUsed = new List<string> { label.LabelName }
                    });
                }
            }

            // Operation 5: Label / 2
            foreach (var label in labels)
            {
                if (label.LabelValue == 0) continue;

                var result = label.LabelValue / 2;
                var error = Math.Abs(result - targetValue);
                if (error <= tolerance)
                {
                    patterns.Add(new DiscoveredPattern
                    {
                        Formula = $"{label.LabelName} / 2",
                        CalculatedValue = result,
                        TargetValue = targetValue,
                        TargetStrike = targetStrike,
                        ErrorAbsolute = error,
                        ErrorPercentage = (error / targetValue) * 100,
                        IndexName = indexName,
                        Complexity = 1,
                        LabelsUsed = new List<string> { label.LabelName }
                    });
                }
            }

            // Operation 6: Label * 2
            foreach (var label in labels)
            {
                var result = label.LabelValue * 2;
                var error = Math.Abs(result - targetValue);
                if (error <= tolerance)
                {
                    patterns.Add(new DiscoveredPattern
                    {
                        Formula = $"{label.LabelName} * 2",
                        CalculatedValue = result,
                        TargetValue = targetValue,
                        TargetStrike = targetStrike,
                        ErrorAbsolute = error,
                        ErrorPercentage = (error / targetValue) * 100,
                        IndexName = indexName,
                        Complexity = 1,
                        LabelsUsed = new List<string> { label.LabelName }
                    });
                }
            }

            // Operation 7: (L1 + L2) - L3 (3-way combinations for best matches)
            if (patterns.Count < 5) // Only if we haven't found good patterns yet
            {
                for (int i = 0; i < labels.Count && i < 15; i++) // Limit to avoid explosion
                {
                    for (int j = i + 1; j < labels.Count && j < 15; j++)
                    {
                        for (int k = 0; k < labels.Count && k < 15; k++)
                        {
                            if (k == i || k == j) continue;

                            var result = (labels[i].LabelValue + labels[j].LabelValue) - labels[k].LabelValue;
                            var error = Math.Abs(result - targetValue);
                            if (error <= tolerance)
                            {
                                patterns.Add(new DiscoveredPattern
                                {
                                    Formula = $"({labels[i].LabelName} + {labels[j].LabelName}) - {labels[k].LabelName}",
                                    CalculatedValue = result,
                                    TargetValue = targetValue,
                                    TargetStrike = targetStrike,
                                    ErrorAbsolute = error,
                                    ErrorPercentage = (error / targetValue) * 100,
                                    IndexName = indexName,
                                    Complexity = 3,
                                    LabelsUsed = new List<string> { labels[i].LabelName, labels[j].LabelName, labels[k].LabelName }
                                });
                            }
                        }
                    }
                }
            }

            return patterns;
        }

        /// <summary>
        /// Get nearest expiry date for the given business date
        /// </summary>
        private async Task<DateTime> GetNearestExpiryAsync(
            MarketDataContext context,
            DateTime businessDate,
            string indexName)
        {
            var expiry = await context.MarketQuotes
                .Where(q => q.BusinessDate == businessDate
                    && q.TradingSymbol.StartsWith(indexName)
                    && q.ExpiryDate > businessDate)
                .Select(q => q.ExpiryDate)
                .OrderBy(e => e)
                .FirstOrDefaultAsync();

            return expiry;
        }

        /// <summary>
        /// Store discovered patterns in database for future reference
        /// </summary>
        public async Task StoreDiscoveredPatternsAsync(List<DiscoveredPattern> patterns)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            // Note: You'll need to create a DiscoveredPatterns table first
            // For now, just log them
            foreach (var pattern in patterns.Take(10))
            {
                _logger.LogInformation($"📊 Pattern: {pattern.Formula} = {pattern.CalculatedValue:F2}, Target: {pattern.TargetValue:F2}, Error: {pattern.ErrorPercentage:F2}%");
            }
        }
    }

    /// <summary>
    /// Represents a discovered pattern
    /// </summary>
    public class DiscoveredPattern
    {
        public string Formula { get; set; } = string.Empty;
        public decimal CalculatedValue { get; set; }
        public decimal TargetValue { get; set; }
        public decimal TargetStrike { get; set; }
        public decimal ErrorAbsolute { get; set; }
        public decimal ErrorPercentage { get; set; }
        public string IndexName { get; set; } = string.Empty;
        public int Complexity { get; set; } // Number of labels used
        public List<string> LabelsUsed { get; set; } = new List<string>();
        public DateTime DiscoveryDate { get; set; } = DateTime.Now;
    }
}

