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
    public class MarketDataService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<MarketDataService> _logger;

        public MarketDataService(IServiceScopeFactory scopeFactory, ILogger<MarketDataService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        public async Task ClearPlaceholderInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Remove instruments with placeholder tokens (1, 2, 3, 4, 5, etc.)
                var placeholderInstruments = await context.Instruments
                    .Where(i => i.InstrumentToken <= 100) // Remove placeholder tokens
                    .ToListAsync();

                if (placeholderInstruments.Any())
                {
                    context.Instruments.RemoveRange(placeholderInstruments);
                    await context.SaveChangesAsync();
                    _logger.LogInformation($"Cleared {placeholderInstruments.Count} placeholder instruments");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to clear placeholder instruments");
            }
        }

        public async Task RemoveNonIndexOptionInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var allowedPrefixes = new[] { "NIFTY", "BANKNIFTY", "FINNIFTY", "MIDCPNIFTY", "SENSEX" };

                var toRemove = await context.Instruments
                    .Where(i => (i.InstrumentType == "CE" || i.InstrumentType == "PE")
                                && !allowedPrefixes.Any(p => i.TradingSymbol.StartsWith(p))
                                || i.TradingSymbol.StartsWith("NIFTYNXT"))
                    .ToListAsync();

                if (toRemove.Any())
                {
                    context.Instruments.RemoveRange(toRemove);
                    await context.SaveChangesAsync();
                    _logger.LogInformation($"Removed {toRemove.Count} non-index option instruments");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to remove non-index option instruments");
            }
        }

        public async Task SaveInstrumentsAsync(List<Instrument> instruments)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var savedCount = 0;
                var updatedCount = 0;

                foreach (var instrument in instruments)
                {
                    var existing = await context.Instruments
                        .FirstOrDefaultAsync(i => i.Exchange == instrument.Exchange && i.TradingSymbol == instrument.TradingSymbol);

                    if (existing == null)
                    {
                        context.Instruments.Add(instrument);
                        savedCount++;
                        _logger.LogInformation($"Added new instrument: {instrument.TradingSymbol}");
                    }
                    else
                    {
                        // Update existing instrument with new data
                        existing.InstrumentToken = instrument.InstrumentToken;
                        existing.ExchangeToken = instrument.ExchangeToken;
                        existing.Name = instrument.Name;
                        existing.LastPrice = instrument.LastPrice;
                        existing.Expiry = instrument.Expiry;
                        existing.Strike = instrument.Strike;
                        existing.TickSize = instrument.TickSize;
                        existing.LotSize = instrument.LotSize;
                        existing.InstrumentType = instrument.InstrumentType;
                        existing.Segment = instrument.Segment;
                        existing.UpdatedAt = DateTime.UtcNow;
                        
                        updatedCount++;
                        _logger.LogDebug($"Updated instrument: {instrument.TradingSymbol}");
                    }
                }

                await context.SaveChangesAsync();
                _logger.LogInformation($"Saved {savedCount} new instruments, updated {updatedCount} existing instruments");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to save instruments to database");
                throw;
            }
        }

        public async Task SaveMarketQuotesAsync(List<MarketQuote> quotes)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var savedCount = 0;
                var skippedCount = 0;

                foreach (var quote in quotes)
                {
                    // Check for duplicate - same instrument with same OHLC and LC/UC values
                    var existing = await context.MarketQuotes
                        .Where(q => q.InstrumentToken == quote.InstrumentToken)
                        .OrderByDescending(q => q.QuoteTimestamp)
                        .FirstOrDefaultAsync();

                    if (existing == null)
                    {
                        // First time seeing this instrument
                        context.MarketQuotes.Add(quote);
                        savedCount++;
                    }
                    else
                    {
                        // Check if OHLC and LC/UC values are the same (true duplicate)
                        bool isDuplicate = 
                            existing.OpenPrice == quote.OpenPrice &&
                            existing.HighPrice == quote.HighPrice &&
                            existing.LowPrice == quote.LowPrice &&
                            existing.ClosePrice == quote.ClosePrice &&
                            existing.LowerCircuitLimit == quote.LowerCircuitLimit &&
                            existing.UpperCircuitLimit == quote.UpperCircuitLimit &&
                            existing.LastPrice == quote.LastPrice;

                        if (isDuplicate)
                        {
                            skippedCount++;
                            _logger.LogDebug($"Skipped duplicate data for {quote.TradingSymbol} - no change in OHLC/LC/UC");
                        }
                        else
                        {
                            // Data has changed, save the new quote
                            context.MarketQuotes.Add(quote);
                            savedCount++;
                            _logger.LogDebug($"Saved new data for {quote.TradingSymbol} - OHLC/LC/UC changed");
                        }
                    }
                }

                await context.SaveChangesAsync();
                _logger.LogInformation($"Saved {savedCount} new quotes, skipped {skippedCount} duplicates");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to save market quotes to database");
                throw;
            }
        }

        public async Task<List<Instrument>> GetOptionInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                return await context.Instruments
                    .Where(i => i.InstrumentType == "CE" || i.InstrumentType == "PE")
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get option instruments from database");
                return new List<Instrument>();
            }
        }

        public async Task<List<string>> GetOptionInstrumentsForQuotesAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var instruments = await context.Instruments
                    .Where(i => i.InstrumentType == "CE" || i.InstrumentType == "PE")
                    .Select(i => i.InstrumentToken.ToString()) // Return instrument tokens instead of symbols
                    .ToListAsync();

                return instruments;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get option instruments for quotes");
                return new List<string>();
            }
        }

        public async Task CleanupOldDataAsync(int daysToKeep = 30)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var cutoffDate = DateTime.UtcNow.AddDays(-daysToKeep);
                
                var oldQuotes = await context.MarketQuotes
                    .Where(q => q.QuoteTimestamp < cutoffDate)
                    .ToListAsync();

                if (oldQuotes.Any())
                {
                    context.MarketQuotes.RemoveRange(oldQuotes);
                    await context.SaveChangesAsync();
                    _logger.LogInformation($"Cleaned up {oldQuotes.Count} old quotes older than {daysToKeep} days");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to cleanup old data");
            }
        }

        public async Task EnsureDatabaseCreatedAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                await context.Database.EnsureCreatedAsync();
                _logger.LogInformation("Database created/verified successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create/verify database");
                throw;
            }
        }

        // Methods for Circuit Limit Testing
        public async Task<List<Instrument>> GetAllInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                return await context.Instruments.ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get all instruments from database");
                return new List<Instrument>();
            }
        }

        public async Task<List<Instrument>> GetSampleInstrumentsAsync(int count)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                return await context.Instruments
                    .Where(i => i.InstrumentType == "CE" || i.InstrumentType == "PE")
                    .Take(count)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get sample instruments from database");
                return new List<Instrument>();
            }
        }

        public async Task<List<Instrument>> GetInstrumentsByTypeAsync(string type, int count)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Simple categorization based on strike price ranges
                var allInstruments = await context.Instruments
                    .Where(i => i.InstrumentType == "CE" || i.InstrumentType == "PE")
                    .ToListAsync();

                var groupedInstruments = allInstruments
                    .GroupBy(i => i.TradingSymbol.Split('2')[0]) // Group by underlying
                    .SelectMany(g => g)
                    .ToList();

                switch (type.ToUpper())
                {
                    case "DEEP_ITM":
                        return groupedInstruments
                            .Where(i => i.Strike < 100) // Low strike = deep ITM
                            .Take(count)
                            .ToList();
                    case "ATM":
                        return groupedInstruments
                            .Where(i => i.Strike >= 100 && i.Strike <= 500) // Medium strike = ATM
                            .Take(count)
                            .ToList();
                    case "DEEP_OTM":
                        return groupedInstruments
                            .Where(i => i.Strike > 500) // High strike = deep OTM
                            .Take(count)
                            .ToList();
                    default:
                        return groupedInstruments.Take(count).ToList();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get instruments by type from database");
                return new List<Instrument>();
            }
        }

        public async Task<List<Instrument>> GetInstrumentsWithRecentQuotesAsync(int count)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var recentDate = DateTime.Today;
                
                var instrumentsWithQuotes = await context.MarketQuotes
                    .Where(q => q.QuoteTimestamp.Date == recentDate)
                    .Select(q => q.InstrumentToken)
                    .Distinct()
                    .Take(count)
                    .ToListAsync();

                return await context.Instruments
                    .Where(i => instrumentsWithQuotes.Contains(i.InstrumentToken))
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get instruments with recent quotes from database");
                return new List<Instrument>();
            }
        }

        public async Task<List<HistoricalCircuitLimit>> GetHistoricalCircuitLimitsAsync(long instrumentToken, int days)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var cutoffDate = DateTime.Today.AddDays(-days);

                return await context.MarketQuotes
                    .Where(q => q.InstrumentToken == instrumentToken && q.QuoteTimestamp.Date >= cutoffDate)
                    .GroupBy(q => q.QuoteTimestamp.Date)
                    .Select(g => new HistoricalCircuitLimit
                    {
                        TradeDate = g.Key,
                        LowerCircuitLimit = g.Max(q => q.LowerCircuitLimit),
                        UpperCircuitLimit = g.Max(q => q.UpperCircuitLimit)
                    })
                    .OrderByDescending(h => h.TradeDate)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get historical circuit limits from database");
                return new List<HistoricalCircuitLimit>();
            }
        }
    }

    // Helper class for historical circuit limits
    public class HistoricalCircuitLimit
    {
        public DateTime TradeDate { get; set; }
        public decimal LowerCircuitLimit { get; set; }
        public decimal UpperCircuitLimit { get; set; }
    }
} 