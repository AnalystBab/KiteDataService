using System;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Data;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Backfills strategy labels for historical dates where we have spot data but no labels
    /// </summary>
    public class LabelBackfillService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<LabelBackfillService> _logger;
        private readonly StrategyCalculatorService _strategyCalculator;

        public LabelBackfillService(
            IServiceScopeFactory scopeFactory,
            ILogger<LabelBackfillService> logger,
            StrategyCalculatorService strategyCalculator)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _strategyCalculator = strategyCalculator;
        }

        /// <summary>
        /// Backfill labels for all dates where we have spot data but no labels
        /// </summary>
        public async Task BackfillLabelsAsync()
        {
            _logger.LogInformation("🔄 LABEL BACKFILL SERVICE STARTED");
            _logger.LogInformation("   Purpose: Calculate labels for historical dates");

            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            // Get all dates with spot data
            var spotDates = await context.HistoricalSpotData
                .Where(s => s.IndexName == "SENSEX") // Use SENSEX as reference for trading dates
                .Select(s => s.TradingDate)
                .Distinct()
                .OrderBy(d => d)
                .ToListAsync();

            _logger.LogInformation($"   Found {spotDates.Count} dates with spot data");

            // Get dates that already have labels
            var labelDates = await context.StrategyLabels
                .Select(l => l.BusinessDate)
                .Distinct()
                .ToListAsync();

            _logger.LogInformation($"   Found {labelDates.Count} dates with labels already calculated");

            // Find dates that need backfilling
            var datesToBackfill = spotDates.Except(labelDates).ToList();

            if (!datesToBackfill.Any())
            {
                _logger.LogInformation("   ✅ No backfill needed - all dates have labels!");
                return;
            }

            _logger.LogInformation($"   📋 Need to backfill {datesToBackfill.Count} dates");
            _logger.LogInformation($"   Date range: {datesToBackfill.Min():yyyy-MM-dd} to {datesToBackfill.Max():yyyy-MM-dd}");

            int successCount = 0;
            int failCount = 0;

            foreach (var date in datesToBackfill)
            {
                _logger.LogInformation($"\n   📅 Backfilling {date:yyyy-MM-dd}...");

                try
                {
                    // Calculate labels for each index
                    foreach (var indexName in new[] { "SENSEX", "BANKNIFTY", "NIFTY" })
                    {
                        try
                        {
                            var labels = await _strategyCalculator.CalculateAllLabelsAsync(date, indexName);
                            if (labels.Any())
                            {
                                _logger.LogInformation($"      ✅ {indexName}: {labels.Count} labels calculated");
                                successCount++;
                            }
                            else
                            {
                                _logger.LogWarning($"      ⚠️ {indexName}: No labels calculated (missing data?)");
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, $"      ❌ {indexName}: Failed to calculate labels");
                            failCount++;
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"   ❌ Failed to backfill {date:yyyy-MM-dd}");
                    failCount++;
                }
            }

            _logger.LogInformation($"\n✅ BACKFILL COMPLETE!");
            _logger.LogInformation($"   Success: {successCount} index-dates");
            _logger.LogInformation($"   Failed: {failCount} index-dates");
            _logger.LogInformation($"   Total dates processed: {datesToBackfill.Count}");
        }
    }
}

