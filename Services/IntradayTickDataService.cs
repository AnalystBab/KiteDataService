using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Models;
using KiteMarketDataService.Worker.Data;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service to store intraday tick data for all options instruments
    /// Stores OHLC, LC/UC, Greeks every minute regardless of changes
    /// </summary>
    public class IntradayTickDataService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<IntradayTickDataService> _logger;

        public IntradayTickDataService(
            IServiceScopeFactory scopeFactory,
            ILogger<IntradayTickDataService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Store intraday tick data for all instruments every minute
        /// </summary>
        public async Task StoreIntradayTickDataAsync()
        {
            try
            {
                _logger.LogInformation("=== STARTING INTRADAY TICK DATA STORAGE ===");

                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get current business date - FIXED: Use proper BusinessDate calculation
                var currentTime = DateTime.UtcNow.AddHours(5.5); // IST
                var tickTimestamp = new DateTime(currentTime.Year, currentTime.Month, currentTime.Day, 
                                                currentTime.Hour, currentTime.Minute, 0); // Round to minute
                var tickTime = tickTimestamp.TimeOfDay;

                // Get the actual BusinessDate from existing MarketQuotes
                var businessDateNullable = await GetCurrentBusinessDateAsync();
                if (businessDateNullable == null || businessDateNullable == DateTime.MinValue)
                {
                    _logger.LogWarning("No BusinessDate available - cannot store tick data");
                    return;
                }

                var businessDate = businessDateNullable.Value;
                _logger.LogInformation($"📊 Storing tick data for BusinessDate: {businessDate:yyyy-MM-dd} at {tickTimestamp:HH:mm:ss} IST");

                // Get latest market quotes for all instruments
                var latestQuotes = await GetLatestMarketQuotesForTickAsync(businessDate);
                _logger.LogInformation($"🔍 Found {latestQuotes.Count} market quotes for tick data processing");

                if (!latestQuotes.Any())
                {
                    _logger.LogWarning("❌ No market quotes available for tick data storage");
                    return;
                }

                // Log breakdown by instrument type
                var niftyCount = latestQuotes.Count(q => q.TradingSymbol.StartsWith("NIFTY"));
                var sensexCount = latestQuotes.Count(q => q.TradingSymbol.StartsWith("SENSEX"));
                var bankniftyCount = latestQuotes.Count(q => q.TradingSymbol.StartsWith("BANKNIFTY"));
                
                _logger.LogInformation($"📈 Instrument breakdown - NIFTY: {niftyCount}, SENSEX: {sensexCount}, BANKNIFTY: {bankniftyCount}");

                var ticksStored = 0;
                var ticksSkipped = 0;

                foreach (var quote in latestQuotes)
                {
                    try
                    {
                        _logger.LogDebug($"🔄 Processing {quote.TradingSymbol} for tick data");
                        
                        var tickData = await CreateTickDataFromQuoteAsync(quote, businessDate, tickTimestamp, tickTime);
                        if (tickData != null)
                        {
                            var saved = await SaveTickDataAsync(tickData);
                            if (saved)
                            {
                                ticksStored++;
                                _logger.LogDebug($"✅ Stored tick data for {quote.TradingSymbol}");
                            }
                            else
                            {
                                ticksSkipped++;
                                _logger.LogDebug($"⏭️ Skipped tick data for {quote.TradingSymbol} (already exists)");
                            }
                        }
                        else
                        {
                            ticksSkipped++;
                            _logger.LogWarning($"❌ Failed to create tick data for {quote.TradingSymbol}");
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"💥 Failed to create tick data for {quote.TradingSymbol}");
                        ticksSkipped++;
                    }
                }

                _logger.LogInformation($"🎯 Intraday tick data storage completed:");
                _logger.LogInformation($"   ✅ Stored: {ticksStored}");
                _logger.LogInformation($"   ⏭️ Skipped: {ticksSkipped}");
                _logger.LogInformation($"   📊 Success Rate: {(latestQuotes.Count > 0 ? (ticksStored * 100.0 / latestQuotes.Count):0):F1}%");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "💥 Failed to store intraday tick data");
            }
        }

        /// <summary>
        /// Create tick data from market quote
        /// </summary>
        private async Task<IntradayTickData?> CreateTickDataFromQuoteAsync(MarketQuote quote, DateTime businessDate, DateTime tickTimestamp, TimeSpan tickTime)
        {
            try
            {
                // Get current spot price for the underlying index
                var spotPrice = await GetCurrentSpotPriceAsync(quote.TradingSymbol);
                if (spotPrice <= 0)
                {
                    _logger.LogWarning($"No spot price available for {quote.TradingSymbol}");
                    return null;
                }


                var tickData = new IntradayTickData
                {
                    BusinessDate = businessDate,
                    TickTimestamp = tickTimestamp,
                    TickTime = tickTime,
                    InstrumentToken = quote.InstrumentToken,
                    TradingSymbol = quote.TradingSymbol,
                    IndexName = GetIndexName(quote.TradingSymbol),
                    Strike = quote.Strike,
                    OptionType = quote.OptionType,
                    ExpiryDate = quote.ExpiryDate,
                    
                    // OHLC Data from Kite API
                    OpenPrice = quote.OpenPrice,
                    HighPrice = quote.HighPrice,
                    LowPrice = quote.LowPrice,
                    ClosePrice = quote.ClosePrice,
                    LastPrice = quote.LastPrice,
                    
                    // Circuit Limits from Kite API
                    LowerCircuitLimit = quote.LowerCircuitLimit,
                    UpperCircuitLimit = quote.UpperCircuitLimit,
                    
                    // Volume, OpenInterest, and other market data removed - not needed for LC/UC monitoring
                    
                    // Spot Price (underlying index)
                    SpotPrice = spotPrice,
                    
                    
                    
                    // Data Quality Flags
                    HasValidData = true,
                    IsMarketOpen = IsMarketOpen(tickTime),
                    DataSource = "KITE_API"
                };

                return tickData;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error creating tick data for {quote.TradingSymbol}");
                return null;
            }
        }

        /// <summary>
        /// Save tick data to database
        /// </summary>
        private async Task<bool> SaveTickDataAsync(IntradayTickData tickData)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Check if tick data already exists for this timestamp
                var existing = await context.IntradayTickData
                    .Where(t => t.InstrumentToken == tickData.InstrumentToken && 
                               t.TickTimestamp == tickData.TickTimestamp)
                    .FirstOrDefaultAsync();

                if (existing == null)
                {
                    context.IntradayTickData.Add(tickData);
                    await context.SaveChangesAsync();
                    return true; // New record saved
                }
                else
                {
                    // Update existing tick data
                    existing.LastPrice = tickData.LastPrice;
                    existing.OpenPrice = tickData.OpenPrice;
                    existing.HighPrice = tickData.HighPrice;
                    existing.LowPrice = tickData.LowPrice;
                    existing.ClosePrice = tickData.ClosePrice;
                    existing.LowerCircuitLimit = tickData.LowerCircuitLimit;
                    existing.UpperCircuitLimit = tickData.UpperCircuitLimit;
                    existing.Volume = tickData.Volume;
                    existing.OpenInterest = tickData.OpenInterest;
                    existing.SpotPrice = tickData.SpotPrice;
                    
                    // Update Greeks
                    existing.Delta = tickData.Delta;
                    existing.Gamma = tickData.Gamma;
                    existing.Theta = tickData.Theta;
                    existing.Vega = tickData.Vega;
                    existing.Rho = tickData.Rho;
                    existing.ImpliedVolatility = tickData.ImpliedVolatility;
                    existing.TheoreticalPrice = tickData.TheoreticalPrice;
                    existing.PriceDeviation = tickData.PriceDeviation;
                    existing.PriceDeviationPercent = tickData.PriceDeviationPercent;
                    existing.UpdatedAt = DateTime.UtcNow.AddHours(5.5);
                    
                    await context.SaveChangesAsync();
                    return false; // Updated existing record
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error saving tick data for {tickData.TradingSymbol}");
                return false;
            }
        }

        /// <summary>
        /// Get latest market quotes for tick data storage
        /// </summary>
        private async Task<List<MarketQuote>> GetLatestMarketQuotesForTickAsync(DateTime businessDate)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                _logger.LogDebug($"🔍 Querying MarketQuotes for BusinessDate: {businessDate:yyyy-MM-dd}");

                // First get all quotes for the business date
                var allQuotes = await context.MarketQuotes
                    .Where(q => q.BusinessDate == businessDate)
                    .ToListAsync();

                _logger.LogDebug($"📊 Found {allQuotes.Count} total quotes for BusinessDate: {businessDate:yyyy-MM-dd}");

                // Filter for our target instruments
                var filteredQuotes = allQuotes
                    .Where(q => q.TradingSymbol.StartsWith("NIFTY") || 
                               q.TradingSymbol.StartsWith("SENSEX") || 
                               q.TradingSymbol.StartsWith("BANKNIFTY"))
                    .ToList();

                _logger.LogDebug($"📈 Filtered to {filteredQuotes.Count} target instruments");

                // Group by instrument token and get the latest quote for each
                var latestQuotes = filteredQuotes
                    .GroupBy(q => q.InstrumentToken)
                    .Select(g => g.OrderByDescending(q => q.RecordDateTime).First())
                    .ToList();

                _logger.LogInformation($"✅ Retrieved {latestQuotes.Count} latest quotes for tick data processing");

                return latestQuotes;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "💥 Error getting latest market quotes for tick data");
                return new List<MarketQuote>();
            }
        }


        /// <summary>
        /// Get current BusinessDate from existing MarketQuotes
        /// </summary>
        private async Task<DateTime?> GetCurrentBusinessDateAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get the latest BusinessDate from MarketQuotes
                var latestBusinessDate = await context.MarketQuotes
                    .Where(q => q.BusinessDate != DateTime.MinValue)
                    .OrderByDescending(q => q.BusinessDate)
                    .Select(q => q.BusinessDate)
                    .FirstOrDefaultAsync();

                if (latestBusinessDate != DateTime.MinValue)
                {
                    _logger.LogInformation($"📅 Found BusinessDate: {latestBusinessDate:yyyy-MM-dd} from MarketQuotes");
                    return latestBusinessDate;
                }

                _logger.LogWarning("⚠️ No BusinessDate found in MarketQuotes");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting current BusinessDate");
                return null;
            }
        }

        #region Helper Methods

        private string GetIndexName(string tradingSymbol)
        {
            if (tradingSymbol.StartsWith("NIFTY")) return "NIFTY";
            if (tradingSymbol.StartsWith("SENSEX")) return "SENSEX";
            if (tradingSymbol.StartsWith("BANKNIFTY")) return "BANKNIFTY";
            return "UNKNOWN";
        }

        private string GetStrikeType(decimal spot, decimal strike)
        {
            var moneyness = spot / strike;
            if (moneyness > 1.02m) return "ITM";
            if (moneyness < 0.98m) return "OTM";
            return "ATM";
        }

        private decimal CalculateIntrinsicValue(decimal spot, decimal strike, string optionType)
        {
            if (optionType == "CE")
                return Math.Max(0, spot - strike);
            else // PE
                return Math.Max(0, strike - spot);
        }

        private bool IsMarketOpen(TimeSpan tickTime)
        {
            // Market hours: 9:15 AM to 3:30 PM IST
            var marketOpen = new TimeSpan(9, 15, 0);
            var marketClose = new TimeSpan(15, 30, 0);
            return tickTime >= marketOpen && tickTime <= marketClose;
        }

        private async Task<decimal> GetCurrentSpotPriceAsync(string tradingSymbol)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var indexName = GetIndexName(tradingSymbol);
                var today = DateTime.UtcNow.Date;

                _logger.LogDebug($"🔍 Looking for spot price for {indexName} (from {tradingSymbol})");

                var spotData = await context.HistoricalSpotData
                    .Where(s => s.IndexName == indexName && s.TradingDate >= today.AddDays(-5))
                    .OrderByDescending(s => s.TradingDate)
                    .ThenByDescending(s => s.LastUpdated)
                    .FirstOrDefaultAsync();

                if (spotData != null)
                {
                    _logger.LogDebug($"✅ Found spot price for {indexName}: {spotData.ClosePrice} (from {spotData.TradingDate:yyyy-MM-dd})");
                    return spotData.ClosePrice;
                }

                _logger.LogWarning($"⚠️ No spot price found for {indexName}");
                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"💥 Error getting spot price for {tradingSymbol}");
                return 0;
            }
        }



        #endregion
    }
}
