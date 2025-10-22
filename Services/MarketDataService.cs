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
        private readonly BusinessDateCalculationService _businessDateService;
        private readonly ExcelExportService _excelExportService;
        private readonly IConfiguration _configuration;

        public MarketDataService(
            IServiceScopeFactory scopeFactory, 
            ILogger<MarketDataService> logger,
            BusinessDateCalculationService businessDateService,
            ExcelExportService excelExportService,
            IConfiguration configuration)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _businessDateService = businessDateService;
            _excelExportService = excelExportService;
            _configuration = configuration;
        }

        public async Task ClearAllInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get count before clearing
                var instrumentCount = await context.Instruments.CountAsync();
                
                if (instrumentCount > 0)
                {
                    _logger.LogInformation($"Clearing ALL {instrumentCount} instruments (including expired contracts and invalid tokens)...");
                    
                    // Remove ALL instruments to ensure fresh data
                    await context.Database.ExecuteSqlRawAsync("TRUNCATE TABLE Instruments");
                    await context.Database.ExecuteSqlRawAsync("DBCC CHECKIDENT ('Instruments', RESEED, 0)");
                    
                    _logger.LogInformation($"Successfully cleared all {instrumentCount} instruments");
                }
                else
                {
                    _logger.LogInformation("Instruments table is already empty");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to clear all instruments");
            }
        }

        public async Task RemoveNonIndexOptionInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var allowedPrefixes = new[] { "NIFTY", "BANKNIFTY", "SENSEX" }; // Only 3 indices

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

        public async Task SaveInstrumentsAsync(List<Instrument> instruments, DateTime? loadDate = null)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Use current business date if not provided
                var businessDate = (loadDate ?? DateTime.UtcNow.AddHours(5.5)).Date;
                var currentTime = DateTime.UtcNow.AddHours(5.5);
                
                _logger.LogInformation($"Processing {instruments.Count} instruments for business date: {businessDate:yyyy-MM-dd}...");

                // OPTIMIZED: Get all existing tokens in ONE query (fast)
                var existingTokens = await context.Instruments
                    .Select(i => i.InstrumentToken)
                    .ToHashSetAsync();

                _logger.LogInformation($"Found {existingTokens.Count} existing instruments in database");

                // OPTIMIZED: Filter NEW instruments only (in-memory, super fast)
                var newInstruments = instruments
                    .Where(i => !existingTokens.Contains(i.InstrumentToken))
                    .ToList();

                if (newInstruments.Any())
                {
                    _logger.LogInformation($"Found {newInstruments.Count} NEW instruments to add");

                    // Set all date fields for new instruments
                    foreach (var instrument in newInstruments)
                    {
                        instrument.LoadDate = businessDate; // Backward compatibility
                        instrument.FirstSeenDate = businessDate; // When we FIRST discovered it
                        instrument.LastFetchedDate = businessDate; // When we last fetched it
                        instrument.IsExpired = instrument.Expiry.HasValue && instrument.Expiry.Value.Date < businessDate;
                        instrument.CreatedAt = currentTime;
                        instrument.UpdatedAt = currentTime;
                    }

                    // Bulk insert (fast)
                    context.Instruments.AddRange(newInstruments);
                    await context.SaveChangesAsync();
                    
                    _logger.LogInformation($"✅ Successfully added {newInstruments.Count} NEW instruments for business date {businessDate:yyyy-MM-dd}");

                    // Log breakdown by exchange
                    var exchangeGroups = newInstruments.GroupBy(i => i.Exchange).ToList();
                    foreach (var group in exchangeGroups)
                    {
                        _logger.LogInformation($"  {group.Key}: {group.Count()} new instruments");
                    }

                    // Log breakdown by instrument type for options
                    var optionInstruments = newInstruments.Where(i => i.InstrumentType == "CE" || i.InstrumentType == "PE").ToList();
                    if (optionInstruments.Any())
                    {
                        var optionGroups = optionInstruments.GroupBy(i => i.TradingSymbol?.Substring(0, Math.Min(10, i.TradingSymbol?.Length ?? 0))).ToList();
                        _logger.LogInformation($"New option instruments breakdown:");
                        foreach (var group in optionGroups.Take(5)) // Show top 5
                        {
                            _logger.LogInformation($"  {group.Key}: {group.Count()} new options");
                        }
                    }
                }
                else
                {
                    _logger.LogInformation($"✅ No new instruments found - all {instruments.Count} instruments already exist in database");
                }

                // Note: We DON'T update LastFetchedDate for existing instruments on every refresh
                // because it's not critical and would cause unnecessary database writes
                // We only care about discovering NEW instruments (new strikes/expiries)
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to save instruments to database");
                throw;
            }
        }

        public async Task SaveMarketQuotesAsync(List<MarketQuote> quotes)
        {
            var startTime = DateTime.Now;
            _logger.LogInformation($"🔄 SaveMarketQuotesAsync STARTED at {startTime:HH:mm:ss} - Processing {quotes.Count} quotes");
            
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var savedCount = 0;
                var skippedCount = 0;

                foreach (var quote in quotes)
                {
                    // Check for duplicate - same instrument with same circuit limit values (LC/UC)
                    var existing = await context.MarketQuotes
                        .Where(q => q.InstrumentToken == quote.InstrumentToken && 
                                   q.ExpiryDate == quote.ExpiryDate)  // ✅ Add expiry date check
                        .OrderByDescending(q => q.InsertionSequence)  // ✅ Order by sequence, not timestamp
                        .FirstOrDefaultAsync();

                    if (existing == null)
                    {
                        // First time seeing this instrument
                        quote.InsertionSequence = 1; // First record for this business date
                        quote.GlobalSequence = 1;     // First record globally for this contract
                        context.MarketQuotes.Add(quote);
                        savedCount++;
                    }
                    else
                    {
                        // Check if circuit limits have changed - only save if LC or UC values are different
                        bool isDuplicate = 
                            existing.LowerCircuitLimit == quote.LowerCircuitLimit &&
                            existing.UpperCircuitLimit == quote.UpperCircuitLimit;

                        _logger.LogDebug($"Duplicate check for {quote.TradingSymbol}: Existing LC={existing.LowerCircuitLimit}, UC={existing.UpperCircuitLimit}, New LC={quote.LowerCircuitLimit}, UC={quote.UpperCircuitLimit}, IsDuplicate={isDuplicate}");

                        if (isDuplicate)
                        {
                            skippedCount++;
                            _logger.LogDebug($"Skipped duplicate data for {quote.TradingSymbol} - no change in LC/UC (LC: {quote.LowerCircuitLimit}, UC: {quote.UpperCircuitLimit})");
                        }
                        else
                        {
                            // Circuit limits have changed, save the new quote
                            
                            // Calculate next DAILY insertion sequence (resets per business date)
                            var maxDailySequence = await context.MarketQuotes
                                .Where(q => q.InstrumentToken == quote.InstrumentToken && 
                                           q.ExpiryDate == quote.ExpiryDate &&
                                           q.BusinessDate == quote.BusinessDate)
                                .MaxAsync(q => (int?)q.InsertionSequence) ?? 0;
                            
                            quote.InsertionSequence = maxDailySequence + 1;
                            
                            // Calculate next GLOBAL sequence (continuous across all business dates until expiry)
                            var maxGlobalSequence = await context.MarketQuotes
                                .Where(q => q.TradingSymbol == quote.TradingSymbol && 
                                           q.ExpiryDate == quote.ExpiryDate)
                                .MaxAsync(q => (int?)q.GlobalSequence) ?? 0;
                            
                            quote.GlobalSequence = maxGlobalSequence + 1;
                            
                            context.MarketQuotes.Add(quote);
                            savedCount++;
                            _logger.LogInformation($"Saved new data for {quote.TradingSymbol} - LC/UC changed: LC {existing.LowerCircuitLimit}->{quote.LowerCircuitLimit}, UC {existing.UpperCircuitLimit}->{quote.UpperCircuitLimit}, DailySeq={quote.InsertionSequence}, GlobalSeq={quote.GlobalSequence}");
                        }
                    }
                }

                _logger.LogInformation($"💾 Attempting to save to database: {savedCount} new quotes, {skippedCount} skipped");
                
                var saveStartTime = DateTime.Now;
                await context.SaveChangesAsync();
                var saveEndTime = DateTime.Now;
                var saveDuration = (saveEndTime - saveStartTime).TotalMilliseconds;
                
                var totalDuration = (DateTime.Now - startTime).TotalMilliseconds;
                _logger.LogInformation($"✅ SaveMarketQuotesAsync DB SAVE SUCCESSFUL in {saveDuration}ms (Total: {totalDuration}ms) - Saved: {savedCount}, Skipped: {skippedCount}");

                // Calculate and apply BusinessDate after quotes are saved (only if we saved new quotes)
                if (savedCount > 0)
                {
                    var businessDate = await _businessDateService.CalculateBusinessDateAsync();
                    if (businessDate.HasValue)
                    {
                        await _businessDateService.ApplyBusinessDateToAllQuotesAsync(businessDate.Value);
                        _logger.LogInformation($"Applied BusinessDate {businessDate.Value:yyyy-MM-dd} to all quotes");

                        // Check if LC/UC changes occurred and auto-export Excel if needed
                        await CheckAndExportLCUCChangesAsync(businessDate.Value);
                    }
                    else
                    {
                        _logger.LogInformation("BusinessDate calculation will be attempted in next data collection cycle");
                    }
                }
            }
            catch (Exception ex)
            {
                var errorTime = DateTime.Now;
                var duration = (errorTime - startTime).TotalMilliseconds;
                _logger.LogError(ex, $"❌ SaveMarketQuotesAsync FAILED at {errorTime:HH:mm:ss} after {duration}ms");
                _logger.LogError($"❌ Exception Type: {ex.GetType().Name}");
                _logger.LogError($"❌ Exception Message: {ex.Message}");
                _logger.LogError($"❌ Stack Trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    _logger.LogError($"❌ Inner Exception: {ex.InnerException.Message}");
                }
                throw;
            }
        }

        public async Task<List<Instrument>> GetOptionInstrumentsAsync(DateTime? businessDate = null)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get primary expiry from configuration
                var primaryExpiryStr = _configuration.GetValue<string>("PrimaryExpiry");
                DateTime? primaryExpiry = null;
                
                if (DateTime.TryParse(primaryExpiryStr, out var parsedExpiry))
                {
                    primaryExpiry = parsedExpiry.Date;
                    _logger.LogInformation($"🎯 FOCUSING ON PRIMARY EXPIRY: {primaryExpiry:yyyy-MM-dd}");
                }
                else
                {
                    _logger.LogWarning("⚠️ Primary expiry not configured, using all expiries");
                }

                // If no business date provided, get the latest LoadDate
                if (!businessDate.HasValue)
                {
                    var latestLoadDate = await context.Instruments
                        .OrderByDescending(i => i.LoadDate)
                        .Select(i => i.LoadDate)
                        .FirstOrDefaultAsync();
                    
                    if (latestLoadDate == default)
                    {
                        _logger.LogWarning("No instruments found in database");
                        return new List<Instrument>();
                    }
                    
                    businessDate = latestLoadDate;
                    _logger.LogInformation($"Using latest instrument load date: {businessDate.Value:yyyy-MM-dd}");
                }

                // Get instruments for the specified business date (ALL EXPIRIES)
                var query = context.Instruments
                    .Where(i => (i.InstrumentType == "CE" || i.InstrumentType == "PE") && i.LoadDate == businessDate.Value.Date);
                
                var instruments = await query.ToListAsync();

                _logger.LogInformation($"Retrieved {instruments.Count} option instruments for business date: {businessDate.Value:yyyy-MM-dd}");
                if (primaryExpiry.HasValue)
                {
                    _logger.LogInformation($"🎯 PRIMARY EXPIRY FOCUS: {primaryExpiry:yyyy-MM-dd} (Calculations will focus on this expiry)");
                    _logger.LogInformation($"📊 DATA COLLECTION: All expiries collected, calculations focused on primary expiry");
                }
                return instruments;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get option instruments from database");
                return new List<Instrument>();
            }
        }

        public async Task<List<Instrument>> GetPrimaryExpiryInstrumentsAsync(DateTime? businessDate = null)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get primary expiry from configuration
                var primaryExpiryStr = _configuration.GetValue<string>("PrimaryExpiry");
                DateTime? primaryExpiry = null;
                
                if (DateTime.TryParse(primaryExpiryStr, out var parsedExpiry))
                {
                    primaryExpiry = parsedExpiry.Date;
                    _logger.LogInformation($"🎯 CALCULATION FOCUS: Primary Expiry {primaryExpiry:yyyy-MM-dd}");
                }
                else
                {
                    _logger.LogWarning("⚠️ Primary expiry not configured, using all expiries for calculations");
                    return await GetOptionInstrumentsAsync(businessDate);
                }

                // If no business date provided, get the latest LoadDate
                if (!businessDate.HasValue)
                {
                    var latestLoadDate = await context.Instruments
                        .OrderByDescending(i => i.LoadDate)
                        .Select(i => i.LoadDate)
                        .FirstOrDefaultAsync();
                    
                    if (latestLoadDate == default)
                    {
                        _logger.LogWarning("No instruments found in database");
                        return new List<Instrument>();
                    }
                    
                    businessDate = latestLoadDate;
                    _logger.LogInformation($"Using latest instrument load date: {businessDate.Value:yyyy-MM-dd}");
                }

                // Get instruments for PRIMARY EXPIRY ONLY (for calculations)
                var instruments = await context.Instruments
                    .Where(i => (i.InstrumentType == "CE" || i.InstrumentType == "PE") 
                             && i.LoadDate == businessDate.Value.Date
                             && i.Expiry == primaryExpiry.Value)
                    .ToListAsync();

                _logger.LogInformation($"🎯 Retrieved {instruments.Count} PRIMARY EXPIRY instruments for calculations: {primaryExpiry:yyyy-MM-dd}");
                return instruments;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get primary expiry instruments from database");
                return new List<Instrument>();
            }
        }

        public async Task<List<Instrument>> GetAllInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                return await context.Instruments
                    .Where(i => i.InstrumentType == "CE" || i.InstrumentType == "PE" || i.InstrumentType == "INDEX")
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get all instruments from database");
                return new List<Instrument>();
            }
        }

        public async Task<List<Instrument>> GetIndexInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                return await context.Instruments
                    .Where(i => i.InstrumentType == "INDEX")
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get INDEX instruments from database");
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
                    .Where(q => q.RecordDateTime < cutoffDate)
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

        public async Task<List<MarketQuote>> GetLatestQuotesForInstrumentsAsync(List<long> instrumentTokens)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var latestQuotes = new List<MarketQuote>();
                
                foreach (var token in instrumentTokens)
                {
                    var latestQuote = await context.MarketQuotes
                        .Where(q => q.InstrumentToken == token)
                        .OrderByDescending(q => q.RecordDateTime)
                        .FirstOrDefaultAsync();
                        
                    if (latestQuote != null)
                    {
                        latestQuotes.Add(latestQuote);
                    }
                }

                _logger.LogInformation($"Retrieved {latestQuotes.Count} latest quotes for {instrumentTokens.Count} instruments");
                return latestQuotes;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get latest quotes for instruments");
                return new List<MarketQuote>();
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
                    .Where(q => q.RecordDateTime.Date == recentDate)
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
                    .Where(q => q.InstrumentToken == instrumentToken && q.RecordDateTime.Date >= cutoffDate)
                    .GroupBy(q => q.RecordDateTime.Date)
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

        /// <summary>
        /// Check for available data and automatically export Excel (at least once per business date, and when LC/UC changes)
        /// </summary>
        private async Task CheckAndExportLCUCChangesAsync(DateTime businessDate)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Check if there are any options data for this business date
                var optionsDataCount = await context.MarketQuotes
                    .Where(q => q.BusinessDate == businessDate 
                        && q.TradingSymbol != null 
                        && q.TradingSymbol.StartsWith("NIFTY") 
                        && q.TradingSymbol != "NIFTY")
                    .CountAsync();

                if (optionsDataCount == 0)
                {
                    _logger.LogDebug($"No options data found for {businessDate:yyyy-MM-dd} - skipping Excel export");
                    return;
                }

                // Check if this is the first export for this business date
                var expectedFileName = $"OptionsData_{businessDate:yyyyMMdd}.xlsx";
                var exportPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Exports");
                var expectedFilePath = Path.Combine(exportPath, expectedFileName);
                var isFirstExport = !File.Exists(expectedFilePath);

                // Check for LC/UC changes in the last few minutes (indicating active trading)
                var recentLCUCChanges = await context.MarketQuotes
                    .Where(q => q.BusinessDate == businessDate 
                        && q.TradingSymbol != null 
                        && q.TradingSymbol.StartsWith("NIFTY") 
                        && q.TradingSymbol != "NIFTY"
                        && (q.LowerCircuitLimit > 0 || q.UpperCircuitLimit > 0)
                        && q.RecordDateTime >= DateTime.UtcNow.AddMinutes(-5)) // Last 5 minutes
                    .CountAsync();

                // Export if:
                // 1. First export for this business date, OR
                // 2. Recent LC/UC changes detected (active trading)
                bool shouldExport = isFirstExport || recentLCUCChanges > 0;

                if (shouldExport)
                {
                    var exportReason = isFirstExport ? "initial data capture" : $"LC/UC changes detected ({recentLCUCChanges} recent updates)";
                    _logger.LogInformation($"Found {optionsDataCount} options instruments for {businessDate:yyyy-MM-dd} - exporting Excel file ({exportReason})");

                    // Auto-export Excel file with timestamp for LC/UC changes to handle multiple exports per day
                    var excelFilePath = await _excelExportService.ExportOptionsDataToExcelAsync(businessDate, includeTimestamp: !isFirstExport);
                    
                    if (!string.IsNullOrEmpty(excelFilePath))
                    {
                        _logger.LogInformation($"✅ AUTOMATIC EXCEL EXPORT COMPLETED: {excelFilePath}");
                        _logger.LogInformation($"📊 Exported {optionsDataCount} options instruments for business date {businessDate:yyyy-MM-dd} ({exportReason})");
                    }
                }
                else
                {
                    _logger.LogDebug($"Excel file exists and no recent LC/UC changes for {businessDate:yyyy-MM-dd} - skipping export");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to check and export data for {businessDate:yyyy-MM-dd}");
                // Don't throw - this is a non-critical operation
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

    /// <summary>
    /// Record class for LC/UC change data
    /// </summary>
    public class LCUCChangeRecord
    {
        public string TradingSymbol { get; set; } = string.Empty;
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty;
        public DateTime ExpiryDate { get; set; }
        public decimal CurrentLC { get; set; }
        public decimal CurrentUC { get; set; }
        public DateTime ChangeTime { get; set; }
    }
} 