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
    /// Enhanced BusinessDateCalculationService with XML fallback for spot data
    /// </summary>
    public class BusinessDateCalculationServiceWithXML
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<BusinessDateCalculationServiceWithXML> _logger;
        private readonly ManualSpotDataService _manualSpotDataService;

        public BusinessDateCalculationServiceWithXML(
            IServiceScopeFactory scopeFactory,
            ILogger<BusinessDateCalculationServiceWithXML> logger,
            ManualSpotDataService manualSpotDataService)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _manualSpotDataService = manualSpotDataService;
        }

        /// <summary>
        /// Calculate BusinessDate with XML fallback for spot data
        /// </summary>
        public async Task<DateTime?> CalculateBusinessDateAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Step 1: Try to get NIFTY spot data from database
                var spotData = await GetNiftySpotDataAsync(context);
                
                // Step 2: If no database spot data, try XML fallback
                if (spotData == null)
                {
                    _logger.LogWarning("No NIFTY spot data in database, trying XML fallback...");
                    spotData = await _manualSpotDataService.GetNiftySpotDataFromXmlAsync();
                }

                if (spotData != null)
                {
                    // Step 3: Determine spot price (Open if available, else Previous Close)
                    var spotPrice = DetermineSpotPrice(spotData);
                    _logger.LogInformation($"Using spot price: {spotPrice} (from {(spotData.OpenPrice > 0 ? "Open" : "Previous Close")})");

                    // Step 4: Find nearest NIFTY strike to spot price
                    var nearestStrike = await FindNearestNiftyStrikeAsync(context, spotPrice);
                    if (nearestStrike != null)
                    {
                        _logger.LogInformation($"Found nearest strike: {nearestStrike.Strike} for spot price: {spotPrice}");

                        // Step 5: Get LTT from nearest strike and derive BusinessDate
                        var businessDate = GetBusinessDateFromLTT(nearestStrike.LastTradeTime);
                        _logger.LogInformation($"✅ Calculated BusinessDate: {businessDate:yyyy-MM-dd} from LTT: {nearestStrike.LastTradeTime}");
                        return businessDate;
                    }
                    else
                    {
                        _logger.LogWarning($"No nearest strike found for spot price: {spotPrice}");
                    }
                }

                // Step 6: Final fallback - Use XML business date or time-based logic
                _logger.LogWarning("No NIFTY spot data available - using final fallback logic");
                return await GetBusinessDateFromXMLOrTimeBased();
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
        /// Get business date from XML or use time-based logic
        /// </summary>
        private async Task<DateTime> GetBusinessDateFromXMLOrTimeBased()
        {
            try
            {
                // Try to get business date from XML first
                if (_manualSpotDataService.IsXmlFileAvailable())
                {
                    var xmlSpotData = await _manualSpotDataService.GetNiftySpotDataFromXmlAsync();
                    if (xmlSpotData != null)
                    {
                        var xmlBusinessDate = xmlSpotData.RecordDateTime.Date;
                        _logger.LogInformation($"✅ Using XML business date: {xmlBusinessDate:yyyy-MM-dd}");
                        return xmlBusinessDate;
                    }
                }

                // Fallback to time-based logic
                _logger.LogWarning("XML fallback not available - using time-based logic");
                var indianTime = DateTime.Now;
                var timeOnly = indianTime.TimeOfDay;
                var marketOpen = new TimeSpan(9, 15, 0);  // 9:15 AM
                var marketClose = new TimeSpan(15, 30, 0); // 3:30 PM
                var isMarketHours = timeOnly >= marketOpen && timeOnly <= marketClose;
                
                if (isMarketHours)
                {
                    var businessDate = indianTime.Date;
                    _logger.LogInformation($"✅ Time-based: Market is running - using current date: {businessDate:yyyy-MM-dd}");
                    return businessDate;
                }
                else
                {
                    var previousTradingDay = GetPreviousTradingDay(indianTime);
                    _logger.LogInformation($"✅ Time-based: Market is closed - using previous trading day: {previousTradingDay:yyyy-MM-dd}");
                    return previousTradingDay;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get business date from XML or time-based logic");
                return DateTime.Now.Date;
            }
        }

        // ... (rest of the methods remain the same as original BusinessDateCalculationService)
        // I'll include the key methods here for completeness

        private async Task<MarketQuote?> GetNiftySpotDataAsync(MarketDataContext context)
        {
            try
            {
                var today = DateTime.Now.Date;
                var spotData = await context.SpotData
                    .Where(s => s.IndexName == "NIFTY" && s.TradingDate >= today.AddDays(-1))
                    .OrderByDescending(s => s.TradingDate)
                    .ThenByDescending(s => s.QuoteTimestamp)
                    .FirstOrDefaultAsync();

                if (spotData != null)
                {
                    _logger.LogInformation($"✅ Found NIFTY spot data for {spotData.TradingDate:yyyy-MM-dd}: Open={spotData.OpenPrice}, Close={spotData.ClosePrice}");
                    
                    return new MarketQuote
                    {
                        TradingSymbol = spotData.IndexName,
                        OpenPrice = spotData.OpenPrice,
                        HighPrice = spotData.HighPrice,
                        LowPrice = spotData.LowPrice,
                        ClosePrice = spotData.ClosePrice,
                        LastPrice = spotData.LastPrice,
                        RecordDateTime = spotData.QuoteTimestamp
                    };
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get NIFTY spot data from database");
                return null;
            }
        }

        private decimal DetermineSpotPrice(MarketQuote spotData)
        {
            bool isMarketOpen = spotData.OpenPrice > 0 && spotData.HighPrice > 0 && spotData.LowPrice > 0;
            return isMarketOpen ? spotData.OpenPrice : spotData.ClosePrice;
        }

        private async Task<MarketQuote?> FindNearestNiftyStrikeAsync(MarketDataContext context, decimal spotPrice)
        {
            try
            {
                var niftyOptions = await context.MarketQuotes
                    .Where(q => q.TradingSymbol.StartsWith("NIFTY") && 
                               q.TradingSymbol != "NIFTY" &&
                               q.LastTradeTime != DateTime.MinValue &&
                               q.OptionType == "CE")
                    .OrderByDescending(q => q.RecordDateTime)
                    .ToListAsync();

                if (!niftyOptions.Any())
                {
                    return null;
                }

                var nearestStrike = niftyOptions
                    .OrderBy(q => Math.Abs(q.Strike - spotPrice))
                    .First();

                return nearestStrike;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to find nearest NIFTY strike");
                return null;
            }
        }

        private DateTime? GetBusinessDateFromLTT(DateTime? ltt)
        {
            if (!ltt.HasValue)
            {
                return null;
            }
            return ltt.Value.Date;
        }

        private DateTime GetPreviousTradingDay(DateTime currentDate)
        {
            var date = currentDate.Date.AddDays(-1);
            while (date.DayOfWeek == DayOfWeek.Saturday || date.DayOfWeek == DayOfWeek.Sunday)
            {
                date = date.AddDays(-1);
            }
            return date;
        }

        public async Task ApplyBusinessDateToAllQuotesAsync(DateTime businessDate)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var quotesToUpdate = await context.MarketQuotes
                    .Where(q => q.RecordDateTime >= DateTime.Today.AddDays(-1))
                    .ToListAsync();

                if (quotesToUpdate.Any())
                {
                    foreach (var quote in quotesToUpdate)
                    {
                        quote.BusinessDate = businessDate;
                    }

                    await context.SaveChangesAsync();
                    _logger.LogInformation($"Applied BusinessDate {businessDate:yyyy-MM-dd} to {quotesToUpdate.Count} market quotes");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to apply BusinessDate to quotes");
                throw;
            }
        }
    }
}
