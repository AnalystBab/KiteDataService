using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service for archiving historical options data after expiry
    /// Preserves complete options data including LC/UC values for analysis
    /// </summary>
    public class HistoricalOptionsDataService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<HistoricalOptionsDataService> _logger;
        private readonly KiteConnectService _kiteService;

        public HistoricalOptionsDataService(
            IServiceScopeFactory scopeFactory,
            ILogger<HistoricalOptionsDataService> logger,
            KiteConnectService kiteService)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _kiteService = kiteService;
        }

        /// <summary>
        /// Archive options data DAILY for all active contracts
        /// Archives TODAY's data (last record of current business date) into historical table
        /// This ensures data is preserved BEFORE Kite API discontinues it after expiry
        /// </summary>
        public async Task ArchiveDailyOptionsDataAsync(DateTime businessDate)
        {
            try
            {
                _logger.LogInformation($"📦 Starting DAILY archival for {businessDate:yyyy-MM-dd}");

                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get ALL active instruments (don't filter by expiry - archive everything)
                var allInstruments = await context.Instruments
                    .Where(i => i.InstrumentType == "CE" || i.InstrumentType == "PE")
                    .ToListAsync();

                if (!allInstruments.Any())
                {
                    _logger.LogInformation($"No options instruments found to archive");
                    return;
                }

                _logger.LogInformation($"Found {allInstruments.Count} options instruments for archival");

                // Get the last record of this business date from MarketQuotes for EACH instrument
                // Using GlobalSequence ensures we get the absolute last record in the contract's lifetime for this business date
                var instrumentTokens = allInstruments.Select(i => i.InstrumentToken).ToList();
                
                var lastRecordsOfDay = await context.MarketQuotes
                    .Where(q => q.BusinessDate == businessDate &&
                               instrumentTokens.Contains(q.InstrumentToken))
                    .GroupBy(q => q.InstrumentToken)
                    .Select(g => g.OrderByDescending(q => q.GlobalSequence).First())  // ✅ Use GlobalSequence (lifetime counter)
                    .ToListAsync();

                if (!lastRecordsOfDay.Any())
                {
                    _logger.LogWarning($"No MarketQuotes found for {businessDate:yyyy-MM-dd}");
                    return;
                }

                _logger.LogInformation($"Found {lastRecordsOfDay.Count} instruments with data for {businessDate:yyyy-MM-dd}");

                int archived = 0;
                int updated = 0;

                foreach (var quote in lastRecordsOfDay)
                {
                    var instrument = allInstruments.FirstOrDefault(i => i.InstrumentToken == quote.InstrumentToken);
                    if (instrument == null) continue;

                    var indexName = GetIndexName(instrument.TradingSymbol);
                    if (string.IsNullOrEmpty(indexName)) continue;

                    // Check if this record already exists
                    var existing = await context.HistoricalOptionsData
                        .FirstOrDefaultAsync(h => h.InstrumentToken == quote.InstrumentToken &&
                                                 h.TradingDate == businessDate);

                    if (existing != null)
                    {
                        // Update existing record with latest values (including after-hours changes)
                        existing.OpenPrice = quote.OpenPrice;
                        existing.HighPrice = quote.HighPrice;
                        existing.LowPrice = quote.LowPrice;
                        existing.ClosePrice = quote.ClosePrice;
                        existing.LastPrice = quote.LastPrice;
                        existing.LowerCircuitLimit = quote.LowerCircuitLimit;
                        existing.UpperCircuitLimit = quote.UpperCircuitLimit;
                        existing.LastTradeTime = quote.LastTradeTime;
                        existing.LastUpdated = DateTime.UtcNow.AddHours(5.5);
                        updated++;
                    }
                    else
                    {
                        // Create new record
                        var historicalData = new HistoricalOptionsData
                        {
                            InstrumentToken = quote.InstrumentToken,
                            TradingSymbol = quote.TradingSymbol,
                            IndexName = indexName,
                            Strike = quote.Strike,
                            OptionType = quote.OptionType,
                            ExpiryDate = quote.ExpiryDate,
                            TradingDate = businessDate,
                            OpenPrice = quote.OpenPrice,
                            HighPrice = quote.HighPrice,
                            LowPrice = quote.LowPrice,
                            ClosePrice = quote.ClosePrice,
                            LastPrice = quote.LastPrice,
                            Volume = 0,  // Not available in MarketQuotes
                            LowerCircuitLimit = quote.LowerCircuitLimit,
                            UpperCircuitLimit = quote.UpperCircuitLimit,
                            OpenInterest = null,  // Not available in MarketQuotes
                            DataSource = "MarketQuotes",
                            ArchivedDate = DateTime.UtcNow.AddHours(5.5),
                            IsExpired = instrument.Expiry.HasValue && instrument.Expiry.Value.Date < DateTime.UtcNow.AddHours(5.5).Date,
                            LastTradeTime = quote.LastTradeTime,
                            CreatedAt = DateTime.UtcNow.AddHours(5.5),
                            LastUpdated = DateTime.UtcNow.AddHours(5.5)
                        };

                        context.HistoricalOptionsData.Add(historicalData);
                        archived++;
                    }
                }

                await context.SaveChangesAsync();
                _logger.LogInformation($"✅ DAILY archival complete for {businessDate:yyyy-MM-dd}: {archived} new, {updated} updated");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to archive daily options data for {businessDate:yyyy-MM-dd}");
            }
        }


        /// <summary>
        /// Get index name from trading symbol
        /// </summary>
        private string GetIndexName(string tradingSymbol)
        {
            if (tradingSymbol.StartsWith("NIFTY")) return "NIFTY";
            if (tradingSymbol.StartsWith("SENSEX")) return "SENSEX";
            if (tradingSymbol.StartsWith("BANKNIFTY")) return "BANKNIFTY";
            if (tradingSymbol.StartsWith("FINNIFTY")) return "FINNIFTY";
            if (tradingSymbol.StartsWith("MIDCPNIFTY")) return "MIDCPNIFTY";
            return string.Empty;
        }

        /// <summary>
        /// Query historical options data
        /// </summary>
        public async Task<List<HistoricalOptionsData>> QueryHistoricalDataAsync(
            string? indexName = null,
            DateTime? expiryDate = null,
            DateTime? fromDate = null,
            DateTime? toDate = null,
            decimal? strike = null,
            string? optionType = null)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            var query = context.HistoricalOptionsData.AsQueryable();

            if (!string.IsNullOrEmpty(indexName))
                query = query.Where(h => h.IndexName == indexName);

            if (expiryDate.HasValue)
                query = query.Where(h => h.ExpiryDate == expiryDate.Value);

            if (fromDate.HasValue)
                query = query.Where(h => h.TradingDate >= fromDate.Value);

            if (toDate.HasValue)
                query = query.Where(h => h.TradingDate <= toDate.Value);

            if (strike.HasValue)
                query = query.Where(h => h.Strike == strike.Value);

            if (!string.IsNullOrEmpty(optionType))
                query = query.Where(h => h.OptionType == optionType);

            return await query.OrderBy(h => h.TradingDate).ToListAsync();
        }
    }
}

