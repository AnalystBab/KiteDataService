using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service for time-based data collection with different frequencies based on market hours
    /// </summary>
    public class TimeBasedDataCollectionService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<TimeBasedDataCollectionService> _logger;
        private readonly KiteConnectService _kiteService;
        private readonly MarketDataService _marketDataService;
        private readonly BusinessDateCalculationService _businessDateCalculationService;

        // Collection intervals
        private readonly TimeSpan _marketHoursInterval = TimeSpan.FromMinutes(1);      // 9:15 AM - 3:30 PM
        private readonly TimeSpan _afterHoursInterval = TimeSpan.FromHours(1);        // 3:30 PM - 6:00 AM
        private readonly TimeSpan _preMarketInterval = TimeSpan.FromMinutes(3);       // 6:00 AM - 9:15 AM
        private readonly int _maxRetries = 3; // Maximum retry attempts

        // Market hours (IST)
        private readonly TimeSpan _marketOpen = new TimeSpan(9, 15, 0);   // 9:15 AM
        private readonly TimeSpan _marketClose = new TimeSpan(15, 30, 0); // 3:30 PM
        private readonly TimeSpan _preMarketStart = new TimeSpan(6, 0, 0); // 6:00 AM

        public TimeBasedDataCollectionService(
            IServiceScopeFactory scopeFactory,
            ILogger<TimeBasedDataCollectionService> logger,
            KiteConnectService kiteService,
            MarketDataService marketDataService,
            BusinessDateCalculationService businessDateCalculationService)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _kiteService = kiteService;
            _marketDataService = marketDataService;
            _businessDateCalculationService = businessDateCalculationService;
        }

        /// <summary>
        /// Main data collection method that determines collection frequency based on current time
        /// </summary>
        public async Task CollectDataAsync()
        {
            var currentTime = DateTime.UtcNow.AddHours(5.5); // IST
            var timeOfDay = currentTime.TimeOfDay;

            try
            {
                if (IsPreMarketHours(timeOfDay))
                {
                    _logger.LogInformation("🌅 PRE-MARKET HOURS: Collecting LC/UC changes every 3 minutes");
                    await CollectPreMarketDataAsync();
                }
                else if (IsMarketHours(timeOfDay))
                {
                    _logger.LogInformation("📈 MARKET HOURS: Collecting full data every 1 minute");
                    await CollectMarketHoursDataAsync();
                }
                else
                {
                    _logger.LogInformation("🌙 AFTER HOURS: Collecting LC/UC changes every 1 hour");
                    await CollectAfterHoursDataAsync();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "💥 Error in time-based data collection");
            }
        }

        /// <summary>
        /// Pre-market data collection (6:00 AM - 9:15 AM IST) - Every 3 minutes
        /// Focus: LC/UC changes for ALL specified indices (NIFTY, SENSEX, BANKNIFTY)
        /// </summary>
        private async Task CollectPreMarketDataAsync()
        {
            _logger.LogInformation("🔍 Pre-market LC/UC monitoring started for NIFTY, SENSEX, BANKNIFTY");

            // Collect spot data first
            await CollectSpotDataAsync();

            var instruments = await GetTargetInstrumentsAsync();
            if (instruments.Count == 0)
            {
                _logger.LogWarning("⚠️ No target instruments found for pre-market monitoring");
                return;
            }

            var currentQuotes = await GetCurrentMarketQuotesAsync(instruments);
            var previousQuotes = await GetPreviousMarketQuotesAsync(instruments);

            int changesDetected = 0;
            int newRecordsInserted = 0;
            var recordDateTime = DateTime.UtcNow.AddHours(5.5); // IST current time when change is detected

            // Group changes by index for better logging
            var changesByIndex = new Dictionary<string, int>();

            foreach (var currentQuote in currentQuotes)
            {
                var previousQuote = previousQuotes.FirstOrDefault(p => 
                    p.TradingSymbol == currentQuote.TradingSymbol && 
                    p.BusinessDate == currentQuote.BusinessDate);

                // Check for LC/UC changes
                bool lcChanged = previousQuote == null || 
                    previousQuote.LowerCircuitLimit != currentQuote.LowerCircuitLimit;
                bool ucChanged = previousQuote == null || 
                    previousQuote.UpperCircuitLimit != currentQuote.UpperCircuitLimit;

                if (lcChanged || ucChanged)
                {
                    changesDetected++;
                    
                    // Get index name for grouping
                    var indexName = GetIndexName(currentQuote.TradingSymbol);
                    if (!changesByIndex.ContainsKey(indexName))
                        changesByIndex[indexName] = 0;
                    changesByIndex[indexName]++;

                    // Insert new record with updated sequence and record datetime
                    var businessDate = currentQuote.BusinessDate;
                    var newSequence = await GetNextSequenceNumberAsync(currentQuote.TradingSymbol, businessDate);
                    var newRecord = CreateNewMarketQuoteWithRecordTime(currentQuote, newSequence, recordDateTime);
                    
                    await InsertMarketQuoteAsync(newRecord);
                    newRecordsInserted++;

                    _logger.LogInformation($"🔄 LC/UC Change detected for {currentQuote.TradingSymbol} ({indexName}): " +
                        $"LC {previousQuote?.LowerCircuitLimit} → {currentQuote.LowerCircuitLimit}, " +
                        $"UC {previousQuote?.UpperCircuitLimit} → {currentQuote.UpperCircuitLimit} " +
                        $"[Recorded: {recordDateTime:yyyy-MM-dd HH:mm:ss} IST]");
                }
            }

            // Log summary by index
            if (changesDetected > 0)
            {
                _logger.LogInformation($"📊 Pre-market LC/UC changes by index:");
                foreach (var kvp in changesByIndex.OrderByDescending(x => x.Value))
                {
                    _logger.LogInformation($"   {kvp.Key}: {kvp.Value} changes");
                }
            }

            _logger.LogInformation($"✅ Pre-market monitoring completed: {changesDetected} changes detected, {newRecordsInserted} new records inserted");
        }

        /// <summary>
        /// Market hours data collection (9:15 AM - 3:30 PM IST) - Every 1 minute
        /// Focus: Complete data with 100% coverage (max 3 retries)
        /// </summary>
        private async Task CollectMarketHoursDataAsync()
        {
            _logger.LogInformation("📊 Market hours data collection started");

            // Collect spot data first
            await CollectSpotDataAsync();

            var instruments = await GetTargetInstrumentsAsync();
            if (instruments.Count == 0)
            {
                _logger.LogWarning("⚠️ No target instruments found for market hours collection");
                return;
            }

            var allInstruments = instruments.Select(i => i.InstrumentToken).ToHashSet();
            var collectedInstruments = new HashSet<long>();
            var missingInstruments = new HashSet<long>();
            var allMarketQuotes = new List<Models.MarketQuote>();

            // Attempt collection with max 3 retries
            for (int attempt = 1; attempt <= _maxRetries; attempt++)
            {
                _logger.LogInformation($"🔄 Collection attempt {attempt}/{_maxRetries}");

                var instrumentTokens = instruments.Select(i => i.InstrumentToken.ToString()).ToList();
                var quoteResponse = await _kiteService.GetMarketQuotesAsync(instrumentTokens);
                var quotes = quoteResponse?.Data?.Values?.ToList() ?? new List<QuoteData>();
                var quoteTokens = quotes.Select(q => q.InstrumentToken).ToHashSet();

                collectedInstruments.UnionWith(quoteTokens);
                missingInstruments = allInstruments.Except(collectedInstruments).ToHashSet();

                // Convert quotes to MarketQuote objects for this attempt
                var marketQuotes = await GetCurrentMarketQuotesAsync(instruments);
                allMarketQuotes = marketQuotes; // Use the latest quotes

                if (missingInstruments.Count == 0)
                {
                    _logger.LogInformation($"✅ 100% coverage achieved on attempt {attempt}");
                    break;
                }

                _logger.LogWarning($"⚠️ Missing {missingInstruments.Count} instruments on attempt {attempt}");
                
                if (attempt < _maxRetries)
                {
                    await Task.Delay(5000); // Wait 5 seconds before retry
                }
            }

            // Save all collected market quotes to database
            if (allMarketQuotes.Any())
            {
                _logger.LogInformation($"💾 Saving {allMarketQuotes.Count} market quotes to database...");
                await _marketDataService.SaveMarketQuotesAsync(allMarketQuotes);
                _logger.LogInformation($"✅ Market quotes saved successfully");
            }

            // Log final results
            if (missingInstruments.Count == 0)
            {
                _logger.LogInformation($"✅ Market hours collection successful: {collectedInstruments.Count} instruments collected and saved");
            }
            else
            {
                _logger.LogError($"❌ Market hours collection incomplete: {missingInstruments.Count} instruments missing after {_maxRetries} attempts");
                
                // Log missing instruments for debugging
                var missingSymbols = instruments.Where(i => missingInstruments.Contains(i.InstrumentToken))
                    .Select(i => i.TradingSymbol).Take(10); // Log first 10 missing
                _logger.LogWarning($"Missing instruments: {string.Join(", ", missingSymbols)}");
            }
        }

        /// <summary>
        /// After hours data collection (3:30 PM - 6:00 AM next day IST) - Every 1 hour
        /// Focus: LC/UC changes detection ONLY (no spot data collection after market close)
        /// Business Day concept: 9:15 AM Day 1 → 9:15 AM Day 2
        /// </summary>
        private async Task CollectAfterHoursDataAsync()
        {
            _logger.LogInformation("🌙 After hours LC/UC monitoring started - Checking for changes only");
            
            try
            {
                // Get target instruments for LC/UC monitoring
                var instruments = await GetTargetInstrumentsAsync();
                
                if (!instruments.Any())
                {
                    _logger.LogWarning("No target instruments found for after-hours monitoring");
                    return;
                }

                // Get current market quotes for LC/UC comparison
                var currentQuotesResponse = await _kiteService.GetMarketQuotesAsync(instruments.Select(i => i.InstrumentToken.ToString()).ToList());
                
                if (currentQuotesResponse?.Data?.Any() != true)
                {
                    _logger.LogWarning("No market quotes received for after-hours LC/UC monitoring");
                    return;
                }

                // Convert to MarketQuote list
                var currentQuotes = new List<MarketQuote>();
                foreach (var kvp in currentQuotesResponse.Data)
                {
                    var instrument = instruments.FirstOrDefault(i => i.InstrumentToken.ToString() == kvp.Key);
                    if (instrument != null)
                    {
                        var quote = new MarketQuote
                        {
                            InstrumentToken = instrument.InstrumentToken,
                            TradingSymbol = instrument.TradingSymbol,
                            Strike = instrument.Strike,
                            OptionType = instrument.InstrumentType,
                            ExpiryDate = instrument.Expiry ?? DateTime.MinValue,
                            OpenPrice = kvp.Value.OHLC?.Open ?? 0,
                            HighPrice = kvp.Value.OHLC?.High ?? 0,
                            LowPrice = kvp.Value.OHLC?.Low ?? 0,
                            ClosePrice = kvp.Value.OHLC?.Close ?? 0,
                            LastPrice = kvp.Value.LastPrice,
                            LowerCircuitLimit = kvp.Value.LowerCircuitLimit,
                            UpperCircuitLimit = kvp.Value.UpperCircuitLimit,
                            RecordDateTime = DateTime.UtcNow.AddHours(5.5)
                        };
                        currentQuotes.Add(quote);
                    }
                }

                // Calculate business date for after-hours (should be previous trading day until 9:15 AM)
                var businessDate = await _businessDateCalculationService.CalculateBusinessDateAsync();
                
                // Check for LC/UC changes and store only if changes detected
                var changesDetected = await DetectAndStoreLCUCChangesAsync(currentQuotes, businessDate);
                
                if (changesDetected)
                {
                    _logger.LogInformation("✅ LC/UC changes detected and stored during after-hours");
                }
                else
                {
                    _logger.LogDebug("No LC/UC changes detected during after-hours monitoring");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in after-hours LC/UC monitoring");
            }
        }

        /// <summary>
        /// Get target instruments for the specified indices
        /// </summary>
        private async Task<List<Models.Instrument>> GetTargetInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<Data.MarketDataContext>();

                var targetIndices = new[] { "NIFTY", "SENSEX", "BANKNIFTY" };
                
                var instruments = await context.Instruments
                    .Where(i => targetIndices.Any(index => i.TradingSymbol.Contains(index)) &&
                               (i.InstrumentType == "CE" || i.InstrumentType == "PE"))
                    .ToListAsync();

                _logger.LogInformation($"📋 Found {instruments.Count} target instruments for data collection");
                return instruments;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "💥 Error getting target instruments");
                return new List<Models.Instrument>();
            }
        }

        /// <summary>
        /// Get current market quotes from Kite API
        /// </summary>
        private async Task<List<Models.MarketQuote>> GetCurrentMarketQuotesAsync(List<Models.Instrument> instruments)
        {
            try
            {
                // CRITICAL: Calculate BusinessDate ONCE for all quotes using BusinessDateCalculationService
                var calculatedBusinessDate = await _businessDateCalculationService.CalculateBusinessDateAsync();
                var businessDate = calculatedBusinessDate ?? DateTime.UtcNow.AddHours(5.5).Date; // Fallback if calculation fails
                
                _logger.LogInformation($"🗓️  BusinessDate for this collection: {businessDate:yyyy-MM-dd}");
                
                var instrumentTokens = instruments.Select(i => i.InstrumentToken.ToString()).ToList();
                var quoteResponse = await _kiteService.GetMarketQuotesAsync(instrumentTokens);
                var kiteQuotes = quoteResponse?.Data?.Values?.ToList() ?? new List<QuoteData>();
                
                // Convert KiteQuoteData to MarketQuote
                var marketQuotes = new List<Models.MarketQuote>();
                foreach (var kiteQuote in kiteQuotes)
                {
                    var instrument = instruments.FirstOrDefault(i => i.InstrumentToken == kiteQuote.InstrumentToken);
                    if (instrument != null)
                    {
                        var marketQuote = new Models.MarketQuote
                        {
                            TradingSymbol = instrument.TradingSymbol,
                            InstrumentToken = kiteQuote.InstrumentToken, // CRITICAL: Keep for API integration
                            Strike = instrument.Strike,
                            OptionType = instrument.InstrumentType,
                            ExpiryDate = instrument.Expiry ?? DateTime.MinValue,
                            OpenPrice = kiteQuote.OHLC?.Open ?? 0,
                            HighPrice = kiteQuote.OHLC?.High ?? 0,
                            LowPrice = kiteQuote.OHLC?.Low ?? 0,
                            ClosePrice = kiteQuote.OHLC?.Close ?? 0,
                            LastPrice = kiteQuote.LastPrice,
                            LowerCircuitLimit = kiteQuote.LowerCircuitLimit,
                            UpperCircuitLimit = kiteQuote.UpperCircuitLimit,
                            LastTradeTime = DateTime.TryParse(kiteQuote.LastTradeTime, out var ltt) ? ltt : DateTime.MinValue,
                            RecordDateTime = DateTime.UtcNow.AddHours(5.5), // Current IST time
                            BusinessDate = businessDate, // ✅ FIXED: Use calculated BusinessDate
                            InsertionSequence = 1
                        };
                        marketQuotes.Add(marketQuote);
                    }
                }
                
                _logger.LogInformation($"📊 Retrieved {marketQuotes.Count} current market quotes with BusinessDate: {businessDate:yyyy-MM-dd}");
                return marketQuotes;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "💥 Error getting current market quotes");
                return new List<Models.MarketQuote>();
            }
        }

        /// <summary>
        /// Get previous market quotes from database for comparison
        /// </summary>
        private async Task<List<Models.MarketQuote>> GetPreviousMarketQuotesAsync(List<Models.Instrument> instruments)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<Data.MarketDataContext>();

                var symbols = instruments.Select(i => i.TradingSymbol).ToList();
                var today = DateTime.UtcNow.AddHours(5.5).Date;

                var previousQuotes = await context.MarketQuotes
                    .Where(q => symbols.Contains(q.TradingSymbol) && 
                               q.BusinessDate == today)
                    .GroupBy(q => q.TradingSymbol)
                    .Select(g => g.OrderByDescending(x => x.InsertionSequence).First())
                    .ToListAsync();

                _logger.LogInformation($"📊 Retrieved {previousQuotes.Count} previous market quotes for comparison");
                return previousQuotes;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "💥 Error getting previous market quotes");
                return new List<Models.MarketQuote>();
            }
        }

        /// <summary>
        /// Get next sequence number for a trading symbol and business date
        /// </summary>
        private async Task<int> GetNextSequenceNumberAsync(string tradingSymbol, DateTime businessDate)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<Data.MarketDataContext>();

                var maxSequence = await context.MarketQuotes
                    .Where(q => q.TradingSymbol == tradingSymbol && q.BusinessDate == businessDate)
                    .MaxAsync(q => (int?)q.InsertionSequence) ?? 0;

                return maxSequence + 1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"💥 Error getting next sequence number for {tradingSymbol}");
                return 1;
            }
        }

        /// <summary>
        /// Create new market quote record with updated sequence
        /// </summary>
        private Models.MarketQuote CreateNewMarketQuote(Models.MarketQuote source, int newSequence)
        {
            return new Models.MarketQuote
            {
                TradingSymbol = source.TradingSymbol,
                Strike = source.Strike,
                OptionType = source.OptionType,
                ExpiryDate = source.ExpiryDate,
                OpenPrice = source.OpenPrice,
                HighPrice = source.HighPrice,
                LowPrice = source.LowPrice,
                ClosePrice = source.ClosePrice,
                LastPrice = source.LastPrice,
                LowerCircuitLimit = source.LowerCircuitLimit,
                UpperCircuitLimit = source.UpperCircuitLimit,
                LastTradeTime = source.LastTradeTime,
                InsertionSequence = newSequence,
                BusinessDate = source.BusinessDate
            };
        }

        /// <summary>
        /// Create new market quote record with updated sequence and record datetime
        /// </summary>
        private Models.MarketQuote CreateNewMarketQuoteWithRecordTime(Models.MarketQuote source, int newSequence, DateTime recordDateTime)
        {
            return new Models.MarketQuote
            {
                TradingSymbol = source.TradingSymbol,
                InstrumentToken = source.InstrumentToken, // CRITICAL: Keep for API integration
                Strike = source.Strike,
                OptionType = source.OptionType,
                ExpiryDate = source.ExpiryDate,
                OpenPrice = source.OpenPrice,
                HighPrice = source.HighPrice,
                LowPrice = source.LowPrice,
                ClosePrice = source.ClosePrice,
                LastPrice = source.LastPrice,
                LowerCircuitLimit = source.LowerCircuitLimit,
                UpperCircuitLimit = source.UpperCircuitLimit,
                LastTradeTime = source.LastTradeTime,
                RecordDateTime = recordDateTime, // Record when LC/UC change was detected
                InsertionSequence = newSequence,
                BusinessDate = source.BusinessDate
            };
        }

        /// <summary>
        /// Get index name from trading symbol
        /// </summary>
        private string GetIndexName(string tradingSymbol)
        {
            if (tradingSymbol.Contains("SENSEX"))
                return "SENSEX";
            else if (tradingSymbol.Contains("BANKNIFTY"))
                return "BANKNIFTY";
            else if (tradingSymbol.Contains("NIFTY"))
                return "NIFTY";
            else
                return "UNKNOWN";
        }

        /// <summary>
        /// Insert new market quote record
        /// </summary>
        private async Task InsertMarketQuoteAsync(Models.MarketQuote quote)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<Data.MarketDataContext>();

                context.MarketQuotes.Add(quote);
                await context.SaveChangesAsync();

                _logger.LogDebug($"✅ Inserted new market quote: {quote.TradingSymbol} (Seq: {quote.InsertionSequence})");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"💥 Error inserting market quote for {quote.TradingSymbol}");
            }
        }

        /// <summary>
        /// Check if current time is pre-market hours (6:00 AM - 9:15 AM IST)
        /// </summary>
        private bool IsPreMarketHours(TimeSpan timeOfDay)
        {
            return timeOfDay >= _preMarketStart && timeOfDay < _marketOpen;
        }

        /// <summary>
        /// Check if current time is market hours (9:15 AM - 3:30 PM IST)
        /// </summary>
        private bool IsMarketHours(TimeSpan timeOfDay)
        {
            return timeOfDay >= _marketOpen && timeOfDay <= _marketClose;
        }

        /// <summary>
        /// Get next collection interval based on current time
        /// </summary>
        public TimeSpan GetNextCollectionInterval()
        {
            var currentTime = DateTime.UtcNow.AddHours(5.5); // IST
            var timeOfDay = currentTime.TimeOfDay;

            if (IsPreMarketHours(timeOfDay))
                return _preMarketInterval;
            else if (IsMarketHours(timeOfDay))
                return _marketHoursInterval;
            else
                return _afterHoursInterval;
        }

        /// <summary>
        /// Collect spot data for NIFTY, SENSEX, BANKNIFTY indices
        /// </summary>
        private async Task CollectSpotDataAsync()
        {
            try
            {
                _logger.LogInformation("📊 Collecting spot data for indices...");

                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<Data.MarketDataContext>();

                // Get actual INDEX instruments (NIFTY, SENSEX, BANKNIFTY) from database
                var indexNames = new[] { "NIFTY", "SENSEX", "BANKNIFTY" };
                var spotInstruments = await context.Instruments
                    .Where(i => i.InstrumentType == "INDEX" && indexNames.Contains(i.TradingSymbol))
                    .ToListAsync();

                if (!spotInstruments.Any())
                {
                    _logger.LogWarning("⚠️ No INDEX instruments found in database");
                    return;
                }

                var spotTokens = spotInstruments.Select(i => i.InstrumentToken.ToString()).ToList();
                _logger.LogInformation($"🔍 Found {spotInstruments.Count} INDEX instruments:");
                foreach (var inst in spotInstruments)
                {
                    _logger.LogInformation($"  📊 {inst.TradingSymbol} - Token: {inst.InstrumentToken} - Exchange: {inst.Exchange}");
                }
                _logger.LogInformation($"📡 Requesting spot data from Kite API for tokens: {string.Join(", ", spotTokens)}");
                
                var quoteResponse = await _kiteService.GetMarketQuotesAsync(spotTokens);
                var kiteQuotes = quoteResponse?.Data?.Values?.ToList() ?? new List<QuoteData>();
                
                _logger.LogInformation($"📥 Received {kiteQuotes.Count} quotes from Kite API");
                foreach (var quote in kiteQuotes)
                {
                    _logger.LogInformation($"  💰 Token: {quote.InstrumentToken} - LastPrice: {quote.LastPrice}");
                }
                
                if (kiteQuotes.Count == 0)
                {
                    _logger.LogWarning("⚠️ No spot data received from Kite API");
                    return;
                }

                var recordDateTime = DateTime.UtcNow.AddHours(5.5); // Current IST time

                foreach (var kiteQuote in kiteQuotes)
                {
                    // Map instrument token to index name using database lookup
                    var indexName = await GetIndexNameFromTokenAsync(kiteQuote.InstrumentToken, context);
                    
                    // Check if we already have recent spot data for this index
                    var existingSpotData = await context.IntradaySpotData
                        .Where(s => s.IndexName == indexName && 
                                   s.QuoteTimestamp >= recordDateTime.AddMinutes(-5)) // Last 5 minutes
                        .FirstOrDefaultAsync();

                    if (existingSpotData != null)
                    {
                        _logger.LogDebug($"Spot data for {indexName} already exists within last 5 minutes, skipping");
                        continue;
                    }

                    // Create new intraday spot data record
                    var spotData = new IntradaySpotData
                    {
                        IndexName = indexName,
                        TradingDate = recordDateTime.Date,
                        QuoteTimestamp = recordDateTime,
                        OpenPrice = kiteQuote.OHLC?.Open ?? 0,
                        HighPrice = kiteQuote.OHLC?.High ?? 0,
                        LowPrice = kiteQuote.OHLC?.Low ?? 0,
                        ClosePrice = kiteQuote.OHLC?.Close ?? 0,
                        LastPrice = kiteQuote.LastPrice,
                        Volume = 0, // Not available from Kite quote
                        Change = 0, // Calculate if needed
                        ChangePercent = 0, // Calculate if needed
                        DataSource = "Kite API",
                        IsMarketOpen = IsMarketHours(recordDateTime.TimeOfDay),
                        CreatedDate = recordDateTime,
                        LastUpdated = recordDateTime
                    };

                    context.IntradaySpotData.Add(spotData);
                    _logger.LogInformation($"✅ SAVING spot data for {indexName} (Token: {kiteQuote.InstrumentToken}): LTP={kiteQuote.LastPrice}, O={kiteQuote.OHLC?.Open}, H={kiteQuote.OHLC?.High}, L={kiteQuote.OHLC?.Low}, C={kiteQuote.OHLC?.Close}");
                }

                await context.SaveChangesAsync();
                _logger.LogInformation($"✅ Spot data collection completed: {kiteQuotes.Count} indices updated");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "💥 Error collecting spot data");
            }
        }

        /// <summary>
        /// Map instrument token to index name using database lookup
        /// </summary>
        private async Task<string> GetIndexNameFromTokenAsync(long instrumentToken, Data.MarketDataContext context)
        {
            try
            {
                var instrument = await context.Instruments
                    .Where(i => i.InstrumentToken == instrumentToken && i.InstrumentType == "INDEX")
                    .FirstOrDefaultAsync();
                
                if (instrument != null)
                {
                    _logger.LogInformation($"🔍 Mapped token {instrumentToken} to index: {instrument.TradingSymbol}");
                    return instrument.TradingSymbol;
                }
                
                _logger.LogWarning($"⚠️ No INDEX instrument found for token: {instrumentToken}");
                return "UNKNOWN";
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"💥 Error mapping token {instrumentToken} to index name");
                return "UNKNOWN";
            }
        }

        /// <summary>
        /// Detect and store LC/UC changes during after-hours monitoring
        /// Only stores data if LC/UC values actually changed
        /// </summary>
        private async Task<bool> DetectAndStoreLCUCChangesAsync(List<Models.MarketQuote> currentQuotes, DateTime? businessDate)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<Data.MarketDataContext>();

                var changesDetected = false;
                var currentTime = DateTime.UtcNow.AddHours(5.5); // IST

                foreach (var quote in currentQuotes)
                {
                    // Get the last stored LC/UC values for this instrument
                    var lastQuote = await context.MarketQuotes
                        .Where(q => q.InstrumentToken == quote.InstrumentToken && 
                                   q.BusinessDate == businessDate)
                        .OrderByDescending(q => q.RecordDateTime)
                        .FirstOrDefaultAsync();

                    if (lastQuote != null)
                    {
                        // Check if LC/UC values changed
                        var lcChanged = lastQuote.LowerCircuitLimit != quote.LowerCircuitLimit;
                        var ucChanged = lastQuote.UpperCircuitLimit != quote.UpperCircuitLimit;

                        if (lcChanged || ucChanged)
                        {
                            // LC/UC changed - store the new data
                            var newQuote = new Models.MarketQuote
                            {
                                InstrumentToken = quote.InstrumentToken,
                                TradingSymbol = quote.TradingSymbol,
                                BusinessDate = businessDate ?? currentTime.Date,
                                RecordDateTime = currentTime,
                                OpenPrice = quote.OpenPrice,
                                HighPrice = quote.HighPrice,
                                LowPrice = quote.LowPrice,
                                ClosePrice = quote.ClosePrice,
                            LastPrice = quote.LastPrice,
                            LowerCircuitLimit = quote.LowerCircuitLimit,
                            UpperCircuitLimit = quote.UpperCircuitLimit
                        };

                        context.MarketQuotes.Add(newQuote);
                        changesDetected = true;

                        _logger.LogInformation($"🔄 LC/UC CHANGE DETECTED for {quote.TradingSymbol}: LC {lastQuote.LowerCircuitLimit}→{quote.LowerCircuitLimit}, UC {lastQuote.UpperCircuitLimit}→{quote.UpperCircuitLimit}");
                        }
                        else
                        {
                            _logger.LogDebug($"No LC/UC changes for {quote.TradingSymbol} - skipping");
                        }
                    }
                    else
                    {
                        // No previous data found - this might be a new instrument, store it
                        var newQuote = new Models.MarketQuote
                        {
                            InstrumentToken = quote.InstrumentToken,
                            TradingSymbol = quote.TradingSymbol,
                            BusinessDate = businessDate ?? currentTime.Date,
                            RecordDateTime = currentTime,
                            OpenPrice = quote.OpenPrice,
                            HighPrice = quote.HighPrice,
                            LowPrice = quote.LowPrice,
                            ClosePrice = quote.ClosePrice,
                            LastPrice = quote.LastPrice,
                            LowerCircuitLimit = quote.LowerCircuitLimit,
                            UpperCircuitLimit = quote.UpperCircuitLimit
                        };

                        context.MarketQuotes.Add(newQuote);
                        changesDetected = true;

                        _logger.LogInformation($"🆕 NEW INSTRUMENT detected during after-hours: {quote.TradingSymbol} - LC={quote.LowerCircuitLimit}, UC={quote.UpperCircuitLimit}");
                    }
                }

                if (changesDetected)
                {
                    await context.SaveChangesAsync();
                    _logger.LogInformation($"✅ After-hours LC/UC changes saved to database");
                }

                return changesDetected;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error detecting and storing LC/UC changes during after-hours");
                return false;
            }
        }
    }
}
