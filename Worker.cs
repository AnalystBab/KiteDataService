using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Services;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly IConfiguration _configuration;
        private readonly KiteConnectService _kiteService;
        private readonly MarketDataService _marketDataService;
        private readonly SmartCircuitLimitsService _smartCircuitLimitsService;
        private readonly EnhancedCircuitLimitService _enhancedCircuitLimitService;
        private readonly TimeSpan _quoteInterval = TimeSpan.FromMinutes(1); // Collect quotes every minute
        private readonly TimeSpan _instrumentUpdateInterval = TimeSpan.FromHours(24); // Update instruments daily

        public Worker(
            ILogger<Worker> logger,
            IConfiguration configuration,
            KiteConnectService kiteService,
            MarketDataService marketDataService,
            SmartCircuitLimitsService smartCircuitLimitsService,
            EnhancedCircuitLimitService enhancedCircuitLimitService)
        {
            _logger = logger;
            _configuration = configuration;
            _kiteService = kiteService;
            _marketDataService = marketDataService;
            _smartCircuitLimitsService = smartCircuitLimitsService;
            _enhancedCircuitLimitService = enhancedCircuitLimitService;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Kite Market Data Service started");

            try
            {
                // Ensure database is created
                await _marketDataService.EnsureDatabaseCreatedAsync();

                // Get request token from configuration
                var requestToken = _configuration["KiteConnect:RequestToken"];
                
                if (string.IsNullOrEmpty(requestToken))
                {
                    _logger.LogError("No request token found in configuration. Please update appsettings.json with your request token.");
                    _logger.LogError("Service will not start without a valid request token.");
                    return;
                }
                
                _logger.LogInformation("Request token found in configuration. Attempting to authenticate...");
                
                // Authenticate with the provided request token
                var isAuthenticated = await _kiteService.AuthenticateWithRequestTokenAsync(requestToken);
                
                if (!isAuthenticated)
                {
                    _logger.LogError("Failed to authenticate with provided request token. Please check your token and try again.");
                    _logger.LogError("Service will not start without successful authentication.");
                    return;
                }
                
                _logger.LogInformation("Authentication successful! Service is ready to collect data.");

                // Initialize enhanced circuit limit service
                await _enhancedCircuitLimitService.InitializeBaselineFromLastTradingDayAsync();

                // Load initial instruments
                await LoadInstrumentsAsync();

                var lastInstrumentUpdate = DateTime.UtcNow;

                while (!stoppingToken.IsCancellationRequested)
                {
                    try
                    {
                        // Update instruments daily
                        if (DateTime.UtcNow - lastInstrumentUpdate > _instrumentUpdateInterval)
                        {
                            await LoadInstrumentsAsync();
                            lastInstrumentUpdate = DateTime.UtcNow;
                        }

                        // Collect market quotes
                        await CollectMarketQuotesAsync();

                        // Process smart circuit limits (after collecting quotes)
                        await ProcessSmartCircuitLimitsAsync();

                        // Cleanup old data (once per day)
                        if (DateTime.UtcNow.Hour == 2 && DateTime.UtcNow.Minute == 0)
                        {
                            await _marketDataService.CleanupOldDataAsync(30);
                        }

                        await Task.Delay(_quoteInterval, stoppingToken);
                    }
                    catch (OperationCanceledException)
                    {
                        break;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error in main service loop");
                        await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken); // Wait 5 minutes before retrying
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fatal error in worker service");
            }
        }

        private async Task LoadInstrumentsAsync()
        {
            try
            {
                _logger.LogInformation("Loading instruments from Kite Connect...");
                
                // First clear any placeholder instruments
                await _marketDataService.ClearPlaceholderInstrumentsAsync();
                
                // Get real instruments from Kite Connect API
                var realInstruments = await _kiteService.GetInstrumentsListAsync();
                
                if (realInstruments.Any())
                {
                    await _marketDataService.SaveInstrumentsAsync(realInstruments);
                    _logger.LogInformation($"Loaded {realInstruments.Count} real instruments from API");
                }
                else
                {
                    _logger.LogError("No instruments returned by Kite API. Skipping instrument load and will retry later.");
                    return;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load instruments");
            }
        }

        private async Task CollectMarketQuotesAsync()
        {
            try
            {
                _logger.LogInformation("=== STARTING MARKET QUOTE COLLECTION ===");
                _logger.LogInformation($"Collection started at: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");

                // Get real instruments from database with their tokens
                var instruments = await _marketDataService.GetOptionInstrumentsAsync();
                
                if (!instruments.Any())
                {
                    _logger.LogWarning("No instruments available for quote collection");
                    return;
                }

                _logger.LogInformation($"Total instruments found in database: {instruments.Count}");
                
                // Log instrument distribution by underlying
                var instrumentGroups = instruments.GroupBy(i => i.TradingSymbol.Substring(0, Math.Min(10, i.TradingSymbol.Length))).ToList();
                _logger.LogInformation($"Instrument distribution:");
                foreach (var group in instrumentGroups.Take(5)) // Log first 5 groups
                {
                    _logger.LogInformation($"  {group.Key}: {group.Count()} instruments");
                }

                // Get quotes from Kite Connect using real instrument tokens
                var instrumentTokens = instruments.Select(i => i.InstrumentToken.ToString()).ToList();
                _logger.LogInformation($"Requesting quotes for {instrumentTokens.Count} instrument tokens from Kite Connect API");
                
                var quoteResponse = await _kiteService.GetMarketQuotesAsync(instrumentTokens);
                
                if (quoteResponse?.Data == null)
                {
                    _logger.LogWarning("No quote response received from Kite Connect");
                    return;
                }

                _logger.LogInformation($"API Response Status: {quoteResponse.Status}");

                if (!quoteResponse.Data.Any())
                {
                    _logger.LogWarning($"Quote response received but no data. Response status: {quoteResponse.Status}");
                    _logger.LogInformation("This might be normal if market is closed or instruments are not trading");
                    return;
                }

                _logger.LogInformation($"Received quotes for {quoteResponse.Data.Count} instruments out of {instrumentTokens.Count} requested");
                _logger.LogInformation($"Success rate: {(double)quoteResponse.Data.Count / instrumentTokens.Count * 100:F1}%");

                // Log which instruments got quotes vs which didn't
                var receivedTokens = quoteResponse.Data.Keys.ToHashSet();
                var missingTokens = instrumentTokens.Except(receivedTokens).ToList();
                
                if (missingTokens.Any())
                {
                    _logger.LogWarning($"Missing quotes for {missingTokens.Count} instruments:");
                    foreach (var missingToken in missingTokens.Take(10)) // Log first 10 missing
                    {
                        var instrument = instruments.FirstOrDefault(i => i.InstrumentToken.ToString() == missingToken);
                        _logger.LogWarning($"  Token {missingToken}: {instrument?.TradingSymbol ?? "Unknown"}");
                    }
                    if (missingTokens.Count > 10)
                    {
                        _logger.LogWarning($"  ... and {missingTokens.Count - 10} more missing instruments");
                    }
                }

                // Convert to MarketQuote entities
                var marketQuotes = new List<MarketQuote>();
                
                // Create a lookup dictionary for instrument tokens to instrument details
                var instrumentLookup = instruments.ToDictionary(i => i.InstrumentToken.ToString(), i => i);
                
                foreach (var quote in quoteResponse.Data)
                {
                    var marketQuote = ConvertToMarketQuote(quote.Key, quote.Value, instrumentLookup, quoteResponse.Data);
                    if (marketQuote != null)
                    {
                        marketQuotes.Add(marketQuote);
                    }
                }

                _logger.LogInformation($"Successfully converted {marketQuotes.Count} quotes to MarketQuote entities");

                // Save to database
                if (marketQuotes.Any())
                {
                    await _marketDataService.SaveMarketQuotesAsync(marketQuotes);
                    _logger.LogInformation($"Collected and saved {marketQuotes.Count} market quotes to database");
                    
                    // Process enhanced circuit limit tracking
                    await _enhancedCircuitLimitService.ProcessEnhancedCircuitLimitsAsync(marketQuotes);
                    
                    // Log summary by underlying
                    var quoteGroups = marketQuotes.GroupBy(q => q.TradingSymbol.Substring(0, Math.Min(10, q.TradingSymbol.Length))).ToList();
                    _logger.LogInformation($"Saved quotes by underlying:");
                    foreach (var group in quoteGroups.Take(5))
                    {
                        _logger.LogInformation($"  {group.Key}: {group.Count()} quotes");
                    }
                }
                else
                {
                    _logger.LogInformation("No valid quotes to save");
                }
                
                _logger.LogInformation("=== MARKET QUOTE COLLECTION COMPLETED ===");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to collect market quotes");
            }
        }

        private MarketQuote ConvertToMarketQuote(string instrumentKey, QuoteData quoteData, Dictionary<string, Instrument> instrumentLookup, Dictionary<string, QuoteData>? allQuotes = null)
        {
            try
            {
                // The instrumentKey is actually the instrument token from Kite Connect
                if (!long.TryParse(instrumentKey, out var instrumentToken))
                {
                    _logger.LogWarning($"Invalid instrument token format: {instrumentKey}");
                    return null;
                }

                // Look up the instrument details from our database
                if (!instrumentLookup.TryGetValue(instrumentKey, out var instrument))
                {
                    _logger.LogWarning($"Instrument not found in database for token: {instrumentKey}");
                    return null;
                }

                var quoteTimestamp = GetValidTimestamp(quoteData.Timestamp, quoteData.LastTradeTime, allQuotes);
                
                var marketQuote = new MarketQuote
                {
                    // Trading Information
                    TradingDate = quoteTimestamp.Date,
                    TradeTime = quoteTimestamp.TimeOfDay,
                    QuoteTimestamp = quoteTimestamp,
                    
                    // Instrument Information
                    InstrumentToken = quoteData.InstrumentToken,
                    TradingSymbol = instrument.TradingSymbol,
                    Exchange = instrument.Exchange,
                    Strike = instrument.Strike,
                    OptionType = instrument.InstrumentType,
                    ExpiryDate = instrument.Expiry?.Date ?? DateTime.MinValue,
                    
                    // Price Data (OHLC + Last)
                    OpenPrice = quoteData.OHLC?.Open ?? 0,
                    HighPrice = quoteData.OHLC?.High ?? 0,
                    LowPrice = quoteData.OHLC?.Low ?? 0,
                    ClosePrice = quoteData.OHLC?.Close ?? 0,
                    LastPrice = quoteData.LastPrice,
                    
                    // Circuit Limits
                    LowerCircuitLimit = quoteData.LowerCircuitLimit,
                    UpperCircuitLimit = quoteData.UpperCircuitLimit,
                    
                    // Volume and Trading Data
                    Volume = quoteData.Volume,
                    LastQuantity = quoteData.LastQuantity,
                    BuyQuantity = quoteData.BuyQuantity,
                    SellQuantity = quoteData.SellQuantity,
                    AveragePrice = quoteData.AveragePrice,
                    
                    // Open Interest
                    OpenInterest = quoteData.OpenInterest,
                    OiDayHigh = quoteData.OiDayHigh,
                    OiDayLow = quoteData.OiDayLow,
                    NetChange = quoteData.NetChange
                };

                // Set market depth data
                if (quoteData.Depth?.Buy != null && quoteData.Depth.Buy.Count > 0)
                {
                    var buy1 = quoteData.Depth.Buy[0];
                    marketQuote.BuyPrice1 = buy1.Price;
                    marketQuote.BuyQuantity1 = buy1.Quantity;
                    marketQuote.BuyOrders1 = (int)buy1.Orders;
                }

                if (quoteData.Depth?.Buy != null && quoteData.Depth.Buy.Count > 1)
                {
                    var buy2 = quoteData.Depth.Buy[1];
                    marketQuote.BuyPrice2 = buy2.Price;
                    marketQuote.BuyQuantity2 = buy2.Quantity;
                    marketQuote.BuyOrders2 = (int)buy2.Orders;
                }

                if (quoteData.Depth?.Buy != null && quoteData.Depth.Buy.Count > 2)
                {
                    var buy3 = quoteData.Depth.Buy[2];
                    marketQuote.BuyPrice3 = buy3.Price;
                    marketQuote.BuyQuantity3 = buy3.Quantity;
                    marketQuote.BuyOrders3 = (int)buy3.Orders;
                }

                if (quoteData.Depth?.Buy != null && quoteData.Depth.Buy.Count > 3)
                {
                    var buy4 = quoteData.Depth.Buy[3];
                    marketQuote.BuyPrice4 = buy4.Price;
                    marketQuote.BuyQuantity4 = buy4.Quantity;
                    marketQuote.BuyOrders4 = (int)buy4.Orders;
                }

                if (quoteData.Depth?.Buy != null && quoteData.Depth.Buy.Count > 4)
                {
                    var buy5 = quoteData.Depth.Buy[4];
                    marketQuote.BuyPrice5 = buy5.Price;
                    marketQuote.BuyQuantity5 = buy5.Quantity;
                    marketQuote.BuyOrders5 = (int)buy5.Orders;
                }

                if (quoteData.Depth?.Sell != null && quoteData.Depth.Sell.Count > 0)
                {
                    var sell1 = quoteData.Depth.Sell[0];
                    marketQuote.SellPrice1 = sell1.Price;
                    marketQuote.SellQuantity1 = sell1.Quantity;
                    marketQuote.SellOrders1 = (int)sell1.Orders;
                }

                if (quoteData.Depth?.Sell != null && quoteData.Depth.Sell.Count > 1)
                {
                    var sell2 = quoteData.Depth.Sell[1];
                    marketQuote.SellPrice2 = sell2.Price;
                    marketQuote.SellQuantity2 = sell2.Quantity;
                    marketQuote.SellOrders2 = (int)sell2.Orders;
                }

                if (quoteData.Depth?.Sell != null && quoteData.Depth.Sell.Count > 2)
                {
                    var sell3 = quoteData.Depth.Sell[2];
                    marketQuote.SellPrice3 = sell3.Price;
                    marketQuote.SellQuantity3 = sell3.Quantity;
                    marketQuote.SellOrders3 = (int)sell3.Orders;
                }

                if (quoteData.Depth?.Sell != null && quoteData.Depth.Sell.Count > 3)
                {
                    var sell4 = quoteData.Depth.Sell[3];
                    marketQuote.SellPrice4 = sell4.Price;
                    marketQuote.SellQuantity4 = sell4.Quantity;
                    marketQuote.SellOrders4 = (int)sell4.Orders;
                }

                if (quoteData.Depth?.Sell != null && quoteData.Depth.Sell.Count > 4)
                {
                    var sell5 = quoteData.Depth.Sell[4];
                    marketQuote.SellPrice5 = sell5.Price;
                    marketQuote.SellQuantity5 = sell5.Quantity;
                    marketQuote.SellOrders5 = (int)sell5.Orders;
                }

                return marketQuote;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to convert quote data for {instrumentKey}");
                return null;
            }
        }

        private async Task ProcessSmartCircuitLimitsAsync()
        {
            try
            {
                _logger.LogInformation("Processing smart circuit limits...");
                
                await _smartCircuitLimitsService.ProcessSmartCircuitLimitsAsync();
                
                _logger.LogInformation("Smart circuit limits processing completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process smart circuit limits");
            }
        }

        private DateTime GetValidTimestamp(string? timestamp, string? lastTradeTime, Dictionary<string, QuoteData>? allQuotes = null)
        {
            // Try to parse the main timestamp first
            if (!string.IsNullOrEmpty(timestamp) && DateTime.TryParse(timestamp, out var parsedTimestamp))
            {
                // Check if it's a valid date (not 1970-01-01 or similar)
                if (parsedTimestamp.Year > 1970)
                {
                    // Kite API already sends timestamps in IST, no need to add hours
                    _logger.LogDebug($"Using valid timestamp: {timestamp} -> IST: {parsedTimestamp}");
                    return parsedTimestamp;
                }
            }
            
            // Try to parse LastTradeTime as fallback - this is more reliable
            if (!string.IsNullOrEmpty(lastTradeTime) && DateTime.TryParse(lastTradeTime, out var parsedLastTradeTime))
            {
                if (parsedLastTradeTime.Year > 1970)
                {
                    // Kite API already sends timestamps in IST, no need to add hours
                    _logger.LogDebug($"Using LastTradeTime fallback: {lastTradeTime} -> IST: {parsedLastTradeTime}");
                    return parsedLastTradeTime;
                }
            }
            
            // If both are invalid, try to find a valid timestamp from other instruments in the same response
            if (allQuotes != null && allQuotes.Any())
            {
                foreach (var quote in allQuotes.Values)
                {
                    // Try timestamp first
                    if (!string.IsNullOrEmpty(quote.Timestamp) && DateTime.TryParse(quote.Timestamp, out var otherTimestamp))
                    {
                        if (otherTimestamp.Year > 1970)
                        {
                            // Kite API already sends timestamps in IST, no need to add hours
                            _logger.LogWarning($"Using timestamp from other instrument: {quote.Timestamp} -> IST: {otherTimestamp}");
                            return otherTimestamp;
                        }
                    }
                    
                    // Try LastTradeTime from other instrument
                    if (!string.IsNullOrEmpty(quote.LastTradeTime) && DateTime.TryParse(quote.LastTradeTime, out var otherLastTradeTime))
                    {
                        if (otherLastTradeTime.Year > 1970)
                        {
                            // Kite API already sends timestamps in IST, no need to add hours
                            _logger.LogWarning($"Using LastTradeTime from other instrument: {quote.LastTradeTime} -> IST: {otherLastTradeTime}");
                            return otherLastTradeTime;
                        }
                    }
                }
            }
            
            // If still no valid timestamp found, use current time as last resort
            var currentTime = DateTime.Now; // Use local time (should be IST)
            _logger.LogWarning($"No valid timestamp found in API response, using current IST time: {currentTime}");
            return currentTime;
        }
    }
}
