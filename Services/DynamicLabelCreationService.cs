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
    /// REVOLUTIONARY: Automatically creates NEW labels from discovered patterns!
    /// Self-evolving system that grows its own vocabulary over time.
    /// </summary>
    public class DynamicLabelCreationService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<DynamicLabelCreationService> _logger;
        private const decimal ACCURACY_THRESHOLD = 0.5m; // Must be < 0.5% error to become a label
        private const int MIN_OCCURRENCES = 5; // Must work at least 5 times
        private const decimal MIN_CONSISTENCY = 80.0m; // Must be 80%+ consistent

        public DynamicLabelCreationService(
            IServiceScopeFactory scopeFactory,
            ILogger<DynamicLabelCreationService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Analyzes discovered patterns and promotes best ones to permanent labels
        /// RULE: Only promotes patterns using PURE label combinations (no %, no multipliers, no hard-coded values!)
        /// </summary>
        public async Task PromotePatternsToLabelsAsync()
        {
            _logger.LogInformation("🧬 DYNAMIC LABEL CREATION - Analyzing patterns for promotion...");
            _logger.LogInformation("   RULE: Only PURE label combinations (no %, no multipliers, no hard-coded values)");

            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            // Get current highest label number
            var currentMaxLabel = await GetMaxLabelNumberAsync(context);
            _logger.LogInformation($"   Current max label number: {currentMaxLabel}");

            // Get patterns worthy of promotion
            // CRITICAL FILTER: Only patterns with pure operations (+, -, ABS)
            // NO: *, /, SQRT, or any hard-coded multipliers!
            var eligiblePatterns = await context.Database
                .SqlQueryRaw<PatternForPromotion>(@"
                    SELECT 
                        Formula,
                        TargetType,
                        IndexName,
                        AvgErrorPercentage,
                        ConsistencyScore,
                        OccurrenceCount
                    FROM DiscoveredPatterns
                    WHERE IsActive = 1
                      AND AvgErrorPercentage < {0}
                      AND OccurrenceCount >= {1}
                      AND ConsistencyScore >= {2}
                      AND Formula NOT IN (
                          SELECT DISTINCT LabelName FROM StrategyLabels
                      )
                      AND Formula NOT LIKE '%/%'        -- No division
                      AND Formula NOT LIKE '%*%'        -- No multiplication
                      AND Formula NOT LIKE '%SQRT%'     -- No square root
                      AND Formula NOT LIKE '%.%'        -- No decimal multipliers
                      AND (
                          Formula LIKE '%+%'            -- Only addition
                          OR Formula LIKE '%-%'         -- Or subtraction
                          OR Formula LIKE 'ABS(%'       -- Or absolute value
                          OR Formula NOT LIKE '%(%'     -- Or single label
                      )",
                    ACCURACY_THRESHOLD, MIN_OCCURRENCES, MIN_CONSISTENCY)
                .ToListAsync();

            _logger.LogInformation($"   Found {eligiblePatterns.Count} patterns eligible for promotion");

            if (!eligiblePatterns.Any())
            {
                _logger.LogInformation("   No patterns meet criteria for promotion");
                return;
            }

            int promoted = 0;
            int nextLabelNumber = currentMaxLabel + 1;

            foreach (var pattern in eligiblePatterns)
            {
                try
                {
                    // Create catalog entry for this new label
                    await CreateLabelCatalogEntryAsync(
                        context, 
                        nextLabelNumber, 
                        pattern);

                    _logger.LogInformation(
                        $"   ✅ Promoted: Label #{nextLabelNumber} = {pattern.Formula} " +
                        $"(Error: {pattern.AvgErrorPercentage:F2}%, Occurrences: {pattern.OccurrenceCount})");

                    // Mark pattern as promoted
                    await context.Database.ExecuteSqlRawAsync(@"
                        UPDATE DiscoveredPatterns 
                        SET IsRecommended = 1,
                            ValidationStatus = 'PROMOTED_TO_LABEL',
                            Notes = CONCAT(Notes, ' | Promoted to Label #', {0}, ' on ', GETDATE())
                        WHERE Formula = {1} 
                          AND TargetType = {2} 
                          AND IndexName = {3}",
                        nextLabelNumber, pattern.Formula, pattern.TargetType, pattern.IndexName);

                    nextLabelNumber++;
                    promoted++;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"   ❌ Failed to promote pattern: {pattern.Formula}");
                }
            }

            _logger.LogInformation($"✅ Promoted {promoted} patterns to labels (Labels #{currentMaxLabel + 1} to #{nextLabelNumber - 1})");
        }

        /// <summary>
        /// Get current maximum label number
        /// </summary>
        private async Task<int> GetMaxLabelNumberAsync(MarketDataContext context)
        {
            var maxFromCatalog = await context.Database
                .SqlQueryRaw<int>("SELECT ISNULL(MAX(LabelNumber), 28) FROM StrategyLabelsCatalog")
                .FirstOrDefaultAsync();

            return maxFromCatalog;
        }

        /// <summary>
        /// Create catalog entry for new dynamic label
        /// </summary>
        private async Task CreateLabelCatalogEntryAsync(
            MarketDataContext context,
            int labelNumber,
            PatternForPromotion pattern)
        {
            var labelName = GenerateLabelName(pattern);
            var description = GenerateDescription(pattern);
            var category = DetermineCategory(pattern);

            await context.Database.ExecuteSqlRawAsync(@"
                INSERT INTO StrategyLabelsCatalog (
                    LabelNumber,
                    LabelName,
                    LabelCategory,
                    StepNumber,
                    ImportanceLevel,
                    Formula,
                    Description,
                    Purpose,
                    Meaning,
                    DataType,
                    UnitType,
                    CreatedDate,
                    LastUpdated,
                    Notes
                ) VALUES (
                    {0}, {1}, {2}, 3, 5, {3}, {4}, {5}, {6}, 
                    'DECIMAL', 'POINTS', GETDATE(), GETDATE(), {7}
                )",
                labelNumber,
                labelName,
                category,
                pattern.Formula,
                description,
                $"Predicts {pattern.TargetType} for {pattern.IndexName} with {pattern.AvgErrorPercentage:F2}% error",
                $"This label was auto-generated from pattern discovery. It consistently predicts {pattern.TargetType} with {pattern.ConsistencyScore:F1}% consistency across {pattern.OccurrenceCount} occurrences.",
                $"Auto-created from discovered pattern. Original accuracy: {pattern.AvgErrorPercentage:F2}%, Consistency: {pattern.ConsistencyScore:F2}%, Occurrences: {pattern.OccurrenceCount}");
        }

        /// <summary>
        /// Generate meaningful label name from formula
        /// </summary>
        private string GenerateLabelName(PatternForPromotion pattern)
        {
            // Convert formula to label name
            // Example: "SPOT_CLOSE_D0 + CE_PE_UC_DIFFERENCE" 
            //       → "PREDICTED_HIGH_FROM_SPOT_CE_PE"
            
            var targetPrefix = pattern.TargetType switch
            {
                "LOW" => "PREDICTED_LOW",
                "HIGH" => "PREDICTED_HIGH",
                "CLOSE" => "PREDICTED_CLOSE",
                _ => "PREDICTED_VALUE"
            };

            // Extract key terms from formula
            var formula = pattern.Formula.ToUpper();
            var terms = new List<string>();

            if (formula.Contains("SPOT")) terms.Add("SPOT");
            if (formula.Contains("CE") && formula.Contains("PE")) terms.Add("CE_PE");
            else if (formula.Contains("CE")) terms.Add("CE");
            else if (formula.Contains("PE")) terms.Add("PE");
            
            if (formula.Contains("UC")) terms.Add("UC");
            if (formula.Contains("DISTANCE")) terms.Add("DIST");
            if (formula.Contains("BASE")) terms.Add("BASE");

            var suffix = terms.Any() ? "_" + string.Join("_", terms) : "_DERIVED";
            
            return $"{targetPrefix}{suffix}";
        }

        /// <summary>
        /// Generate description for new label
        /// </summary>
        private string GenerateDescription(PatternForPromotion pattern)
        {
            return $"★★ AUTO-GENERATED! Predicts {pattern.TargetType} for {pattern.IndexName}. " +
                   $"Discovered pattern with {pattern.AvgErrorPercentage:F2}% avg error, " +
                   $"{pattern.ConsistencyScore:F1}% consistency over {pattern.OccurrenceCount} occurrences. " +
                   $"Formula: {pattern.Formula}";
        }

        /// <summary>
        /// Determine category for new label
        /// </summary>
        private string DetermineCategory(PatternForPromotion pattern)
        {
            if (pattern.TargetType == "LOW" || pattern.TargetType == "HIGH")
                return "BOUNDARY";
            else if (pattern.TargetType == "CLOSE")
                return "TARGET";
            else
                return "DERIVED";
        }
    }

    /// <summary>
    /// Pattern eligible for promotion to label
    /// </summary>
    public class PatternForPromotion
    {
        public string Formula { get; set; } = string.Empty;
        public string TargetType { get; set; } = string.Empty;
        public string IndexName { get; set; } = string.Empty;
        public decimal AvgErrorPercentage { get; set; }
        public decimal ConsistencyScore { get; set; }
        public int OccurrenceCount { get; set; }
    }
}

