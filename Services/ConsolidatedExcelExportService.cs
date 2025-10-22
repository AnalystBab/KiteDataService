using OfficeOpenXml;
using OfficeOpenXml.Style;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service for creating consolidated Excel exports with LC/UC changes over time
    /// One row per strike showing multiple LC/UC values at different times
    /// </summary>
    public class ConsolidatedExcelExportService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<ConsolidatedExcelExportService> _logger;
        private readonly FlexibleExcelDataService _flexibleExcelDataService;

        public ConsolidatedExcelExportService(
            IServiceScopeFactory scopeFactory,
            ILogger<ConsolidatedExcelExportService> logger,
            FlexibleExcelDataService flexibleExcelDataService)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
            _flexibleExcelDataService = flexibleExcelDataService;
        }

        /// <summary>
        /// Create consolidated Excel export for a specific business date
        /// Separate folders for each expiry, separate Excel files for Calls and Puts
        /// </summary>
        public async Task<List<string>> CreateConsolidatedExcelExportAsync(DateTime businessDate)
        {
            var createdFiles = new List<string>();
            
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                _logger.LogInformation($"📊 Creating consolidated Excel export for BusinessDate: {businessDate:yyyy-MM-dd}");

                // Get all market quotes for the business date
                var allQuotes = await context.MarketQuotes
                    .Where(q => q.BusinessDate == businessDate)
                    .OrderBy(q => q.ExpiryDate)
                    .ThenBy(q => q.TradingSymbol)
                    .ThenBy(q => q.Strike)
                    .ThenBy(q => q.InsertionSequence)
                    .ToListAsync();

                if (!allQuotes.Any())
                {
                    _logger.LogWarning($"No data found for BusinessDate: {businessDate:yyyy-MM-dd}");
                    return createdFiles;
                }

                // Group by expiry date
                var quotesByExpiry = allQuotes
                    .GroupBy(q => q.ExpiryDate)
                    .OrderBy(g => g.Key)
                    .ToList();

                // Create one Excel file per expiry with separate sheets for Calls and Puts
                foreach (var expiryGroup in quotesByExpiry)
                {
                    var expiryDate = expiryGroup.Key;
                    var expiryFolderName = $"Expiry_{expiryDate:dd-MM-yyyy}";
                    
                    _logger.LogInformation($"📋 Creating expiry folder: {expiryFolderName}");
                    
                    // Create folder structure: Exports/ConsolidatedLCUC/2025-09-22/Expiry_23-09-2025/
                    var baseDirectory = Path.Combine("Exports", "ConsolidatedLCUC", businessDate.ToString("yyyy-MM-dd"), expiryFolderName);
                    
                    // Ensure directory exists
                    Directory.CreateDirectory(baseDirectory);
                    
                    // Create one Excel file for this expiry
                    var fileName = $"OptionsData_{businessDate:yyyyMMdd}_{expiryDate:ddMMyyyy}.xlsx";
                    var filePath = Path.Combine(baseDirectory, fileName);
                    
                    using var package = new ExcelPackage();
                    
                    // Separate Calls and Puts
                    var calls = expiryGroup.Where(q => q.OptionType == "CE").OrderBy(q => q.Strike).ToList();
                    var puts = expiryGroup.Where(q => q.OptionType == "PE").OrderByDescending(q => q.Strike).ToList();
                    
                    // Create Calls sheet
                    if (calls.Any())
                    {
                        var callsWorksheet = package.Workbook.Worksheets.Add("Calls");
                        await CreateConsolidatedSheetAsync(callsWorksheet, calls, businessDate, expiryDate);
                        _logger.LogInformation($"✅ Calls sheet created with {calls.Count} strikes");
                    }
                    
                    // Create Puts sheet
                    if (puts.Any())
                    {
                        var putsWorksheet = package.Workbook.Worksheets.Add("Puts");
                        await CreateConsolidatedSheetAsync(putsWorksheet, puts, businessDate, expiryDate);
                        _logger.LogInformation($"✅ Puts sheet created with {puts.Count} strikes");
                    }
                    
                    // Save the Excel file
                    await package.SaveAsAsync(new FileInfo(filePath));
                    createdFiles.Add(filePath);
                    
                    _logger.LogInformation($"✅ Excel file created: {filePath}");
                    
                    // Store export data in database for querying
                    try
                    {
                        await _flexibleExcelDataService.StoreConsolidatedExcelDataAsync(
                            businessDate, expiryDate, calls, puts, filePath);
                        _logger.LogInformation($"✅ Excel export data stored in database for {expiryDate:yyyy-MM-dd}");
                    }
                    catch (Exception dbEx)
                    {
                        _logger.LogError(dbEx, $"💥 Failed to store Excel export data in database for {expiryDate:yyyy-MM-dd}");
                        // Continue even if database storage fails - Excel file is still created
                    }
                }
                
                _logger.LogInformation($"✅ Consolidated Excel exports created: {createdFiles.Count} files");
                return createdFiles;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"💥 Error creating consolidated Excel export for {businessDate:yyyy-MM-dd}");
                return createdFiles;
            }
        }

        /// <summary>
        /// Create consolidated sheet with one row per strike showing LC/UC changes over time
        /// </summary>
        private async Task CreateConsolidatedSheetAsync(ExcelWorksheet worksheet, List<MarketQuote> quotes, DateTime businessDate, DateTime expiryDate)
        {
            try
            {
                // Group quotes by strike and option type
                var consolidatedData = quotes
                    .GroupBy(q => new { q.Strike, q.OptionType })
                    .OrderBy(g => g.Key.Strike)
                    .ThenBy(g => g.Key.OptionType)
                    .ToList();

                // Create headers
                var headers = new List<string>
                {
                    "BusinessDate",
                    "Expiry",
                    "Strike",
                    "OptionType",
                    "OpenPrice",
                    "HighPrice", 
                    "LowPrice",
                    "ClosePrice",
                    "LastPrice",
                    "RecordDateTime"
                };

                // Add dynamic LC/UC time columns ONLY when values actually change
                var lcucChangeTimes = await GetLCUCChangeTimesAsync(quotes);
                
                foreach (var changeTime in lcucChangeTimes)
                {
                    headers.Add($"LCUC_TIME_{changeTime:HHmm}"); // Format: LCUC_TIME_0915
                    headers.Add($"LC_{changeTime:HHmm}");         // Format: LC_0915
                    headers.Add($"UC_{changeTime:HHmm}");         // Format: UC_0915
                }

                // Write headers
                for (int i = 0; i < headers.Count; i++)
                {
                    worksheet.Cells[1, i + 1].Value = headers[i];
                    worksheet.Cells[1, i + 1].Style.Font.Bold = true;
                    worksheet.Cells[1, i + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    worksheet.Cells[1, i + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
                }

                // Write data rows
                int row = 2;
                foreach (var strikeGroup in consolidatedData)
                {
                    var strike = strikeGroup.Key.Strike;
                    var optionType = strikeGroup.Key.OptionType;
                    var strikeQuotes = strikeGroup.OrderBy(q => q.InsertionSequence).ToList();

                    // Get the latest quote for basic data
                    var latestQuote = strikeQuotes.Last();

                    // Write basic columns
                    worksheet.Cells[row, 1].Value = businessDate; // BusinessDate
                    worksheet.Cells[row, 1].Style.Numberformat.Format = "dd-mm-yyyy"; // Fix datetime format
                    
                    worksheet.Cells[row, 2].Value = expiryDate; // Expiry
                    worksheet.Cells[row, 2].Style.Numberformat.Format = "dd-mm-yyyy"; // Fix datetime format
                    
                    worksheet.Cells[row, 3].Value = strike;
                    worksheet.Cells[row, 4].Value = optionType;
                    worksheet.Cells[row, 5].Value = latestQuote.OpenPrice;
                    worksheet.Cells[row, 6].Value = latestQuote.HighPrice;
                    worksheet.Cells[row, 7].Value = latestQuote.LowPrice;
                    worksheet.Cells[row, 8].Value = latestQuote.ClosePrice;
                    worksheet.Cells[row, 9].Value = latestQuote.LastPrice;
                    worksheet.Cells[row, 10].Value = latestQuote.RecordDateTime; // RecordDateTime
                    worksheet.Cells[row, 10].Style.Numberformat.Format = "dd-mm-yyyy hh:mm:ss"; // Fix datetime format

                    // Write LC/UC data ONLY for times when values changed
                    // Color code by BusinessDate for easy visual analysis
                    int col = 11; // Start after basic columns (including RecordDateTime)
                    foreach (var changeTime in lcucChangeTimes)
                    {
                        var quoteAtTime = strikeQuotes
                            .Where(q => q.RecordDateTime.Date == changeTime.Date && 
                                       Math.Abs((q.RecordDateTime - changeTime).TotalMinutes) < 30) // Within 30 minutes
                            .OrderByDescending(q => q.InsertionSequence)
                            .FirstOrDefault();

                        if (quoteAtTime != null)
                        {
                            // Determine BusinessDate for this record to assign color
                            var recordBusinessDate = quoteAtTime.BusinessDate;
                            var color = GetBusinessDateColor(recordBusinessDate, businessDate);
                            
                            // LCUC_TIME column - show the actual time
                            worksheet.Cells[row, col].Value = quoteAtTime.RecordDateTime;
                            worksheet.Cells[row, col].Style.Numberformat.Format = "hh:mm:ss";
                            worksheet.Cells[row, col].Style.Fill.PatternType = ExcelFillStyle.Solid;
                            worksheet.Cells[row, col].Style.Fill.BackgroundColor.SetColor(color);
                            
                            // LC column
                            worksheet.Cells[row, col + 1].Value = quoteAtTime.LowerCircuitLimit;
                            worksheet.Cells[row, col + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                            worksheet.Cells[row, col + 1].Style.Fill.BackgroundColor.SetColor(color);
                            
                            // UC column  
                            worksheet.Cells[row, col + 2].Value = quoteAtTime.UpperCircuitLimit;
                            worksheet.Cells[row, col + 2].Style.Fill.PatternType = ExcelFillStyle.Solid;
                            worksheet.Cells[row, col + 2].Style.Fill.BackgroundColor.SetColor(color);
                        }
                        else
                        {
                            // No data for this time - leave empty
                            worksheet.Cells[row, col].Value = "";
                            worksheet.Cells[row, col + 1].Value = "";
                            worksheet.Cells[row, col + 2].Value = "";
                        }

                        col += 3; // Move to next time group
                    }

                    row++;
                }

                // Auto-fit columns
                worksheet.Cells[worksheet.Dimension.Address].AutoFitColumns();

                // Add borders
                using (var range = worksheet.Cells[1, 1, row - 1, headers.Count])
                {
                    range.Style.Border.Top.Style = ExcelBorderStyle.Thin;
                    range.Style.Border.Left.Style = ExcelBorderStyle.Thin;
                    range.Style.Border.Right.Style = ExcelBorderStyle.Thin;
                    range.Style.Border.Bottom.Style = ExcelBorderStyle.Thin;
                }

                // Add color legend at the bottom
                AddColorLegend(worksheet, row, headers.Count);

                // Freeze header row
                worksheet.View.FreezePanes(2, 1);

                _logger.LogInformation($"📊 Sheet '{worksheet.Name}' created with {consolidatedData.Count} strikes");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"💥 Error creating consolidated sheet for {expiryDate:yyyy-MM-dd}");
            }
        }

        /// <summary>
        /// Get times when LC/UC values actually changed (compared to previous business day's last record)
        /// </summary>
        private async Task<List<DateTime>> GetLCUCChangeTimesAsync(List<MarketQuote> quotes)
        {
            var changeTimes = new List<DateTime>();
            
            if (!quotes.Any())
                return changeTimes;

            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            // Get the business date of the quotes
            var businessDate = quotes.First().BusinessDate;
            var previousBusinessDate = GetPreviousBusinessDate(businessDate);

            // Get the last record from previous business day as baseline
            var baselineRecord = await GetLastRecordFromPreviousBusinessDayAsync(context, businessDate, previousBusinessDate, quotes.First().Strike, quotes.First().OptionType);
            
            // Sort quotes by insertion sequence to get chronological order
            var sortedQuotes = quotes.OrderBy(q => q.InsertionSequence).ToList();
            
            // Always include the first record (baseline for current day)
            changeTimes.Add(sortedQuotes.First().RecordDateTime);
            
            decimal? previousLC = baselineRecord?.LowerCircuitLimit;
            decimal? previousUC = baselineRecord?.UpperCircuitLimit;
            
            foreach (var quote in sortedQuotes)
            {
                // Check if LC or UC values changed from previous record (including baseline)
                bool lcChanged = previousLC.HasValue && quote.LowerCircuitLimit != previousLC.Value;
                bool ucChanged = previousUC.HasValue && quote.UpperCircuitLimit != previousUC.Value;
                
                if (lcChanged || ucChanged)
                {
                    changeTimes.Add(quote.RecordDateTime);
                }
                
                previousLC = quote.LowerCircuitLimit;
                previousUC = quote.UpperCircuitLimit;
            }
            
            return changeTimes.OrderBy(t => t).ToList();
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
        /// Create daily consolidated export (called when LC/UC changes are detected)
        /// </summary>
        public async Task CreateDailyConsolidatedExportAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get the current business date from MarketQuotes
                var currentBusinessDate = await context.MarketQuotes
                    .Where(q => q.BusinessDate != DateTime.MinValue)
                    .OrderByDescending(q => q.BusinessDate)
                    .Select(q => q.BusinessDate)
                    .FirstOrDefaultAsync();

                if (currentBusinessDate == DateTime.MinValue)
                {
                    _logger.LogWarning("⚠️ No business date found in MarketQuotes - cannot create export");
                    return;
                }
                
                _logger.LogInformation($"🔄 Starting consolidated export for current business date: {currentBusinessDate:yyyy-MM-dd}");
                
                var createdFiles = await CreateConsolidatedExcelExportAsync(currentBusinessDate);
                
                if (createdFiles.Any())
                {
                    _logger.LogInformation($"✅ Consolidated export completed: {createdFiles.Count} files created");
                    foreach (var file in createdFiles)
                    {
                        _logger.LogInformation($"  📄 {file}");
                    }
                }
                else
                {
                    _logger.LogWarning($"⚠️ Consolidated export failed for: {currentBusinessDate:yyyy-MM-dd}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "💥 Error in consolidated export");
            }
        }

        /// <summary>
        /// Get color for BusinessDate to visually distinguish data from different business days
        /// </summary>
        private Color GetBusinessDateColor(DateTime recordBusinessDate, DateTime currentExportBusinessDate)
        {
            // Calculate how many business days back this record is from current export date
            int daysBack = (currentExportBusinessDate - recordBusinessDate).Days;
            
            // Color scheme for different business dates
            if (daysBack == 0)
            {
                // Current business day - Light Green
                return Color.FromArgb(198, 239, 206); // Light green
            }
            else if (daysBack == 1)
            {
                // Previous business day (baseline) - Light Blue
                return Color.FromArgb(180, 198, 231); // Light blue
            }
            else if (daysBack == 2)
            {
                // 2 days back - Light Yellow
                return Color.FromArgb(255, 235, 156); // Light yellow
            }
            else if (daysBack == 3)
            {
                // 3 days back - Light Orange
                return Color.FromArgb(252, 213, 180); // Light orange
            }
            else if (daysBack >= 4)
            {
                // 4+ days back - Light Pink
                return Color.FromArgb(244, 204, 204); // Light pink
            }
            else
            {
                // Future date (shouldn't happen) - White
                return Color.White;
            }
        }

        /// <summary>
        /// Add color legend to explain BusinessDate color coding
        /// </summary>
        private void AddColorLegend(ExcelWorksheet worksheet, int startRow, int totalColumns)
        {
            try
            {
                int legendRow = startRow + 2; // Leave a blank row
                
                // Legend title
                worksheet.Cells[legendRow, 1].Value = "COLOR LEGEND (BusinessDate):";
                worksheet.Cells[legendRow, 1].Style.Font.Bold = true;
                worksheet.Cells[legendRow, 1].Style.Font.Size = 11;
                
                legendRow++;
                
                // Current business day
                worksheet.Cells[legendRow, 1].Value = "Current Business Day";
                worksheet.Cells[legendRow, 2].Style.Fill.PatternType = ExcelFillStyle.Solid;
                worksheet.Cells[legendRow, 2].Style.Fill.BackgroundColor.SetColor(Color.FromArgb(198, 239, 206));
                legendRow++;
                
                // Previous business day (baseline)
                worksheet.Cells[legendRow, 1].Value = "Previous Business Day (Baseline)";
                worksheet.Cells[legendRow, 2].Style.Fill.PatternType = ExcelFillStyle.Solid;
                worksheet.Cells[legendRow, 2].Style.Fill.BackgroundColor.SetColor(Color.FromArgb(180, 198, 231));
                legendRow++;
                
                // 2 days back
                worksheet.Cells[legendRow, 1].Value = "2 Days Back";
                worksheet.Cells[legendRow, 2].Style.Fill.PatternType = ExcelFillStyle.Solid;
                worksheet.Cells[legendRow, 2].Style.Fill.BackgroundColor.SetColor(Color.FromArgb(255, 235, 156));
                legendRow++;
                
                // 3 days back
                worksheet.Cells[legendRow, 1].Value = "3 Days Back";
                worksheet.Cells[legendRow, 2].Style.Fill.PatternType = ExcelFillStyle.Solid;
                worksheet.Cells[legendRow, 2].Style.Fill.BackgroundColor.SetColor(Color.FromArgb(252, 213, 180));
                legendRow++;
                
                // 4+ days back
                worksheet.Cells[legendRow, 1].Value = "4+ Days Back";
                worksheet.Cells[legendRow, 2].Style.Fill.PatternType = ExcelFillStyle.Solid;
                worksheet.Cells[legendRow, 2].Style.Fill.BackgroundColor.SetColor(Color.FromArgb(244, 204, 204));
                
                _logger.LogInformation("✅ Color legend added to Excel sheet");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to add color legend");
            }
        }
    }
}
