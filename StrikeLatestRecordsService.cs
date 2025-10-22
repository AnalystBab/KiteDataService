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
    /// Service to maintain only the latest 3 records for each strike
    /// Any given time, only last 3 records for each strike
    /// </summary>
    public class StrikeLatestRecordsService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<StrikeLatestRecordsService> _logger;

        public StrikeLatestRecordsService(
            IServiceScopeFactory scopeFactory,
            ILogger<StrikeLatestRecordsService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Update strike latest records - maintain only latest 3 records per strike
        /// </summary>
        public async Task UpdateStrikeLatestRecordsAsync(List<MarketQuote> newQuotes)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                foreach (var quote in newQuotes)
                {
                    await UpdateSingleStrikeLatestRecordsAsync(context, quote);
                }

                await context.SaveChangesAsync();
                _logger.LogInformation($"Updated latest records for {newQuotes.Count} quotes");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating strike latest records");
                throw;
            }
        }

        /// <summary>
        /// Update latest records for a single strike - maintain exactly 3 records
        /// </summary>
        private async Task UpdateSingleStrikeLatestRecordsAsync(MarketDataContext context, MarketQuote newQuote)
        {
            var strikeKey = new
            {
                TradingSymbol = newQuote.TradingSymbol,
                Strike = newQuote.Strike,
                OptionType = newQuote.OptionType,
                ExpiryDate = newQuote.ExpiryDate
            };

            // Get existing records for this strike (should be 0-3 records)
            var existingRecords = await context.StrikeLatestRecords
                .Where(r => r.TradingSymbol == strikeKey.TradingSymbol &&
                           r.Strike == strikeKey.Strike &&
                           r.OptionType == strikeKey.OptionType &&
                           r.ExpiryDate == strikeKey.ExpiryDate)
                .OrderBy(r => r.RecordOrder)
                .ToListAsync();

            // If we have 3 records, delete the oldest (RecordOrder = 3)
            if (existingRecords.Count >= 3)
            {
                var oldestRecord = existingRecords.FirstOrDefault(r => r.RecordOrder == 3);
                if (oldestRecord != null)
                {
                    context.StrikeLatestRecords.Remove(oldestRecord);
                    _logger.LogDebug($"Deleted oldest record for {strikeKey.TradingSymbol} {strikeKey.Strike} {strikeKey.OptionType}");
                }

                // Shift existing records: 2→3, 1→2
                foreach (var record in existingRecords.Where(r => r.RecordOrder <= 2))
                {
                    record.RecordOrder += 1;
                }
            }

            // Insert new record as latest (RecordOrder = 1)
            var newRecord = new StrikeLatestRecord
            {
                TradingSymbol = newQuote.TradingSymbol,
                Strike = newQuote.Strike,
                OptionType = newQuote.OptionType,
                ExpiryDate = newQuote.ExpiryDate,
                BusinessDate = newQuote.BusinessDate != DateTime.MinValue ? newQuote.BusinessDate : DateTime.UtcNow.AddHours(5.5).Date,
                
                // OHLC Data
                OpenPrice = newQuote.OpenPrice,
                HighPrice = newQuote.HighPrice,
                LowPrice = newQuote.LowPrice,
                ClosePrice = newQuote.ClosePrice,
                LastPrice = newQuote.LastPrice,
                
                // Circuit Limits
                LowerCircuitLimit = newQuote.LowerCircuitLimit,
                UpperCircuitLimit = newQuote.UpperCircuitLimit,
                
                // Timestamps
                RecordDateTime = newQuote.RecordDateTime,
                InsertionSequence = newQuote.InsertionSequence,
                
                // Record Management
                RecordOrder = 1, // Always latest
                CreatedAt = DateTime.UtcNow
            };

            context.StrikeLatestRecords.Add(newRecord);
            
            _logger.LogDebug($"Added new latest record for {strikeKey.TradingSymbol} {strikeKey.Strike} {strikeKey.OptionType} - UC: {newQuote.UpperCircuitLimit}");
        }

        /// <summary>
        /// Get latest records for a specific strike
        /// </summary>
        public async Task<List<StrikeLatestRecord>> GetLatestRecordsForStrikeAsync(
            string tradingSymbol, 
            decimal strike, 
            string optionType, 
            DateTime expiryDate)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            return await context.StrikeLatestRecords
                .Where(r => r.TradingSymbol == tradingSymbol &&
                           r.Strike == strike &&
                           r.OptionType == optionType &&
                           r.ExpiryDate == expiryDate)
                .OrderBy(r => r.RecordOrder)
                .ToListAsync();
        }

        /// <summary>
        /// Get all latest records (RecordOrder = 1) for all strikes
        /// </summary>
        public async Task<List<StrikeLatestRecord>> GetAllLatestRecordsAsync()
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            return await context.StrikeLatestRecords
                .Where(r => r.RecordOrder == 1)
                .OrderBy(r => r.TradingSymbol)
                .ThenBy(r => r.Strike)
                .ThenBy(r => r.OptionType)
                .ToListAsync();
        }

        /// <summary>
        /// Get latest UC values for a specific strike
        /// </summary>
        public async Task<decimal?> GetLatestUCValueAsync(
            string tradingSymbol, 
            decimal strike, 
            string optionType, 
            DateTime expiryDate)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            var latestRecord = await context.StrikeLatestRecords
                .Where(r => r.TradingSymbol == tradingSymbol &&
                           r.Strike == strike &&
                           r.OptionType == optionType &&
                           r.ExpiryDate == expiryDate &&
                           r.RecordOrder == 1)
                .FirstOrDefaultAsync();

            return latestRecord?.UpperCircuitLimit;
        }

        /// <summary>
        /// Get UC change history for a specific strike (last 3 records)
        /// </summary>
        public async Task<List<decimal>> GetUCChangeHistoryAsync(
            string tradingSymbol, 
            decimal strike, 
            string optionType, 
            DateTime expiryDate)
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            var history = await context.StrikeLatestRecords
                .Where(r => r.TradingSymbol == tradingSymbol &&
                           r.Strike == strike &&
                           r.OptionType == optionType &&
                           r.ExpiryDate == expiryDate)
                .OrderBy(r => r.RecordOrder)
                .Select(r => r.UpperCircuitLimit)
                .ToListAsync();
            
            return history.Where(uc => uc.HasValue).Select(uc => uc.Value).ToList();
        }

        /// <summary>
        /// Check if UC value changed for a specific strike
        /// </summary>
        public async Task<bool> HasUCValueChangedAsync(
            string tradingSymbol, 
            decimal strike, 
            string optionType, 
            DateTime expiryDate,
            decimal newUCValue)
        {
            var latestUC = await GetLatestUCValueAsync(tradingSymbol, strike, optionType, expiryDate);
            
            if (latestUC == null)
                return true; // No previous record, so it's a change
            
            return latestUC.Value != newUCValue;
        }

        /// <summary>
        /// Get statistics about the table
        /// </summary>
        public async Task<StrikeLatestRecordsStats> GetStatisticsAsync()
        {
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            var totalRecords = await context.StrikeLatestRecords.CountAsync();
            var uniqueStrikes = await context.StrikeLatestRecords
                .GroupBy(r => new { r.TradingSymbol, r.Strike, r.OptionType, r.ExpiryDate })
                .CountAsync();
            
            var latestRecords = await context.StrikeLatestRecords
                .Where(r => r.RecordOrder == 1)
                .CountAsync();

            return new StrikeLatestRecordsStats
            {
                TotalRecords = totalRecords,
                UniqueStrikes = uniqueStrikes,
                LatestRecords = latestRecords,
                ExpectedRecords = uniqueStrikes * 3
            };
        }
    }

    /// <summary>
    /// Model for strike latest records
    /// </summary>
    public class StrikeLatestRecord
    {
        public long Id { get; set; }
        public string TradingSymbol { get; set; }
        public decimal Strike { get; set; }
        public string OptionType { get; set; }
        public DateTime ExpiryDate { get; set; }
        public DateTime BusinessDate { get; set; }
        
        // OHLC Data
        public decimal? OpenPrice { get; set; }
        public decimal? HighPrice { get; set; }
        public decimal? LowPrice { get; set; }
        public decimal? ClosePrice { get; set; }
        public decimal? LastPrice { get; set; }
        
        // Circuit Limits
        public decimal? LowerCircuitLimit { get; set; }
        public decimal? UpperCircuitLimit { get; set; }
        
        // Timestamps
        public DateTime RecordDateTime { get; set; }
        public int InsertionSequence { get; set; }
        
        // Record Management
        public int RecordOrder { get; set; } // 1=Latest, 2=Second Latest, 3=Oldest
        public DateTime CreatedAt { get; set; }
    }

    /// <summary>
    /// Statistics model
    /// </summary>
    public class StrikeLatestRecordsStats
    {
        public int TotalRecords { get; set; }
        public int UniqueStrikes { get; set; }
        public int LatestRecords { get; set; }
        public int ExpectedRecords { get; set; }
        public bool IsValid => TotalRecords == ExpectedRecords;
    }
}
