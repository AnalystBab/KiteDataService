# Test Excel Export Only - Skip Authentication
Write-Host "🎯 Testing Excel Export Only (Skip Authentication)..." -ForegroundColor Yellow

# Create a simple console app to test Excel export
$testCode = @"
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.EntityFrameworkCore;
using KiteMarketDataService.Worker.Services;
using KiteMarketDataService.Worker.Data;
using System;
using System.Threading.Tasks;

class Program
{
    static async Task Main(string[] args)
    {
        try
        {
            Console.WriteLine("🎯 Starting Excel Export Test...");
            
            // Setup configuration
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
                .Build();

            // Setup services
            var services = new ServiceCollection();
            
            // Add logging
            services.AddLogging(builder => builder.AddConsole().SetMinimumLevel(LogLevel.Information));
            
            // Add database context
            services.AddDbContext<MarketDataContext>(options =>
                options.UseSqlServer(configuration.GetConnectionString("DefaultConnection")));
            
            // Add required services
            services.AddSingleton<IServiceScopeFactory, ServiceScopeFactory>();
            services.AddScoped<StrategyCalculatorService>();
            services.AddSingleton<StrategyExcelExportService>();
            
            var serviceProvider = services.BuildServiceProvider();
            
            // Get Excel export service
            var excelExportService = serviceProvider.GetRequiredService<StrategyExcelExportService>();
            
            Console.WriteLine("📊 Running Excel Export...");
            await excelExportService.ExportStrategyAnalysisAsync();
            
            Console.WriteLine("✅ Excel Export completed successfully!");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Error: {ex.Message}");
            Console.WriteLine($"Stack Trace: {ex.StackTrace}");
        }
    }
}
"@

# Write the test file
$testCode | Out-File -FilePath "TestExcelExportOnly.cs" -Encoding UTF8

# Compile and run
Write-Host "📝 Creating test file..." -ForegroundColor Green
Write-Host "🔨 Compiling test..." -ForegroundColor Green

try {
    # Try to run the test
    Write-Host "🚀 Running Excel Export Test..." -ForegroundColor Cyan
    dotnet run --project KiteMarketDataService.Worker.csproj -- --excel-only
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "✅ Test completed!" -ForegroundColor Green
