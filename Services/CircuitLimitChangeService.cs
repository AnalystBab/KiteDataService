using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    public class CircuitLimitChangeService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<CircuitLimitChangeService> _logger;
        private readonly HistoricalDataService _historicalDataService;
        private readonly ExcelExportService _excelExportService;

        public CircuitLimitChangeService(
            IServiceScopeFactory scopeFactory,
            ILogger<CircuitLimitChangeService> logger,
            HistoricalDataService historicalDataService,
            ExcelExportService excelExportService)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _historicalDataService = historicalDataService;
            _excelExportService = excelExportService;
        }

        public async Task ProcessCircuitLimitChangesAsync(List<MarketQuote> currentQuotes)
        {
            try
            {
                _logger.LogInformation($"=== CIRCUIT LIMIT CHANGE SERVICE STARTED ===");
                _logger.LogInformation($"Received {currentQuotes.Count} quotes for processing");
                
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();
                var trackingContext = scope.ServiceProvider.GetRequiredService<CircuitLimitTrackingContext>();

                // var changes = new List<CircuitLimitChangeHistory>(); // DISABLED - table removed
                var detailedChanges = new List<CircuitLimitChangeDetails>();

                // Get spot/index data for all indices
                _logger.LogInformation("Fetching spot data for circuit limit changes...");
                var spotData = await GetSpotDataAsync(context);
                _logger.LogInformation($"Found spot data for {spotData.Count} indices: {string.Join(", ", spotData.Keys)}");

                foreach (var quote in currentQuotes)
                {
                    _logger.LogDebug($"Processing quote: {quote.TradingSymbol} (Token: {quote.InstrumentToken})");
                    _logger.LogDebug($"  LC: {quote.LowerCircuitLimit}, UC: {quote.UpperCircuitLimit}, LTP: {quote.LastPrice}");
                    
                    // Get the last recorded circuit limit change for this instrument from CircuitLimitTracking database
                    var lastChange = await trackingContext.CircuitLimitChangeDetails
                        .Where(c => c.InstrumentToken == quote.InstrumentToken)
                        .OrderByDescending(c => c.ChangeTimestamp)
                        .FirstOrDefaultAsync();

                    _logger.LogDebug($"  Last change found: {(lastChange != null ? "YES" : "NO")}");

                    // Check if LC or UC has changed - only record if we have valid circuit limit values
                    bool hasChanged = false;
                    bool hasValidCircuitLimits = quote.LowerCircuitLimit > 0 || quote.UpperCircuitLimit > 0;
                    
                    _logger.LogDebug($"  Has valid circuit limits: {hasValidCircuitLimits} (LC > 0: {quote.LowerCircuitLimit > 0}, UC > 0: {quote.UpperCircuitLimit > 0})");
                    
                    if (!hasValidCircuitLimits)
                    {
                        _logger.LogDebug($"Skipping {quote.TradingSymbol} - no valid circuit limits (LC: {quote.LowerCircuitLimit}, UC: {quote.UpperCircuitLimit})");
                        continue; // Skip this quote
                    }
                    
                    if (lastChange == null)
                    {
                        // First time recording for this instrument
                        hasChanged = true;
                        _logger.LogInformation($"First time recording circuit limits for {quote.TradingSymbol} (LC: {quote.LowerCircuitLimit}, UC: {quote.UpperCircuitLimit})");
                    }
                    else if (lastChange.NewLowerCircuit != quote.LowerCircuitLimit || lastChange.NewUpperCircuit != quote.UpperCircuitLimit)
                    {
                        // Circuit limits have changed
                        hasChanged = true;
                        _logger.LogInformation($"Circuit limits changed for {quote.TradingSymbol}: LC {lastChange.NewLowerCircuit}->{quote.LowerCircuitLimit}, UC {lastChange.NewUpperCircuit}->{quote.UpperCircuitLimit}");
                    }

                    if (hasChanged)
                    {
                        var index = GetIndexFromSymbol(quote.TradingSymbol);
                        var spotQuote = spotData.GetValueOrDefault(index);
                        
                        // Get current IST timestamp
                        var currentISTTime = DateTime.Now; // Already in IST
                        
                        // Calculate insertion sequence for this instrument+expiry combination
                        var insertionSequence = await GetNextInsertionSequenceAsync(context, quote.InstrumentToken, quote.ExpiryDate);
                        
                        // Create record for OLD database (existing functionality)
                        // DISABLED - CircuitLimitChangeHistory creation removed

                        // Create record for NEW database (detailed tracking)
                        var detailedChange = new CircuitLimitChangeDetails
                        {
                            InstrumentToken = quote.InstrumentToken,
                            TradingSymbol = quote.TradingSymbol,
                            // Exchange removed - not needed for LC/UC monitoring
                            Segment = "NFO-OPT", // Default segment for options
                            Strike = quote.Strike,
                            OptionType = quote.OptionType,
                            ExpiryDate = quote.ExpiryDate,
                            
                            // Previous values (from last change in CircuitLimitTracking database)
                            PreviousLowerCircuit = lastChange?.NewLowerCircuit ?? 0,
                            PreviousUpperCircuit = lastChange?.NewUpperCircuit ?? 0,
                            
                            // New values (current quote values)
                            NewLowerCircuit = quote.LowerCircuitLimit,
                            NewUpperCircuit = quote.UpperCircuitLimit,
                            
                            // Calculate changes
                            LowerCircuitChange = quote.LowerCircuitLimit - (lastChange?.NewLowerCircuit ?? 0),
                            UpperCircuitChange = quote.UpperCircuitLimit - (lastChange?.NewUpperCircuit ?? 0),
                            
                            // Determine change direction using current quote vs last change
                            ChangeDirection = GetChangeDirection(lastChange, quote),
                            
                            // OHLC data at change time (always use current quote data for freshness)
                            OpenPrice = quote.OpenPrice,
                            HighPrice = quote.HighPrice,
                            LowPrice = quote.LowPrice,
                            ClosePrice = quote.ClosePrice,
                            LastPrice = quote.LastPrice,
                            
                            // Market data removed - not needed for LC/UC monitoring
                            LastTradeTime = quote.LastTradeTime,
                            
                            // Timestamps (use IST time consistently)
                            ChangeTimestamp = currentISTTime, // IST
                            QuoteTimestamp = quote.RecordDateTime,
                            BusinessDate = quote.BusinessDate,  // Copy BusinessDate from MarketQuote
                            
                            // Set insertion sequence
                            InsertionSequence = insertionSequence
                        };

                        // Log spot data population
                        if (spotQuote != null)
                        {
                            _logger.LogInformation($"Spot data populated for {index}: O={spotQuote.OpenPrice}, H={spotQuote.HighPrice}, L={spotQuote.LowPrice}, C={spotQuote.ClosePrice}, LTP={spotQuote.LastPrice}");
                        }
                        else
                        {
                            _logger.LogWarning($"Spot data not found for index {index} when recording circuit limit change for {quote.TradingSymbol}. Available indices: {string.Join(", ", spotData.Keys)}");
                        }

                        // changes.Add(change); // DISABLED
                        
                        // Validate the change record before adding
                        if (ValidateChangeRecord(detailedChange, lastChange, quote))
                        {
                            detailedChanges.Add(detailedChange);
                            _logger.LogDebug($"Validated change record for {quote.TradingSymbol}: LC {detailedChange.PreviousLowerCircuit}->{detailedChange.NewLowerCircuit}, UC {detailedChange.PreviousUpperCircuit}->{detailedChange.NewUpperCircuit}");
                        }
                        else
                        {
                            _logger.LogWarning($"Invalid change record detected for {quote.TradingSymbol} - skipping detailed record");
                        }
                    }
                }

                // DISABLED - CircuitLimitChangeHistory functionality removed
                /*
                if (changes.Any())
                {
                    _logger.LogInformation($"Saving {changes.Count} circuit limit changes to OLD database...");
                    context.CircuitLimitChangeHistory.AddRange(changes);
                    await context.SaveChangesAsync();
                    _logger.LogInformation($"Successfully recorded {changes.Count} circuit limit changes to OLD database");
                    
                    // Log first few changes for verification
                    var sampleChanges = changes.Take(3).ToList();
                */

                if (detailedChanges.Any())
                {
                    var businessDate = detailedChanges.First().BusinessDate ?? DateTime.Now.Date;
                    
                    // Export Excel file BEFORE saving LC/UC changes (to capture existing state)
                    try
                    {
                        var excelFilePathBefore = await ExportBusinessDayDataIfNeededAsync(businessDate, "BEFORE_LCUC_CHANGE");
                        if (!string.IsNullOrEmpty(excelFilePathBefore))
                        {
                            _logger.LogInformation($"✅ Excel file exported BEFORE LC/UC changes for business day {businessDate:yyyy-MM-dd}: {excelFilePathBefore}");
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to export business day data BEFORE LC/UC changes");
                    }
                    
                    _logger.LogInformation($"Saving {detailedChanges.Count} detailed circuit limit changes to NEW database...");
                    trackingContext.CircuitLimitChangeDetails.AddRange(detailedChanges);
                    await trackingContext.SaveChangesAsync();
                    _logger.LogInformation($"Successfully recorded {detailedChanges.Count} detailed circuit limit changes to NEW database");
                    
                    // Export Excel file AFTER saving LC/UC changes (to capture new state)
                    try
                    {
                        var excelFilePathAfter = await ExportBusinessDayDataIfNeededAsync(businessDate, "AFTER_LCUC_CHANGE");
                        if (!string.IsNullOrEmpty(excelFilePathAfter))
                        {
                            _logger.LogInformation($"✅ Excel file exported AFTER LC/UC changes for business day {businessDate:yyyy-MM-dd}: {excelFilePathAfter}");
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Failed to export business day data AFTER LC/UC changes");
                    }
                    
                    // Log first few detailed changes for verification
                    var sampleDetailedChanges = detailedChanges.Take(3).ToList();
                    _logger.LogInformation("Sample recorded detailed changes (NEW DB):");
                    foreach (var change in sampleDetailedChanges)
                    {
                        _logger.LogInformation($"  {change.TradingSymbol}: LC {change.PreviousLowerCircuit}->{change.NewLowerCircuit} ({change.LowerCircuitChange:+0.00;-0.00}), UC {change.PreviousUpperCircuit}->{change.NewUpperCircuit} ({change.UpperCircuitChange:+0.00;-0.00})");
                    }
                }

                if (!detailedChanges.Any())
                {
                    _logger.LogWarning("No circuit limit changes detected - this might indicate an issue");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process circuit limit changes");
            }
        }

        private string GetIndexFromSymbol(string tradingSymbol)
        {
            if (tradingSymbol.StartsWith("NIFTY"))
                return "NIFTY";
            else if (tradingSymbol.StartsWith("SENSEX"))
                return "SENSEX";
            else if (tradingSymbol.StartsWith("BANKNIFTY"))
                return "BANKNIFTY";
            else
                return "UNKNOWN";
        }

        private string GetMarketHourFlag(TimeSpan? tradeTime)
        {
            if (tradeTime == null)
                return "UNKNOWN";

            var marketStart = new TimeSpan(9, 15, 0); // 9:15 AM
            var marketEnd = new TimeSpan(15, 30, 0);   // 3:30 PM

            if (tradeTime >= marketStart && tradeTime <= marketEnd)
                return "MARKET_HOUR";
            else
                return "AFTER_MARKET";
        }

        private async Task<Dictionary<string, MarketQuote>> GetSpotDataAsync(MarketDataContext context)
        {
            var spotData = new Dictionary<string, MarketQuote>();
            
            try
            {
                // Get latest spot data from SpotData table (new approach)
                var spotQuotes = await context.SpotData
                    .Where(s => s.QuoteTimestamp >= DateTime.UtcNow.AddHours(-1)) // Last 1 hour for better coverage
                    .ToListAsync();

                // Group by index and get the latest quote for each
                var groupedQuotes = spotQuotes
                    .GroupBy(s => s.IndexName)
                    .Select(g => g.OrderByDescending(s => s.QuoteTimestamp).First())
                    .ToList();

                foreach (var spotQuote in groupedQuotes)
                {
                    var index = spotQuote.IndexName;
                    
                    // Convert SpotData to MarketQuote format for compatibility
                    var quote = new MarketQuote
                    {
                        TradingSymbol = spotQuote.IndexName,
                        OpenPrice = spotQuote.OpenPrice,
                        HighPrice = spotQuote.HighPrice,
                        LowPrice = spotQuote.LowPrice,
                        ClosePrice = spotQuote.ClosePrice,
                        LastPrice = spotQuote.LastPrice,
                        RecordDateTime = spotQuote.QuoteTimestamp
                    };
                    
                    // TEMPORARILY DISABLED: Historical data enhancement to fix service
                    // Check if spot quote has zero OHLC values and needs historical data
                    /*
                    if (quote.OpenPrice == 0 && quote.HighPrice == 0 && quote.LowPrice == 0 && quote.ClosePrice == 0)
                    {
                        _logger.LogInformation($"Spot index {index} has zero OHLC values, will try to enhance with historical data");
                        
                        // Try to get historical data for this spot index
                        var enhancedQuote = await EnhanceSpotQuoteWithHistoricalDataAsync(quote, context);
                        if (enhancedQuote != null)
                        {
                            spotData[index] = enhancedQuote;
                            _logger.LogInformation($"Enhanced spot data for {index} with historical data: O={enhancedQuote.OpenPrice}, H={enhancedQuote.HighPrice}, L={enhancedQuote.LowPrice}, C={enhancedQuote.ClosePrice}");
                        }
                        else
                        {
                            spotData[index] = quote; // Use original quote if enhancement fails
                            _logger.LogWarning($"Failed to enhance spot data for {index}, using original quote with zero values");
                        }
                    }
                    else
                    {
                        spotData[index] = quote;
                        _logger.LogInformation($"Found valid spot data for {index} ({quote.TradingSymbol}): O={quote.OpenPrice}, H={quote.HighPrice}, L={quote.LowPrice}, C={quote.ClosePrice}, LTP={quote.LastPrice}");
                    }
                    */
                    
                    // Use original quote without historical enhancement for now
                    spotData[index] = quote;
                    _logger.LogInformation($"Using spot data for {index} ({quote.TradingSymbol}): O={quote.OpenPrice}, H={quote.HighPrice}, L={quote.LowPrice}, C={quote.ClosePrice}, LTP={quote.LastPrice}");
                }

                // Log if any indices are missing
                var expectedIndices = new[] { "NIFTY", "SENSEX", "BANKNIFTY" };
                foreach (var expectedIndex in expectedIndices)
                {
                    if (!spotData.ContainsKey(expectedIndex))
                    {
                        _logger.LogWarning($"No spot data found for {expectedIndex}");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to fetch spot data");
            }

            return spotData;
        }

        /// <summary>
        /// Enhance spot quote with historical data if current OHLC is zero
        /// </summary>
        private async Task<MarketQuote?> EnhanceSpotQuoteWithHistoricalDataAsync(MarketQuote spotQuote, MarketDataContext context)
        {
            try
            {
                // Check if we have LastTradeTime (LTT) - this is crucial for historical data
                if (spotQuote.LastTradeTime == DateTime.MinValue)
                {
                    _logger.LogWarning($"Cannot enhance spot quote {spotQuote.TradingSymbol} - no LastTradeTime (LTT) available");
                    return null; // Cannot enhance without LTT
                }
                
                // Use the LTT date for historical data fetch
                var lttDate = spotQuote.LastTradeTime.Date;
                _logger.LogInformation($"Attempting to enhance spot quote {spotQuote.TradingSymbol} using LTT date: {lttDate:yyyy-MM-dd}");
                
                // Use HistoricalDataService to get historical data for this spot index on LTT date
                var historicalData = await _historicalDataService.GetHistoricalDataForInstrumentsAsync(
                    new List<long> { spotQuote.InstrumentToken }, 
                    lttDate,  // Use LTT date
                    lttDate); // Same LTT date
                
                if (historicalData.TryGetValue(spotQuote.InstrumentToken, out var historicalQuote))
                {
                    // Create enhanced quote with historical data from LTT date
                    var enhancedQuote = new MarketQuote
                    {
                        InstrumentToken = spotQuote.InstrumentToken,
                        TradingSymbol = spotQuote.TradingSymbol,
                        // TradingDate and TradeTime removed - not needed for LC/UC monitoring
                        OpenPrice = historicalQuote.Open,
                        HighPrice = historicalQuote.High,
                        LowPrice = historicalQuote.Low,
                        ClosePrice = historicalQuote.Close,
                        LastPrice = spotQuote.LastPrice, // Keep current last price
                        LowerCircuitLimit = spotQuote.LowerCircuitLimit,
                        UpperCircuitLimit = spotQuote.UpperCircuitLimit,
                        RecordDateTime = spotQuote.RecordDateTime,
                        LastTradeTime = spotQuote.LastTradeTime // Preserve LTT
                    };
                    
                    _logger.LogInformation($"Successfully enhanced spot quote {spotQuote.TradingSymbol} with historical data from LTT date {lttDate:yyyy-MM-dd}");
                    return enhancedQuote;
                }
                else
                {
                    _logger.LogWarning($"No historical data found for spot index {spotQuote.TradingSymbol} on LTT date {lttDate:yyyy-MM-dd}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to enhance spot quote {spotQuote.TradingSymbol} with historical data");
                return null;
            }
        }

        /// <summary>
        /// Map spot instrument symbols to our index names
        /// </summary>
        private string GetSpotIndexName(string tradingSymbol)
        {
            return tradingSymbol switch
            {
                "NIFTY 50" => "NIFTY",
                "SENSEX" => "SENSEX", 
                "NIFTY BANK" => "BANKNIFTY",
                _ => "UNKNOWN"
            };
        }

        private string GetChangeDirection(CircuitLimitChangeDetails? lastChange, MarketQuote currentQuote)
        {
            if (lastChange == null)
                return "FIRST_RECORD";
            
            // Calculate actual changes
            decimal lcChange = currentQuote.LowerCircuitLimit - lastChange.NewLowerCircuit;
            decimal ucChange = currentQuote.UpperCircuitLimit - lastChange.NewUpperCircuit;
            
            // Check if there are any changes at all
            if (lcChange == 0 && ucChange == 0)
                return "NO_CHANGE";
            
            // Determine change direction based on actual changes
            if (lcChange > 0 && ucChange > 0)
                return "BOTH_INCREASED";
            else if (lcChange > 0 && ucChange == 0)
                return "LC_INCREASED";
            else if (lcChange == 0 && ucChange > 0)
                return "UC_INCREASED";
            else if (lcChange < 0 && ucChange < 0)
                return "BOTH_DECREASED";
            else if (lcChange < 0 && ucChange == 0)
                return "LC_DECREASED";
            else if (lcChange == 0 && ucChange < 0)
                return "UC_DECREASED";
            else if (lcChange > 0 && ucChange < 0)
                return "LC_INCREASED_UC_DECREASED";
            else if (lcChange < 0 && ucChange > 0)
                return "LC_DECREASED_UC_INCREASED";
            else
                return "MIXED_CHANGES";
        }

        /// <summary>
        /// Validates a change record to ensure it makes logical sense
        /// </summary>
        private bool ValidateChangeRecord(CircuitLimitChangeDetails change, CircuitLimitChangeDetails? lastChange, MarketQuote currentQuote)
        {
            try
            {
                // Basic validation: ensure new values are not negative
                if (change.NewLowerCircuit < 0 || change.NewUpperCircuit < 0)
                {
                    _logger.LogWarning($"Invalid circuit limits for {change.TradingSymbol}: LC={change.NewLowerCircuit}, UC={change.NewUpperCircuit}");
                    return false;
                }

                // Validation: ensure previous values make sense
                if (lastChange != null)
                {
                    // If this is not the first record, validate the change makes sense
                    if (change.PreviousLowerCircuit != lastChange.NewLowerCircuit || change.PreviousUpperCircuit != lastChange.NewUpperCircuit)
                    {
                        _logger.LogWarning($"Previous value mismatch for {change.TradingSymbol}: Expected LC={lastChange.NewLowerCircuit}, UC={lastChange.NewUpperCircuit}, Got LC={change.PreviousLowerCircuit}, UC={change.PreviousUpperCircuit}");
                        return false;
                    }

                    // Validate that the change direction matches the actual values
                    var expectedDirection = GetChangeDirection(lastChange, currentQuote);
                    if (change.ChangeDirection != expectedDirection)
                    {
                        _logger.LogWarning($"Change direction mismatch for {change.TradingSymbol}: Expected={expectedDirection}, Got={change.ChangeDirection}");
                        return false;
                    }
                }

                // Validation: ensure OHLC data is reasonable
                if (change.HighPrice < change.LowPrice)
                {
                    _logger.LogWarning($"Invalid OHLC for {change.TradingSymbol}: High={change.HighPrice} < Low={change.LowPrice}");
                    return false;
                }

                if (change.LastPrice < 0)
                {
                    _logger.LogWarning($"Invalid LastPrice for {change.TradingSymbol}: {change.LastPrice}");
                    return false;
                }

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error validating change record for {change.TradingSymbol}");
                return false;
            }
        }

        /// <summary>
        /// Gets the next insertion sequence number for a specific instrument+expiry combination
        /// </summary>
        private async Task<int> GetNextInsertionSequenceAsync(MarketDataContext context, long instrumentToken, DateTime expiryDate)
        {
            try
            {
                // Get the maximum sequence number for this instrument+expiry combination
                var maxSequence = await context.MarketQuotes
                    .Where(q => q.InstrumentToken == instrumentToken && q.ExpiryDate == expiryDate)
                    .MaxAsync(q => (int?)q.InsertionSequence) ?? 0;

                // Return the next sequence number
                return maxSequence + 1;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error calculating insertion sequence for instrument {instrumentToken}, expiry {expiryDate:yyyy-MM-dd}");
                return 1; // Default to 1 if there's an error
            }
        }

        /// <summary>
        /// Export business day data to Excel file with timestamp suffix
        /// </summary>
        private async Task<string?> ExportBusinessDayDataIfNeededAsync(DateTime businessDate, string suffix = "")
        {
            try
            {
                // Create business date folder structure
                var businessDateFolder = Path.Combine(_excelExportService.GetExportPath(), businessDate.ToString("yyyy-MM-dd"));
                if (!Directory.Exists(businessDateFolder))
                    Directory.CreateDirectory(businessDateFolder);

                // Create filename with suffix and timestamp
                var timestamp = DateTime.Now.ToString("HHmmss");
                var fileName = string.IsNullOrEmpty(suffix) 
                    ? $"OptionsData_{businessDate:yyyyMMdd}.xlsx"
                    : $"OptionsData_{businessDate:yyyyMMdd}_{suffix}_{timestamp}.xlsx";
                var filePath = Path.Combine(businessDateFolder, fileName);

                // Export with custom format (separate sheets per expiry)
                var excelFilePath = await _excelExportService.ExportBusinessDayDataWithCustomFormatAsync(businessDate, filePath);
                return excelFilePath;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to export business day data");
                return null;
            }
        }
    }
}
