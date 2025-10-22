using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service to export daily initial data to Excel files
    /// Creates initial data export even when no LC/UC changes occur
    /// </summary>
    public class DailyInitialDataExportService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<DailyInitialDataExportService> _logger;
        private readonly string _exportPath;

        public DailyInitialDataExportService(
            IServiceScopeFactory scopeFactory,
            ILogger<DailyInitialDataExportService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            
            // Set up export directory for daily initial data
            _exportPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Exports", "DailyInitialData");
            if (!Directory.Exists(_exportPath))
                Directory.CreateDirectory(_exportPath);

            // Set EPPlus license context
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
        }

        /// <summary>
        /// Export initial data for a specific business date
        /// Creates separate files for each index (NIFTY, SENSEX, BANKNIFTY)
        /// </summary>
        public async Task<List<string>> ExportDailyInitialDataAsync(DateTime businessDate)
        {
            var createdFiles = new List<string>();
            
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                _logger.LogInformation($"📊 Creating daily initial data export for BusinessDate: {businessDate:yyyy-MM-dd}");

                // Get all market quotes for the business date
                var allQuotes = await context.MarketQuotes
                    .Where(q => q.BusinessDate == businessDate)
                    .OrderBy(q => q.TradingSymbol)
                    .ThenBy(q => q.Strike)
                    .ThenBy(q => q.OptionType)
                    .ToListAsync();

                if (!allQuotes.Any())
                {
                    _logger.LogWarning($"No data found for BusinessDate: {businessDate:yyyy-MM-dd}");
                    return createdFiles;
                }

                // Group by index (NIFTY, SENSEX, BANKNIFTY)
                var indexGroups = allQuotes
                    .GroupBy(q => GetIndexName(q.TradingSymbol))
                    .Where(g => !string.IsNullOrEmpty(g.Key))
                    .ToList();

                foreach (var indexGroup in indexGroups)
                {
                    var indexName = indexGroup.Key;
                    var quotes = indexGroup.ToList();

                    _logger.LogInformation($"Processing {indexName}: {quotes.Count} quotes");

                    // Create Excel file for this index
                    var fileName = $"{indexName}_InitialData_{businessDate:yyyyMMdd}.xlsx";
                    var filePath = Path.Combine(_exportPath, businessDate.ToString("yyyy-MM-dd"), fileName);
                    
                    // Ensure directory exists
                    var directory = Path.GetDirectoryName(filePath);
                    if (!Directory.Exists(directory))
                        Directory.CreateDirectory(directory!);

                    await CreateInitialDataExcelFileAsync(filePath, quotes, indexName, businessDate);
                    createdFiles.Add(filePath);
                    
                    _logger.LogInformation($"✅ Created initial data file: {fileName}");
                }

                _logger.LogInformation($"📊 Daily initial data export completed: {createdFiles.Count} files created");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to export daily initial data");
            }

            return createdFiles;
        }

        /// <summary>
        /// Create Excel file with initial data for an index
        /// </summary>
        private async Task CreateInitialDataExcelFileAsync(string filePath, List<MarketQuote> quotes, string indexName, DateTime businessDate)
        {
            try
            {
                using var package = new ExcelPackage();
                
                // Group quotes by expiry
                var expiryGroups = quotes
                    .GroupBy(q => q.ExpiryDate.Date)
                    .OrderBy(g => g.Key)
                    .ToList();

                foreach (var expiryGroup in expiryGroups)
                {
                    var expiryDate = expiryGroup.Key;
                    var expiryQuotes = expiryGroup.ToList();

                    // Create sheet for this expiry
                    var sheetName = $"Expiry_{expiryDate:dd-MM-yyyy}";
                    var worksheet = package.Workbook.Worksheets.Add(sheetName);

                    // Create Calls sheet
                    await CreateCallsSheetAsync(worksheet, expiryQuotes.Where(q => q.OptionType == "CE").ToList(), indexName, businessDate, expiryDate);
                    
                    // Add Puts sheet
                    var putsWorksheet = package.Workbook.Worksheets.Add($"{sheetName}_Puts");
                    await CreatePutsSheetAsync(putsWorksheet, expiryQuotes.Where(q => q.OptionType == "PE").ToList(), indexName, businessDate, expiryDate);
                }

                // Save the file
                await package.SaveAsAsync(new FileInfo(filePath));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to create initial data Excel file: {filePath}");
            }
        }

        /// <summary>
        /// Create Calls sheet with initial data
        /// </summary>
        private async Task CreateCallsSheetAsync(ExcelWorksheet worksheet, List<MarketQuote> calls, string indexName, DateTime businessDate, DateTime expiryDate)
        {
            try
            {
                // Headers
                var headers = new[]
                {
                    "BusinessDate", "TradeDate", "Expiry", "Strike", "OptionType",
                    "OpenPrice", "HighPrice", "LowPrice", "ClosePrice", "LastPrice",
                    "LowerCircuitLimit", "UpperCircuitLimit", "RecordDateTime", "InsertionSequence"
                };

                // Add headers
                for (int i = 0; i < headers.Length; i++)
                {
                    worksheet.Cells[1, i + 1].Value = headers[i];
                    worksheet.Cells[1, i + 1].Style.Font.Bold = true;
                    worksheet.Cells[1, i + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    worksheet.Cells[1, i + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
                }

                // Add data (sorted by strike ASC for calls)
                var sortedCalls = calls.OrderBy(c => c.Strike).ToList();
                for (int i = 0; i < sortedCalls.Count; i++)
                {
                    var quote = sortedCalls[i];
                    var row = i + 2;

                    worksheet.Cells[row, 1].Value = quote.BusinessDate.ToString("yyyy-MM-dd");
                    worksheet.Cells[row, 2].Value = quote.RecordDateTime.ToString("yyyy-MM-dd HH:mm:ss");
                    worksheet.Cells[row, 3].Value = quote.ExpiryDate.ToString("yyyy-MM-dd");
                    worksheet.Cells[row, 4].Value = quote.Strike;
                    worksheet.Cells[row, 5].Value = quote.OptionType;
                    worksheet.Cells[row, 6].Value = quote.OpenPrice;
                    worksheet.Cells[row, 7].Value = quote.HighPrice;
                    worksheet.Cells[row, 8].Value = quote.LowPrice;
                    worksheet.Cells[row, 9].Value = quote.ClosePrice;
                    worksheet.Cells[row, 10].Value = quote.LastPrice;
                    worksheet.Cells[row, 11].Value = quote.LowerCircuitLimit;
                    worksheet.Cells[row, 12].Value = quote.UpperCircuitLimit;
                    worksheet.Cells[row, 13].Value = quote.RecordDateTime.ToString("yyyy-MM-dd HH:mm:ss");
                    worksheet.Cells[row, 14].Value = quote.InsertionSequence;
                }

                // Auto-fit columns
                worksheet.Cells.AutoFitColumns();

                // Add title
                worksheet.Cells[1, 1, 1, headers.Length].Merge = true;
                worksheet.Cells[1, 1].Value = $"{indexName} CALLS - Initial Data - {businessDate:yyyy-MM-dd} - Expiry: {expiryDate:dd-MM-yyyy}";
                worksheet.Cells[1, 1].Style.Font.Bold = true;
                worksheet.Cells[1, 1].Style.Font.Size = 14;
                worksheet.Cells[1, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;

                await Task.CompletedTask;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create calls sheet");
            }
        }

        /// <summary>
        /// Create Puts sheet with initial data
        /// </summary>
        private async Task CreatePutsSheetAsync(ExcelWorksheet worksheet, List<MarketQuote> puts, string indexName, DateTime businessDate, DateTime expiryDate)
        {
            try
            {
                // Headers
                var headers = new[]
                {
                    "BusinessDate", "TradeDate", "Expiry", "Strike", "OptionType",
                    "OpenPrice", "HighPrice", "LowPrice", "ClosePrice", "LastPrice",
                    "LowerCircuitLimit", "UpperCircuitLimit", "RecordDateTime", "InsertionSequence"
                };

                // Add headers
                for (int i = 0; i < headers.Length; i++)
                {
                    worksheet.Cells[1, i + 1].Value = headers[i];
                    worksheet.Cells[1, i + 1].Style.Font.Bold = true;
                    worksheet.Cells[1, i + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    worksheet.Cells[1, i + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGreen);
                }

                // Add data (sorted by strike DESC for puts)
                var sortedPuts = puts.OrderByDescending(p => p.Strike).ToList();
                for (int i = 0; i < sortedPuts.Count; i++)
                {
                    var quote = sortedPuts[i];
                    var row = i + 2;

                    worksheet.Cells[row, 1].Value = quote.BusinessDate.ToString("yyyy-MM-dd");
                    worksheet.Cells[row, 2].Value = quote.RecordDateTime.ToString("yyyy-MM-dd HH:mm:ss");
                    worksheet.Cells[row, 3].Value = quote.ExpiryDate.ToString("yyyy-MM-dd");
                    worksheet.Cells[row, 4].Value = quote.Strike;
                    worksheet.Cells[row, 5].Value = quote.OptionType;
                    worksheet.Cells[row, 6].Value = quote.OpenPrice;
                    worksheet.Cells[row, 7].Value = quote.HighPrice;
                    worksheet.Cells[row, 8].Value = quote.LowPrice;
                    worksheet.Cells[row, 9].Value = quote.ClosePrice;
                    worksheet.Cells[row, 10].Value = quote.LastPrice;
                    worksheet.Cells[row, 11].Value = quote.LowerCircuitLimit;
                    worksheet.Cells[row, 12].Value = quote.UpperCircuitLimit;
                    worksheet.Cells[row, 13].Value = quote.RecordDateTime.ToString("yyyy-MM-dd HH:mm:ss");
                    worksheet.Cells[row, 14].Value = quote.InsertionSequence;
                }

                // Auto-fit columns
                worksheet.Cells.AutoFitColumns();

                // Add title
                worksheet.Cells[1, 1, 1, headers.Length].Merge = true;
                worksheet.Cells[1, 1].Value = $"{indexName} PUTS - Initial Data - {businessDate:yyyy-MM-dd} - Expiry: {expiryDate:dd-MM-yyyy}";
                worksheet.Cells[1, 1].Style.Font.Bold = true;
                worksheet.Cells[1, 1].Style.Font.Size = 14;
                worksheet.Cells[1, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;

                await Task.CompletedTask;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create puts sheet");
            }
        }

        /// <summary>
        /// Get index name from trading symbol
        /// </summary>
        private string GetIndexName(string tradingSymbol)
        {
            if (tradingSymbol.StartsWith("NIFTY"))
                return "NIFTY";
            if (tradingSymbol.StartsWith("SENSEX"))
                return "SENSEX";
            if (tradingSymbol.StartsWith("BANKNIFTY"))
                return "BANKNIFTY";
            
            return "";
        }

        /// <summary>
        /// Get the export path for external access
        /// </summary>
        public string GetExportPath()
        {
            return _exportPath;
        }
    }
}
