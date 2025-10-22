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
    /// Service to store Excel export data in flexible database table
    /// </summary>
    public class FlexibleExcelDataService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<FlexibleExcelDataService> _logger;

        public FlexibleExcelDataService(
            IServiceScopeFactory scopeFactory,
            ILogger<FlexibleExcelDataService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Store consolidated Excel export data in flexible database table
        /// </summary>
        public async Task StoreConsolidatedExcelDataAsync(
            DateTime businessDate, 
            DateTime expiryDate, 
            List<MarketQuote> callsData, 
            List<MarketQuote> putsData,
            string filePath)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var exportDateTime = DateTime.UtcNow.AddHours(5.5); // IST

                // Store Calls data
                await StoreOptionTypeDataAsync(context, businessDate, expiryDate, "CE", callsData, exportDateTime, filePath);

                // Store Puts data
                await StoreOptionTypeDataAsync(context, businessDate, expiryDate, "PE", putsData, exportDateTime, filePath);

                await context.SaveChangesAsync();

                _logger.LogInformation($"✅ Stored Excel export data: {callsData.Count} calls + {putsData.Count} puts for {businessDate:yyyy-MM-dd} {expiryDate:dd-MM-yyyy}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"💥 Error storing Excel export data for {businessDate:yyyy-MM-dd} {expiryDate:dd-MM-yyyy}");
            }
        }

        /// <summary>
        /// Store data for a specific option type (Calls or Puts)
        /// </summary>
        private async Task StoreOptionTypeDataAsync(
            MarketDataContext context,
            DateTime businessDate,
            DateTime expiryDate,
            string optionType,
            List<MarketQuote> quotes,
            DateTime exportDateTime,
            string filePath)
        {
            foreach (var quote in quotes)
            {
                // Get all records for this strike
                var allRecords = await GetLCUCChangesForStrikeAsync(context, businessDate, (int)quote.Strike, optionType);

                // Create flexible LC/UC time data - ONLY for actual changes
                var lcucTimeData = new LCUCTimeDataCollection();
                
                // Filter to only include records where LC/UC values actually changed
                var changeRecords = await GetActualLCUCChangeRecordsAsync(allRecords, context, businessDate, (int)quote.Strike, optionType);
                
                foreach (var change in changeRecords)
                {
                    var timeKey = change.RecordDateTime.ToString("HHmm"); // "0915", "1130", etc.
                    var timeString = change.RecordDateTime.ToString("HH:mm:ss"); // "09:15:00"
                    var recordDateTimeString = change.RecordDateTime.ToString("yyyy-MM-dd HH:mm:ss"); // "2025-09-23 08:00:00"
                    
                    lcucTimeData.AddLCUCData(timeKey, timeString, recordDateTimeString, change.LowerCircuitLimit, change.UpperCircuitLimit);
                }

                // Create ExcelExportData record
                var excelData = new ExcelExportData
                {
                    BusinessDate = businessDate,
                    ExpiryDate = expiryDate,
                    Strike = (int)quote.Strike,
                    OptionType = optionType,
                    OpenPrice = quote.OpenPrice,
                    HighPrice = quote.HighPrice,
                    LowPrice = quote.LowPrice,
                    ClosePrice = quote.ClosePrice,
                    LastPrice = quote.LastPrice,
                    LCUCTimeData = lcucTimeData.ToJson(),
                    ExportDateTime = exportDateTime,
                    ExportType = "ConsolidatedLCUC",
                    FilePath = filePath
                };

                context.ExcelExportData.Add(excelData);
            }
        }

        /// <summary>
        /// Get only records where LC/UC values actually changed (compared to previous business day's last record)
        /// </summary>
        private async Task<List<MarketQuote>> GetActualLCUCChangeRecordsAsync(
            List<MarketQuote> allRecords,
            MarketDataContext context,
            DateTime businessDate,
            decimal strike,
            string optionType)
        {
            var changeRecords = new List<MarketQuote>();
            
            if (!allRecords.Any())
                return changeRecords;

            // Get the previous business date
            var previousBusinessDate = GetPreviousBusinessDate(businessDate);

            // Get the last record from previous business day as baseline
            var baselineRecord = await GetLastRecordFromPreviousBusinessDayAsync(context, businessDate, previousBusinessDate, strike, optionType);
            
            // Sort by insertion sequence to get chronological order
            var sortedRecords = allRecords.OrderBy(r => r.InsertionSequence).ToList();
            
            // Always include the first record (baseline for current day)
            changeRecords.Add(sortedRecords.First());
            
            decimal? previousLC = baselineRecord?.LowerCircuitLimit;
            decimal? previousUC = baselineRecord?.UpperCircuitLimit;
            
            foreach (var record in sortedRecords)
            {
                // Check if LC or UC values changed from previous record (including baseline)
                bool lcChanged = previousLC.HasValue && record.LowerCircuitLimit != previousLC.Value;
                bool ucChanged = previousUC.HasValue && record.UpperCircuitLimit != previousUC.Value;
                
                if (lcChanged || ucChanged)
                {
                    changeRecords.Add(record);
                }
                
                previousLC = record.LowerCircuitLimit;
                previousUC = record.UpperCircuitLimit;
            }
            
            return changeRecords.OrderBy(r => r.InsertionSequence).ToList();
        }

        /// <summary>
        /// Get the last record from previous business day as baseline
        /// </summary>
        private async Task<MarketQuote?> GetLastRecordFromPreviousBusinessDayAsync(
            MarketDataContext context, 
            DateTime currentBusinessDate, 
            DateTime previousBusinessDate,
            decimal strike,
            string optionType)
        {
            try
            {
                var baselineRecord = await context.MarketQuotes
                    .Where(q => q.BusinessDate == previousBusinessDate &&
                               q.Strike == strike &&
                               q.OptionType == optionType)
                    .OrderByDescending(q => q.InsertionSequence)
                    .FirstOrDefaultAsync();

                if (baselineRecord != null)
                {
                    _logger.LogInformation($"✅ Found baseline for {strike} {optionType}: LC={baselineRecord.LowerCircuitLimit}, UC={baselineRecord.UpperCircuitLimit} from {previousBusinessDate:yyyy-MM-dd}");
                }
                else
                {
                    _logger.LogWarning($"❌ No baseline found for {strike} {optionType} from {previousBusinessDate:yyyy-MM-dd}");
                }

                return baselineRecord;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to get baseline record for {strike} {optionType} from {previousBusinessDate:yyyy-MM-dd}");
                return null;
            }
        }

        /// <summary>
        /// Get previous business date (skip weekends)
        /// </summary>
        private DateTime GetPreviousBusinessDate(DateTime businessDate)
        {
            var date = businessDate.AddDays(-1);
            
            // Skip weekends (Saturday = 6, Sunday = 0)
            while (date.DayOfWeek == DayOfWeek.Saturday || date.DayOfWeek == DayOfWeek.Sunday)
            {
                date = date.AddDays(-1);
            }
            
            return date;
        }

        /// <summary>
        /// Get all records for a specific strike and option type (used as input for change detection)
        /// </summary>
        private async Task<List<MarketQuote>> GetLCUCChangesForStrikeAsync(
            MarketDataContext context,
            DateTime businessDate,
            int strike,
            string optionType)
        {
            return await context.MarketQuotes
                .Where(q => q.BusinessDate == businessDate &&
                           q.Strike == strike &&
                           q.OptionType == optionType)
                .OrderBy(q => q.InsertionSequence)
                .ToListAsync();
        }

        /// <summary>
        /// Query Excel export data with flexible JSON filtering
        /// </summary>
        public async Task<List<ExcelExportData>> QueryExcelExportDataAsync(
            DateTime? businessDate = null,
            DateTime? expiryDate = null,
            int? strike = null,
            string? optionType = null,
            DateTime? fromDate = null,
            DateTime? toDate = null)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var query = context.ExcelExportData.AsQueryable();

                if (businessDate.HasValue)
                    query = query.Where(e => e.BusinessDate == businessDate.Value);

                if (expiryDate.HasValue)
                    query = query.Where(e => e.ExpiryDate == expiryDate.Value);

                if (strike.HasValue)
                    query = query.Where(e => e.Strike == strike.Value);

                if (!string.IsNullOrEmpty(optionType))
                    query = query.Where(e => e.OptionType == optionType);

                if (fromDate.HasValue)
                    query = query.Where(e => e.ExportDateTime >= fromDate.Value);

                if (toDate.HasValue)
                    query = query.Where(e => e.ExportDateTime <= toDate.Value);

                return await query
                    .OrderBy(e => e.BusinessDate)
                    .ThenBy(e => e.ExpiryDate)
                    .ThenBy(e => e.Strike)
                    .ThenBy(e => e.OptionType)
                    .ToListAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "💥 Error querying Excel export data");
                return new List<ExcelExportData>();
            }
        }

        /// <summary>
        /// Get LC/UC data for a specific strike with time breakdown
        /// </summary>
        public async Task<LCUCTimeDataCollection> GetLCUCDataForStrikeAsync(
            DateTime businessDate,
            DateTime expiryDate,
            int strike,
            string optionType)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var excelData = await context.ExcelExportData
                    .Where(e => e.BusinessDate == businessDate &&
                               e.ExpiryDate == expiryDate &&
                               e.Strike == strike &&
                               e.OptionType == optionType)
                    .OrderByDescending(e => e.ExportDateTime)
                    .FirstOrDefaultAsync();

                if (excelData != null)
                {
                    return LCUCTimeDataCollection.FromJson(excelData.LCUCTimeData);
                }

                return new LCUCTimeDataCollection();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"💥 Error getting LC/UC data for strike {strike} {optionType}");
                return new LCUCTimeDataCollection();
            }
        }
    }
}
