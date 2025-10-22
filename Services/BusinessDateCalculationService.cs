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
    /// <summary>
    /// Service to calculate BusinessDate based on spot price and nearest strike LTT logic
    /// </summary>
    public class BusinessDateCalculationService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<BusinessDateCalculationService> _logger;
        private readonly ManualNiftySpotDataService _manualSpotDataService;

        public BusinessDateCalculationService(
            IServiceScopeFactory scopeFactory,
            ILogger<BusinessDateCalculationService> logger,
            ManualNiftySpotDataService manualSpotDataService)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _manualSpotDataService = manualSpotDataService;
        }

        /// <summary>
        /// Calculate BusinessDate for all market quotes based on spot price logic
        /// </summary>
        public async Task<DateTime?> CalculateBusinessDateAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // PRIORITY 1: Try to get BusinessDate from NIFTY spot data → nearest strike → LTT
                var spotData = await GetNiftySpotDataAsync(context);
                if (spotData != null)
                {
                    // Determine spot price (Open if available, else Previous Close)
                    var spotPrice = DetermineSpotPrice(spotData);
                    _logger.LogInformation($"Using spot price: {spotPrice} (from {(spotData.OpenPrice > 0 ? "Open" : "Previous Close")})");

                    // Find nearest NIFTY strike to spot price
                    var nearestStrike = await FindNearestNiftyStrikeAsync(context, spotPrice);
                    if (nearestStrike != null && nearestStrike.LastTradeTime != DateTime.MinValue)
                    {
                        // Get BusinessDate from nearest strike's LTT (THIS IS THE PRIMARY LOGIC)
                        var businessDate = GetBusinessDateFromLTT(nearestStrike.LastTradeTime);
                        if (businessDate.HasValue)
                        {
                            _logger.LogInformation($"✅ Calculated BusinessDate: {businessDate:yyyy-MM-dd} from nearest strike LTT: {nearestStrike.LastTradeTime}");
                            return businessDate;
                        }
                    }
                }

                // PRIORITY 2: Use NIFTY spot's last_trade_time from HistoricalSpotData
                // This is the most recent data we have, which tells us the actual business date
                _logger.LogInformation("⚠️ FALLBACK: NIFTY spot data not available or no valid LTT from strikes");
                
                // Try to get the most recent NIFTY data from HistoricalSpotData
                var recentSpotData = await context.HistoricalSpotData
                    .Where(s => s.IndexName == "NIFTY")
                    .OrderByDescending(s => s.TradingDate)
                    .ThenByDescending(s => s.LastUpdated)
                    .FirstOrDefaultAsync();
                
                if (recentSpotData != null)
                {
                    // Use the trading date from the most recent spot data
                    var businessDate = recentSpotData.TradingDate;
                    _logger.LogInformation($"✅ FALLBACK: Using TradingDate from recent NIFTY spot data: {businessDate:yyyy-MM-dd} (Last Updated: {recentSpotData.LastUpdated})");
                    return businessDate;
                }
                
                // FINAL FALLBACK: Use previous trading day (safest assumption when no data available)
                var fallbackDate = GetPreviousTradingDay(DateTime.Now);
                _logger.LogWarning($"⚠️ FINAL FALLBACK: No spot data available - using previous trading day: {fallbackDate:yyyy-MM-dd}");
                return fallbackDate;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to calculate BusinessDate");
                
                // Final fallback - use current date
                var fallbackDate = DateTime.Now.Date;
                _logger.LogWarning($"Final fallback: Using current date as BusinessDate: {fallbackDate:yyyy-MM-dd}");
                return fallbackDate;
            }
        }

        /// <summary>
        /// Get NIFTY spot data from database (reliable historical data stored before/after market hours)
        /// NO XML file logic - only database-based spot data
        /// AFTER MARKET CLOSE: Returns TODAY's data (if available)
        /// BEFORE MARKET OPEN: Returns YESTERDAY's data
        /// </summary>
        private async Task<MarketQuote?> GetNiftySpotDataAsync(MarketDataContext context)
        {
            try
            {
                // Get the most recent NIFTY spot data from HistoricalSpotData table
                var today = DateTime.Now.Date;
                var currentTime = DateTime.Now.TimeOfDay;
                var marketClose = new TimeSpan(15, 30, 0); // 3:30 PM
                
                // CRITICAL: After market close, we should have TODAY's historical data available
                var lookbackDays = currentTime > marketClose ? 0 : -1; // Today if after close, yesterday if before
                
                var spotData = await context.HistoricalSpotData
                    .Where(s => s.IndexName == "NIFTY" && s.TradingDate >= today.AddDays(-2)) // Look back 2 days to be safe
                    .OrderByDescending(s => s.TradingDate)
                    .FirstOrDefaultAsync();

                if (spotData != null)
                {
                    var dataAge = spotData.TradingDate == today ? "TODAY" : 
                                 spotData.TradingDate == today.AddDays(-1) ? "YESTERDAY" : 
                                 $"{(today - spotData.TradingDate).Days} days old";
                    
                    _logger.LogInformation($"✅ Using NIFTY spot data from HISTORICAL DATABASE for {spotData.TradingDate:yyyy-MM-dd} ({dataAge}): Open={spotData.OpenPrice}, Close={spotData.ClosePrice}");
                    
                    // Convert HistoricalSpotData to MarketQuote format
                    var marketQuote = new MarketQuote
                    {
                        TradingSymbol = spotData.IndexName,
                        OpenPrice = spotData.OpenPrice,
                        HighPrice = spotData.HighPrice,
                        LowPrice = spotData.LowPrice,
                        ClosePrice = spotData.ClosePrice,
                        LastPrice = spotData.ClosePrice, // Use close price as last price for historical data
                        RecordDateTime = DateTime.Now // Current time for the quote
                    };
                    
                    return marketQuote;
                }

                _logger.LogWarning("❌ No NIFTY spot data found in HistoricalSpotData table");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get NIFTY spot data from database");
                return null;
            }
        }

        /// <summary>
        /// Get the latest NIFTY close price from available data sources
        /// </summary>
        private async Task<decimal> GetLatestNiftyClosePriceAsync(MarketDataContext context)
        {
            try
            {
                // Method 1: Try to get from Kite historical API (if available)
                // This would be the most accurate source
                var historicalClosePrice = await GetNiftyCloseFromHistoricalAPIAsync();
                if (historicalClosePrice > 0)
                {
                    _logger.LogInformation($"Got NIFTY close price from historical API: {historicalClosePrice}");
                    return historicalClosePrice;
                }

                // Method 2: Try to derive from current options data
                // Look for ATM (At-The-Money) options and estimate spot price
                var estimatedSpotPrice = await EstimateSpotFromOptionsDataAsync(context);
                if (estimatedSpotPrice > 0)
                {
                    _logger.LogInformation($"Estimated NIFTY spot price from options data: {estimatedSpotPrice}");
                    return estimatedSpotPrice;
                }

                // Method 3: Use the most recent close price from any NIFTY data
                var recentClose = await context.MarketQuotes
                    .Where(q => q.TradingSymbol.StartsWith("NIFTY") && q.ClosePrice > 0)
                    .OrderByDescending(q => q.RecordDateTime)
                    .Select(q => q.ClosePrice)
                    .FirstOrDefaultAsync();

                if (recentClose > 0)
                {
                    _logger.LogInformation($"Using recent close price from available data: {recentClose}");
                    return recentClose;
                }

                _logger.LogWarning("Could not determine NIFTY close price from any available source");
                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get latest NIFTY close price");
                return 0;
            }
        }

        /// <summary>
        /// Get NIFTY close price from historical API (placeholder for future implementation)
        /// </summary>
        private async Task<decimal> GetNiftyCloseFromHistoricalAPIAsync()
        {
            try
            {
                // TODO: Implement Kite historical API call to get NIFTY close price
                // This would call Kite Connect historical API for NIFTY index data
                // For now, return 0 to indicate not available
                await Task.CompletedTask;
                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get NIFTY close from historical API");
                return 0;
            }
        }

        /// <summary>
        /// Estimate spot price from options data (ATM options)
        /// </summary>
        private async Task<decimal> EstimateSpotFromOptionsDataAsync(MarketDataContext context)
        {
            try
            {
                // Get recent NIFTY options data
                var recentOptions = await context.MarketQuotes
                    .Where(q => q.TradingSymbol.StartsWith("NIFTY") && 
                               q.TradingSymbol != "NIFTY" &&
                               q.OptionType == "CE" &&
                               q.LastPrice > 0)
                    .OrderByDescending(q => q.RecordDateTime)
                    .Take(100)
                    .ToListAsync();

                if (!recentOptions.Any())
                {
                    return 0;
                }

                // Find the strike closest to current price (simple approach for LC/UC monitoring)
                var currentPrice = recentOptions.FirstOrDefault()?.LastPrice ?? 0;
                var atmStrike = recentOptions
                    .OrderBy(q => Math.Abs(q.Strike - currentPrice))
                    .FirstOrDefault()?.Strike ?? 0;

                if (atmStrike > 0)
                {
                    _logger.LogInformation($"Estimated ATM strike from options data: {atmStrike}");
                    return atmStrike;
                }

                return 0;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to estimate spot price from options data");
                return 0;
            }
        }

        /// <summary>
        /// Determine spot price based on market conditions
        /// Market Open: Use OpenPrice if > 0
        /// Market Closed: Use Previous Close (when Open=0, High=0, Low=0)
        /// </summary>
        private decimal DetermineSpotPrice(MarketQuote spotData)
        {
            // Check if market is open (Open, High, Low > 0)
            bool isMarketOpen = spotData.OpenPrice > 0 && spotData.HighPrice > 0 && spotData.LowPrice > 0;

            if (isMarketOpen)
            {
                _logger.LogDebug("Market is open - using OpenPrice");
                return spotData.OpenPrice;
            }
            else
            {
                _logger.LogDebug("Market is closed - using Previous Close");
                // Use Previous Close when market is closed
                return spotData.ClosePrice;
            }
        }

        /// <summary>
        /// Find the nearest NIFTY strike to the spot price
        /// Considers 50-point strike gaps for NIFTY
        /// </summary>
        private async Task<MarketQuote?> FindNearestNiftyStrikeAsync(MarketDataContext context, decimal spotPrice)
        {
            try
            {
                // Get all NIFTY options with valid LTT
                var niftyOptions = await context.MarketQuotes
                    .Where(q => q.TradingSymbol.StartsWith("NIFTY") && 
                               q.TradingSymbol != "NIFTY" && // Exclude spot
                               q.LastTradeTime != DateTime.MinValue &&
                               q.OptionType == "CE") // Start with CE options
                    .OrderByDescending(q => q.RecordDateTime)
                    .ToListAsync();

                if (!niftyOptions.Any())
                {
                    _logger.LogWarning("No NIFTY options found with valid LTT");
                    return null;
                }

                // Group by strike to get unique strikes with latest LTT
                var strikesWithLTT = niftyOptions
                    .GroupBy(q => q.Strike)
                    .Select(g => g.OrderByDescending(q => q.RecordDateTime).First())
                    .Where(q => q.LastTradeTime != DateTime.MinValue)
                    .ToList();

                if (!strikesWithLTT.Any())
                {
                    _logger.LogWarning("No NIFTY strikes found with valid LTT");
                    return null;
                }

                // Find nearest strike (considering 50-point gaps)
                var nearestStrike = strikesWithLTT
                    .OrderBy(q => Math.Abs(q.Strike - spotPrice))
                    .First();

                _logger.LogInformation($"Found nearest strike to spot {spotPrice}: {nearestStrike.Strike} (LTT: {nearestStrike.LastTradeTime})");

                return nearestStrike;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to find nearest NIFTY strike");
                return null;
            }
        }

        /// <summary>
        /// Get BusinessDate from LTT (Last Trade Time)
        /// </summary>
        private DateTime? GetBusinessDateFromLTT(DateTime? ltt)
        {
            if (!ltt.HasValue)
            {
                _logger.LogWarning("No LTT available - cannot determine BusinessDate");
                return null;
            }

            // BusinessDate is the date part of LTT
            var businessDate = ltt.Value.Date;
            _logger.LogDebug($"BusinessDate derived from LTT {ltt}: {businessDate:yyyy-MM-dd}");
            
            return businessDate;
        }

        /// <summary>
        /// Apply BusinessDate to all market quotes in the database
        /// </summary>
        public async Task ApplyBusinessDateToAllQuotesAsync(DateTime businessDate)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Update ALL quotes to use the same BusinessDate (universal for all instruments)
                // This ensures NIFTY, SENSEX, BANKNIFTY, etc. all have the same BusinessDate
                var quotesToUpdate = await context.MarketQuotes
                    .Where(q => q.RecordDateTime >= DateTime.Today.AddDays(-1)) // Only recent quotes
                    .ToListAsync();

                if (quotesToUpdate.Any())
                {
                    foreach (var quote in quotesToUpdate)
                    {
                        quote.BusinessDate = businessDate;
                    }

                    await context.SaveChangesAsync();
                    _logger.LogInformation($"Applied BusinessDate {businessDate:yyyy-MM-dd} to {quotesToUpdate.Count} market quotes (universal for all instruments)");
                }
                else
                {
                    _logger.LogInformation("No quotes need BusinessDate update");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to apply BusinessDate to quotes");
                throw;
            }
        }

        /// <summary>
        /// Apply BusinessDate to new market quotes
        /// </summary>
        public void ApplyBusinessDateToQuotes(List<MarketQuote> quotes, DateTime businessDate)
        {
            try
            {
                foreach (var quote in quotes)
                {
                    if (quote.BusinessDate == DateTime.MinValue)
                    {
                        quote.BusinessDate = businessDate;
                    }
                }

                _logger.LogDebug($"Applied BusinessDate {businessDate:yyyy-MM-dd} to {quotes.Count} new quotes");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to apply BusinessDate to new quotes");
                throw;
            }
        }

        /// <summary>
        /// Get the previous trading day (skip weekends)
        /// </summary>
        private DateTime GetPreviousTradingDay(DateTime currentDate)
        {
            var date = currentDate.Date.AddDays(-1);
            
            // Skip weekends (Saturday = 6, Sunday = 0)
            while (date.DayOfWeek == DayOfWeek.Saturday || date.DayOfWeek == DayOfWeek.Sunday)
            {
                date = date.AddDays(-1);
            }
            
            return date;
        }

    }
}
