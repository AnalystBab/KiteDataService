using System;
using System.Collections.Generic;
using System.Data;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Data.SqlClient;
using OfficeOpenXml;
using OfficeOpenXml.Style;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service to export options data to Excel files
    /// </summary>
    public class ExcelExportService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<ExcelExportService> _logger;
        private readonly string _exportPath;

        public ExcelExportService(
            IConfiguration configuration,
            ILogger<ExcelExportService> logger)
        {
            _configuration = configuration;
            _logger = logger;
            
            // Set up export directory - Original format goes to TraditionalExports folder
            _exportPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Exports", "TraditionalExports");
            if (!Directory.Exists(_exportPath))
                Directory.CreateDirectory(_exportPath);

            // Set EPPlus license context
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
        }

        /// <summary>
        /// Get the export path for external access
        /// </summary>
        public string GetExportPath()
        {
            return _exportPath;
        }

        /// <summary>
        /// Export business day data with custom format (separate sheets per expiry)
        /// </summary>
        public async Task<string> ExportBusinessDayDataWithCustomFormatAsync(DateTime businessDate, string filePath)
        {
            try
            {
                _logger.LogInformation($"Exporting business day data for {businessDate:yyyy-MM-dd} with custom format");

                using var package = new ExcelPackage();
                
                // Get all expiries for this business date
                var expiries = await GetExpiryDatesFromDatabaseAsync(businessDate);
                
                foreach (var expiry in expiries)
                {
                    // Create sheet for each expiry
                    var sheetName = $"Expiry_{expiry:yyyyMMdd}";
                    var worksheet = package.Workbook.Worksheets.Add(sheetName);
                    
                    // Get data for this expiry with custom columns
                    await CreateCustomFormatSheetAsync(worksheet, businessDate, expiry);
                }

                // Save the file
                await package.SaveAsAsync(new FileInfo(filePath));
                
                _logger.LogInformation($"Business day data exported successfully to: {filePath}");
                return filePath;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to export business day data with custom format");
                throw;
            }
        }

        /// <summary>
        /// Export options data to Excel file for a specific business date
        /// </summary>
        public async Task<string> ExportOptionsDataToExcelAsync(DateTime businessDate, bool includeTimestamp = false)
        {
            try
            {
                var fileName = includeTimestamp 
                    ? $"OptionsData_{businessDate:yyyyMMdd}_{DateTime.Now:HHmmss}.xlsx"
                    : $"OptionsData_{businessDate:yyyyMMdd}.xlsx";
                var filePath = Path.Combine(_exportPath, fileName);

                _logger.LogInformation($"Exporting options data for {businessDate:yyyy-MM-dd} to {fileName}");

                using var package = new ExcelPackage();
                
                // 1. All Options Data Sheet
                await CreateAllOptionsSheetAsync(package, businessDate);
                
                // 2. Strike Summary Sheet
                await CreateStrikeSummarySheetAsync(package, businessDate);
                
                // 3. LC/UC Changes Sheet
                await CreateLCUCChangesSheetAsync(package, businessDate);
                
                // 4. Expiry-wise Sheets
                await CreateExpiryWiseSheetsAsync(package, businessDate);

                // Save the file
                await package.SaveAsAsync(new FileInfo(filePath));
                
                _logger.LogInformation($"Successfully exported options data to {filePath}");
                return filePath;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to export options data for {businessDate:yyyy-MM-dd}");
                throw;
            }
        }

        /// <summary>
        /// Create the main options data sheet
        /// </summary>
        private async Task CreateAllOptionsSheetAsync(ExcelPackage package, DateTime businessDate)
        {
            var worksheet = package.Workbook.Worksheets.Add("All Options Data");
            
            // Get data from database
            var data = await GetOptionsDataFromDatabaseAsync(businessDate);
            
            if (data.Rows.Count == 0)
            {
                worksheet.Cells[1, 1].Value = "No data available for the specified business date";
                return;
            }

            // Add headers
            var headers = new[]
            {
                "BusinessDate", "ExpiryDate", "TickerSymbol", "StrikePrice", "OptionType",
                "Open", "High", "Low", "Close", "LastPrice", "LC", "UC", "Volume", "OpenInterest"
            };

            for (int i = 0; i < headers.Length; i++)
            {
                worksheet.Cells[1, i + 1].Value = headers[i];
                worksheet.Cells[1, i + 1].Style.Font.Bold = true;
                worksheet.Cells[1, i + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                worksheet.Cells[1, i + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
            }

            // Add data
            for (int row = 0; row < data.Rows.Count; row++)
            {
                for (int col = 0; col < headers.Length; col++)
                {
                    worksheet.Cells[row + 2, col + 1].Value = data.Rows[row][col];
                }
            }

            // Auto-fit columns
            worksheet.Cells.AutoFitColumns();
            
            // Add filters
            worksheet.Cells[1, 1, data.Rows.Count + 1, headers.Length].AutoFilter = true;
        }

        /// <summary>
        /// Create strike summary sheet
        /// </summary>
        private async Task CreateStrikeSummarySheetAsync(ExcelPackage package, DateTime businessDate)
        {
            var worksheet = package.Workbook.Worksheets.Add("Strike Summary");
            
            // Get data from database
            var data = await GetStrikeSummaryFromDatabaseAsync(businessDate);
            
            if (data.Rows.Count == 0)
            {
                worksheet.Cells[1, 1].Value = "No strike summary data available";
                return;
            }

            // Add headers for strike summary
            var headers = new[]
            {
                "BusinessDate", "ExpiryDate", "StrikePrice",
                "CallSymbol", "CallOpen", "CallHigh", "CallLow", "CallClose", "CallLC", "CallUC", "CallVolume", "CallOI",
                "PutSymbol", "PutOpen", "PutHigh", "PutLow", "PutClose", "PutLC", "PutUC", "PutVolume", "PutOI"
            };

            for (int i = 0; i < headers.Length; i++)
            {
                worksheet.Cells[1, i + 1].Value = headers[i];
                worksheet.Cells[1, i + 1].Style.Font.Bold = true;
                worksheet.Cells[1, i + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                worksheet.Cells[1, i + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGreen);
            }

            // Add data
            for (int row = 0; row < data.Rows.Count; row++)
            {
                for (int col = 0; col < headers.Length; col++)
                {
                    worksheet.Cells[row + 2, col + 1].Value = data.Rows[row][col];
                }
            }

            worksheet.Cells.AutoFitColumns();
            worksheet.Cells[1, 1, data.Rows.Count + 1, headers.Length].AutoFilter = true;
        }

        /// <summary>
        /// Create custom format sheet with exact columns requested
        /// </summary>
        private async Task CreateCustomFormatSheetAsync(ExcelWorksheet worksheet, DateTime businessDate, DateTime expiry)
        {
            try
            {
                // Get data from database for this expiry
                var data = await GetOptionsDataForExpiryCustomFormatAsync(businessDate, expiry);
                
                if (data.Rows.Count == 0)
                {
                    worksheet.Cells[1, 1].Value = "No data available for this expiry";
                    return;
                }

                // Add headers with exact column names requested
                var headers = new[]
                {
                    "BusinessDate", "TradeDate", "Expiry", "Strike", "OptionType",
                    "OpenPrice", "HighPrice", "LowPrice", "ClosePrice", 
                    "LowerCircuitLimit", "UpperCircuitLimit", "TradingSymbol", 
                    "LastPrice", "InsertionSequence"
                };

                // Style headers
                for (int i = 0; i < headers.Length; i++)
                {
                    worksheet.Cells[1, i + 1].Value = headers[i];
                    worksheet.Cells[1, i + 1].Style.Font.Bold = true;
                    worksheet.Cells[1, i + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    worksheet.Cells[1, i + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
                    worksheet.Cells[1, i + 1].Style.Border.BorderAround(ExcelBorderStyle.Thin);
                }

                // Add data
                for (int row = 0; row < data.Rows.Count; row++)
                {
                    for (int col = 0; col < headers.Length; col++)
                    {
                        worksheet.Cells[row + 2, col + 1].Value = data.Rows[row][col];
                        worksheet.Cells[row + 2, col + 1].Style.Border.BorderAround(ExcelBorderStyle.Thin);
                    }
                }

                // Auto-fit columns and add filters
                worksheet.Cells.AutoFitColumns();
                worksheet.Cells[1, 1, data.Rows.Count + 1, headers.Length].AutoFilter = true;
                
                // Freeze header row
                worksheet.View.FreezePanes(2, 1);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to create custom format sheet for expiry {expiry:yyyy-MM-dd}");
                worksheet.Cells[1, 1].Value = $"Error creating sheet: {ex.Message}";
            }
        }

        /// <summary>
        /// Create LC/UC changes sheet
        /// </summary>
        private async Task CreateLCUCChangesSheetAsync(ExcelPackage package, DateTime businessDate)
        {
            var worksheet = package.Workbook.Worksheets.Add("LC UC Changes");
            
            // Get data from database
            var data = await GetLCUCChangesFromDatabaseAsync(businessDate);
            
            if (data.Rows.Count == 0)
            {
                worksheet.Cells[1, 1].Value = "No LC/UC changes detected";
                return;
            }

            // Add headers
            var headers = new[]
            {
                "BusinessDate", "ExpiryDate", "TickerSymbol", "StrikePrice", "OptionType",
                "LC", "UC", "PrevLC", "PrevUC", "ChangeType", "ChangeTime"
            };

            for (int i = 0; i < headers.Length; i++)
            {
                worksheet.Cells[1, i + 1].Value = headers[i];
                worksheet.Cells[1, i + 1].Style.Font.Bold = true;
                worksheet.Cells[1, i + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                worksheet.Cells[1, i + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightCoral);
            }

            // Add data
            for (int row = 0; row < data.Rows.Count; row++)
            {
                for (int col = 0; col < headers.Length; col++)
                {
                    worksheet.Cells[row + 2, col + 1].Value = data.Rows[row][col];
                }
            }

            worksheet.Cells.AutoFitColumns();
            worksheet.Cells[1, 1, data.Rows.Count + 1, headers.Length].AutoFilter = true;
        }

        /// <summary>
        /// Create expiry-wise sheets
        /// </summary>
        private async Task CreateExpiryWiseSheetsAsync(ExcelPackage package, DateTime businessDate)
        {
            var expiries = await GetExpiryDatesFromDatabaseAsync(businessDate);
            
            foreach (var expiry in expiries)
            {
                var sheetName = $"Expiry_{expiry:yyyyMMdd}";
                var worksheet = package.Workbook.Worksheets.Add(sheetName);
                
                var data = await GetOptionsDataForExpiryAsync(businessDate, expiry);
                
                if (data.Rows.Count == 0) continue;

                // Add headers
                var headers = new[]
                {
                    "BusinessDate", "TickerSymbol", "StrikePrice", "OptionType",
                    "Open", "High", "Low", "Close", "LC", "UC", "Volume", "OpenInterest"
                };

                for (int i = 0; i < headers.Length; i++)
                {
                    worksheet.Cells[1, i + 1].Value = headers[i];
                    worksheet.Cells[1, i + 1].Style.Font.Bold = true;
                    worksheet.Cells[1, i + 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    worksheet.Cells[1, i + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightYellow);
                }

                // Add data
                for (int row = 0; row < data.Rows.Count; row++)
                {
                    for (int col = 0; col < headers.Length; col++)
                    {
                        worksheet.Cells[row + 2, col + 1].Value = data.Rows[row][col];
                    }
                }

                worksheet.Cells.AutoFitColumns();
                worksheet.Cells[1, 1, data.Rows.Count + 1, headers.Length].AutoFilter = true;
            }
        }

        /// <summary>
        /// Get options data from database
        /// </summary>
        private async Task<DataTable> GetOptionsDataFromDatabaseAsync(DateTime businessDate)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            
            using var connection = new SqlConnection(connectionString);
            using var command = new SqlCommand(
                "SELECT BusinessDate, ExpiryDate, TickerSymbol, StrikePrice, OptionType, " +
                "[Open], [High], [Low], [Close], LastPrice, LC, UC, Volume, OpenInterest " +
                "FROM vw_OptionsData " +
                "WHERE BusinessDate = @BusinessDate " +
                "ORDER BY ExpiryDate, OptionType, SortStrike", 
                connection);
            
            command.Parameters.AddWithValue("@BusinessDate", businessDate);
            
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            await Task.Run(() => adapter.Fill(dataTable));
            
            return dataTable;
        }

        /// <summary>
        /// Get strike summary from database
        /// </summary>
        private async Task<DataTable> GetStrikeSummaryFromDatabaseAsync(DateTime businessDate)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            
            using var connection = new SqlConnection(connectionString);
            using var command = new SqlCommand(
                "SELECT * FROM vw_StrikeSummary " +
                "WHERE BusinessDate = @BusinessDate " +
                "ORDER BY ExpiryDate, StrikePrice", 
                connection);
            
            command.Parameters.AddWithValue("@BusinessDate", businessDate);
            
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            await Task.Run(() => adapter.Fill(dataTable));
            
            return dataTable;
        }

        /// <summary>
        /// Get LC/UC changes from database
        /// </summary>
        private async Task<DataTable> GetLCUCChangesFromDatabaseAsync(DateTime businessDate)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            
            using var connection = new SqlConnection(connectionString);
            using var command = new SqlCommand(
                "SELECT * FROM vw_LC_UC_Changes " +
                "WHERE BusinessDate = @BusinessDate " +
                "ORDER BY ExpiryDate, StrikePrice, ChangeTime", 
                connection);
            
            command.Parameters.AddWithValue("@BusinessDate", businessDate);
            
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            await Task.Run(() => adapter.Fill(dataTable));
            
            return dataTable;
        }

        /// <summary>
        /// Get options data for specific expiry with custom format
        /// </summary>
        private async Task<DataTable> GetOptionsDataForExpiryCustomFormatAsync(DateTime businessDate, DateTime expiry)
        {
            var dataTable = new DataTable();
            
            try
            {
                var connectionString = _configuration.GetConnectionString("DefaultConnection");
                using var connection = new SqlConnection(connectionString);
                await connection.OpenAsync();

                var query = @"
                    SELECT 
                        mq.BusinessDate,
                        mq.RecordDateTime,
                        i.Expiry,
                        mq.Strike,
                        mq.OptionType,
                        mq.OpenPrice,
                        mq.HighPrice,
                        mq.LowPrice,
                        mq.ClosePrice,
                        mq.LowerCircuitLimit,
                        mq.UpperCircuitLimit,
                        mq.TradingSymbol,
                        mq.LastPrice,
                        mq.InsertionSequence
                    FROM MarketQuotes mq
                    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
                    WHERE CAST(mq.BusinessDate AS DATE) = @BusinessDate
                        AND CAST(i.Expiry AS DATE) = @Expiry
                    ORDER BY mq.Strike ASC, mq.OptionType ASC, mq.InsertionSequence ASC";

                using var command = new SqlCommand(query, connection);
                command.Parameters.AddWithValue("@BusinessDate", businessDate.Date);
                command.Parameters.AddWithValue("@Expiry", expiry.Date);

                using var adapter = new SqlDataAdapter(command);
                adapter.Fill(dataTable);

                _logger.LogInformation($"Retrieved {dataTable.Rows.Count} rows for expiry {expiry:yyyy-MM-dd}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to get options data for expiry {expiry:yyyy-MM-dd}");
            }

            return dataTable;
        }

        /// <summary>
        /// Get expiry dates from database
        /// </summary>
        private async Task<List<DateTime>> GetExpiryDatesFromDatabaseAsync(DateTime businessDate)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            var expiries = new List<DateTime>();
            
            using var connection = new SqlConnection(connectionString);
            using var command = new SqlCommand(
                "SELECT DISTINCT ExpiryDate FROM vw_OptionsData " +
                "WHERE BusinessDate = @BusinessDate " +
                "ORDER BY ExpiryDate", 
                connection);
            
            command.Parameters.AddWithValue("@BusinessDate", businessDate);
            
            await connection.OpenAsync();
            using var reader = await command.ExecuteReaderAsync();
            
            while (await reader.ReadAsync())
            {
                expiries.Add(reader.GetDateTime("ExpiryDate"));
            }
            
            return expiries;
        }

        /// <summary>
        /// Get options data for specific expiry
        /// </summary>
        private async Task<DataTable> GetOptionsDataForExpiryAsync(DateTime businessDate, DateTime expiryDate)
        {
            var connectionString = _configuration.GetConnectionString("DefaultConnection");
            
            using var connection = new SqlConnection(connectionString);
            using var command = new SqlCommand(
                "SELECT BusinessDate, TickerSymbol, StrikePrice, OptionType, " +
                "[Open], [High], [Low], [Close], LC, UC, Volume, OpenInterest " +
                "FROM vw_OptionsData " +
                "WHERE BusinessDate = @BusinessDate AND ExpiryDate = @ExpiryDate " +
                "ORDER BY OptionType, SortStrike", 
                connection);
            
            command.Parameters.AddWithValue("@BusinessDate", businessDate);
            command.Parameters.AddWithValue("@ExpiryDate", expiryDate);
            
            using var adapter = new SqlDataAdapter(command);
            var dataTable = new DataTable();
            await Task.Run(() => adapter.Fill(dataTable));
            
            return dataTable;
        }

        /// <summary>
        /// Get list of available export files
        /// </summary>
        public List<string> GetAvailableExports()
        {
            try
            {
                return Directory.GetFiles(_exportPath, "*.xlsx")
                    .Select(Path.GetFileName)
                    .Where(f => !string.IsNullOrEmpty(f))
                    .Cast<string>()
                    .OrderByDescending(f => f)
                    .ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get available exports");
                return new List<string>();
            }
        }

        /// <summary>
        /// Clean up old export files (keep last 30 days)
        /// </summary>
        public void CleanupOldExports()
        {
            try
            {
                var cutoffDate = DateTime.Now.AddDays(-30);
                var files = Directory.GetFiles(_exportPath, "*.xlsx");
                
                foreach (var file in files)
                {
                    var fileInfo = new FileInfo(file);
                    if (fileInfo.CreationTime < cutoffDate)
                    {
                        File.Delete(file);
                        _logger.LogInformation($"Deleted old export file: {fileInfo.Name}");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to cleanup old exports");
            }
        }
    }
}
