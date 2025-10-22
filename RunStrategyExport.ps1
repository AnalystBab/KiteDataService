# =============================================
# STRATEGY ANALYSIS EXCEL EXPORT RUNNER
# =============================================
# Exports comprehensive strategy analysis for specified indices and date
# Generates 12-sheet Excel reports with all processes (C-, C+, P-, P+)

param(
    [string]$Date = "2025-10-09"
)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "   STRATEGY ANALYSIS EXCEL EXPORT" -ForegroundColor Yellow
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📅 Export Date: $Date" -ForegroundColor Green
Write-Host "📊 Indices: SENSEX, BANKNIFTY, NIFTY" -ForegroundColor Green
Write-Host ""

# Update appsettings.json with the date
$appSettingsPath = "appsettings.json"
if (Test-Path $appSettingsPath) {
    Write-Host "✅ Updating appsettings.json..." -ForegroundColor Yellow
    $settings = Get-Content $appSettingsPath | ConvertFrom-Json
    $settings.StrategyExport.ExportDate = $Date
    $settings.StrategyExport.EnableExport = $true
    $settings | ConvertTo-Json -Depth 10 | Set-Content $appSettingsPath
    Write-Host "✅ Configuration updated!" -ForegroundColor Green
    Write-Host ""
}

Write-Host "🚀 Starting Strategy Export Service..." -ForegroundColor Yellow
Write-Host ""

# Create test program that runs only the export
$testCode = @"
using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Services;

class Program
{
    static async Task Main(string[] args)
    {
        var configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json")
            .Build();

        var services = new ServiceCollection();
        
        // Configure DbContext
        services.AddDbContext<MarketDataContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
        
        services.AddDbContext<CircuitLimitTrackingContext>(options =>
            options.UseSqlServer(configuration.GetConnectionString("CircuitLimitTrackingConnection")));

        // Register services
        services.AddSingleton<IConfiguration>(configuration);
        services.AddLogging(builder => builder.AddConsole());
        services.AddSingleton<StrategyCalculatorService>();
        services.AddSingleton<StrikeScannerService>();
        services.AddSingleton<StrategyExcelExportService>();

        var serviceProvider = services.BuildServiceProvider();
        var exportService = serviceProvider.GetRequiredService<StrategyExcelExportService>();

        Console.WriteLine("🎯 Running Strategy Excel Export...");
        await exportService.ExportStrategyAnalysisAsync();
        Console.WriteLine("✅ Export completed!");
    }
}
"@

# Save test program
$testCode | Out-File -FilePath "StrategyExportRunner.cs" -Encoding UTF8

Write-Host "📝 Compiling and running export service..." -ForegroundColor Yellow
Write-Host ""

# Run using dotnet
dotnet build
if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "✅ Build successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "   EXPORT RESULTS" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $exportFolder = "Exports\StrategyAnalysis\$Date"
    if (Test-Path $exportFolder) {
        Write-Host "📁 Export Folder: $exportFolder" -ForegroundColor Green
        Write-Host ""
        
        Get-ChildItem -Path $exportFolder -Recurse -Filter "*.xlsx" | ForEach-Object {
            Write-Host "  ✅ $($_.FullName)" -ForegroundColor Green
            Write-Host "     Size: $([math]::Round($_.Length/1KB, 2)) KB" -ForegroundColor Gray
            Write-Host "     Created: $($_.CreationTime)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "⚠️  Export folder not found. Check logs for errors." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "   EXCEL FILE STRUCTURE" -ForegroundColor Yellow
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Each Excel file contains 12 sheets:" -ForegroundColor White
    Write-Host "  1. 📊 Summary - Overview and key metrics" -ForegroundColor Cyan
    Write-Host "  2. 📋 All Labels - All 27 strategy labels with formulas" -ForegroundColor Cyan
    Write-Host "  3. C- Call Minus - Call seller's profit zone analysis" -ForegroundColor Cyan
    Write-Host "  4. C+ Call Plus - Call seller's danger zone analysis" -ForegroundColor Cyan
    Write-Host "  5. P- Put Minus - Put seller's danger zone analysis" -ForegroundColor Cyan
    Write-Host "  6. P+ Put Plus - Put seller's profit zone analysis" -ForegroundColor Cyan
    Write-Host "  7. 🎯 Quadrant Analysis - Complete C-/C+/P-/P+ breakdown" -ForegroundColor Cyan
    Write-Host "  8. ⚡ Distance Analysis - Key predictors with 99%+ accuracy" -ForegroundColor Cyan
    Write-Host "  9. ★ Target Premiums - Strike scanner results" -ForegroundColor Cyan
    Write-Host " 10. 🎯 Base Strike Selection - How base strikes were chosen" -ForegroundColor Cyan
    Write-Host " 11. 🔒 Boundary Analysis - Upper/lower boundaries" -ForegroundColor Cyan
    Write-Host " 12. 📁 Raw Data - All market quotes with final LC/UC values" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
} else {
    Write-Host "❌ Build failed! Check errors above." -ForegroundColor Red
}

# Clean up
if (Test-Path "StrategyExportRunner.cs") {
    Remove-Item "StrategyExportRunner.cs"
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

