using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;
using System.Net.Http;
using System.Text.Json;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service to collect and store historical spot data using Kite's historical API
    /// This ensures we have proper historical OHLC data for BusinessDate calculation
    /// </summary>
    public class HistoricalSpotDataService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<HistoricalSpotDataService> _logger;
        private readonly KiteConnectService _kiteService;

        // Index names to collect historical data for
        private readonly string[] _indexNames = { "NIFTY", "SENSEX", "BANKNIFTY" };

        public HistoricalSpotDataService(
            IServiceScopeFactory scopeFactory,
            ILogger<HistoricalSpotDataService> logger,
            KiteConnectService kiteService)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _kiteService = kiteService;
        }

        /// <summary>
        /// Collect and store historical spot data for all indices
        /// This should be called BEFORE market hours to get previous day's data
        /// </summary>
        public async Task CollectAndStoreHistoricalDataAsync()
        {
            try
            {
                _logger.LogInformation("=== STARTING HISTORICAL SPOT DATA COLLECTION ===");

                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get INDEX instruments from database
                var indexInstruments = await context.Instruments
                    .Where(i => i.InstrumentType == "INDEX" && _indexNames.Contains(i.TradingSymbol))
                    .ToListAsync();

                _logger.LogInformation($"🔍 Found {indexInstruments.Count} INDEX instruments for historical data:");
                foreach (var inst in indexInstruments)
                {
                    _logger.LogInformation($"  📊 {inst.TradingSymbol} - Token: {inst.InstrumentToken} - Exchange: {inst.Exchange}");
                }

                foreach (var instrument in indexInstruments)
                {
                    await CollectHistoricalDataForIndexAsync(instrument.TradingSymbol, instrument.InstrumentToken);
                }

                _logger.LogInformation("=== HISTORICAL SPOT DATA COLLECTION COMPLETED ===");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to collect historical spot data");
            }
        }

        /// <summary>
        /// Collect historical data for a specific index
        /// </summary>
        private async Task CollectHistoricalDataForIndexAsync(string indexName, long instrumentToken)
        {
            try
            {
                _logger.LogInformation($"Collecting historical data for {indexName} (Token: {instrumentToken})");

                // Check what's the last available historical data date
                var lastHistoricalDate = await GetLastHistoricalDataDateAsync(indexName);
                
                // Calculate date range - get data from last available date + 1 to yesterday/today
                var fromDate = lastHistoricalDate?.AddDays(1) ?? DateTime.Today.AddDays(-30); // Default to last 30 days if no data
                
                // CRITICAL: After market close (3:30 PM), include TODAY's data
                var currentTime = DateTime.Now.TimeOfDay;
                var marketClose = new TimeSpan(15, 30, 0); // 3:30 PM
                var toDate = currentTime > marketClose 
                    ? DateTime.Today           // AFTER market close - include today's data
                    : DateTime.Today.AddDays(-1); // BEFORE market close - only yesterday's data

                _logger.LogInformation($"Current time: {DateTime.Now:HH:mm:ss}, Market close: {marketClose}, Using toDate: {toDate:yyyy-MM-dd}");

                if (fromDate > toDate)
                {
                    _logger.LogInformation($"No new historical data needed for {indexName} - last date: {lastHistoricalDate:yyyy-MM-dd}");
                    return;
                }

                _logger.LogInformation($"Fetching historical data for {indexName} from {fromDate:yyyy-MM-dd} to {toDate:yyyy-MM-dd}");

                // Call Kite historical API using KiteConnectService
                var historicalData = await _kiteService.GetHistoricalDataAsync(instrumentToken, fromDate, toDate);
                
                if (historicalData?.Any() == true)
                {
                    await StoreHistoricalDataAsync(indexName, historicalData);
                    _logger.LogInformation($"✅ Successfully stored {historicalData.Count} historical records for {indexName}");
                }
                else
                {
                    _logger.LogWarning($"No historical data received from Kite API for {indexName}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to collect historical data for {indexName}");
            }
        }

        /// <summary>
        /// Get the last available historical data date for an index
        /// </summary>
        private async Task<DateTime?> GetLastHistoricalDataDateAsync(string indexName)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var lastData = await context.HistoricalSpotData
                    .Where(s => s.IndexName == indexName)
                    .OrderByDescending(s => s.TradingDate)
                    .FirstOrDefaultAsync();

                return lastData?.TradingDate;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to get last historical data date for {indexName}");
                return null;
            }
        }


        /// <summary>
        /// Store historical data in SpotData table
        /// </summary>
        private async Task StoreHistoricalDataAsync(string indexName, List<HistoricalCandleData> historicalData)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var historicalSpotDataList = new List<HistoricalSpotData>();
                var currentTime = DateTime.Now;

                foreach (var candle in historicalData)
                {
                    // Convert historical candle to HistoricalSpotData
                    var historicalSpotData = new HistoricalSpotData
                    {
                        IndexName = indexName,
                        TradingDate = candle.Date.Date, // Historical date from Kite
                        OpenPrice = candle.Open,
                        HighPrice = candle.High,
                        LowPrice = candle.Low,
                        ClosePrice = candle.Close,
                        Volume = candle.Volume,
                        DataSource = "Kite Historical API",
                        CreatedDate = currentTime,
                        LastUpdated = currentTime
                    };

                    historicalSpotDataList.Add(historicalSpotData);
                }

                // Save to database with duplicate prevention
                var savedCount = 0;
                var skippedCount = 0;

                foreach (var historicalSpotData in historicalSpotDataList)
                {
                    // Check if we already have data for this index and trading date
                    var existingData = await context.HistoricalSpotData
                        .Where(s => s.IndexName == historicalSpotData.IndexName && 
                                   s.TradingDate.Date == historicalSpotData.TradingDate.Date)
                        .FirstOrDefaultAsync();

                    if (existingData == null)
                    {
                        context.HistoricalSpotData.Add(historicalSpotData);
                        savedCount++;
                    }
                    else
                    {
                        skippedCount++;
                        _logger.LogDebug($"Skipped duplicate historical data for {historicalSpotData.IndexName} on {historicalSpotData.TradingDate:yyyy-MM-dd}");
                    }
                }

                await context.SaveChangesAsync();
                _logger.LogInformation($"Historical data stored for {indexName}: {savedCount} new records, {skippedCount} duplicates skipped");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to store historical data for {indexName}");
            }
        }
    }

    /// <summary>
    /// Kite Historical API response model
    /// </summary>
    public class KiteHistoricalResponse
    {
        public string Status { get; set; } = string.Empty;
        public HistoricalData Data { get; set; } = new();
    }

    public class HistoricalData
    {
        public List<HistoricalCandleData> Candles { get; set; } = new();
    }

    public class HistoricalCandleData
    {
        public DateTime Date { get; set; }
        public decimal Open { get; set; }
        public decimal High { get; set; }
        public decimal Low { get; set; }
        public decimal Close { get; set; }
        public long Volume { get; set; }
    }
}
