# PowerShell script to download daily close data using Kite API historical methods
# This should be run after market closes (after 4:00 PM IST)

param(
    [Parameter(Mandatory=$false)]
    [string]$TargetDate = (Get-Date).ToString("yyyy-MM-dd"),
    
    [Parameter(Mandatory=$false)]
    [string]$FromDate = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ToDate = ""
)

Write-Host "🚀 Daily Close Data Download Script" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if service is running
$process = Get-Process -Name "KiteMarketDataService.Worker" -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "⚠️  Kite Market Data Service is running. Please stop it first." -ForegroundColor Yellow
    Write-Host "Run: StopService.bat" -ForegroundColor Yellow
    Read-Host "Press Enter to continue anyway"
}

# Navigate to project directory
Set-Location $PSScriptRoot

# Build the project
Write-Host "🔨 Building project..." -ForegroundColor Cyan
dotnet build --configuration Release

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Build successful!" -ForegroundColor Green

# Create a simple console app to call the service
$consoleAppCode = @"
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Services;
using KiteMarketDataService.Worker.Data;

var host = Host.CreateDefaultBuilder(args)
    .ConfigureServices((context, services) =>
    {
        // Add database context
        services.AddDbContext<MarketDataContext>(options =>
            options.UseSqlServer("Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"));
        
        // Add required services
        services.AddSingleton<KiteConnectService>();
        services.AddSingleton<DailyCloseDataService>();
    })
    .Build();

var dailyCloseService = host.Services.GetRequiredService<DailyCloseDataService>();
var logger = host.Services.GetRequiredService<ILogger<Program>>();

try
{
    logger.LogInformation("Starting daily close data download...");
    
    if (!string.IsNullOrEmpty("$FromDate") && !string.IsNullOrEmpty("$ToDate"))
    {
        // Download for date range
        var fromDate = DateTime.Parse("$FromDate");
        var toDate = DateTime.Parse("$ToDate");
        await dailyCloseService.DownloadHistoricalDailyCloseDataAsync(fromDate, toDate);
    }
    else
    {
        // Download for specific date
        var targetDate = DateTime.Parse("$TargetDate");
        await dailyCloseService.SaveDailyCloseDataAsync(targetDate);
    }
    
    logger.LogInformation("Daily close data download completed successfully!");
}
catch (Exception ex)
{
    logger.LogError(ex, "Error downloading daily close data");
}

Console.WriteLine("Press any key to exit...");
Console.ReadKey();
"@

# Write the console app code to a temporary file
$tempFile = "TempDailyCloseApp.cs"
$consoleAppCode | Out-File -FilePath $tempFile -Encoding UTF8

try
{
    # Compile and run the console app
    Write-Host "🚀 Running daily close data download..." -ForegroundColor Cyan
    
    if (!string.IsNullOrEmpty($FromDate) -and !string.IsNullOrEmpty($ToDate)) {
        Write-Host "📅 Date Range: $FromDate to $ToDate" -ForegroundColor Yellow
        dotnet run --project . -- --from-date $FromDate --to-date $ToDate
    } else {
        Write-Host "📅 Target Date: $TargetDate" -ForegroundColor Yellow
        dotnet run --project . -- --target-date $TargetDate
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Daily close data download completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Daily close data download failed!" -ForegroundColor Red
    }
}
finally
{
    # Clean up temporary file
    if (Test-Path $tempFile) {
        Remove-Item $tempFile -Force
    }
}

Write-Host "`n📊 Check SpotData table for updated daily close prices" -ForegroundColor Cyan
Write-Host "🔍 Query: SELECT * FROM SpotData WHERE DataSource = 'Kite Historical API' ORDER BY TradingDate DESC" -ForegroundColor Gray
