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
    public class SmartCircuitLimitsService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<SmartCircuitLimitsService> _logger;

        public SmartCircuitLimitsService(
            IServiceScopeFactory scopeFactory,
            ILogger<SmartCircuitLimitsService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Main method to process smart circuit limits
        /// </summary>
        public async Task ProcessSmartCircuitLimitsAsync()
        {
            try
            {
                _logger.LogInformation("Starting smart circuit limits processing...");

                // Step 1: Analyze traded vs non-traded instruments
                var analysis = await AnalyzeTradedVsNonTradedAsync();
                
                _logger.LogInformation($"Analysis: {analysis.TradedCount} traded, {analysis.NonTradedCount} non-traded instruments");

                // Step 2: Detect underlying-level circuit limit changes
                var underlyingChanges = await DetectCircuitLimitChangesAsync();
                
                if (underlyingChanges.Any())
                {
                    _logger.LogInformation($"Detected {underlyingChanges.Count} underlying-level circuit limit changes");
                    
                    // Step 3: Apply changes to all related instruments
                    foreach (var change in underlyingChanges)
                    {
                        await ApplyCircuitLimitsToAllInstrumentsAsync(change);
                        await TrackCircuitLimitChangeAsync(change);
                    }
                }
                else
                {
                    _logger.LogInformation("No underlying-level circuit limit changes detected");
                }

                // Step 4: Detect individual instrument circuit limit changes
                var individualChanges = await DetectIndividualInstrumentChangesAsync();
                
                if (individualChanges.Any())
                {
                    _logger.LogInformation($"Detected {individualChanges.Count} individual instrument circuit limit changes");
                    
                    // Track individual changes
                    foreach (var change in individualChanges)
                    {
                        await TrackCircuitLimitChangeAsync(change);
                    }
                }
                else
                {
                    _logger.LogInformation("No individual instrument circuit limit changes detected");
                }

                _logger.LogInformation($"Smart circuit limits processing completed. Total changes tracked: {underlyingChanges.Count + individualChanges.Count}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in smart circuit limits processing");
            }
        }

        /// <summary>
        /// Analyze which instruments are traded vs non-traded
        /// </summary>
        public async Task<TradedAnalysisResult> AnalyzeTradedVsNonTradedAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var today = DateTime.Today;

                // Get all instruments
                var allInstruments = await context.Instruments
                    .Where(i => i.InstrumentType == "CE" || i.InstrumentType == "PE")
                    .ToListAsync();

                // Get instruments that have quotes today (traded)
                var tradedInstruments = await context.MarketQuotes
                    .Where(q => q.RecordDateTime.Date == today)
                    .Select(q => q.InstrumentToken)
                    .Distinct()
                    .ToListAsync();

                // Get instruments that DON'T have quotes today (non-traded)
                var nonTradedInstruments = allInstruments
                    .Where(i => !tradedInstruments.Contains(i.InstrumentToken))
                    .ToList();

                var tradedInstrumentsList = allInstruments
                    .Where(i => tradedInstruments.Contains(i.InstrumentToken))
                    .ToList();

                return new TradedAnalysisResult
                {
                    TradedInstruments = tradedInstrumentsList,
                    NonTradedInstruments = nonTradedInstruments,
                    TradedCount = tradedInstrumentsList.Count,
                    NonTradedCount = nonTradedInstruments.Count,
                    TotalCount = allInstruments.Count
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error analyzing traded vs non-traded instruments");
                return new TradedAnalysisResult();
            }
        }

        /// <summary>
        /// Detect circuit limit changes by underlying symbol
        /// </summary>
        public async Task<List<CircuitLimitChange>> DetectCircuitLimitChangesAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var today = DateTime.Today;
                var yesterday = today.AddDays(-1);

                // Check if we have any data for comparison
                var yesterdayCount = await context.MarketQuotes
                    .Where(q => q.RecordDateTime.Date == yesterday)
                    .CountAsync();
                    
                var todayCount = await context.MarketQuotes
                    .Where(q => q.RecordDateTime.Date == today)
                    .CountAsync();
                    
                // Only proceed if we have some data for both days
                // This allows detection even with minimal data collection
                if (yesterdayCount == 0 || todayCount == 0)
                {
                    _logger.LogWarning($"No data available for circuit limit detection. Yesterday: {yesterdayCount}, Today: {todayCount}. Need data for both days.");
                    return new List<CircuitLimitChange>();
                }
                
                _logger.LogInformation($"Data available for circuit limit detection. Yesterday: {yesterdayCount}, Today: {todayCount} quotes.");

                // Get all instruments first, then group by underlying in memory
                var allInstruments = await context.Instruments
                    .Where(i => i.InstrumentType == "CE" || i.InstrumentType == "PE")
                    .ToListAsync();

                var instrumentsByUnderlying = allInstruments
                    .GroupBy(i => GetUnderlyingSymbol(i.TradingSymbol))
                    .ToList();

                var changes = new List<CircuitLimitChange>();

                foreach (var underlyingGroup in instrumentsByUnderlying)
                {
                    var underlyingSymbol = underlyingGroup.Key;
                    var instrumentTokens = underlyingGroup.Select(i => i.InstrumentToken).ToList();

                    // Get yesterday's and today's quotes for this underlying
                    var yesterdayQuotes = await context.MarketQuotes
                        .Where(q => instrumentTokens.Contains(q.InstrumentToken) && 
                                   q.RecordDateTime.Date == yesterday)
                        .ToListAsync();

                    var todayQuotes = await context.MarketQuotes
                        .Where(q => instrumentTokens.Contains(q.InstrumentToken) && 
                                   q.RecordDateTime.Date == today)
                        .ToListAsync();

                    if (!yesterdayQuotes.Any() || !todayQuotes.Any()) continue;

                    // Get the most common circuit limits for yesterday and today
                    var yesterdayLimits = yesterdayQuotes
                        .Where(q => q.LowerCircuitLimit > 0 || q.UpperCircuitLimit > 0)
                        .GroupBy(q => new CircuitLimitValue 
                        { 
                            Lower = q.LowerCircuitLimit, 
                            Upper = q.UpperCircuitLimit 
                        })
                        .OrderByDescending(g => g.Count())
                        .FirstOrDefault()?.Key;

                    var todayLimits = todayQuotes
                        .Where(q => q.LowerCircuitLimit > 0 || q.UpperCircuitLimit > 0)
                        .GroupBy(q => new CircuitLimitValue 
                        { 
                            Lower = q.LowerCircuitLimit, 
                            Upper = q.UpperCircuitLimit 
                        })
                        .OrderByDescending(g => g.Count())
                        .FirstOrDefault()?.Key;

                    // Check if there's a change between yesterday and today
                    if (yesterdayLimits != null && todayLimits != null && 
                        (yesterdayLimits.Lower != todayLimits.Lower || yesterdayLimits.Upper != todayLimits.Upper))
                    {
                        // Get the instrument that triggered this change (first instrument with new limits)
                        var triggeringInstrument = todayQuotes
                            .Where(q => q.LowerCircuitLimit == todayLimits.Lower && 
                                       q.UpperCircuitLimit == todayLimits.Upper)
                            .FirstOrDefault();

                        if (triggeringInstrument != null)
                        {
                            // Get instrument details for better user experience
                            var instrument = await context.Instruments
                                .FirstOrDefaultAsync(i => i.InstrumentToken == triggeringInstrument.InstrumentToken);

                            // Get spot/index OHLC values at the time of change
                            var spotData = await GetSpotIndexDataAsync(underlyingSymbol);

                            var change = new CircuitLimitChange
                            {
                                UnderlyingSymbol = underlyingSymbol,
                                OldLowerLimit = yesterdayLimits.Lower,
                                OldUpperLimit = yesterdayLimits.Upper,
                                NewLowerLimit = todayLimits.Lower,
                                NewUpperLimit = todayLimits.Upper,
                                TriggeredByInstrumentToken = triggeringInstrument.InstrumentToken,
                                InstrumentsAffected = instrumentTokens.Count,
                                ChangeTimestamp = DateTime.UtcNow,
                                // Spot/Index data
                                SpotOpen = spotData?.Open,
                                SpotHigh = spotData?.High,
                                SpotLow = spotData?.Low,
                                SpotClose = spotData?.Close,
                                SpotVolume = spotData?.Volume,
                                SpotLastPrice = spotData?.LastPrice,
                                SpotLowerCircuitLimit = spotData?.LowerCircuitLimit,
                                SpotUpperCircuitLimit = spotData?.UpperCircuitLimit,
                                SpotInstrumentToken = spotData?.InstrumentToken,
                                SpotTradingSymbol = spotData?.TradingSymbol
                            };

                            // Add instrument details if available
                            if (instrument != null)
                            {
                                change.TriggeredByTradingSymbol = instrument.TradingSymbol;
                                change.TriggeredByStrike = instrument.Strike;
                                change.TriggeredByExpiry = instrument.Expiry;
                                change.TriggeredByInstrumentType = instrument.InstrumentType;
                            }

                            changes.Add(change);
                        }
                    }
                }

                return changes;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error detecting circuit limit changes");
                return new List<CircuitLimitChange>();
            }
        }

        /// <summary>
        /// Detect individual instrument circuit limit changes (not just underlying-level)
        /// </summary>
        public async Task<List<CircuitLimitChange>> DetectIndividualInstrumentChangesAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var today = DateTime.Today;
                var yesterday = today.AddDays(-1);

                // Check if we have any data for comparison
                var yesterdayCount = await context.MarketQuotes
                    .Where(q => q.RecordDateTime.Date == yesterday)
                    .CountAsync();
                    
                var todayCount = await context.MarketQuotes
                    .Where(q => q.RecordDateTime.Date == today)
                    .CountAsync();
                    
                if (yesterdayCount == 0 || todayCount == 0)
                {
                    _logger.LogWarning($"No data available for individual instrument circuit limit detection. Yesterday: {yesterdayCount}, Today: {todayCount}.");
                    return new List<CircuitLimitChange>();
                }

                var changes = new List<CircuitLimitChange>();

                // Get all instruments that have quotes both yesterday and today
                var instrumentsWithQuotes = await context.MarketQuotes
                    .Where(q => q.RecordDateTime.Date == yesterday || q.RecordDateTime.Date == today)
                    .Select(q => q.InstrumentToken)
                    .Distinct()
                    .ToListAsync();

                foreach (var instrumentToken in instrumentsWithQuotes)
                {
                    // Get yesterday's and today's quotes for this specific instrument
                    var yesterdayQuote = await context.MarketQuotes
                        .Where(q => q.InstrumentToken == instrumentToken && 
                                   q.RecordDateTime.Date == yesterday)
                        .OrderByDescending(q => q.RecordDateTime)
                        .FirstOrDefaultAsync();

                    var todayQuote = await context.MarketQuotes
                        .Where(q => q.InstrumentToken == instrumentToken && 
                                   q.RecordDateTime.Date == today)
                        .OrderByDescending(q => q.RecordDateTime)
                        .FirstOrDefaultAsync();

                    if (yesterdayQuote == null || todayQuote == null) continue;

                    // Check if circuit limits changed for this specific instrument
                    if (yesterdayQuote.LowerCircuitLimit != todayQuote.LowerCircuitLimit || 
                        yesterdayQuote.UpperCircuitLimit != todayQuote.UpperCircuitLimit)
                    {
                        // Get instrument details
                        var instrument = await context.Instruments
                            .FirstOrDefaultAsync(i => i.InstrumentToken == instrumentToken);

                        if (instrument != null)
                        {
                            var underlyingSymbol = GetUnderlyingSymbol(instrument.TradingSymbol);
                            
                            // Get spot/index OHLC values at the time of change
                            var spotData = await GetSpotIndexDataAsync(underlyingSymbol);

                            var change = new CircuitLimitChange
                            {
                                UnderlyingSymbol = underlyingSymbol,
                                OldLowerLimit = yesterdayQuote.LowerCircuitLimit,
                                OldUpperLimit = yesterdayQuote.UpperCircuitLimit,
                                NewLowerLimit = todayQuote.LowerCircuitLimit,
                                NewUpperLimit = todayQuote.UpperCircuitLimit,
                                TriggeredByInstrumentToken = instrumentToken,
                                InstrumentsAffected = 1, // Only this instrument
                                ChangeTimestamp = DateTime.UtcNow,
                                // Instrument details
                                TriggeredByTradingSymbol = instrument.TradingSymbol,
                                TriggeredByStrike = instrument.Strike,
                                TriggeredByExpiry = instrument.Expiry,
                                TriggeredByInstrumentType = instrument.InstrumentType,
                                // Spot/Index data
                                SpotOpen = spotData?.Open,
                                SpotHigh = spotData?.High,
                                SpotLow = spotData?.Low,
                                SpotVolume = spotData?.Volume,
                                SpotLastPrice = spotData?.LastPrice,
                                SpotLowerCircuitLimit = spotData?.LowerCircuitLimit,
                                SpotUpperCircuitLimit = spotData?.UpperCircuitLimit,
                                SpotInstrumentToken = spotData?.InstrumentToken,
                                SpotTradingSymbol = spotData?.TradingSymbol
                            };

                            changes.Add(change);
                            
                            _logger.LogInformation($"Individual instrument circuit limit change detected: {instrument.TradingSymbol} - {yesterdayQuote.LowerCircuitLimit}/{yesterdayQuote.UpperCircuitLimit} → {todayQuote.LowerCircuitLimit}/{todayQuote.UpperCircuitLimit}");
                        }
                    }
                }

                return changes;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error detecting individual instrument circuit limit changes");
                return new List<CircuitLimitChange>();
            }
        }

        /// <summary>
        /// Apply circuit limits to all instruments of the same underlying
        /// </summary>
        public async Task ApplyCircuitLimitsToAllInstrumentsAsync(CircuitLimitChange change)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var today = DateTime.Today;

                // Get all instruments for this underlying
                var allInstruments = await context.Instruments
                    .Where(i => i.TradingSymbol.StartsWith(change.UnderlyingSymbol))
                    .ToListAsync();

                _logger.LogInformation($"Applying circuit limits to {allInstruments.Count} {change.UnderlyingSymbol} instruments");

                var circuitLimitsToAdd = new List<CircuitLimit>();

                foreach (var instrument in allInstruments)
                {
                    // Check if we already have circuit limits for this instrument today
                    var existing = await context.CircuitLimits
                        .FirstOrDefaultAsync(cl => cl.InstrumentToken == instrument.InstrumentToken && cl.TradingDate == today);

                    if (existing == null)
                    {
                        // Create new circuit limit record
                        var circuitLimit = new CircuitLimit
                        {
                            TradingDate = today,
                            InstrumentToken = instrument.InstrumentToken,
                            TradingSymbol = instrument.TradingSymbol,
                            Strike = instrument.Strike,
                            OptionType = instrument.InstrumentType,
                            LowerCircuitLimit = change.NewLowerLimit,
                            UpperCircuitLimit = change.NewUpperLimit,
                            Source = "CASCADE_FROM_TRADED",
                            LastUpdated = DateTime.UtcNow
                        };

                        circuitLimitsToAdd.Add(circuitLimit);
                    }
                    else
                    {
                        // Update existing record
                        existing.LowerCircuitLimit = change.NewLowerLimit;
                        existing.UpperCircuitLimit = change.NewUpperLimit;
                        existing.Source = "CASCADE_FROM_TRADED";
                        existing.LastUpdated = DateTime.UtcNow;
                    }
                }

                // Add new circuit limits
                if (circuitLimitsToAdd.Any())
                {
                    await context.CircuitLimits.AddRangeAsync(circuitLimitsToAdd);
                }

                // Save changes
                await context.SaveChangesAsync();

                // Track the change
                await TrackCircuitLimitChangeAsync(change);

                _logger.LogInformation($"Successfully applied circuit limits to {allInstruments.Count} {change.UnderlyingSymbol} instruments");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error applying circuit limits for {change.UnderlyingSymbol}");
            }
        }

        /// <summary>
        /// Get spot/index OHLC data for the underlying symbol
        /// </summary>
        public async Task<SpotIndexData?> GetSpotIndexDataAsync(string underlyingSymbol)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get the spot/index instrument for this underlying
                var spotInstrument = await GetSpotInstrumentAsync(underlyingSymbol);
                
                if (spotInstrument == null)
                {
                    _logger.LogWarning($"No spot instrument found for {underlyingSymbol}");
                    return null;
                }

                // Get the most recent quote for the spot instrument
                var spotQuote = await context.MarketQuotes
                    .Where(q => q.InstrumentToken == spotInstrument.InstrumentToken)
                    .OrderByDescending(q => q.RecordDateTime)
                    .FirstOrDefaultAsync();

                if (spotQuote == null)
                {
                    _logger.LogWarning($"No spot quote found for {underlyingSymbol}");
                    return null;
                }

                return new SpotIndexData
                {
                    InstrumentToken = spotInstrument.InstrumentToken.ToString(),
                    TradingSymbol = spotInstrument.TradingSymbol,
                    Open = spotQuote.OpenPrice,
                    High = spotQuote.HighPrice,
                    Low = spotQuote.LowPrice,
                    Close = spotQuote.ClosePrice,
                    // Volume removed - not needed for LC/UC monitoring
                    LastPrice = spotQuote.LastPrice,
                    LowerCircuitLimit = spotQuote.LowerCircuitLimit,
                    UpperCircuitLimit = spotQuote.UpperCircuitLimit
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting spot data for {underlyingSymbol}");
                return null;
            }
        }

        /// <summary>
        /// Get the spot/index instrument for an underlying symbol
        /// </summary>
        public async Task<Instrument?> GetSpotInstrumentAsync(string underlyingSymbol)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Map underlying to spot instrument symbols
                var spotSymbol = GetSpotSymbolForUnderlying(underlyingSymbol);
                
                if (string.IsNullOrEmpty(spotSymbol))
                {
                    _logger.LogWarning($"No spot symbol mapping found for {underlyingSymbol}");
                    return null;
                }

                // Get the spot instrument
                var spotInstrument = await context.Instruments
                    .FirstOrDefaultAsync(i => i.TradingSymbol == spotSymbol);

                if (spotInstrument == null)
                {
                    _logger.LogWarning($"Spot instrument not found: {spotSymbol}");
                    return null;
                }

                return spotInstrument;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting spot instrument for {underlyingSymbol}");
                return null;
            }
        }

        /// <summary>
        /// Map underlying symbol to its spot instrument symbol
        /// </summary>
        private string GetSpotSymbolForUnderlying(string underlyingSymbol)
        {
            return underlyingSymbol switch
            {
                "NIFTY" => "NIFTY 50",
                "BANKNIFTY" => "NIFTY BANK",
                "FINNIFTY" => "NIFTY FIN SERVICE",
                "MIDCPNIFTY" => "NIFTY MIDCAP SELECT",
                "SENSEX" => "SENSEX",
                _ => underlyingSymbol // Fallback to same symbol
            };
        }

        /// <summary>
        /// Track circuit limit changes for historical analysis
        /// </summary>
        public async Task TrackCircuitLimitChangeAsync(CircuitLimitChange change)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var changeRecord = new CircuitLimitChangeRecord
                {
                    TradingDate = DateTime.Today,
                    InstrumentToken = change.TriggeredByInstrumentToken,
                    TradingSymbol = change.TriggeredByTradingSymbol ?? "Unknown",
                    Strike = change.TriggeredByStrike ?? 0,
                    OptionType = change.TriggeredByInstrumentType ?? "Unknown",
                    Exchange = "NFO", // Default for options
                    ExpiryDate = change.TriggeredByExpiry ?? DateTime.MinValue,
                    ChangeType = "BOTH_CHANGE", // Default, can be enhanced later
                    PreviousLC = change.OldLowerLimit,
                    PreviousUC = change.OldUpperLimit,
                    PreviousOpenPrice = null, // Not available in current change object
                    PreviousHighPrice = null,
                    PreviousLowPrice = null,
                    PreviousClosePrice = null,
                    PreviousLastPrice = null,
                    NewLC = change.NewLowerLimit,
                    NewUC = change.NewUpperLimit,
                    NewOpenPrice = null, // Not available in current change object
                    NewHighPrice = null,
                    NewLowPrice = null,
                    NewClosePrice = null,
                    NewLastPrice = null,
                    ChangeTime = change.ChangeTimestamp,
                    IndexOpenPrice = change.SpotOpen,
                    IndexHighPrice = change.SpotHigh,
                    IndexLowPrice = change.SpotLow,
                    IndexClosePrice = change.SpotLastPrice,
                    IndexLastPrice = change.SpotLastPrice,
                    CreatedAt = DateTime.UtcNow.AddHours(5.5)
                };

                await context.CircuitLimitChanges.AddAsync(changeRecord);
                await context.SaveChangesAsync();

                _logger.LogInformation($"Tracked circuit limit change for {change.TriggeredByTradingSymbol ?? "Unknown"} with spot data: O={change.SpotOpen}, H={change.SpotHigh}, L={change.SpotLow}, C={change.SpotLastPrice}, V={change.SpotVolume}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error tracking circuit limit change");
            }
        }

        /// <summary>
        /// Extract underlying symbol from trading symbol
        /// </summary>
        private string GetUnderlyingSymbol(string tradingSymbol)
        {
            // Examples: NIFTY24DEC24000CE -> NIFTY, BANKNIFTY24DEC52000PE -> BANKNIFTY
            if (tradingSymbol.StartsWith("NIFTY") && !tradingSymbol.StartsWith("NIFTYNXT"))
                return "NIFTY";
            else if (tradingSymbol.StartsWith("BANKNIFTY"))
                return "BANKNIFTY";
            else if (tradingSymbol.StartsWith("FINNIFTY"))
                return "FINNIFTY";
            else if (tradingSymbol.StartsWith("MIDCPNIFTY"))
                return "MIDCPNIFTY";
            else if (tradingSymbol.StartsWith("SENSEX"))
                return "SENSEX";
            else
                return tradingSymbol.Split('2')[0]; // Fallback: take part before first '2'
        }

        /// <summary>
        /// Get current circuit limits for an instrument
        /// </summary>
        public async Task<CircuitLimit?> GetCurrentCircuitLimitsAsync(long instrumentToken)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var today = DateTime.Today;

                return await context.CircuitLimits
                    .FirstOrDefaultAsync(cl => cl.InstrumentToken == instrumentToken && cl.TradingDate == today);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting circuit limits for instrument {instrumentToken}");
                return null;
            }
        }

        /// <summary>
        /// Get circuit limits for all instruments of an underlying
        /// </summary>
        public async Task<List<CircuitLimit>> GetCircuitLimitsByUnderlyingAsync(string underlyingSymbol)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var today = DateTime.Today;

                return await context.CircuitLimits
                    .Where(cl => cl.TradingDate == today)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting circuit limits for {underlyingSymbol}");
                return new List<CircuitLimit>();
            }
        }
    }

    // Data models for the smart circuit limits service
    public class TradedAnalysisResult
    {
        public List<Instrument> TradedInstruments { get; set; } = new List<Instrument>();
        public List<Instrument> NonTradedInstruments { get; set; } = new List<Instrument>();
        public int TradedCount { get; set; }
        public int NonTradedCount { get; set; }
        public int TotalCount { get; set; }
    }

    public class CircuitLimitChange
    {
        public string UnderlyingSymbol { get; set; } = string.Empty;
        public decimal OldLowerLimit { get; set; }
        public decimal OldUpperLimit { get; set; }
        public decimal NewLowerLimit { get; set; }
        public decimal NewUpperLimit { get; set; }
        public long TriggeredByInstrumentToken { get; set; }
        public int InstrumentsAffected { get; set; }
        public DateTime ChangeTimestamp { get; set; }

        // Instrument details for better user experience
        public string? TriggeredByTradingSymbol { get; set; }
        public decimal? TriggeredByStrike { get; set; }
        public DateTime? TriggeredByExpiry { get; set; }
        public string? TriggeredByInstrumentType { get; set; }

        // Spot/Index data
        public decimal? SpotOpen { get; set; }
        public decimal? SpotHigh { get; set; }
        public decimal? SpotLow { get; set; }
        public decimal? SpotClose { get; set; }
        public long? SpotVolume { get; set; }
        public decimal? SpotLastPrice { get; set; }
        public decimal? SpotLowerCircuitLimit { get; set; }
        public decimal? SpotUpperCircuitLimit { get; set; }
        public string? SpotInstrumentToken { get; set; }
        public string? SpotTradingSymbol { get; set; }
    }

    public class SpotIndexData
    {
        public string InstrumentToken { get; set; } = string.Empty;
        public string TradingSymbol { get; set; } = string.Empty;
        public decimal Open { get; set; }
        public decimal High { get; set; }
        public decimal Low { get; set; }
        public decimal Close { get; set; }
        public long Volume { get; set; }
        public decimal LastPrice { get; set; }
        public decimal LowerCircuitLimit { get; set; }
        public decimal UpperCircuitLimit { get; set; }
    }

    public class CircuitLimitValue
    {
        public decimal Lower { get; set; }
        public decimal Upper { get; set; }

        public override bool Equals(object? obj)
        {
            if (obj is CircuitLimitValue other)
            {
                return Lower == other.Lower && Upper == other.Upper;
            }
            return false;
        }

        public override int GetHashCode()
        {
            return HashCode.Combine(Lower, Upper);
        }
    }
} 