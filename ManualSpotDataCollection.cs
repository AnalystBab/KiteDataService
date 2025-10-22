using System;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Services;
using KiteMarketDataService.Worker.Data;

namespace KiteMarketDataService.Worker
{
    /// <summary>
    /// Manual script to collect spot data for 2025-10-13
    /// </summary>
    public class ManualSpotDataCollection
    {
        public static async Task Main(string[] args)
        {
            try
            {
                Console.WriteLine("=== MANUAL SPOT DATA COLLECTION FOR 2025-10-13 ===");
                Console.WriteLine($"Started at: {DateTime.Now:yyyy-MM-dd HH:mm:ss}");
                
                // Create host builder
                var host = Host.CreateDefaultBuilder(args)
                    .ConfigureServices((context, services) =>
                    {
                        // Add all required services
                        services.AddDbContext<MarketDataContext>();
                        services.AddHttpClient();
                        services.AddScoped<KiteConnectService>();
                        services.AddScoped<HistoricalSpotDataService>();
                        services.AddLogging(builder => builder.AddConsole());
                    })
                    .Build();

                // Get the service
                var spotDataService = host.Services.GetRequiredService<HistoricalSpotDataService>();
                
                // Collect historical data
                await spotDataService.CollectAndStoreHistoricalDataAsync();
                
                Console.WriteLine("✅ Manual spot data collection completed!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ Error: {ex.Message}");
                Console.WriteLine($"Stack Trace: {ex.StackTrace}");
            }
        }
    }
}
