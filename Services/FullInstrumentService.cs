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
    public class FullInstrumentService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<FullInstrumentService> _logger;

        public FullInstrumentService(IServiceScopeFactory scopeFactory, ILogger<FullInstrumentService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Save all instruments to FullInstruments table
        /// </summary>
        public async Task SaveAllInstrumentsAsync(List<Instrument> instruments)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Clear existing data
                await context.Database.ExecuteSqlRawAsync("DELETE FROM FullInstruments");

                // Convert to FullInstrument entities
                var fullInstruments = instruments.Select(i => new FullInstrument
                {
                    InstrumentToken = i.InstrumentToken,
                    ExchangeToken = i.ExchangeToken,
                    TradingSymbol = i.TradingSymbol,
                    Name = i.Name,
                    LastPrice = i.LastPrice,
                    Expiry = i.Expiry,
                    Strike = i.Strike,
                    TickSize = i.TickSize,
                    LotSize = i.LotSize,
                    InstrumentType = i.InstrumentType,
                    Segment = i.Segment,
                    Exchange = i.Exchange,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now,
                    IsIndex = IsIndexInstrument(i),
                    IndexName = GetIndexName(i)
                }).ToList();

                // Add all instruments
                context.FullInstruments.AddRange(fullInstruments);
                await context.SaveChangesAsync();

                _logger.LogInformation($"Saved {fullInstruments.Count} instruments to FullInstruments table");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to save instruments to FullInstruments table");
                throw;
            }
        }

        /// <summary>
        /// Get INDEX instruments from FullInstruments table
        /// </summary>
        public async Task<List<Instrument>> GetIndexInstrumentsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var indexInstruments = await context.FullInstruments
                    .Where(fi => fi.IsIndex == true)
                    .Select(fi => new Instrument
                    {
                        InstrumentToken = fi.InstrumentToken,
                        ExchangeToken = fi.ExchangeToken,
                        TradingSymbol = fi.TradingSymbol,
                        Name = fi.Name,
                        LastPrice = fi.LastPrice,
                        Expiry = fi.Expiry,
                        Strike = fi.Strike,
                        TickSize = fi.TickSize,
                        LotSize = fi.LotSize,
                        InstrumentType = fi.InstrumentType ?? "INDEX",
                        Segment = fi.Segment,
                        Exchange = fi.Exchange,
                        CreatedAt = fi.CreatedAt,
                        UpdatedAt = fi.UpdatedAt
                    })
                    .ToListAsync();

                _logger.LogInformation($"Found {indexInstruments.Count} INDEX instruments");
                return indexInstruments;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get INDEX instruments from FullInstruments table");
                return new List<Instrument>();
            }
        }

        /// <summary>
        /// Check if an instrument is an INDEX instrument (actual INDEX or current month FUTURES as proxy)
        /// </summary>
        private bool IsIndexInstrument(Instrument instrument)
        {
            // INDEX instruments can be:
            // 1. Actual INDEX instruments (NIFTY 50, SENSEX) - InstrumentType = "EQ", Segment = "INDICES"
            // 2. Current month FUTURES as proxies for indices that don't have direct INDEX instruments (BANKNIFTY, FINNIFTY, MIDCPNIFTY)
            
            var allowedPrefixes = new[] { "NIFTY", "BANKNIFTY", "FINNIFTY", "MIDCPNIFTY", "SENSEX" };
            
            // Check if it's a base index symbol (not a derivative)
            var isBaseIndex = allowedPrefixes.Any(prefix => 
                instrument.TradingSymbol.Equals(prefix, StringComparison.OrdinalIgnoreCase) ||
                instrument.TradingSymbol.Equals($"{prefix} 50", StringComparison.OrdinalIgnoreCase) ||
                instrument.TradingSymbol.Equals($"{prefix} 100", StringComparison.OrdinalIgnoreCase) ||
                instrument.TradingSymbol.Equals($"{prefix} 200", StringComparison.OrdinalIgnoreCase) ||
                instrument.TradingSymbol.Equals($"{prefix} 500", StringComparison.OrdinalIgnoreCase));
            
            // For actual INDEX instruments (NIFTY 50, SENSEX)
            var isActualIndex = isBaseIndex &&
                               instrument.Strike == 0 &&
                               (instrument.InstrumentType == "EQ" && instrument.Segment == "INDICES") &&
                               !instrument.TradingSymbol.Contains("CE") &&
                               !instrument.TradingSymbol.Contains("PE") &&
                               !instrument.TradingSymbol.Contains("FUT") &&
                               !instrument.TradingSymbol.StartsWith("NIFTYNXT");
            
            // For FUTURES as INDEX proxies (BANKNIFTY, FINNIFTY, MIDCPNIFTY)
            var isFutureProxy = instrument.InstrumentType == "FUT" &&
                               instrument.Strike == 0 &&
                               (instrument.TradingSymbol.Contains("BANKNIFTY") ||
                                instrument.TradingSymbol.Contains("FINNIFTY") ||
                                instrument.TradingSymbol.Contains("MIDCPNIFTY")) &&
                               (instrument.TradingSymbol.Contains("25SEP") || 
                                instrument.TradingSymbol.Contains("25OCT") || 
                                instrument.TradingSymbol.Contains("25NOV") ||
                                instrument.TradingSymbol.Contains("25DEC")) &&
                               !instrument.TradingSymbol.Contains("CE") &&
                               !instrument.TradingSymbol.Contains("PE");
            
            return isActualIndex || isFutureProxy;
        }

        /// <summary>
        /// Get the base index name from instrument symbol
        /// </summary>
        private string? GetIndexName(Instrument instrument)
        {
            var symbol = instrument.TradingSymbol;
            
            // Handle exact matches for actual INDEX instruments
            if (symbol.Equals("NIFTY 50", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (symbol.Equals("NIFTY 100", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (symbol.Equals("NIFTY 200", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (symbol.Equals("NIFTY 500", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (symbol.Equals("SENSEX", StringComparison.OrdinalIgnoreCase)) return "SENSEX";
            
            // Handle prefix matches for both actual INDEX and FUTURES proxy
            if (symbol.StartsWith("NIFTY", StringComparison.OrdinalIgnoreCase) && 
                !symbol.StartsWith("NIFTYNXT", StringComparison.OrdinalIgnoreCase)) return "NIFTY";
            if (symbol.StartsWith("BANKNIFTY", StringComparison.OrdinalIgnoreCase)) return "BANKNIFTY";
            if (symbol.StartsWith("FINNIFTY", StringComparison.OrdinalIgnoreCase)) return "FINNIFTY";
            if (symbol.StartsWith("MIDCPNIFTY", StringComparison.OrdinalIgnoreCase)) return "MIDCPNIFTY";
            if (symbol.StartsWith("SENSEX", StringComparison.OrdinalIgnoreCase)) return "SENSEX";
            
            return null;
        }
    }
}
