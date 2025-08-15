using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Models;
using KiteMarketDataService.Worker.Data;

namespace KiteMarketDataService.Worker.Services
{
    public class CircuitLimitTestService
    {
        private readonly KiteConnectService _kiteService;
        private readonly MarketDataService _marketDataService;
        private readonly ILogger<CircuitLimitTestService> _logger;

        public CircuitLimitTestService(
            KiteConnectService kiteService,
            MarketDataService marketDataService,
            ILogger<CircuitLimitTestService> logger)
        {
            _kiteService = kiteService;
            _marketDataService = marketDataService;
            _logger = logger;
        }

        /// <summary>
        /// Test 1: Request quotes for ALL instruments to see what data is returned
        /// </summary>
        public async Task TestAllInstrumentsQuoteRequestAsync()
        {
            try
            {
                _logger.LogInformation("=== TEST 1: Requesting quotes for ALL instruments ===");
                
                // Get all instruments from database
                var allInstruments = await _marketDataService.GetAllInstrumentsAsync();
                _logger.LogInformation($"Total instruments in database: {allInstruments.Count}");
                
                // Get instrument tokens
                var allInstrumentTokens = allInstruments.Select(i => i.InstrumentToken.ToString()).ToList();
                _logger.LogInformation($"Requesting quotes for {allInstrumentTokens.Count} instruments");
                
                // Request quotes for all instruments
                var quoteResponse = await _kiteService.GetMarketQuotesAsync(allInstrumentTokens);
                
                if (quoteResponse?.Data == null)
                {
                    _logger.LogWarning("No quote response received");
                    return;
                }
                
                var returnedInstruments = quoteResponse.Data.Keys.ToList();
                var nonReturnedInstruments = allInstrumentTokens.Except(returnedInstruments).ToList();
                
                _logger.LogInformation($"Instruments with quotes: {returnedInstruments.Count}");
                _logger.LogInformation($"Instruments without quotes: {nonReturnedInstruments.Count}");
                
                // Analyze circuit limits in returned data
                var instrumentsWithCircuitLimits = new List<string>();
                var instrumentsWithoutCircuitLimits = new List<string>();
                
                foreach (var quote in quoteResponse.Data)
                {
                    var quoteData = quote.Value;
                    if (quoteData.LowerCircuitLimit > 0 || quoteData.UpperCircuitLimit > 0)
                    {
                        instrumentsWithCircuitLimits.Add(quote.Key);
                        _logger.LogInformation($"Instrument {quote.Key}: LCL={quoteData.LowerCircuitLimit}, UCL={quoteData.UpperCircuitLimit}");
                    }
                    else
                    {
                        instrumentsWithoutCircuitLimits.Add(quote.Key);
                    }
                }
                
                _logger.LogInformation($"Instruments with circuit limits: {instrumentsWithCircuitLimits.Count}");
                _logger.LogInformation($"Instruments without circuit limits: {instrumentsWithoutCircuitLimits.Count}");
                
                // Test individual requests for non-returned instruments
                await TestIndividualRequestsForNonReturnedAsync(nonReturnedInstruments.Take(10).ToList());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in TestAllInstrumentsQuoteRequestAsync");
            }
        }

        /// <summary>
        /// Test 2: Request quotes for individual instruments that weren't returned in bulk request
        /// </summary>
        public async Task TestIndividualRequestsForNonReturnedAsync(List<string> instrumentTokens)
        {
            try
            {
                _logger.LogInformation("=== TEST 2: Individual requests for non-returned instruments ===");
                
                foreach (var instrumentToken in instrumentTokens)
                {
                    try
                    {
                        _logger.LogInformation($"Testing individual request for instrument: {instrumentToken}");
                        
                        var individualQuote = await _kiteService.GetMarketQuotesAsync(new List<string> { instrumentToken });
                        
                        if (individualQuote?.Data?.Any() == true)
                        {
                            var quote = individualQuote.Data.First();
                            var quoteData = quote.Value;
                            
                            _logger.LogInformation($"✅ Individual request SUCCESS for {instrumentToken}:");
                            _logger.LogInformation($"   LCL: {quoteData.LowerCircuitLimit}");
                            _logger.LogInformation($"   UCL: {quoteData.UpperCircuitLimit}");
                            _logger.LogInformation($"   Last Price: {quoteData.LastPrice}");
                            _logger.LogInformation($"   Volume: {quoteData.Volume}");
                        }
                        else
                        {
                            _logger.LogInformation($"❌ Individual request FAILED for {instrumentToken}: No data returned");
                        }
                        
                        // Rate limiting
                        await Task.Delay(500);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning($"Error testing individual request for {instrumentToken}: {ex.Message}");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in TestIndividualRequestsForNonReturnedAsync");
            }
        }

        /// <summary>
        /// Test 3: Compare market hours vs non-market hours behavior
        /// </summary>
        public async Task TestMarketHoursBehaviorAsync()
        {
            try
            {
                _logger.LogInformation("=== TEST 3: Market hours behavior comparison ===");
                
                var currentTime = DateTime.Now;
                var isMarketHours = IsMarketHours(currentTime);
                
                _logger.LogInformation($"Current time: {currentTime}");
                _logger.LogInformation($"Is market hours: {isMarketHours}");
                
                // Get sample instruments
                var sampleInstruments = await _marketDataService.GetSampleInstrumentsAsync(20);
                var sampleTokens = sampleInstruments.Select(i => i.InstrumentToken.ToString()).ToList();
                
                // Request quotes
                var quoteResponse = await _kiteService.GetMarketQuotesAsync(sampleTokens);
                
                if (quoteResponse?.Data != null)
                {
                    _logger.LogInformation($"Market hours test: {quoteResponse.Data.Count} instruments returned");
                    
                    foreach (var quote in quoteResponse.Data.Take(5))
                    {
                        var quoteData = quote.Value;
                        _logger.LogInformation($"Sample instrument {quote.Key}: LCL={quoteData.LowerCircuitLimit}, UCL={quoteData.UpperCircuitLimit}, Volume={quoteData.Volume}");
                    }
                }
                else
                {
                    _logger.LogInformation("Market hours test: No data returned");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in TestMarketHoursBehaviorAsync");
            }
        }

        /// <summary>
        /// Test 4: Test specific instrument types (deep ITM, ATM, OTM)
        /// </summary>
        public async Task TestSpecificInstrumentTypesAsync()
        {
            try
            {
                _logger.LogInformation("=== TEST 4: Testing specific instrument types ===");
                
                // Get instruments by type
                var deepITM = await _marketDataService.GetInstrumentsByTypeAsync("DEEP_ITM", 5);
                var atm = await _marketDataService.GetInstrumentsByTypeAsync("ATM", 5);
                var deepOTM = await _marketDataService.GetInstrumentsByTypeAsync("DEEP_OTM", 5);
                
                var testGroups = new[]
                {
                    new { Name = "Deep ITM", Instruments = deepITM },
                    new { Name = "ATM", Instruments = atm },
                    new { Name = "Deep OTM", Instruments = deepOTM }
                };
                
                foreach (var group in testGroups)
                {
                    _logger.LogInformation($"Testing {group.Name} instruments:");
                    
                    var tokens = group.Instruments.Select(i => i.InstrumentToken.ToString()).ToList();
                    var quotes = await _kiteService.GetMarketQuotesAsync(tokens);
                    
                    if (quotes?.Data != null)
                    {
                        _logger.LogInformation($"  {group.Name}: {quotes.Data.Count} instruments returned");
                        
                        foreach (var quote in quotes.Data)
                        {
                            var quoteData = quote.Value;
                            _logger.LogInformation($"    {quote.Key}: LCL={quoteData.LowerCircuitLimit}, UCL={quoteData.UpperCircuitLimit}, Volume={quoteData.Volume}");
                        }
                    }
                    else
                    {
                        _logger.LogInformation($"  {group.Name}: No data returned");
                    }
                    
                    await Task.Delay(1000); // Rate limiting
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in TestSpecificInstrumentTypesAsync");
            }
        }

        /// <summary>
        /// Test 5: Test circuit limit changes over time
        /// </summary>
        public async Task TestCircuitLimitChangesAsync()
        {
            try
            {
                _logger.LogInformation("=== TEST 5: Testing circuit limit changes over time ===");
                
                // Get instruments that have recent quotes
                var recentInstruments = await _marketDataService.GetInstrumentsWithRecentQuotesAsync(10);
                
                foreach (var instrument in recentInstruments)
                {
                    _logger.LogInformation($"Testing circuit limit changes for {instrument.TradingSymbol}:");
                    
                    // Get current circuit limits
                    var currentQuote = await _kiteService.GetMarketQuotesAsync(new List<string> { instrument.InstrumentToken.ToString() });
                    
                    if (currentQuote?.Data?.Any() == true)
                    {
                        var currentData = currentQuote.Data.First().Value;
                        _logger.LogInformation($"  Current: LCL={currentData.LowerCircuitLimit}, UCL={currentData.UpperCircuitLimit}");
                        
                        // Get historical circuit limits from database
                        var historicalLimits = await _marketDataService.GetHistoricalCircuitLimitsAsync(instrument.InstrumentToken, 5);
                        
                        foreach (var historical in historicalLimits)
                        {
                            _logger.LogInformation($"  Historical ({historical.TradeDate}): LCL={historical.LowerCircuitLimit}, UCL={historical.UpperCircuitLimit}");
                        }
                    }
                    
                    await Task.Delay(500);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in TestCircuitLimitChangesAsync");
            }
        }

        /// <summary>
        /// Run all tests
        /// </summary>
        public async Task RunAllTestsAsync()
        {
            _logger.LogInformation("Starting Circuit Limit Tests...");
            
            await TestAllInstrumentsQuoteRequestAsync();
            await Task.Delay(2000);
            
            await TestMarketHoursBehaviorAsync();
            await Task.Delay(2000);
            
            await TestSpecificInstrumentTypesAsync();
            await Task.Delay(2000);
            
            await TestCircuitLimitChangesAsync();
            
            _logger.LogInformation("Circuit Limit Tests completed!");
        }

        /// <summary>
        /// Check if current time is during market hours (9:15 AM to 3:30 PM IST, Monday to Friday)
        /// </summary>
        private bool IsMarketHours(DateTime time)
        {
            // Convert to IST (UTC + 5:30)
            var istTime = time.AddHours(5.5);
            
            // Check if it's a weekday
            if (istTime.DayOfWeek == DayOfWeek.Saturday || istTime.DayOfWeek == DayOfWeek.Sunday)
                return false;
            
            // Check if it's between 9:15 AM and 3:30 PM IST
            var marketStart = new TimeSpan(9, 15, 0);
            var marketEnd = new TimeSpan(15, 30, 0);
            var currentTime = istTime.TimeOfDay;
            
            return currentTime >= marketStart && currentTime <= marketEnd;
        }
    }
} 