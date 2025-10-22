using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Hosting;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// ADVANCED Pattern Discovery Engine - Runs continuously in background
    /// Discovers patterns for predicting Low, High, and Close of spot
    /// Self-learning system that improves over time
    /// </summary>
    public class AdvancedPatternDiscoveryEngine : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<AdvancedPatternDiscoveryEngine> _logger;
        private readonly PatternDiscoveryService _patternDiscoveryService;

        public AdvancedPatternDiscoveryEngine(
            IServiceScopeFactory scopeFactory,
            ILogger<AdvancedPatternDiscoveryEngine> logger,
            PatternDiscoveryService patternDiscoveryService)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _patternDiscoveryService = patternDiscoveryService;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🤖 Advanced Pattern Discovery Engine STARTED");
            _logger.LogInformation("   Mode: Continuous Background Learning");
            _logger.LogInformation("   Targets: LOW, HIGH, CLOSE prediction patterns");

            // Wait for 5 minutes after service start to let data collection settle
            await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await RunDiscoveryCycleAsync(stoppingToken);

                    // Run discovery every 6 hours
                    _logger.LogInformation("⏰ Next discovery cycle in 6 hours...");
                    await Task.Delay(TimeSpan.FromHours(6), stoppingToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ Error in pattern discovery cycle");
                    await Task.Delay(TimeSpan.FromMinutes(30), stoppingToken);
                }
            }

            _logger.LogInformation("🛑 Advanced Pattern Discovery Engine STOPPED");
        }

        /// <summary>
        /// Run a complete discovery cycle for all available dates
        /// </summary>
        private async Task RunDiscoveryCycleAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("\n" + new string('=', 80));
            _logger.LogInformation("🔍 PATTERN DISCOVERY CYCLE STARTED");
            _logger.LogInformation(new string('=', 80));

            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            // Get date ranges to analyze
            var datePairs = await GetDatePairsForAnalysisAsync(context);
            _logger.LogInformation($"   Found {datePairs.Count} date pairs to analyze");

            // Safety check: Need at least 3 date pairs for meaningful analysis
            if (datePairs.Count < 3)
            {
                _logger.LogWarning($"⚠️ Insufficient data for pattern discovery!");
                _logger.LogWarning($"   Found only {datePairs.Count} date pairs (need at least 3)");
                _logger.LogWarning($"   Please ensure:");
                _logger.LogWarning($"   1. Service runs daily to collect D0 labels");
                _logger.LogWarning($"   2. Historical spot data is being collected");
                _logger.LogWarning($"   3. At least 3-5 days of consecutive data exists");
                _logger.LogWarning($"   Skipping this cycle. Will retry in 6 hours...");
                return;
            }

            var allPatterns = new List<DiscoveredPatternAdvanced>();

            foreach (var (d0, d1) in datePairs)
            {
                if (stoppingToken.IsCancellationRequested) break;

                _logger.LogInformation($"\n📅 Analyzing: D0={d0:yyyy-MM-dd} → D1={d1:yyyy-MM-dd}");

                // Discover patterns for each index
                foreach (var indexName in new[] { "SENSEX", "BANKNIFTY", "NIFTY" })
                {
                    if (stoppingToken.IsCancellationRequested) break;

                    var patterns = await DiscoverPatternsForIndexAsync(context, d0, d1, indexName);
                    allPatterns.AddRange(patterns);
                }
            }

            // Analyze and rank all discovered patterns
            await AnalyzeAndRankPatternsAsync(context, allPatterns);

            // Store best patterns
            await StoreBestPatternsAsync(context, allPatterns);

            _logger.LogInformation(new string('=', 80));
            _logger.LogInformation($"✅ DISCOVERY CYCLE COMPLETE - Found {allPatterns.Count} patterns");
            _logger.LogInformation(new string('=', 80) + "\n");
        }

        /// <summary>
        /// Discover patterns for a specific index and date pair
        /// </summary>
        private async Task<List<DiscoveredPatternAdvanced>> DiscoverPatternsForIndexAsync(
            MarketDataContext context,
            DateTime d0Date,
            DateTime d1Date,
            string indexName)
        {
            var patterns = new List<DiscoveredPatternAdvanced>();

            try
            {
                // Get D0 labels
                var d0Labels = await context.StrategyLabels
                    .Where(l => l.BusinessDate == d0Date && l.IndexName == indexName)
                    .ToListAsync();

                if (!d0Labels.Any())
                {
                    _logger.LogWarning($"   ⚠️ No D0 labels for {indexName}");
                    return patterns;
                }

                // Get D1 actual spot data
                var d1Spot = await context.HistoricalSpotData
                    .Where(s => s.TradingDate == d1Date && s.IndexName == indexName)
                    .FirstOrDefaultAsync();

                if (d1Spot == null)
                {
                    _logger.LogWarning($"   ⚠️ No D1 spot data for {indexName}");
                    return patterns;
                }

                // Get D1 option quotes for UC validation
                var d1Expiry = await GetNearestExpiryAsync(context, d1Date, indexName);
                var d1Quotes = await GetD1OptionQuotesAsync(context, d1Date, indexName, d1Expiry);

                _logger.LogInformation($"   🎯 {indexName}: Low={d1Spot.LowPrice:F2}, High={d1Spot.HighPrice:F2}, Close={d1Spot.ClosePrice:F2}");

                // TARGET 1: Predict LOW
                var lowPatterns = await FindPatternsForTarget(
                    d0Labels, 
                    d1Spot.LowPrice, 
                    "LOW", 
                    indexName, 
                    d0Date, 
                    d1Date,
                    d1Quotes);
                patterns.AddRange(lowPatterns);

                // TARGET 2: Predict HIGH
                var highPatterns = await FindPatternsForTarget(
                    d0Labels, 
                    d1Spot.HighPrice, 
                    "HIGH", 
                    indexName, 
                    d0Date, 
                    d1Date,
                    d1Quotes);
                patterns.AddRange(highPatterns);

                // TARGET 3: Predict CLOSE
                var closePatterns = await FindPatternsForTarget(
                    d0Labels, 
                    d1Spot.ClosePrice, 
                    "CLOSE", 
                    indexName, 
                    d0Date, 
                    d1Date,
                    d1Quotes);
                patterns.AddRange(closePatterns);

                // Log best pattern for each target
                var bestLow = lowPatterns.OrderBy(p => p.ErrorPercentage).FirstOrDefault();
                var bestHigh = highPatterns.OrderBy(p => p.ErrorPercentage).FirstOrDefault();
                var bestClose = closePatterns.OrderBy(p => p.ErrorPercentage).FirstOrDefault();

                if (bestLow != null)
                    _logger.LogInformation($"      ✅ Best LOW: {bestLow.Formula} (Error: {bestLow.ErrorPercentage:F2}%)");
                if (bestHigh != null)
                    _logger.LogInformation($"      ✅ Best HIGH: {bestHigh.Formula} (Error: {bestHigh.ErrorPercentage:F2}%)");
                if (bestClose != null)
                    _logger.LogInformation($"      ✅ Best CLOSE: {bestClose.Formula} (Error: {bestClose.ErrorPercentage:F2}%)");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"   ❌ Error discovering patterns for {indexName}");
            }

            return patterns;
        }

        /// <summary>
        /// Find patterns matching a specific target (LOW/HIGH/CLOSE)
        /// </summary>
        private async Task<List<DiscoveredPatternAdvanced>> FindPatternsForTarget(
            List<StrategyLabel> d0Labels,
            decimal targetValue,
            string targetType,
            string indexName,
            DateTime d0Date,
            DateTime d1Date,
            List<MarketQuote> d1Quotes)
        {
            var patterns = new List<DiscoveredPatternAdvanced>();
            var targetStrike = Math.Round(targetValue / 100) * 100;

            // Try all mathematical combinations
            patterns.AddRange(TryAllOperations(d0Labels, targetValue, targetType, indexName, d0Date, d1Date));

            // For LOW/HIGH predictions, also try matching with PE/CE UC values
            if (targetType == "LOW" || targetType == "HIGH")
            {
                var optionType = targetType == "LOW" ? "PE" : "CE";
                var targetQuote = d1Quotes.FirstOrDefault(q => 
                    q.Strike == targetStrike && 
                    q.OptionType == optionType);

                if (targetQuote != null)
                {
                    var ucPatterns = TryAllOperations(
                        d0Labels, 
                        targetQuote.UpperCircuitLimit, 
                        $"{targetType}_UC", 
                        indexName, 
                        d0Date, 
                        d1Date);

                    patterns.AddRange(ucPatterns);
                }
            }

            return patterns;
        }

        /// <summary>
        /// Try all mathematical operations on labels
        /// </summary>
        private List<DiscoveredPatternAdvanced> TryAllOperations(
            List<StrategyLabel> labels,
            decimal targetValue,
            string targetType,
            string indexName,
            DateTime d0Date,
            DateTime d1Date)
        {
            var patterns = new List<DiscoveredPatternAdvanced>();
            var tolerance = Math.Max(targetValue * 0.05m, 50); // 5% or 50 points, whichever is larger

            // 1. Single label
            foreach (var label in labels)
            {
                TryAddPattern(patterns, label.LabelName, label.LabelValue, targetValue, 
                    targetType, indexName, d0Date, d1Date, 1, new[] { label.LabelName });
            }

            // 2. Label + Label
            for (int i = 0; i < labels.Count; i++)
            {
                for (int j = i + 1; j < labels.Count; j++)
                {
                    var result = labels[i].LabelValue + labels[j].LabelValue;
                    var formula = $"{labels[i].LabelName} + {labels[j].LabelName}";
                    TryAddPattern(patterns, formula, result, targetValue, targetType, 
                        indexName, d0Date, d1Date, 2, new[] { labels[i].LabelName, labels[j].LabelName });
                }
            }

            // 3. Label - Label
            for (int i = 0; i < labels.Count; i++)
            {
                for (int j = 0; j < labels.Count; j++)
                {
                    if (i == j) continue;
                    var result = labels[i].LabelValue - labels[j].LabelValue;
                    var formula = $"{labels[i].LabelName} - {labels[j].LabelName}";
                    TryAddPattern(patterns, formula, result, targetValue, targetType, 
                        indexName, d0Date, d1Date, 2, new[] { labels[i].LabelName, labels[j].LabelName });
                }
            }

            // 4. ABS(Label)
            foreach (var label in labels.Where(l => l.LabelValue < 0))
            {
                var result = Math.Abs(label.LabelValue);
                var formula = $"ABS({label.LabelName})";
                TryAddPattern(patterns, formula, result, targetValue, targetType, 
                    indexName, d0Date, d1Date, 1, new[] { label.LabelName });
            }

            // 5. Label / 2
            foreach (var label in labels.Where(l => l.LabelValue != 0))
            {
                var result = label.LabelValue / 2;
                var formula = $"{label.LabelName} / 2";
                TryAddPattern(patterns, formula, result, targetValue, targetType, 
                    indexName, d0Date, d1Date, 1, new[] { label.LabelName });
            }

            // 6. Label * 2
            foreach (var label in labels)
            {
                var result = label.LabelValue * 2;
                var formula = $"{label.LabelName} * 2";
                TryAddPattern(patterns, formula, result, targetValue, targetType, 
                    indexName, d0Date, d1Date, 1, new[] { label.LabelName });
            }

            // 7. Label * 1.5
            foreach (var label in labels)
            {
                var result = label.LabelValue * 1.5m;
                var formula = $"{label.LabelName} * 1.5";
                TryAddPattern(patterns, formula, result, targetValue, targetType, 
                    indexName, d0Date, d1Date, 1, new[] { label.LabelName });
            }

            // 8. SQRT(Label) - for large values
            foreach (var label in labels.Where(l => l.LabelValue > 0))
            {
                var result = (decimal)Math.Sqrt((double)label.LabelValue);
                var formula = $"SQRT({label.LabelName})";
                TryAddPattern(patterns, formula, result, targetValue, targetType, 
                    indexName, d0Date, d1Date, 1, new[] { label.LabelName });
            }

            // 9. (L1 + L2) / 2 - Average
            for (int i = 0; i < labels.Count; i++)
            {
                for (int j = i + 1; j < labels.Count; j++)
                {
                    var result = (labels[i].LabelValue + labels[j].LabelValue) / 2;
                    var formula = $"({labels[i].LabelName} + {labels[j].LabelName}) / 2";
                    TryAddPattern(patterns, formula, result, targetValue, targetType, 
                        indexName, d0Date, d1Date, 2, new[] { labels[i].LabelName, labels[j].LabelName });
                }
            }

            // 10. (L1 + L2) - L3 (3-way combinations)
            if (labels.Count >= 3)
            {
                for (int i = 0; i < Math.Min(labels.Count, 10); i++)
                {
                    for (int j = i + 1; j < Math.Min(labels.Count, 10); j++)
                    {
                        for (int k = 0; k < Math.Min(labels.Count, 10); k++)
                        {
                            if (k == i || k == j) continue;

                            var result = (labels[i].LabelValue + labels[j].LabelValue) - labels[k].LabelValue;
                            var formula = $"({labels[i].LabelName} + {labels[j].LabelName}) - {labels[k].LabelName}";
                            TryAddPattern(patterns, formula, result, targetValue, targetType, 
                                indexName, d0Date, d1Date, 3, 
                                new[] { labels[i].LabelName, labels[j].LabelName, labels[k].LabelName });
                        }
                    }
                }
            }

            return patterns.Where(p => Math.Abs(p.ErrorAbsolute) <= tolerance).ToList();
        }

        /// <summary>
        /// Helper to try and add a pattern if it's within tolerance
        /// </summary>
        private void TryAddPattern(
            List<DiscoveredPatternAdvanced> patterns,
            string formula,
            decimal calculatedValue,
            decimal targetValue,
            string targetType,
            string indexName,
            DateTime d0Date,
            DateTime d1Date,
            int complexity,
            string[] labelsUsed)
        {
            var error = Math.Abs(calculatedValue - targetValue);
            var errorPct = targetValue == 0 ? 999.99m : (error / Math.Abs(targetValue)) * 100;

            patterns.Add(new DiscoveredPatternAdvanced
            {
                Formula = formula,
                CalculatedValue = calculatedValue,
                TargetValue = targetValue,
                TargetType = targetType,
                ErrorAbsolute = error,
                ErrorPercentage = errorPct,
                IndexName = indexName,
                D0Date = d0Date,
                D1Date = d1Date,
                Complexity = complexity,
                LabelsUsed = labelsUsed.ToList(),
                DiscoveryDate = DateTime.Now
            });
        }

        /// <summary>
        /// Analyze patterns and assign scores
        /// </summary>
        private async Task AnalyzeAndRankPatternsAsync(
            MarketDataContext context,
            List<DiscoveredPatternAdvanced> patterns)
        {
            _logger.LogInformation("\n📊 ANALYZING PATTERNS...");

            // Group by formula and target type
            var groupedPatterns = patterns
                .GroupBy(p => new { p.Formula, p.TargetType, p.IndexName })
                .Select(g => new
                {
                    Formula = g.Key.Formula,
                    TargetType = g.Key.TargetType,
                    IndexName = g.Key.IndexName,
                    Count = g.Count(),
                    AvgError = g.Average(p => p.ErrorPercentage),
                    MinError = g.Min(p => p.ErrorPercentage),
                    MaxError = g.Max(p => p.ErrorPercentage),
                    Consistency = CalculateConsistency(g.ToList())
                })
                .OrderBy(g => g.AvgError)
                .ToList();

            _logger.LogInformation($"   Found {groupedPatterns.Count} unique pattern formulas");

            // Show top 10 patterns per target type
            foreach (var targetType in new[] { "LOW", "HIGH", "CLOSE" })
            {
                _logger.LogInformation($"\n   🎯 TOP 10 PATTERNS FOR {targetType}:");
                var top10 = groupedPatterns
                    .Where(g => g.TargetType == targetType)
                    .Take(10)
                    .ToList();

                for (int i = 0; i < top10.Count; i++)
                {
                    var p = top10[i];
                    _logger.LogInformation(
                        $"      {i + 1}. {p.Formula} " +
                        $"(Avg Error: {p.AvgError:F2}%, Count: {p.Count}, Consistency: {p.Consistency:F2}%)");
                }
            }
        }

        /// <summary>
        /// Calculate consistency score (0-100, higher is better)
        /// </summary>
        private decimal CalculateConsistency(List<DiscoveredPatternAdvanced> patterns)
        {
            if (patterns.Count < 2) return 0;

            var avgError = patterns.Average(p => p.ErrorPercentage);
            var variance = patterns.Average(p => Math.Pow((double)(p.ErrorPercentage - avgError), 2));
            var stdDev = (decimal)Math.Sqrt(variance);

            // Lower std dev = higher consistency
            // Convert to 0-100 scale (inverse relationship)
            var consistency = Math.Max(0, 100 - (stdDev * 2));
            return consistency;
        }

        /// <summary>
        /// Store best patterns in database for future use
        /// </summary>
        private async Task StoreBestPatternsAsync(
            MarketDataContext context,
            List<DiscoveredPatternAdvanced> patterns)
        {
            _logger.LogInformation("\n💾 STORING PATTERNS IN DATABASE...");

            // Group patterns by formula, target type, and index
            var groupedPatterns = patterns
                .GroupBy(p => new { p.Formula, p.TargetType, p.IndexName })
                .Select(g => new
                {
                    Formula = g.Key.Formula,
                    TargetType = g.Key.TargetType,
                    IndexName = g.Key.IndexName,
                    AvgError = g.Average(p => p.ErrorPercentage),
                    MinError = g.Min(p => p.ErrorPercentage),
                    MaxError = g.Max(p => p.ErrorPercentage),
                    Consistency = CalculateConsistency(g.ToList()),
                    Count = g.Count(),
                    Complexity = g.First().Complexity,
                    LabelsUsed = string.Join(", ", g.First().LabelsUsed)
                })
                .Where(g => g.AvgError <= 5.0m) // Only store patterns with <5% error
                .ToList();

            int storedCount = 0;

            foreach (var group in groupedPatterns)
            {
                try
                {
                    // Check if pattern already exists
                    var existing = await context.Database
                        .SqlQueryRaw<int>($@"
                            SELECT Id FROM DiscoveredPatterns 
                            WHERE Formula = {{0}} 
                              AND TargetType = {{1}} 
                              AND IndexName = {{2}}",
                            group.Formula, group.TargetType, group.IndexName)
                        .FirstOrDefaultAsync();

                    if (existing > 0)
                    {
                        // Update existing pattern
                        await context.Database.ExecuteSqlRawAsync($@"
                            UPDATE DiscoveredPatterns 
                            SET AvgErrorPercentage = {{0}},
                                MinErrorPercentage = {{1}},
                                MaxErrorPercentage = {{2}},
                                ConsistencyScore = {{3}},
                                OccurrenceCount = OccurrenceCount + {{4}},
                                LastOccurrence = GETDATE()
                            WHERE Formula = {{5}} 
                              AND TargetType = {{6}} 
                              AND IndexName = {{7}}",
                            group.AvgError, group.MinError, group.MaxError, group.Consistency,
                            group.Count, group.Formula, group.TargetType, group.IndexName);
                    }
                    else
                    {
                        // Insert new pattern
                        await context.Database.ExecuteSqlRawAsync($@"
                            INSERT INTO DiscoveredPatterns (
                                Formula, TargetType, IndexName,
                                AvgErrorPercentage, MinErrorPercentage, MaxErrorPercentage,
                                ConsistencyScore, OccurrenceCount, Complexity, LabelsUsed,
                                FirstDiscovered, LastOccurrence
                            ) VALUES (
                                {{0}}, {{1}}, {{2}}, {{3}}, {{4}}, {{5}}, {{6}}, {{7}}, {{8}}, {{9}},
                                GETDATE(), GETDATE()
                            )",
                            group.Formula, group.TargetType, group.IndexName,
                            group.AvgError, group.MinError, group.MaxError,
                            group.Consistency, group.Count, group.Complexity, group.LabelsUsed);
                    }

                    storedCount++;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Failed to store pattern: {group.Formula}");
                }
            }

            _logger.LogInformation($"   ✅ Stored/Updated {storedCount} patterns in database");

            // Log top 20 patterns
            _logger.LogInformation("\n💾 TOP PATTERNS TO REMEMBER:");

            var bestPatterns = patterns
                .OrderBy(p => p.ErrorPercentage)
                .Take(20)
                .ToList();

            foreach (var pattern in bestPatterns)
            {
                _logger.LogInformation(
                    $"   {pattern.TargetType}: {pattern.Formula} = {pattern.CalculatedValue:F2} " +
                    $"(Target: {pattern.TargetValue:F2}, Error: {pattern.ErrorPercentage:F2}%)");
            }
        }

        /// <summary>
        /// Get date pairs for analysis (D0, D1)
        /// </summary>
        private async Task<List<(DateTime d0, DateTime d1)>> GetDatePairsForAnalysisAsync(
            MarketDataContext context)
        {
            // Get last 30 days of trading dates
            var tradingDates = await context.HistoricalSpotData
                .Where(s => s.IndexName == "SENSEX" && s.TradingDate >= DateTime.Now.AddDays(-60))
                .Select(s => s.TradingDate)
                .Distinct()
                .OrderByDescending(d => d)
                .Take(30)
                .ToListAsync();

            var pairs = new List<(DateTime, DateTime)>();
            for (int i = 0; i < tradingDates.Count - 1; i++)
            {
                pairs.Add((tradingDates[i + 1], tradingDates[i]));
            }

            return pairs;
        }

        /// <summary>
        /// Get nearest expiry for given date
        /// </summary>
        private async Task<DateTime> GetNearestExpiryAsync(
            MarketDataContext context,
            DateTime businessDate,
            string indexName)
        {
            return await context.MarketQuotes
                .Where(q => q.BusinessDate == businessDate
                    && q.TradingSymbol.StartsWith(indexName)
                    && q.ExpiryDate > businessDate)
                .Select(q => q.ExpiryDate)
                .OrderBy(e => e)
                .FirstOrDefaultAsync();
        }

        /// <summary>
        /// Get D1 option quotes
        /// </summary>
        private async Task<List<MarketQuote>> GetD1OptionQuotesAsync(
            MarketDataContext context,
            DateTime d1Date,
            string indexName,
            DateTime expiryDate)
        {
            var quotes = await context.MarketQuotes
                .Where(q => q.BusinessDate == d1Date
                    && q.TradingSymbol.StartsWith(indexName)
                    && q.ExpiryDate == expiryDate)
                .ToListAsync();

            return quotes
                .GroupBy(q => new { q.Strike, q.OptionType })
                .Select(g => g.OrderByDescending(x => x.InsertionSequence).First())
                .ToList();
        }
    }

    /// <summary>
    /// Advanced discovered pattern with more metadata
    /// </summary>
    public class DiscoveredPatternAdvanced
    {
        public string Formula { get; set; } = string.Empty;
        public decimal CalculatedValue { get; set; }
        public decimal TargetValue { get; set; }
        public string TargetType { get; set; } = string.Empty; // LOW, HIGH, CLOSE, LOW_UC, HIGH_UC
        public decimal ErrorAbsolute { get; set; }
        public decimal ErrorPercentage { get; set; }
        public string IndexName { get; set; } = string.Empty;
        public DateTime D0Date { get; set; }
        public DateTime D1Date { get; set; }
        public int Complexity { get; set; }
        public List<string> LabelsUsed { get; set; } = new List<string>();
        public DateTime DiscoveryDate { get; set; }
        public decimal ConsistencyScore { get; set; }
        public int OccurrenceCount { get; set; }
    }
}

