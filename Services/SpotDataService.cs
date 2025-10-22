using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace KiteMarketDataService.Worker.Services
{
    public class SpotDataService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<SpotDataService> _logger;
        private readonly FullInstrumentService _fullInstrumentService;

        public SpotDataService(
            IServiceScopeFactory scopeFactory,
            ILogger<SpotDataService> logger,
            FullInstrumentService fullInstrumentService)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _fullInstrumentService = fullInstrumentService;
        }

        /// <summary>
        /// Save spot data to IntradaySpotData table with duplicate prevention
        /// UPDATED: Use new IntradaySpotData table for real-time quotes
        /// </summary>
        public async Task SaveSpotDataAsync(List<IntradaySpotData> spotDataList)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var savedCount = 0;
                var skippedCount = 0;

                foreach (var spotData in spotDataList)
                {
                    // Check for duplicates: same index, same trading date, same last price
                    var existingData = await context.IntradaySpotData
                        .Where(s => s.IndexName == spotData.IndexName && 
                                   s.TradingDate.Date == spotData.TradingDate.Date &&
                                   s.LastPrice == spotData.LastPrice)
                        .FirstOrDefaultAsync();

                    if (existingData == null)
                    {
                        context.IntradaySpotData.Add(spotData);
                        savedCount++;
                        _logger.LogDebug($"Added new intraday spot data for {spotData.IndexName} at {spotData.QuoteTimestamp:yyyy-MM-dd HH:mm:ss} with price {spotData.LastPrice:F2}");
                    }
                    else
                    {
                        skippedCount++;
                        _logger.LogDebug($"Skipped duplicate intraday spot data for {spotData.IndexName} with price {spotData.LastPrice:F2}");
                    }
                }

                await context.SaveChangesAsync();
                _logger.LogInformation($"Spot data saved: {savedCount} new records, {skippedCount} duplicates skipped");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to save spot data");
                throw;
            }
        }

        /// <summary>
        /// Get latest spot data for a specific index
        /// </summary>
        public async Task<SpotData?> GetLatestSpotDataAsync(string indexName)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                return await context.SpotData
                    .Where(s => s.IndexName == indexName)
                    .OrderByDescending(s => s.TradingDate)
                    .ThenByDescending(s => s.QuoteTimestamp)
                    .FirstOrDefaultAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to get latest spot data for {indexName}");
                return null;
            }
        }

        /// <summary>
        /// Get spot data for a specific date
        /// </summary>
        public async Task<SpotData?> GetSpotDataForDateAsync(string indexName, DateTime date)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                return await context.SpotData
                    .Where(s => s.IndexName == indexName && s.TradingDate.Date == date.Date)
                    .FirstOrDefaultAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to get spot data for {indexName} on {date:yyyy-MM-dd}");
                return null;
            }
        }

        /// <summary>
        /// Get all spot instruments (INDEX type) from Instruments table
        /// FIXED: Use actual INDEX instruments instead of deriving from options
        /// </summary>
        public async Task<List<Instrument>> GetSpotInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get actual INDEX instruments (NIFTY, SENSEX, BANKNIFTY)
                // EXCLUDE futures by only using NSE/BSE exchanges (not NFO/BFO)
                var indexNames = new[] { "NIFTY", "SENSEX", "BANKNIFTY" };
                var spotInstruments = await context.Instruments
                    .Where(i => i.InstrumentType == "INDEX" && 
                               indexNames.Contains(i.TradingSymbol) &&
                               (i.Exchange == "NSE" || i.Exchange == "BSE")) // Only real indices, not futures
                    .ToListAsync();

                _logger.LogInformation($"Found {spotInstruments.Count} actual INDEX instruments for spot data collection:");
                foreach (var instrument in spotInstruments)
                {
                    _logger.LogInformation($"  {instrument.TradingSymbol} - Token: {instrument.InstrumentToken} - Exchange: {instrument.Exchange}");
                }

                return spotInstruments;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get INDEX instruments for spot data");
                return new List<Instrument>();
            }
        }

        /// <summary>
        /// Convert Kite quote response to IntradaySpotData entities
        /// FIXED: Use actual INDEX instrument data instead of deriving from options
        /// </summary>
        public List<IntradaySpotData> ConvertToSpotData(Dictionary<string, QuoteData> quoteData, List<Instrument> spotInstruments)
        {
            var spotDataMap = new Dictionary<string, IntradaySpotData>();
            var currentTime = DateTime.Now; // Already in IST

            foreach (var instrument in spotInstruments)
            {
                if (quoteData.TryGetValue(instrument.InstrumentToken.ToString(), out var quote))
                {
                    // Get the base index name (NIFTY, SENSEX, etc.) from the instrument
                    var indexName = instrument.TradingSymbol; // INDEX instruments have exact names
                    
                    // Check if we already have data for this index name
                    if (spotDataMap.ContainsKey(indexName))
                    {
                        continue; // Skip duplicates
                    }
                    
                    // Use actual INDEX data from Kite API
                    var spotData = new IntradaySpotData
                    {
                        IndexName = indexName,
                        TradingDate = currentTime.Date,
                        QuoteTimestamp = currentTime,
                        OpenPrice = quote.OHLC?.Open ?? 0,
                        HighPrice = quote.OHLC?.High ?? 0,
                        LowPrice = quote.OHLC?.Low ?? 0,
                        ClosePrice = quote.OHLC?.Close ?? 0,
                        LastPrice = quote.LastPrice, // Use actual INDEX last price from Kite API
                        Volume = quote.Volume,
                        Change = quote.NetChange, // Use actual change from Kite API
                        ChangePercent = quote.OHLC?.Close > 0 ? (quote.NetChange / quote.OHLC.Close * 100) : 0,
                        DataSource = "KiteConnect (INDEX)",
                        IsMarketOpen = IsMarketOpen(currentTime),
                        CreatedDate = DateTime.Now, // Already in IST
                        LastUpdated = DateTime.Now // Already in IST
                    };

                    spotDataMap[indexName] = spotData;
                    _logger.LogInformation($"✅ Collected {indexName} spot data: LastPrice={quote.LastPrice:F2}, Change={quote.NetChange:F2} from {instrument.TradingSymbol}");
                }
            }

            return spotDataMap.Values.ToList();
        }

        /// <summary>
        /// Check if market is open (9:15 AM - 3:30 PM IST)
        /// </summary>
        private bool IsMarketOpen(DateTime currentTime)
        {
            var istTime = currentTime; // Already converted to IST
            var timeOnly = istTime.TimeOfDay;
            var marketOpen = new TimeSpan(9, 15, 0);  // 9:15 AM
            var marketClose = new TimeSpan(15, 30, 0); // 3:30 PM

            return timeOnly >= marketOpen && timeOnly <= marketClose;
        }

        /// <summary>
        /// Get the base index name from instrument symbol
        /// </summary>
        private string? GetBaseIndexName(string tradingSymbol)
        {
            // Handle exact matches for actual INDEX instruments
            if (tradingSymbol.Equals("NIFTY 50", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (tradingSymbol.Equals("NIFTY 100", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (tradingSymbol.Equals("NIFTY 200", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (tradingSymbol.Equals("NIFTY 500", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (tradingSymbol.Equals("SENSEX", StringComparison.OrdinalIgnoreCase)) return "SENSEX";
            
            // Handle prefix matches for both actual INDEX and FUTURES proxy
            if (tradingSymbol.StartsWith("NIFTY", StringComparison.OrdinalIgnoreCase) && 
                !tradingSymbol.StartsWith("NIFTYNXT", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (tradingSymbol.StartsWith("BANKNIFTY", StringComparison.OrdinalIgnoreCase)) return "BANKNIFTY";
            if (tradingSymbol.StartsWith("FINNIFTY", StringComparison.OrdinalIgnoreCase)) return "FINNIFTY";
            if (tradingSymbol.StartsWith("MIDCPNIFTY", StringComparison.OrdinalIgnoreCase)) return "MIDCPNIFTY";
            if (tradingSymbol.StartsWith("SENSEX", StringComparison.OrdinalIgnoreCase)) return "SENSEX";
            
            return null;
        }
    }
}
