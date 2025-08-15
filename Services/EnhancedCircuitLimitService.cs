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
    public class EnhancedCircuitLimitService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<EnhancedCircuitLimitService> _logger;
        private DateTime? _lastBaselineDate = null;
        private Dictionary<long, (decimal LC, decimal UC)> _baselineData = new();

        public EnhancedCircuitLimitService(
            IServiceScopeFactory scopeFactory,
            ILogger<EnhancedCircuitLimitService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Main method to process enhanced circuit limit tracking
        /// </summary>
        public async Task ProcessEnhancedCircuitLimitsAsync(List<MarketQuote> currentQuotes)
        {
            try
            {
                var istTime = DateTime.UtcNow.AddHours(5.5); // UTC+5:30
                var snapshotType = DetermineSnapshotType(istTime);
                
                _logger.LogInformation($"Processing circuit limits at {istTime:HH:mm:ss} IST - Type: {snapshotType}");

                switch (snapshotType)
                {
                    case "MARKET_OPEN":
                        await StoreBaselineDataAsync(currentQuotes, istTime);
                        break;
                    
                    case "MARKET_CLOSE":
                        await StoreFinalDataAsync(currentQuotes, istTime);
                        break;
                    
                    case "POST_MARKET":
                        await StorePostMarketDataAsync(currentQuotes, istTime);
                        break;
                    
                    case "TRADING_HOURS":
                        await DetectAndStoreChangesAsync(currentQuotes, istTime);
                        break;
                    
                    default:
                        _logger.LogDebug($"Outside market hours - no processing needed");
                        break;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in enhanced circuit limit processing");
            }
        }

        /// <summary>
        /// Determine snapshot type based on current IST time
        /// </summary>
        private string DetermineSnapshotType(DateTime istTime)
        {
            var timeOfDay = istTime.TimeOfDay;

            if (timeOfDay >= new TimeSpan(9, 16, 0) && timeOfDay < new TimeSpan(9, 17, 0))
                return "MARKET_OPEN";
            else if (timeOfDay >= new TimeSpan(15, 30, 0) && timeOfDay < new TimeSpan(15, 31, 0))
                return "MARKET_CLOSE";
            else if (timeOfDay >= new TimeSpan(17, 0, 0) && timeOfDay < new TimeSpan(17, 1, 0))
                return "POST_MARKET";
            else if (timeOfDay >= new TimeSpan(9, 17, 0) && timeOfDay < new TimeSpan(15, 30, 0))
                return "TRADING_HOURS";
            else
                return "NON_TRADING";
        }

        /// <summary>
        /// Store baseline data at market open (9:16 AM - after 1 minute stabilization)
        /// </summary>
        private async Task StoreBaselineDataAsync(List<MarketQuote> quotes, DateTime istTime)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var tradingDate = istTime.Date;
                
                // Clear previous baseline for this date
                _baselineData.Clear();
                
                // Store baseline data for all instruments
                foreach (var quote in quotes)
                {
                    _baselineData[quote.InstrumentToken] = (quote.LowerCircuitLimit, quote.UpperCircuitLimit);
                }

                _lastBaselineDate = tradingDate;
                
                _logger.LogInformation($"Baseline data stored for {tradingDate:yyyy-MM-dd} - {quotes.Count} instruments");
                
                // Store in database for historical reference
                await StoreDailySnapshotAsync(context, quotes, "MARKET_OPEN", istTime);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error storing baseline data");
            }
        }

        /// <summary>
        /// Store final data at market close (3:30 PM)
        /// </summary>
        private async Task StoreFinalDataAsync(List<MarketQuote> quotes, DateTime istTime)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                _logger.LogInformation($"Storing final market data for {istTime.Date:yyyy-MM-dd}");
                
                await StoreDailySnapshotAsync(context, quotes, "MARKET_CLOSE", istTime);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error storing final data");
            }
        }

        /// <summary>
        /// Store post-market data (5:00 PM)
        /// </summary>
        private async Task StorePostMarketDataAsync(List<MarketQuote> quotes, DateTime istTime)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                _logger.LogInformation($"Storing post-market data for {istTime.Date:yyyy-MM-dd}");
                
                await StoreDailySnapshotAsync(context, quotes, "POST_MARKET", istTime);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error storing post-market data");
            }
        }

        /// <summary>
        /// Detect and store changes during trading hours (change-based storage)
        /// </summary>
        private async Task DetectAndStoreChangesAsync(List<MarketQuote> currentQuotes, DateTime istTime)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var tradingDate = istTime.Date;
                var changes = new List<CircuitLimitChangeRecord>();

                // Get index OHLC data for correlation
                var indexData = await GetIndexOHLCDataAsync(context, tradingDate);

                foreach (var quote in currentQuotes)
                {
                    // Check if we have baseline data for this instrument
                    if (_baselineData.TryGetValue(quote.InstrumentToken, out var baseline))
                    {
                        var (baselineLC, baselineUC) = baseline;
                        
                        // Check if LC or UC has changed
                        if (baselineLC != quote.LowerCircuitLimit || baselineUC != quote.UpperCircuitLimit)
                        {
                            var changeRecord = CreateChangeRecord(quote, baselineLC, baselineUC, indexData, istTime);
                            changes.Add(changeRecord);
                            
                            // Update baseline to current values
                            _baselineData[quote.InstrumentToken] = (quote.LowerCircuitLimit, quote.UpperCircuitLimit);
                        }
                    }
                    else
                    {
                        // No baseline data - this is first time seeing this instrument
                        // Store as baseline
                        _baselineData[quote.InstrumentToken] = (quote.LowerCircuitLimit, quote.UpperCircuitLimit);
                    }
                }

                if (changes.Any())
                {
                    await StoreChangeRecordsAsync(context, changes);
                    _logger.LogInformation($"Detected and stored {changes.Count} circuit limit changes");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error detecting and storing changes");
            }
        }

        /// <summary>
        /// Get index OHLC data for correlation
        /// </summary>
        private async Task<Dictionary<string, (decimal Open, decimal High, decimal Low, decimal Close, decimal Last)>> GetIndexOHLCDataAsync(MarketDataContext context, DateTime tradingDate)
        {
            var indexData = new Dictionary<string, (decimal, decimal, decimal, decimal, decimal)>();

            try
            {
                // Get NIFTY and SENSEX latest OHLC
                var indexQuotes = await context.MarketQuotes
                    .Where(mq => mq.TradingSymbol == "NIFTY" || mq.TradingSymbol == "SENSEX")
                    .Where(mq => mq.QuoteTimestamp.Date == tradingDate)
                    .GroupBy(mq => mq.TradingSymbol)
                    .Select(g => new
                    {
                        Symbol = g.Key,
                        LatestQuote = g.OrderByDescending(q => q.QuoteTimestamp).First()
                    })
                    .ToListAsync();

                foreach (var indexQuote in indexQuotes)
                {
                    indexData[indexQuote.Symbol] = (
                        indexQuote.LatestQuote.OpenPrice,
                        indexQuote.LatestQuote.HighPrice,
                        indexQuote.LatestQuote.LowPrice,
                        indexQuote.LatestQuote.ClosePrice,
                        indexQuote.LatestQuote.LastPrice
                    );
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting index OHLC data");
            }

            return indexData;
        }

        /// <summary>
        /// Create change record
        /// </summary>
        private CircuitLimitChangeRecord CreateChangeRecord(
            MarketQuote quote, 
            decimal previousLC, 
            decimal previousUC,
            Dictionary<string, (decimal Open, decimal High, decimal Low, decimal Close, decimal Last)> indexData,
            DateTime istTime)
        {
            var changeType = DetermineChangeType(previousLC, previousUC, quote.LowerCircuitLimit, quote.UpperCircuitLimit);
            
            // Get index data based on instrument type
            var indexSymbol = quote.TradingSymbol.StartsWith("NIFTY") ? "NIFTY" : "SENSEX";
            var (indexOpen, indexHigh, indexLow, indexClose, indexLast) = indexData.GetValueOrDefault(indexSymbol, (0, 0, 0, 0, 0));

            return new CircuitLimitChangeRecord
            {
                TradingDate = istTime.Date,
                ChangeTime = istTime,
                InstrumentToken = quote.InstrumentToken,
                TradingSymbol = quote.TradingSymbol,
                Strike = quote.Strike,
                OptionType = quote.OptionType,
                Exchange = quote.Exchange,
                ExpiryDate = quote.ExpiryDate,
                ChangeType = changeType,
                PreviousLC = previousLC,
                PreviousUC = previousUC,
                NewLC = quote.LowerCircuitLimit,
                NewUC = quote.UpperCircuitLimit,
                IndexOpenPrice = indexOpen,
                IndexHighPrice = indexHigh,
                IndexLowPrice = indexLow,
                IndexClosePrice = indexClose,
                IndexLastPrice = indexLast,
                CreatedAt = DateTime.UtcNow
            };
        }

        /// <summary>
        /// Determine change type
        /// </summary>
        private string DetermineChangeType(decimal previousLC, decimal previousUC, decimal currentLC, decimal currentUC)
        {
            if (previousLC != currentLC && previousUC != currentUC)
                return "BOTH_CHANGE";
            else if (previousLC != currentLC)
                return "LC_CHANGE";
            else if (previousUC != currentUC)
                return "UC_CHANGE";
            else
                return "NO_CHANGE";
        }

        /// <summary>
        /// Store daily snapshot
        /// </summary>
        private async Task StoreDailySnapshotAsync(MarketDataContext context, List<MarketQuote> quotes, string snapshotType, DateTime istTime)
        {
            try
            {
                var tradingDate = istTime.Date;
                var snapshots = new List<DailyMarketSnapshot>();

                foreach (var quote in quotes)
                {
                    var snapshot = new DailyMarketSnapshot
                    {
                        TradingDate = tradingDate,
                        SnapshotTime = istTime,
                        InstrumentToken = quote.InstrumentToken,
                        TradingSymbol = quote.TradingSymbol,
                        Strike = quote.Strike,
                        OptionType = quote.OptionType,
                        Exchange = quote.Exchange,
                        ExpiryDate = quote.ExpiryDate,
                        OpenPrice = quote.OpenPrice,
                        HighPrice = quote.HighPrice,
                        LowPrice = quote.LowPrice,
                        ClosePrice = quote.ClosePrice,
                        LastPrice = quote.LastPrice,
                        LowerCircuitLimit = quote.LowerCircuitLimit,
                        UpperCircuitLimit = quote.UpperCircuitLimit,
                        Volume = quote.Volume,
                        OpenInterest = quote.OpenInterest,
                        NetChange = quote.NetChange,
                        SnapshotType = snapshotType,
                        CreatedAt = DateTime.UtcNow
                    };

                    snapshots.Add(snapshot);
                }

                context.DailyMarketSnapshots.AddRange(snapshots);
                await context.SaveChangesAsync();

                _logger.LogInformation($"Stored {snapshotType} snapshot for {quotes.Count} instruments at {istTime:HH:mm:ss}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error storing {snapshotType} snapshot");
            }
        }

        /// <summary>
        /// Store change records
        /// </summary>
        private async Task StoreChangeRecordsAsync(MarketDataContext context, List<CircuitLimitChangeRecord> changes)
        {
            try
            {
                context.CircuitLimitChanges.AddRange(changes);
                await context.SaveChangesAsync();
                
                _logger.LogInformation($"Stored {changes.Count} circuit limit change records");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error storing change records");
            }
        }

        /// <summary>
        /// Get last trading day data for comparison
        /// </summary>
        public async Task<DateTime?> GetLastTradingDayAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var lastTradingDay = await context.MarketQuotes
                    .Where(mq => mq.QuoteTimestamp.Date < DateTime.Today)
                    .Select(mq => mq.QuoteTimestamp.Date)
                    .Distinct()
                    .OrderByDescending(date => date)
                    .FirstOrDefaultAsync();

                return lastTradingDay;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting last trading day");
                return null;
            }
        }

        /// <summary>
        /// Initialize baseline data from last trading day
        /// </summary>
        public async Task InitializeBaselineFromLastTradingDayAsync()
        {
            try
            {
                var lastTradingDay = await GetLastTradingDayAsync();
                
                if (lastTradingDay.HasValue)
                {
                    using var scope = _scopeFactory.CreateScope();
                    var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                    var lastDayQuotes = await context.MarketQuotes
                        .Where(mq => mq.QuoteTimestamp.Date == lastTradingDay.Value)
                        .GroupBy(mq => mq.InstrumentToken)
                        .Select(g => g.OrderByDescending(q => q.QuoteTimestamp).First())
                        .ToListAsync();

                    foreach (var quote in lastDayQuotes)
                    {
                        _baselineData[quote.InstrumentToken] = (quote.LowerCircuitLimit, quote.UpperCircuitLimit);
                    }

                    _lastBaselineDate = lastTradingDay.Value;
                    _logger.LogInformation($"Initialized baseline from last trading day {lastTradingDay.Value:yyyy-MM-dd} - {lastDayQuotes.Count} instruments");
                }
                else
                {
                    _logger.LogInformation("No previous trading day data found - will start fresh from today");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error initializing baseline from last trading day");
            }
        }
    }
}
