using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using KiteMarketDataService.Worker.Models;
using System.Net.Http;
using System.Text.Json;
using System.Text;

namespace KiteMarketDataService.Worker.Services
{
    public class HistoricalDataService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<HistoricalDataService> _logger;
        private readonly IConfiguration _configuration;
        private readonly string? _apiKey;
        private readonly string? _accessToken;

        public HistoricalDataService(
            HttpClient httpClient,
            ILogger<HistoricalDataService> logger,
            IConfiguration configuration)
        {
            _httpClient = httpClient;
            _logger = logger;
            _configuration = configuration;
            _apiKey = _configuration["KiteConnect:ApiKey"];
            _accessToken = _configuration["KiteConnect:AccessToken"];
        }

        /// <summary>
        /// Fetch historical data for instruments with zero values
        /// </summary>
        public async Task<Dictionary<long, HistoricalQuoteData>> GetHistoricalDataForInstrumentsAsync(
            List<long> instrumentTokens, 
            DateTime fromDate, 
            DateTime toDate)
        {
            var historicalData = new Dictionary<long, HistoricalQuoteData>();
            
            try
            {
                _logger.LogInformation($"Fetching historical data for {instrumentTokens.Count} instruments from {fromDate:yyyy-MM-dd} to {toDate:yyyy-MM-dd}");

                // Process in batches of 10 (Kite API limit for historical data)
                var batches = instrumentTokens
                    .Select((token, index) => new { token, index })
                    .GroupBy(x => x.index / 10)
                    .Select(g => g.Select(x => x.token).ToList())
                    .ToList();

                foreach (var batch in batches)
                {
                    var batchData = await GetHistoricalDataBatchAsync(batch, fromDate, toDate);
                    foreach (var kvp in batchData)
                    {
                        historicalData[kvp.Key] = kvp.Value;
                    }

                    // Rate limiting - wait between batches
                    if (batches.IndexOf(batch) < batches.Count - 1)
                    {
                        await Task.Delay(1000); // 1 second delay
                    }
                }

                _logger.LogInformation($"Successfully fetched historical data for {historicalData.Count} instruments");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to fetch historical data");
            }

            return historicalData;
        }

        /// <summary>
        /// Fetch historical data for a batch of instruments
        /// </summary>
        private async Task<Dictionary<long, HistoricalQuoteData>> GetHistoricalDataBatchAsync(
            List<long> instrumentTokens, 
            DateTime fromDate, 
            DateTime toDate)
        {
            var batchData = new Dictionary<long, HistoricalQuoteData>();

            try
            {
                // Validate API credentials
                if (string.IsNullOrEmpty(_apiKey) || string.IsNullOrEmpty(_accessToken))
                {
                    throw new InvalidOperationException("API Key or Access Token is not configured");
                }

                // Build the API URL for historical data
                var instrumentParams = string.Join("&", instrumentTokens.Select(token => $"i={token}"));
                var fromDateStr = fromDate.ToString("yyyy-MM-dd");
                var toDateStr = toDate.ToString("yyyy-MM-dd");
                
                var url = $"https://api.kite.trade/instruments/historical/{instrumentParams}/day?from={fromDateStr}&to={toDateStr}";

                // Add authorization headers
                _httpClient.DefaultRequestHeaders.Clear();
                _httpClient.DefaultRequestHeaders.Add("X-Kite-Version", "3");
                _httpClient.DefaultRequestHeaders.Add("Authorization", $"token {_apiKey}:{_accessToken}");

                var response = await _httpClient.GetAsync(url);
                
                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    var historicalResponse = JsonSerializer.Deserialize<HistoricalResponse>(content);

                    if (historicalResponse?.Data != null)
                    {
                        foreach (var kvp in historicalResponse.Data)
                        {
                            if (long.TryParse(kvp.Key, out var token))
                            {
                                var instrumentData = kvp.Value;
                                if (instrumentData.Candles != null && instrumentData.Candles.Any())
                                {
                                    // Get the most recent non-zero data
                                    var lastValidCandle = instrumentData.Candles
                                        .Where(c => c[1] > 0 || c[2] > 0 || c[3] > 0 || c[4] > 0) // OHLC > 0
                                        .OrderByDescending(c => c[0]) // Order by timestamp
                                        .FirstOrDefault();

                                    if (lastValidCandle != null)
                                    {
                                        batchData[token] = new HistoricalQuoteData
                                        {
                                            Timestamp = DateTimeOffset.FromUnixTimeSeconds((long)lastValidCandle[0]).DateTime,
                                            Open = lastValidCandle[1],
                                            High = lastValidCandle[2],
                                            Low = lastValidCandle[3],
                                            Close = lastValidCandle[4],
                                            Volume = lastValidCandle[5]
                                        };
                                    }
                                }
                            }
                        }
                    }
                }
                else
                {
                    _logger.LogWarning($"Historical API request failed: {response.StatusCode} - {response.ReasonPhrase}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to fetch historical data for batch: {string.Join(",", instrumentTokens)}");
            }

            return batchData;
        }

        /// <summary>
        /// Check if quote data has zero values and needs historical data
        /// </summary>
        public bool NeedsHistoricalData(QuoteData quoteData)
        {
            // Check if OHLC data is missing (we don't care about LC/UC as they come from quote API)
            return quoteData.OHLC?.Open == 0 && 
                   quoteData.OHLC?.High == 0 && 
                   quoteData.OHLC?.Low == 0 && 
                   quoteData.OHLC?.Close == 0;
        }

        /// <summary>
        /// Check if specific OHLC values are missing and need historical data
        /// </summary>
        public bool NeedsHistoricalOHLCData(QuoteData quoteData)
        {
            return quoteData.OHLC?.Open == 0 || 
                   quoteData.OHLC?.High == 0 || 
                   quoteData.OHLC?.Low == 0 || 
                   quoteData.OHLC?.Close == 0;
        }
    }

    public class HistoricalResponse
    {
        public string? Status { get; set; }
        public Dictionary<string, HistoricalInstrumentData>? Data { get; set; }
    }

    public class HistoricalInstrumentData
    {
        public List<decimal[]>? Candles { get; set; }
    }

    public class HistoricalQuoteData
    {
        public DateTime Timestamp { get; set; }
        public decimal Open { get; set; }
        public decimal High { get; set; }
        public decimal Low { get; set; }
        public decimal Close { get; set; }
        public decimal Volume { get; set; }
    }
}
