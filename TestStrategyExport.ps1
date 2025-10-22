# Test Strategy Export Manually

Write-Host "🎯 TESTING STRATEGY EXPORT" -ForegroundColor Cyan
Write-Host ""

# Build first
Write-Host "Building..." -ForegroundColor Yellow
dotnet build --no-incremental 2>&1 | Select-String -Pattern "(Build succeeded|Build FAILED)"

Write-Host ""
Write-Host "Running strategy export test..." -ForegroundColor Yellow
Write-Host ""

# Run a simple test
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
    static async Task Main()
    {
        try
        {
            var configuration = new ConfigurationBuilder()
                .AddJsonFile("appsettings.json")
                .Build();

            var services = new ServiceCollection();
            
            services.AddDbContext<MarketDataContext>(options =>
                options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));

            services.AddSingleton<IConfiguration>(configuration);
            services.AddLogging(builder => {
                builder.AddConsole();
                builder.SetMinimumLevel(LogLevel.Information);
            });
            
            services.AddSingleton<StrategyCalculatorService>();
            services.AddSingleton<StrategyExcelExportService>();

            var serviceProvider = services.BuildServiceProvider();
            var exportService = serviceProvider.GetRequiredService<StrategyExcelExportService>();

            Console.WriteLine("🎯 Testing Strategy Excel Export...");
            Console.WriteLine("");
            
            await exportService.ExportStrategyAnalysisAsync();
            
            Console.WriteLine("");
            Console.WriteLine("✅ Export test completed!");
            Console.WriteLine("");
            
            // Check what was created
            if (System.IO.Directory.Exists("Exports\\StrategyAnalysis"))
            {
                var files = System.IO.Directory.GetFiles("Exports\\StrategyAnalysis", "*.xlsx", System.IO.SearchOption.AllDirectories);
                Console.WriteLine($"📁 Found {files.Length} Excel file(s):");
                foreach (var file in files)
                {
                    var info = new System.IO.FileInfo(file);
                    Console.WriteLine($"   - {info.Name} ({info.Length / 1024:F2} KB)");
                    Console.WriteLine($"     {info.DirectoryName}");
                }
            }
            else
            {
                Console.WriteLine("⚠️  No StrategyAnalysis folder created");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ ERROR: {ex.Message}");
            Console.WriteLine($"");
            Console.WriteLine($"Stack Trace:");
            Console.WriteLine(ex.StackTrace);
            if (ex.InnerException != null)
            {
                Console.WriteLine($"");
                Console.WriteLine($"Inner Exception: {ex.InnerException.Message}");
            }
        }
    }
}
"@

$testCode | Out-File -FilePath "StrategyExportTest.cs" -Encoding UTF8

Write-Host "Compiling test..." -ForegroundColor Yellow
$compileResult = dotnet run --project . --no-build 2>&1

$compileResult | ForEach-Object {
    if ($_ -match "ERROR|Exception|Failed") {
        Write-Host $_ -ForegroundColor Red
    } elseif ($_ -match "✅|Success|completed") {
        Write-Host $_ -ForegroundColor Green
    } else {
        Write-Host $_
    }
}

# Cleanup
if (Test-Path "StrategyExportTest.cs") {
    Remove-Item "StrategyExportTest.cs"
}

Write-Host ""
Write-Host "Test completed!" -ForegroundColor Cyan

