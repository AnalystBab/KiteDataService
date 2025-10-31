using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System;
using System.Threading;
using System.Threading.Tasks;
using System.Linq;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Core Data Collection Service - Isolated from pattern services
    /// Handles only essential market data collection without interference
    /// </summary>
    public class CoreDataCollectionService : BackgroundService
    {
        private readonly ILogger<CoreDataCollectionService> _logger;
        private readonly ReliableAuthService _authService;
        private readonly KiteConnectService _kiteService;
        private readonly MarketDataService _marketDataService;
        private readonly BusinessDateCalculationService _businessDateService;

        public CoreDataCollectionService(
            ILogger<CoreDataCollectionService> logger,
            ReliableAuthService authService,
            KiteConnectService kiteService,
            MarketDataService marketDataService,
            BusinessDateCalculationService businessDateService)
        {
            _logger = logger;
            _authService = authService;
            _kiteService = kiteService;
            _marketDataService = marketDataService;
            _businessDateService = businessDateService;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🚀 [CORE-DATA] Core Data Collection Service started");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await PerformDataCollectionCycleAsync();
                    
                    // Wait 5 minutes between cycles
                    await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ [CORE-DATA] Error in data collection cycle");
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                }
            }

            _logger.LogInformation("🛑 [CORE-DATA] Core Data Collection Service stopped");
        }

        private async Task PerformDataCollectionCycleAsync()
        {
            _logger.LogInformation("🔄 [CORE-DATA] Starting data collection cycle");

            // Step 1: Authentication Check
            if (!await _authService.IsAuthenticatedAsync())
            {
                _logger.LogWarning("⚠️ [CORE-DATA] Authentication required - skipping cycle");
                return;
            }

            // Step 2: Business Date Calculation
            var businessDate = await _businessDateService.CalculateBusinessDateAsync() ?? DateTime.Today;
            _logger.LogInformation("📅 [CORE-DATA] Business Date: {BusinessDate}", businessDate);

            // Step 3: Market Data Collection
            await CollectMarketDataAsync(businessDate);

            _logger.LogInformation("✅ [CORE-DATA] Data collection cycle completed");
        }

        private async Task CollectMarketDataAsync(DateTime businessDate)
        {
            try
            {
                _logger.LogInformation("📊 [CORE-DATA] Collecting market data for {BusinessDate}", businessDate);

                // Get access token
                var accessToken = await _authService.GetAccessTokenAsync();
                if (string.IsNullOrEmpty(accessToken))
                {
                    _logger.LogError("❌ [CORE-DATA] No access token available");
                    return;
                }

                // Collect market quotes
                var quotesResponse = await _kiteService.GetMarketQuotesAsync(new List<string> { "NSE:SENSEX", "NSE:NIFTY 50", "NSE:NIFTY BANK" });
                if (quotesResponse?.Data?.Count > 0)
                {
                    // Convert KiteQuoteResponse to MarketQuote list
                    var quotes = quotesResponse.Data.Select(kvp => new MarketQuote
                    {
                        TradingSymbol = kvp.Key,
                        LastPrice = kvp.Value.LastPrice,
                        HighPrice = kvp.Value.OHLC?.High ?? 0,
                        LowPrice = kvp.Value.OHLC?.Low ?? 0,
                        OpenPrice = kvp.Value.OHLC?.Open ?? 0,
                        ClosePrice = kvp.Value.OHLC?.Close ?? 0,
                        BusinessDate = businessDate,
                        RecordDateTime = DateTime.Now
                    }).ToList();

                    await _marketDataService.SaveMarketQuotesAsync(quotes);
                    _logger.LogInformation("✅ [CORE-DATA] Saved {Count} market quotes", quotes.Count);
                }
                else
                {
                    _logger.LogWarning("⚠️ [CORE-DATA] No market quotes received");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [CORE-DATA] Error collecting market data");
            }
        }
    }

    /// <summary>
    /// Pattern Discovery Service - Separate from core data collection
    /// Runs independently without interfering with data collection
    /// </summary>
    public class IndependentPatternDiscoveryService : BackgroundService
    {
        private readonly ILogger<IndependentPatternDiscoveryService> _logger;
        private readonly PatternDiscoveryService _patternService;
        private readonly StrategyCalculatorService _strategyService;

        public IndependentPatternDiscoveryService(
            ILogger<IndependentPatternDiscoveryService> logger,
            PatternDiscoveryService patternService,
            StrategyCalculatorService strategyService)
        {
            _logger = logger;
            _patternService = patternService;
            _strategyService = strategyService;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("🔍 [PATTERN] Pattern Discovery Service started");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await PerformPatternAnalysisAsync();
                    
                    // Wait 1 hour between pattern analysis cycles
                    await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "❌ [PATTERN] Error in pattern analysis cycle");
                    await Task.Delay(TimeSpan.FromMinutes(10), stoppingToken);
                }
            }

            _logger.LogInformation("🛑 [PATTERN] Pattern Discovery Service stopped");
        }

        private async Task PerformPatternAnalysisAsync()
        {
            _logger.LogInformation("🔍 [PATTERN] Starting pattern analysis cycle");

            try
            {
                // Perform pattern discovery
                await _patternService.DiscoverPatternsAsync(DateTime.Today.AddDays(-30), DateTime.Today, "SENSEX");
                
                // Calculate strategies
                await _strategyService.CalculateAllLabelsAsync(DateTime.Today, "SENSEX");

                _logger.LogInformation("✅ [PATTERN] Pattern analysis cycle completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [PATTERN] Error in pattern analysis");
            }
        }
    }

    /// <summary>
    /// Service Manager - Coordinates different services
    /// </summary>
    public class ServiceManager
    {
        private readonly ILogger<ServiceManager> _logger;
        private readonly CoreDataCollectionService _coreDataService;
        private readonly IndependentPatternDiscoveryService _patternService;

        public ServiceManager(
            ILogger<ServiceManager> logger,
            CoreDataCollectionService coreDataService,
            IndependentPatternDiscoveryService patternService)
        {
            _logger = logger;
            _coreDataService = coreDataService;
            _patternService = patternService;
        }

        public async Task StartCoreDataCollectionAsync()
        {
            _logger.LogInformation("🚀 [MANAGER] Starting core data collection service");
            // Core data collection starts automatically as BackgroundService
        }

        public async Task StartPatternDiscoveryAsync()
        {
            _logger.LogInformation("🔍 [MANAGER] Starting pattern discovery service");
            // Pattern discovery starts automatically as BackgroundService
        }

        public async Task StopAllServicesAsync()
        {
            _logger.LogInformation("🛑 [MANAGER] Stopping all services");
            // Services will stop when cancellation token is triggered
        }
    }
}
