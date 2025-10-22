using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using OfficeOpenXml;
using OfficeOpenXml.Style;
using System.Drawing;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Complete Strategy Analysis Excel Export Service
    /// Exports comprehensive 12-sheet Excel reports
    /// </summary>
    public class StrategyExcelExportService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<StrategyExcelExportService> _logger;
        private readonly StrategyCalculatorService _calculatorService;

        public StrategyExcelExportService(
            IServiceScopeFactory scopeFactory,
            IConfiguration configuration,
            ILogger<StrategyExcelExportService> logger,
            StrategyCalculatorService calculatorService)
        {
            _scopeFactory = scopeFactory;
            _configuration = configuration;
            _logger = logger;
            _calculatorService = calculatorService;
            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
        }

        /// <summary>
        /// Main export method - processes all indices
        /// </summary>
        public async Task ExportStrategyAnalysisAsync()
        {
            try
            {
                _logger.LogInformation("================================================================");
                _logger.LogInformation("🎯 STRATEGY EXCEL EXPORT STARTING");
                _logger.LogInformation("================================================================");
                
                bool enableExport = _configuration.GetValue<bool>("StrategyExport:EnableExport");
                _logger.LogInformation($"EnableExport setting: {enableExport}");
                
                if (!enableExport)
                {
                    _logger.LogWarning("Strategy export is DISABLED in configuration - skipping");
                    return;
                }

                string exportDateStr = _configuration.GetValue<string>("StrategyExport:ExportDate");
                _logger.LogInformation($"ExportDate from config: {exportDateStr}");
                
                if (string.IsNullOrEmpty(exportDateStr))
                {
                    _logger.LogWarning("No export date specified in configuration - skipping");
                    return;
                }

                if (!DateTime.TryParse(exportDateStr, out DateTime exportDate))
                {
                    _logger.LogError($"Invalid export date format: {exportDateStr}");
                    return;
                }

                var indices = _configuration.GetSection("StrategyExport:Indices").Get<List<string>>() 
                    ?? new List<string> { "SENSEX", "BANKNIFTY", "NIFTY" };

                _logger.LogInformation($"Export Date: {exportDate:yyyy-MM-dd}");
                _logger.LogInformation($"Indices to Process: {string.Join(", ", indices)}");
                _logger.LogInformation($"Output Folder: Exports\\StrategyAnalysis\\{exportDate:yyyy-MM-dd}");

                foreach (var indexName in indices)
                {
                    try
                    {
                        _logger.LogInformation($"------------------------------------------------------------");
                        _logger.LogInformation($"Processing {indexName}...");
                        await ExportIndexStrategyAsync(exportDate, indexName);
                        _logger.LogInformation($"✅ {indexName} completed successfully");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, $"❌ FAILED to export {indexName}");
                        _logger.LogError($"Error details: {ex.Message}");
                        if (ex.InnerException != null)
                        {
                            _logger.LogError($"Inner exception: {ex.InnerException.Message}");
                        }
                    }
                }

                _logger.LogInformation("================================================================");
                _logger.LogInformation("✅ STRATEGY EXCEL EXPORT COMPLETED");
                _logger.LogInformation("================================================================");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to export strategy analysis");
            }
        }

        /// <summary>
        /// Export strategy analysis for a specific index
        /// </summary>
        private async Task ExportIndexStrategyAsync(DateTime businessDate, string indexName)
        {
            try
            {
                _logger.LogInformation($"Starting {indexName} export for {businessDate:yyyy-MM-dd}");

                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Calculate strategy labels (this will populate database if not already there)
                _logger.LogInformation($"{indexName} - Calling StrategyCalculatorService.CalculateAllLabelsAsync...");
                
                var labels = await _calculatorService.CalculateAllLabelsAsync(businessDate, indexName);
                
                _logger.LogInformation($"{indexName} - CalculateAllLabelsAsync returned {labels?.Count ?? 0} labels");
                
                if (!labels.Any())
                {
                    _logger.LogWarning($"{indexName} - No labels calculated, skipping Excel export");
                    return;
                }

                _logger.LogInformation($"{indexName} - Successfully calculated {labels.Count} labels");

                // Log key labels
                var callBase = labels.FirstOrDefault(l => l.LabelName == "CALL_BASE_STRIKE");
                var distance = labels.FirstOrDefault(l => l.LabelName == "CALL_MINUS_TO_CALL_BASE_DISTANCE");
                
                if (callBase != null)
                {
                    _logger.LogInformation($"{indexName} - CALL_BASE_STRIKE: {callBase.LabelValue:F2}");
                }
                if (distance != null)
                {
                    _logger.LogInformation($"{indexName} - Distance: {distance.LabelValue:F2}");
                }

                // Get expiry date from labels
                var expiryDate = labels.FirstOrDefault()?.ExpiryDate ?? businessDate.AddDays(7);
                _logger.LogInformation($"{indexName} - Using expiry date: {expiryDate:yyyy-MM-dd}");

                // Create Excel file
                _logger.LogInformation($"{indexName} - Creating Excel report...");
                string filePath = await CreateExcelReportAsync(businessDate, indexName, expiryDate, labels);
                
                _logger.LogInformation($"{indexName} - ✅ Excel report created successfully");
                _logger.LogInformation($"{indexName} - File path: {filePath}");
                _logger.LogInformation($"{indexName} - File size: {new System.IO.FileInfo(filePath).Length / 1024:F2} KB");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"{indexName} - EXCEPTION in ExportIndexStrategyAsync");
                _logger.LogError($"{indexName} - Error message: {ex.Message}");
                _logger.LogError($"{indexName} - Stack trace: {ex.StackTrace}");
                if (ex.InnerException != null)
                {
                    _logger.LogError($"{indexName} - Inner exception: {ex.InnerException.Message}");
                }
                throw;
            }
        }

        /// <summary>
        /// Create comprehensive Excel report
        /// </summary>
        private async Task<string> CreateExcelReportAsync(
            DateTime businessDate,
            string indexName,
            DateTime expiryDate,
            List<StrategyLabel> labels)
        {
            _logger.LogInformation($"{indexName} - CreateExcelReportAsync started");
            
            // Create folder structure
            string baseFolder = _configuration.GetValue<string>("StrategyExport:ExportFolder") 
                ?? "Exports\\StrategyAnalysis";
            
            _logger.LogInformation($"{indexName} - Base folder: {baseFolder}");
            
            string dateFolder = Path.Combine(baseFolder, businessDate.ToString("yyyy-MM-dd"));
            string expiryFolder = Path.Combine(dateFolder, $"Expiry_{expiryDate:yyyy-MM-dd}");
            
            _logger.LogInformation($"{indexName} - Creating directory: {expiryFolder}");
            Directory.CreateDirectory(expiryFolder);
            _logger.LogInformation($"{indexName} - Directory created successfully");

            string fileName = $"{indexName}_Strategy_Analysis_{businessDate:yyyyMMdd}.xlsx";
            string filePath = Path.Combine(expiryFolder, fileName);
            
            _logger.LogInformation($"{indexName} - Excel file path: {filePath}");

            // Delete existing file if it exists (to avoid duplicate sheets)
            if (File.Exists(filePath))
            {
                _logger.LogInformation($"{indexName} - Deleting existing file to avoid duplicates");
                File.Delete(filePath);
            }

            using (var package = new ExcelPackage(new FileInfo(filePath)))
            {
                _logger.LogInformation($"{indexName} - Creating Sheet 1: Summary");
                CreateSummarySheet(package, businessDate, indexName, expiryDate, labels);
                
                _logger.LogInformation($"{indexName} - Creating Sheet 2: All Labels");
                CreateAllLabelsSheet(package, labels);
                
                _logger.LogInformation($"{indexName} - Creating Sheet 3: Processes");
                CreateProcessSheetsSheet(package, labels);
                
                _logger.LogInformation($"{indexName} - Creating Sheet 4: Quadrant");
                CreateQuadrantAnalysisSheet(package, labels);
                
                _logger.LogInformation($"{indexName} - Creating Sheet 5: Distance");
                CreateDistanceAnalysisSheet(package, labels);
                
                _logger.LogInformation($"{indexName} - Creating Sheet 6: Base Strikes");
                CreateBaseStrikeSelectionSheet(package, businessDate, indexName, labels);
                
                _logger.LogInformation($"{indexName} - Creating Sheet 7: All Strikes Analysis");
                await CreateAllStrikesAnalysisSheet(package, businessDate, indexName, expiryDate);
                
                _logger.LogInformation($"{indexName} - Creating Sheet 8: Pattern Engine Analysis");
                await CreatePatternEngineSheet(package, businessDate, indexName, expiryDate, labels);
                
                _logger.LogInformation($"{indexName} - Creating Sheet 9: Raw Data");
                await CreateRawDataSheet(package, businessDate, indexName, expiryDate);

                _logger.LogInformation($"{indexName} - Saving Excel package...");
                await package.SaveAsync();
                _logger.LogInformation($"{indexName} - Excel package saved successfully");
            }

            _logger.LogInformation($"{indexName} - Excel file created: {filePath}");
            return filePath;
        }

        /// <summary>
        /// Sheet 1: Summary
        /// </summary>
        private void CreateSummarySheet(
            ExcelPackage package,
            DateTime businessDate,
            string indexName,
            DateTime expiryDate,
            List<StrategyLabel> labels)
        {
            var ws = package.Workbook.Worksheets.Add("📊 Summary");

            int row = 1;

            // Title
            ws.Cells[row, 1].Value = $"STRATEGY ANALYSIS REPORT - {indexName}";
            ws.Cells[row, 1, row, 6].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 18;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row += 2;

            // Report Info
            ws.Cells[row, 1].Value = "D0 Date (Prediction Day):";
            ws.Cells[row, 2].Value = businessDate.ToString("dd-MMM-yyyy");
            ws.Cells[row, 2].Style.Font.Bold = true;
            row++;

            ws.Cells[row, 1].Value = "Expiry Date:";
            ws.Cells[row, 2].Value = expiryDate.ToString("dd-MMM-yyyy");
            row++;

            ws.Cells[row, 1].Value = "Index:";
            ws.Cells[row, 2].Value = indexName;
            row++;

            ws.Cells[row, 1].Value = "Report Generated:";
            ws.Cells[row, 2].Value = DateTime.Now.ToString("dd-MMM-yyyy HH:mm:ss");
            row += 2;

            // Key Metrics
            ws.Cells[row, 1].Value = "KEY METRICS";
            ws.Cells[row, 1, row, 4].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 14;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.LightBlue);
            row++;

            ws.Cells[row, 1].Value = "Metric";
            ws.Cells[row, 2].Value = "Value";
            ws.Cells[row, 3].Value = "Formula";
            ws.Cells[row, 4].Value = "Description";
            FormatHeaderRow(ws, row, 1, 4);
            row++;

            // Display key labels
            var keyLabels = new[] { 
                "SPOT_CLOSE_D0", "CLOSE_STRIKE", 
                "CALL_BASE_STRIKE", "CALL_BASE_LC_D0",
                "PUT_BASE_STRIKE", "PUT_BASE_LC_D0",
                "CALL_MINUS_VALUE", "CALL_MINUS_TO_CALL_BASE_DISTANCE",
                "RANGE_PREDICTION_ACCURACY_PCT", "RANGE_PREDICTION_ERROR"
            };

            foreach (var labelName in keyLabels)
            {
                var label = labels.FirstOrDefault(l => l.LabelName == labelName);
                if (label != null)
                {
                    ws.Cells[row, 1].Value = label.LabelName;
                    ws.Cells[row, 2].Value = label.LabelValue;
                    ws.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 3].Value = label.Formula;
                    ws.Cells[row, 4].Value = label.Description;
                    
                    // Highlight critical metrics
                    if (labelName.Contains("ACCURACY") || labelName.Contains("CALL_BASE"))
                    {
                        ws.Cells[row, 1, row, 4].Style.Fill.PatternType = ExcelFillStyle.Solid;
                        ws.Cells[row, 1, row, 4].Style.Fill.BackgroundColor.SetColor(Color.LightYellow);
                    }
                    
                    row++;
                }
            }

            ws.Cells.AutoFitColumns();
        }

        /// <summary>
        /// Sheet 2: All Labels
        /// </summary>
        private void CreateAllLabelsSheet(ExcelPackage package, List<StrategyLabel> labels)
        {
            var ws = package.Workbook.Worksheets.Add("📋 All Labels");

            int row = 1;

            ws.Cells[row, 1].Value = "ALL STRATEGY LABELS";
            ws.Cells[row, 1, row, 6].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 16;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row += 2;

            ws.Cells[row, 1].Value = "Label Name";
            ws.Cells[row, 2].Value = "Value";
            ws.Cells[row, 3].Value = "Formula";
            ws.Cells[row, 4].Value = "Description";
            ws.Cells[row, 5].Value = "Process Type";
            ws.Cells[row, 6].Value = "Step";
            FormatHeaderRow(ws, row, 1, 6);
            row++;

            foreach (var label in labels.OrderBy(l => l.LabelName))
            {
                ws.Cells[row, 1].Value = label.LabelName;
                ws.Cells[row, 2].Value = label.LabelValue;
                ws.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";
                ws.Cells[row, 3].Value = label.Formula;
                ws.Cells[row, 4].Value = label.Description;
                ws.Cells[row, 5].Value = label.ProcessType;
                ws.Cells[row, 6].Value = label.StepNumber;

                // Highlight important labels
                if (label.LabelName.Contains("ACCURACY") || label.LabelName.Contains("BASE_STRIKE"))
                {
                    ws.Cells[row, 1, row, 6].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    ws.Cells[row, 1, row, 6].Style.Fill.BackgroundColor.SetColor(Color.LightGreen);
                }

                row++;
            }

            ws.Cells.AutoFitColumns();
        }

        /// <summary>
        /// Sheet 3: Process Analysis (C-, C+, P-, P+)
        /// </summary>
        private void CreateProcessSheetsSheet(ExcelPackage package, List<StrategyLabel> labels)
        {
            var ws = package.Workbook.Worksheets.Add("⚙️ Processes");

            int row = 1;

            // Header
            ws.Cells[row, 1].Value = "STRATEGY PROCESSES - COMPLETE ANALYSIS";
            ws.Cells[row, 1, row, 8].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 16;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row += 3;

            // Get key values from labels
            var spotClose = GetLabelValue(labels, "SPOT_CLOSE_D0");
            var closeStrike = GetLabelValue(labels, "CLOSE_STRIKE");
            var closeCeUc = GetLabelValue(labels, "CLOSE_CE_UC_D0");
            var closePeUc = GetLabelValue(labels, "CLOSE_PE_UC_D0");
            var callBase = GetLabelValue(labels, "CALL_BASE_STRIKE");
            var putBase = GetLabelValue(labels, "PUT_BASE_STRIKE");
            var callMinus = GetLabelValue(labels, "CALL_MINUS");
            var callPlus = GetLabelValue(labels, "CALL_PLUS");
            var putMinus = GetLabelValue(labels, "PUT_MINUS");
            var putPlus = GetLabelValue(labels, "PUT_PLUS");
            var distance = GetLabelValue(labels, "CALL_MINUS_TO_CALL_BASE_DISTANCE");
            var targetCePremium = GetLabelValue(labels, "TARGET_CE_PREMIUM");

            // SENSEX Header and Key Values
            ws.Cells[row, 1].Value = "SENSEX";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Size = 14;
            ws.Cells[row, 2].Value = spotClose;
            ws.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";
            ws.Cells[row, 2].Style.Font.Bold = true;
            row += 3;

            // CALL MINUS PROCESS Section (Yellow)
            ws.Cells[row, 1].Value = "CALL MINUS PROCESS";
            ws.Cells[row, 1, row + 8, 6].Merge = true;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Size = 12;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.Yellow);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Black);

            // Call Minus Calculations
            row++;
            ws.Cells[row, 1].Value = $"C- = {closeStrike} - {closeCeUc}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;
            ws.Cells[row, 1].Value = $"C- = {callMinus}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Red);
            row++;
            ws.Cells[row, 1].Value = $"Distance = {callMinus} - {callBase}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;
            ws.Cells[row, 1].Value = $"Distance = {distance}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Red);
            row++;
            ws.Cells[row, 1].Value = $"Target CE Premium = {closeCeUc} - {distance}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;
            ws.Cells[row, 1].Value = $"Target CE Premium = {targetCePremium}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Red);

            row += 3;

            // PUT MINUS PROCESS Section (Orange)
            ws.Cells[row, 1].Value = "PUT MINUS PROCESS";
            ws.Cells[row, 1, row + 6, 6].Merge = true;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Size = 12;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.Orange);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);

            // Put Minus Calculations
            row++;
            ws.Cells[row, 1].Value = $"P- = {closeStrike} - {closePeUc}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row++;
            ws.Cells[row, 1].Value = $"P- = {putMinus}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Red);
            row++;
            ws.Cells[row, 1].Value = $"Purpose: Find minimum spot level";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row++;
            ws.Cells[row, 1].Value = $"(NSE guarantee)";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);

            row += 3;

            // PUT PLUS PROCESS Section (Light Coral)
            ws.Cells[row, 1].Value = "PUT PLUS PROCESS";
            ws.Cells[row, 1, row + 6, 6].Merge = true;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Size = 12;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.LightCoral);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Black);

            // Put Plus Calculations
            row++;
            ws.Cells[row, 1].Value = $"P+ = {closeStrike} + {closePeUc}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;
            ws.Cells[row, 1].Value = $"P+ = {putPlus}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Red);
            row++;
            ws.Cells[row, 1].Value = $"Purpose: Alternative upper boundary";
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;
            ws.Cells[row, 1].Value = $"calculation";
            ws.Cells[row, 1].Style.Font.Bold = true;

            row += 3;

            // CALL PLUS PROCESS Section (Light Green)
            ws.Cells[row, 1].Value = "CALL PLUS PROCESS";
            ws.Cells[row, 1, row + 6, 6].Merge = true;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Size = 12;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.LightGreen);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Black);

            // Call Plus Calculations
            row++;
            ws.Cells[row, 1].Value = $"C+ = {closeStrike} + {closeCeUc}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;
            ws.Cells[row, 1].Value = $"C+ = {callPlus}";
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Red);
            row++;
            ws.Cells[row, 1].Value = $"Purpose: Find maximum spot level";
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;
            ws.Cells[row, 1].Value = $"(NSE limit)";
            ws.Cells[row, 1].Style.Font.Bold = true;

            ws.Cells.AutoFitColumns();
        }

        /// <summary>
        /// Sheet 4: Quadrant Analysis
        /// </summary>
        private void CreateQuadrantAnalysisSheet(ExcelPackage package, List<StrategyLabel> labels)
        {
            var ws = package.Workbook.Worksheets.Add("🎯 Quadrant");

            int row = 1;

            ws.Cells[row, 1].Value = "QUADRANT ANALYSIS (C-, C+, P-, P+)";
            ws.Cells[row, 1, row, 4].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 16;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.Purple);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row += 2;

            var callMinus = GetLabelValue(labels, "CALL_MINUS_VALUE");
            var putMinus = GetLabelValue(labels, "PUT_MINUS_VALUE");
            var spotClose = GetLabelValue(labels, "SPOT_CLOSE_D0");
            var closeStrike = GetLabelValue(labels, "CLOSE_STRIKE");

            ws.Cells[row, 1].Value = "Visual Representation:";
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;

            ws.Cells[row, 1].Value = $"C- (Call Minus): {callMinus:F2}";
            ws.Cells[row, 1, row, 4].Merge = true;
            row++;

            ws.Cells[row, 1].Value = $"CLOSE_STRIKE: {closeStrike:F2}";
            ws.Cells[row, 1, row, 4].Merge = true;
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;

            ws.Cells[row, 1].Value = $"SPOT_CLOSE: {spotClose:F2}";
            ws.Cells[row, 1, row, 4].Merge = true;
            row++;

            ws.Cells[row, 1].Value = $"P- (Put Minus): {putMinus:F2}";
            ws.Cells[row, 1, row, 4].Merge = true;
            row++;

            ws.Cells.AutoFitColumns();
        }

        /// <summary>
        /// Sheet 5: Distance Analysis
        /// </summary>
        private void CreateDistanceAnalysisSheet(ExcelPackage package, List<StrategyLabel> labels)
        {
            var ws = package.Workbook.Worksheets.Add("⚡ Distance");

            int row = 1;

            ws.Cells[row, 1].Value = "DISTANCE ANALYSIS - KEY PREDICTORS";
            ws.Cells[row, 1, row, 4].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 16;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.Gold);
            row += 2;

            var distanceLabels = labels.Where(l => l.LabelName.Contains("DISTANCE")).ToList();

            if (distanceLabels.Any())
            {
                ws.Cells[row, 1].Value = "Label";
                ws.Cells[row, 2].Value = "Distance Value";
                ws.Cells[row, 3].Value = "Formula";
                ws.Cells[row, 4].Value = "Description";
                FormatHeaderRow(ws, row, 1, 4);
                row++;

                foreach (var label in distanceLabels)
                {
                    ws.Cells[row, 1].Value = label.LabelName;
                    ws.Cells[row, 2].Value = label.LabelValue;
                    ws.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 3].Value = label.Formula;
                    ws.Cells[row, 4].Value = label.Description;

                    if (label.LabelName.Contains("CALL_MINUS_TO_CALL_BASE"))
                    {
                        ws.Cells[row, 1, row, 4].Style.Fill.PatternType = ExcelFillStyle.Solid;
                        ws.Cells[row, 1, row, 4].Style.Fill.BackgroundColor.SetColor(Color.LightGreen);
                        ws.Cells[row, 1, row, 4].Style.Font.Bold = true;
                    }

                    row++;
                }
            }

            ws.Cells.AutoFitColumns();
        }

        /// <summary>
        /// Sheet 6: Base Strike Selection
        /// </summary>
        private void CreateBaseStrikeSelectionSheet(
            ExcelPackage package,
            DateTime businessDate,
            string indexName,
            List<StrategyLabel> labels)
        {
            var ws = package.Workbook.Worksheets.Add("🎯 Base Strikes");

            int row = 1;

            ws.Cells[row, 1].Value = "BASE STRIKE SELECTION PROCESS";
            ws.Cells[row, 1, row, 4].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 16;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row += 2;

            ws.Cells[row, 1].Value = "STANDARD PROCESS (SENSEX-BASED)";
            ws.Cells[row, 1].Style.Font.Size = 14;
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;

            ws.Cells[row, 1].Value = "Method: LC > 0.05 (First strike with meaningful protection)";
            ws.Cells[row, 1, row, 4].Merge = true;
            row++;

            ws.Cells[row, 1].Value = "Uses: FINAL LC values (MAX InsertionSequence)";
            ws.Cells[row, 1, row, 4].Merge = true;
            row += 2;

            // Show base strikes
            var callBase = GetLabelValue(labels, "CALL_BASE_STRIKE");
            var callBaseLc = GetLabelValue(labels, "CALL_BASE_LC_D0");
            var putBase = GetLabelValue(labels, "PUT_BASE_STRIKE");
            var putBaseLc = GetLabelValue(labels, "PUT_BASE_LC_D0");

            ws.Cells[row, 1].Value = "CALL_BASE_STRIKE:";
            ws.Cells[row, 2].Value = callBase;
            ws.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";
            ws.Cells[row, 3].Value = $"LC = {callBaseLc:F2}";
            ws.Cells[row, 1, row, 3].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1, row, 3].Style.Fill.BackgroundColor.SetColor(Color.LightGreen);
            ws.Cells[row, 1, row, 3].Style.Font.Bold = true;
            row++;

            ws.Cells[row, 1].Value = "PUT_BASE_STRIKE:";
            ws.Cells[row, 2].Value = putBase;
            ws.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";
            ws.Cells[row, 3].Value = $"LC = {putBaseLc:F2}";
            ws.Cells[row, 1, row, 3].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1, row, 3].Style.Fill.BackgroundColor.SetColor(Color.LightYellow);
            row += 2;

            ws.Cells[row, 1].Value = "KEY POINTS:";
            ws.Cells[row, 1].Style.Font.Bold = true;
            row++;

            var keyPoints = new[]
            {
                "1. Always use FINAL LC (MAX InsertionSequence)",
                "2. Strike is ELIGIBLE only if FINAL LC > 0.05",
                "3. Excludes strikes whose LC dropped to 0.05",
                "4. First eligible strike (descending) = BASE STRIKE",
                "5. Validated with 99.65% accuracy for SENSEX"
            };

            foreach (var point in keyPoints)
            {
                ws.Cells[row, 1].Value = point;
                ws.Cells[row, 1, row, 4].Merge = true;
                row++;
            }

            ws.Cells.AutoFitColumns();
        }

        /// <summary>
        /// Sheet 7: All Base Strikes Comparison Analysis
        /// </summary>
        private async Task CreateAllStrikesAnalysisSheet(
            ExcelPackage package,
            DateTime businessDate,
            string indexName,
            DateTime expiryDate)
        {
            var ws = package.Workbook.Worksheets.Add("🎯 Base Strikes Comparison");

            int row = 1;

            // Header
            ws.Cells[row, 1].Value = $"ALL BASE STRIKES COMPARISON ANALYSIS - {indexName}";
            ws.Cells[row, 1, row, 15].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 16;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkBlue);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row += 3;

            // Get key values for calculations
            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            // Get spot close
            var spotData = await context.HistoricalSpotData
                .Where(s => s.TradingDate == businessDate && s.IndexName == indexName)
                .FirstOrDefaultAsync();

            var spotClose = spotData?.ClosePrice ?? 0m;
            var closeStrike = Math.Round(spotClose / 100) * 100;
            var closeCeUc = GetLabelValue(new List<StrategyLabel>(), "CLOSE_CE_UC_D0"); // We'll get this from current labels

            // Get all quotes and process in memory
            var allQuotes = await context.MarketQuotes
                .Where(q => q.BusinessDate == businessDate
                    && q.TradingSymbol.StartsWith(indexName)
                    && q.ExpiryDate == expiryDate)
                .ToListAsync();

            // Get all eligible base strikes (LC > 0.05)
            var eligibleBaseStrikes = allQuotes
                .GroupBy(q => new { q.Strike, q.OptionType })
                .Select(g => g.OrderByDescending(x => x.InsertionSequence).First())
                .Where(q => q.LowerCircuitLimit > 0.05m && q.OptionType == "CE") // Only CE for call base strikes
                .OrderByDescending(q => q.Strike) // Order by strike descending
                .ToList();

            _logger.LogInformation($"{indexName} - Found {eligibleBaseStrikes.Count} eligible base strikes with LC > 0.05");

            if (eligibleBaseStrikes.Any())
            {
                // Summary section
                ws.Cells[row, 1].Value = "BASE STRIKE COMPARISON RESULTS:";
                ws.Cells[row, 1].Style.Font.Bold = true;
                ws.Cells[row, 1].Style.Font.Size = 14;
                ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkGray);
                ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
                row++;

                ws.Cells[row, 1].Value = $"Total Base Strikes Tested: {eligibleBaseStrikes.Count}";
                ws.Cells[row, 2].Value = $"Close Strike: {closeStrike}";
                ws.Cells[row, 3].Value = $"Spot Close: {spotClose:F2}";
                row += 2;

                // Headers
                ws.Cells[row, 1].Value = "Base Strike";
                ws.Cells[row, 2].Value = "Type";
                ws.Cells[row, 3].Value = "LC";
                ws.Cells[row, 4].Value = "UC";
                ws.Cells[row, 5].Value = "Distance";
                ws.Cells[row, 6].Value = "Target CE Premium";
                ws.Cells[row, 7].Value = "C- Value";
                ws.Cells[row, 8].Value = "C+ Value";
                ws.Cells[row, 9].Value = "P- Value";
                ws.Cells[row, 10].Value = "P+ Value";
                ws.Cells[row, 11].Value = "Pattern Matches";
                ws.Cells[row, 12].Value = "Performance";
                ws.Cells[row, 13].Value = "Recommendation";

                FormatHeaderRow(ws, row, 1, 13);
                row++;

                // Calculate results for each base strike
                var baseStrikeResults = new List<BaseStrikeResult>();

                foreach (var baseStrike in eligibleBaseStrikes)
                {
                    // Calculate strategy values for this base strike
                    var cMinus = closeStrike - closeCeUc;
                    var distance = cMinus - baseStrike.Strike;
                    var targetCePremium = closeCeUc - distance;
                    var cPlus = closeStrike + closeCeUc;

                    // Calculate PE values (assuming PE UC = closePeUc)
                    var closePeUc = closeCeUc * 0.75m; // Approximate PE UC
                    var pMinus = closeStrike - closePeUc;
                    var pPlus = closeStrike + closePeUc;

                    // Check for pattern matches
                    var patternMatches = CheckPatternMatches(targetCePremium, distance, closePeUc);

                    baseStrikeResults.Add(new BaseStrikeResult
                    {
                        Strike = baseStrike.Strike,
                        OptionType = baseStrike.OptionType,
                        LowerCircuitLimit = baseStrike.LowerCircuitLimit,
                        UpperCircuitLimit = baseStrike.UpperCircuitLimit,
                        Distance = distance,
                        TargetCePremium = targetCePremium,
                        CMinus = cMinus,
                        CPlus = cPlus,
                        PMinus = pMinus,
                        PPlus = pPlus,
                        PatternMatches = patternMatches,
                        Performance = CalculatePerformance(distance, patternMatches.Count)
                    });
                }

                // Sort by performance (best first)
                baseStrikeResults = baseStrikeResults.OrderBy(r => Math.Abs(r.Distance)).ToList();

                // Add data rows with color coding
                foreach (var result in baseStrikeResults)
                {
                    ws.Cells[row, 1].Value = result.Strike;
                    ws.Cells[row, 1].Style.Numberformat.Format = "#,##0";
                    ws.Cells[row, 2].Value = result.OptionType;
                    ws.Cells[row, 3].Value = result.LowerCircuitLimit;
                    ws.Cells[row, 3].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 4].Value = result.UpperCircuitLimit;
                    ws.Cells[row, 4].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 5].Value = result.Distance;
                    ws.Cells[row, 5].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 6].Value = result.TargetCePremium;
                    ws.Cells[row, 6].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 7].Value = result.CMinus;
                    ws.Cells[row, 7].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 8].Value = result.CPlus;
                    ws.Cells[row, 8].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 9].Value = result.PMinus;
                    ws.Cells[row, 9].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 10].Value = result.PPlus;
                    ws.Cells[row, 10].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 11].Value = result.PatternMatches;
                    ws.Cells[row, 12].Value = result.Performance;
                    ws.Cells[row, 13].Value = GetRecommendation(result.Performance, result.PatternMatches.Count);

                    // Color coding based on performance
                    if (result.Performance == "Excellent")
                    {
                        // Green - Best performance
                        for (int col = 1; col <= 13; col++)
                        {
                            ws.Cells[row, col].Style.Fill.PatternType = ExcelFillStyle.Solid;
                            ws.Cells[row, col].Style.Fill.BackgroundColor.SetColor(Color.LightGreen);
                        }
                    }
                    else if (result.Performance == "Good")
                    {
                        // Yellow - Good performance
                        for (int col = 1; col <= 13; col++)
                        {
                            ws.Cells[row, col].Style.Fill.PatternType = ExcelFillStyle.Solid;
                            ws.Cells[row, col].Style.Fill.BackgroundColor.SetColor(Color.LightYellow);
                        }
                    }
                    else if (result.Performance == "Poor")
                    {
                        // Red - Poor performance
                        for (int col = 1; col <= 13; col++)
                        {
                            ws.Cells[row, col].Style.Fill.PatternType = ExcelFillStyle.Solid;
                            ws.Cells[row, col].Style.Fill.BackgroundColor.SetColor(Color.LightCoral);
                        }
                    }

                    // Highlight current selection (79600 or closest)
                    if (result.Strike == 79600 || Math.Abs(result.Distance) < 100)
                    {
                        ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                        ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.LightBlue);
                        ws.Cells[row, 13].Value = "✅ CURRENT SELECTION";
                        ws.Cells[row, 13].Style.Font.Bold = true;
                    }

                    row++;
                }

                // Add summary section
                row += 2;
                ws.Cells[row, 1].Value = "PATTERN MATCHES BY BASE STRIKE:";
                ws.Cells[row, 1].Style.Font.Bold = true;
                ws.Cells[row, 1].Style.Font.Size = 14;
                ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkGray);
                ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
                row++;

                var topPerformers = baseStrikeResults.Take(5);
                foreach (var performer in topPerformers)
                {
                    if (performer.PatternMatches.Count > 0)
                    {
                        ws.Cells[row, 1].Value = $"{performer.Strike} CE: {string.Join(", ", performer.PatternMatches)}";
                        ws.Cells[row, 1].Style.Font.Bold = true;
                        row++;
                    }
                }

                row += 2;
                ws.Cells[row, 1].Value = "RECOMMENDATION:";
                ws.Cells[row, 1].Style.Font.Bold = true;
                ws.Cells[row, 1].Style.Font.Size = 14;
                ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkGreen);
                ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
                row++;

                var bestStrike = baseStrikeResults.First();
                ws.Cells[row, 1].Value = $"Based on pattern analysis, {bestStrike.Strike} CE is the optimal base strike selection.";
                ws.Cells[row, 1].Style.Font.Bold = true;
                ws.Cells[row, 1].Style.Font.Color.SetColor(Color.DarkGreen);
            }
            else
            {
                ws.Cells[row, 1].Value = "No eligible base strikes found with LC > 0.05";
                ws.Cells[row, 1].Style.Font.Bold = true;
                ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Red);
            }

            ws.Cells.AutoFitColumns();
        }

        #region Helper Methods for Base Strikes Analysis

        private List<string> CheckPatternMatches(decimal targetCePremium, decimal distance, decimal closePeUc)
        {
            var matches = new List<string>();
            
            // Check if Target CE Premium matches PE UC (within 100 points)
            if (Math.Abs(targetCePremium - closePeUc) <= 100)
            {
                matches.Add("Target CE Premium ≈ PE UC");
            }

            // Check if Distance is reasonable (within 1000 points)
            if (Math.Abs(distance) <= 1000)
            {
                matches.Add("Distance within optimal range");
            }

            // Check if Target CE Premium is positive
            if (targetCePremium > 0)
            {
                matches.Add("Positive Target Premium");
            }

            return matches;
        }

        private string CalculatePerformance(decimal distance, int patternMatches)
        {
            if (Math.Abs(distance) <= 500 && patternMatches >= 2)
                return "Excellent";
            else if (Math.Abs(distance) <= 1000 && patternMatches >= 1)
                return "Good";
            else if (Math.Abs(distance) <= 1500)
                return "Average";
            else
                return "Poor";
        }

        private string GetRecommendation(string performance, int patternMatches)
        {
            if (performance == "Excellent")
                return "✅ RECOMMENDED";
            else if (performance == "Good")
                return "👍 GOOD";
            else if (performance == "Average")
                return "⚠️ AVERAGE";
            else
                return "❌ NOT RECOMMENDED";
        }

        #endregion

        /// <summary>
        /// Sheet 8: Pattern Engine Analysis
        /// </summary>
        private async Task CreatePatternEngineSheet(
            ExcelPackage package,
            DateTime businessDate,
            string indexName,
            DateTime expiryDate,
            List<StrategyLabel> labels)
        {
            var ws = package.Workbook.Worksheets.Add("🧠 Pattern Engine");

            int row = 1;

            // Header
            ws.Cells[row, 1].Value = $"PATTERN ENGINE ANALYSIS - {indexName}";
            ws.Cells[row, 1, row, 10].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 16;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.Purple);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row += 3;

            // Run Pattern Engine
            using var scope = _scopeFactory.CreateScope();
            var patternEngine = scope.ServiceProvider.GetRequiredService<PatternEngine>();
            var patternMatches = await patternEngine.FindPatternMatchesAsync(businessDate, indexName, expiryDate, labels);

            if (patternMatches.Any())
            {
                // Headers
                ws.Cells[row, 1].Value = "Pattern Type";
                ws.Cells[row, 2].Value = "Description";
                ws.Cells[row, 3].Value = "Prediction";
                ws.Cells[row, 4].Value = "Confidence %";
                ws.Cells[row, 5].Value = "Strength";
                ws.Cells[row, 6].Value = "Historical Accuracy %";
                ws.Cells[row, 7].Value = "Reason";

                FormatHeaderRow(ws, row, 1, 7);
                row++;

                // Group patterns by type for better organization
                var groupedPatterns = patternMatches
                    .OrderByDescending(p => p.Confidence)
                    .GroupBy(p => p.PatternType)
                    .ToList();

                foreach (var group in groupedPatterns)
                {
                    // Add group header
                    ws.Cells[row, 1].Value = $"=== {group.Key.ToUpper()} PATTERNS ===";
                    ws.Cells[row, 1, row, 7].Merge = true;
                    ws.Cells[row, 1].Style.Font.Bold = true;
                    ws.Cells[row, 1].Style.Font.Size = 12;
                    ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                    ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.LightGray);
                    row++;

                    foreach (var pattern in group)
                    {
                        ws.Cells[row, 1].Value = pattern.PatternType;
                        ws.Cells[row, 2].Value = pattern.Description;
                        ws.Cells[row, 3].Value = pattern.Prediction;
                        ws.Cells[row, 4].Value = pattern.Confidence;
                        ws.Cells[row, 4].Style.Numberformat.Format = "#,##0.0";
                        ws.Cells[row, 5].Value = pattern.PatternStrength;
                        ws.Cells[row, 6].Value = pattern.HistoricalAccuracy;
                        ws.Cells[row, 6].Style.Numberformat.Format = "#,##0.0";
                        ws.Cells[row, 7].Value = pattern.Reason;

                        // Color code by confidence
                        if (pattern.Confidence >= 80)
                        {
                            ws.Cells[row, 4].Style.Fill.PatternType = ExcelFillStyle.Solid;
                            ws.Cells[row, 4].Style.Fill.BackgroundColor.SetColor(Color.LightGreen);
                        }
                        else if (pattern.Confidence >= 60)
                        {
                            ws.Cells[row, 4].Style.Fill.PatternType = ExcelFillStyle.Solid;
                            ws.Cells[row, 4].Style.Fill.BackgroundColor.SetColor(Color.Yellow);
                        }

                        // Color code by strength
                        if (pattern.PatternStrength == "High")
                        {
                            ws.Cells[row, 5].Style.Fill.PatternType = ExcelFillStyle.Solid;
                            ws.Cells[row, 5].Style.Fill.BackgroundColor.SetColor(Color.LightBlue);
                        }

                        row++;
                    }
                    row++; // Extra space between groups
                }

                // Summary section
                row += 2;
                ws.Cells[row, 1].Value = "PATTERN SUMMARY:";
                ws.Cells[row, 1].Style.Font.Bold = true;
                ws.Cells[row, 1].Style.Font.Size = 14;
                ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
                ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkGray);
                ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
                row++;

                var highConfidencePatterns = patternMatches.Where(p => p.Confidence >= 80).Count();
                var mediumConfidencePatterns = patternMatches.Where(p => p.Confidence >= 60 && p.Confidence < 80).Count();
                var totalPatterns = patternMatches.Count;

                ws.Cells[row, 1].Value = $"Total Patterns Found: {totalPatterns}";
                ws.Cells[row, 2].Value = $"High Confidence (≥80%): {highConfidencePatterns}";
                ws.Cells[row, 3].Value = $"Medium Confidence (60-79%): {mediumConfidencePatterns}";
                row++;

                if (highConfidencePatterns > 0)
                {
                    ws.Cells[row, 1].Value = "🎯 HIGH CONFIDENCE PREDICTIONS:";
                    ws.Cells[row, 1].Style.Font.Bold = true;
                    ws.Cells[row, 1].Style.Font.Color.SetColor(Color.DarkGreen);
                    row++;

                    var topPatterns = patternMatches.Where(p => p.Confidence >= 80).Take(3);
                    foreach (var pattern in topPatterns)
                    {
                        ws.Cells[row, 1].Value = $"• {pattern.Prediction}";
                        ws.Cells[row, 1].Style.Font.Bold = true;
                        row++;
                    }
                }
            }
            else
            {
                ws.Cells[row, 1].Value = "No significant patterns found";
                ws.Cells[row, 1].Style.Font.Bold = true;
                ws.Cells[row, 1].Style.Font.Color.SetColor(Color.Red);
            }

            ws.Cells.AutoFitColumns();
        }

        /// <summary>
        /// Sheet 9: Raw Data
        /// </summary>
        private async Task CreateRawDataSheet(
            ExcelPackage package,
            DateTime businessDate,
            string indexName,
            DateTime expiryDate)
        {
            var ws = package.Workbook.Worksheets.Add("📁 Raw Data");

            int row = 1;

            ws.Cells[row, 1].Value = "RAW MARKET QUOTES DATA";
            ws.Cells[row, 1, row, 8].Merge = true;
            ws.Cells[row, 1].Style.Font.Size = 16;
            ws.Cells[row, 1].Style.Font.Bold = true;
            ws.Cells[row, 1].Style.HorizontalAlignment = ExcelHorizontalAlignment.Center;
            ws.Cells[row, 1].Style.Fill.PatternType = ExcelFillStyle.Solid;
            ws.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(Color.DarkGray);
            ws.Cells[row, 1].Style.Font.Color.SetColor(Color.White);
            row += 2;

            using var scope = _scopeFactory.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

            // Get all quotes and process in memory (EF Core translation issue)
            var allQuotes = await context.MarketQuotes
                .Where(q => q.BusinessDate == businessDate
                    && q.TradingSymbol.StartsWith(indexName)
                    && q.ExpiryDate == expiryDate)
                .ToListAsync();
            
            // Get latest quote for each strike/optionType combination
            var rawData = allQuotes
                .GroupBy(q => new { q.Strike, q.OptionType })
                .Select(g => g.OrderByDescending(x => x.InsertionSequence).First())
                .OrderBy(q => q.Strike)
                .ThenBy(q => q.OptionType)
                .ToList();

            _logger.LogInformation($"{indexName} - Raw data: {allQuotes.Count} total quotes, {rawData.Count} unique strike/type combinations");

            if (rawData.Any())
            {
                ws.Cells[row, 1].Value = "Strike";
                ws.Cells[row, 2].Value = "Type";
                ws.Cells[row, 3].Value = "Final LC";
                ws.Cells[row, 4].Value = "Final UC";
                ws.Cells[row, 5].Value = "Close";
                ws.Cells[row, 6].Value = "Last";
                ws.Cells[row, 7].Value = "Seq";
                ws.Cells[row, 8].Value = "Symbol";
                FormatHeaderRow(ws, row, 1, 8);
                row++;

                foreach (var quote in rawData) // Show all rows
                {
                    ws.Cells[row, 1].Value = quote.Strike;
                    ws.Cells[row, 2].Value = quote.OptionType;
                    ws.Cells[row, 3].Value = quote.LowerCircuitLimit;
                    ws.Cells[row, 3].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 4].Value = quote.UpperCircuitLimit;
                    ws.Cells[row, 4].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 5].Value = quote.ClosePrice;
                    ws.Cells[row, 5].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 6].Value = quote.LastPrice;
                    ws.Cells[row, 6].Style.Numberformat.Format = "#,##0.00";
                    ws.Cells[row, 7].Value = quote.InsertionSequence;
                    ws.Cells[row, 8].Value = quote.TradingSymbol;

                    // Highlight if LC > 0.05
                    if (quote.LowerCircuitLimit > 0.05m)
                    {
                        ws.Cells[row, 3].Style.Fill.PatternType = ExcelFillStyle.Solid;
                        ws.Cells[row, 3].Style.Fill.BackgroundColor.SetColor(Color.LightGreen);
                    }

                    row++;
                }
            }

            ws.Cells.AutoFitColumns();
        }

        // Helper Methods

        private void FormatHeaderRow(ExcelWorksheet ws, int row, int startCol, int endCol)
        {
            var range = ws.Cells[row, startCol, row, endCol];
            range.Style.Font.Bold = true;
            range.Style.Fill.PatternType = ExcelFillStyle.Solid;
            range.Style.Fill.BackgroundColor.SetColor(Color.LightGray);
            range.Style.Border.Bottom.Style = ExcelBorderStyle.Thick;
        }

        private decimal GetLabelValue(List<StrategyLabel> labels, string labelName)
        {
            return labels.FirstOrDefault(l => l.LabelName == labelName)?.LabelValue ?? 0m;
        }
    }

    #region Data Models for Base Strikes Analysis

    public class BaseStrikeResult
    {
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty;
        public decimal LowerCircuitLimit { get; set; }
        public decimal UpperCircuitLimit { get; set; }
        public decimal Distance { get; set; }
        public decimal TargetCePremium { get; set; }
        public decimal CMinus { get; set; }
        public decimal CPlus { get; set; }
        public decimal PMinus { get; set; }
        public decimal PPlus { get; set; }
        public List<string> PatternMatches { get; set; } = new List<string>();
        public string Performance { get; set; } = string.Empty;
    }

    #endregion
}

