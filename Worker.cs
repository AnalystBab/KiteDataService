using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Services;
using KiteMarketDataService.Worker.Models;
using KiteMarketDataService.Worker.Data;

namespace KiteMarketDataService.Worker
{
    public class Worker : BackgroundService
    {
        private readonly ILogger<Worker> _logger;
        private readonly IConfiguration _configuration;
        private readonly KiteConnectService _kiteService;
        private readonly MarketDataService _marketDataService;
        private readonly SmartCircuitLimitsService _smartCircuitLimitsService;
        private readonly EnhancedCircuitLimitService _enhancedCircuitLimitService;
        private readonly CircuitLimitChangeService _circuitLimitChangeService;
        private readonly SpotDataService _spotDataService;
        private readonly IServiceScopeFactory _serviceScopeFactory;
        private readonly HistoricalDataService _historicalDataService;
        private readonly IntradayTickDataService _intradayTickDataService;
        
        // Mutex to prevent multiple instances
        private static readonly Mutex _instanceMutex = new Mutex(false, "KiteMarketDataService.Worker.SingleInstance");
        private readonly TimeBasedDataCollectionService _timeBasedCollectionService;
        private readonly ConsolidatedExcelExportService _consolidatedExcelExportService;
        private readonly DailyInitialDataExportService _dailyInitialDataExportService;
        private readonly ExcelFileProtectionService _excelFileProtectionService;
        private readonly BusinessDateCalculationService _businessDateCalculationService;
        private readonly HistoricalSpotDataService _historicalSpotDataService;
        private readonly HistoricalOptionsDataService _historicalOptionsDataService;
        private readonly StrategyExcelExportService _strategyExcelExportService;
        private readonly LabelBackfillService _labelBackfillService;
        private readonly StrikeLatestRecordsService _strikeLatestRecordsService;
        // private readonly DailyCloseDataService _dailyCloseDataService; // TODO: Implement GetHistoricalDataAsync in KiteConnectService
        // Dynamic instrument update interval (30 min during market hours, 6 hours after market)
        // Removed: private readonly TimeSpan _instrumentUpdateInterval = TimeSpan.FromHours(24);
        private DateTime _lastExportTime = DateTime.MinValue; // Track last export time to avoid duplicate exports

        public Worker(
            ILogger<Worker> logger,
            IConfiguration configuration,
            KiteConnectService kiteService,
            MarketDataService marketDataService,
            SmartCircuitLimitsService smartCircuitLimitsService,
            EnhancedCircuitLimitService enhancedCircuitLimitService,
            CircuitLimitChangeService circuitLimitChangeService,
            SpotDataService spotDataService,
            IServiceScopeFactory serviceScopeFactory,
            HistoricalDataService historicalDataService,
            IntradayTickDataService intradayTickDataService,
            TimeBasedDataCollectionService timeBasedCollectionService,
            ConsolidatedExcelExportService consolidatedExcelExportService,
            DailyInitialDataExportService dailyInitialDataExportService,
            ExcelFileProtectionService excelFileProtectionService,
            BusinessDateCalculationService businessDateCalculationService,
            HistoricalSpotDataService historicalSpotDataService,
            HistoricalOptionsDataService historicalOptionsDataService,
            StrategyExcelExportService strategyExcelExportService,
            LabelBackfillService labelBackfillService,
            StrikeLatestRecordsService strikeLatestRecordsService)
            // DailyCloseDataService dailyCloseDataService) // TODO: Implement GetHistoricalDataAsync in KiteConnectService
        {
            _logger = logger;
            _configuration = configuration;
            _kiteService = kiteService;
            _marketDataService = marketDataService;
            _smartCircuitLimitsService = smartCircuitLimitsService;
            _enhancedCircuitLimitService = enhancedCircuitLimitService;
            _circuitLimitChangeService = circuitLimitChangeService;
            _spotDataService = spotDataService;
            _serviceScopeFactory = serviceScopeFactory;
            _historicalDataService = historicalDataService;
            _intradayTickDataService = intradayTickDataService;
            _timeBasedCollectionService = timeBasedCollectionService;
            _consolidatedExcelExportService = consolidatedExcelExportService;
            _dailyInitialDataExportService = dailyInitialDataExportService;
            _excelFileProtectionService = excelFileProtectionService;
            _businessDateCalculationService = businessDateCalculationService;
            _historicalSpotDataService = historicalSpotDataService;
            _historicalOptionsDataService = historicalOptionsDataService;
            _strategyExcelExportService = strategyExcelExportService;
            _labelBackfillService = labelBackfillService;
            _strikeLatestRecordsService = strikeLatestRecordsService;
            // _dailyCloseDataService = dailyCloseDataService; // TODO: Implement GetHistoricalDataAsync in KiteConnectService
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // Check for existing instances
            if (!_instanceMutex.WaitOne(TimeSpan.FromSeconds(1), false))
            {
                _logger.LogWarning("Another instance of Kite Market Data Service is already running!");
                
                Console.ForegroundColor = ConsoleColor.Yellow;
                Console.WriteLine("\n⚠️ SERVICE ALREADY RUNNING!");
                Console.WriteLine("Another instance is already active. Attempting to stop it...");
                Console.ResetColor();
                
                // Try to stop existing instances automatically
                try
                {
                    var existingProcesses = System.Diagnostics.Process.GetProcessesByName("KiteMarketDataService.Worker");
                    foreach (var process in existingProcesses)
                    {
                        try
                        {
                            _logger.LogInformation($"Stopping existing process with PID: {process.Id}");
                            process.Kill();
                            process.WaitForExit(5000); // Wait up to 5 seconds
                            _logger.LogInformation($"Successfully stopped existing process with PID: {process.Id}");
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning($"Failed to stop process {process.Id}: {ex.Message}");
                        }
                    }
                    
                    // Wait a moment for processes to fully terminate
                    await Task.Delay(2000);
                    
                    // Try to acquire mutex again
                    if (_instanceMutex.WaitOne(TimeSpan.FromSeconds(2), false))
                    {
                        _logger.LogInformation("Successfully stopped existing instance and acquired mutex");
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine("✅ Successfully stopped existing instance. Starting new service...");
                        Console.ResetColor();
                    }
                    else
                    {
                        _logger.LogError("Failed to stop existing instance or acquire mutex");
                        Console.ForegroundColor = ConsoleColor.Red;
                        Console.WriteLine("❌ Failed to stop existing instance. Please stop it manually.");
                        Console.WriteLine("⏳ Press any key to exit...");
                        Console.ResetColor();
                        Console.ReadKey();
                        return;
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to stop existing instances automatically");
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("❌ Failed to stop existing instance automatically.");
                    Console.WriteLine("Please stop the existing instance manually and try again.");
                    Console.WriteLine("⏳ Press any key to exit...");
                    Console.ResetColor();
                    Console.ReadKey();
                    return;
                }
            }

            try
            {
                _logger.LogInformation("Kite Market Data Service started - Single instance confirmed");
                
                // Display startup header
                try { Console.Clear(); } catch { /* Ignore console errors when running as service */ }
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine("╔═══════════════════════════════════════════════════════════╗");
                Console.WriteLine("║                                                           ║");
                Console.WriteLine("║         🎯 KITE MARKET DATA SERVICE STARTING...          ║");
                Console.WriteLine("║                                                           ║");
                Console.WriteLine("╚═══════════════════════════════════════════════════════════╝");
                Console.ResetColor();
                Console.WriteLine();
                
                // STEP 1: Mutex Check
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write("✓  Mutex Check........................... ");
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("✓");
                Console.ResetColor();
                
                // STEP 2: Clear log file for fresh start
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write("✓  Log File Setup........................ ");
                Console.ResetColor();
                ClearLogFile();
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("✓");
                Console.ResetColor();

                // STEP 3: Ensure database is created
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write("✓  Database Setup........................ ");
                Console.ResetColor();
                await _marketDataService.EnsureDatabaseCreatedAsync();
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("✓");
                Console.ResetColor();

                // STEP 4: Get request token from configuration
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write("✓  Request Token & Authentication........ ");
                Console.ResetColor();
                var requestToken = _configuration["KiteConnect:RequestToken"];
                
                if (string.IsNullOrEmpty(requestToken))
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("⚠️ (no token - service starts in token-required mode)");
                    Console.ResetColor();
                    
                    _logger.LogWarning("No request token found in configuration. Service will start in token-required mode.");
                    _logger.LogWarning("Please provide token via web interface at http://localhost:5000/token-management.html");
                    
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine("\n📋 Next Steps:");
                    Console.WriteLine("1. Service will start and web interface will be available");
                    Console.WriteLine("2. Go to: http://localhost:5000/token-management.html");
                    Console.WriteLine("3. Provide your request token via web interface");
                    Console.ResetColor();
                }
                else
                {
                    _logger.LogInformation("Request token found in configuration. Attempting to authenticate...");
                    
                    // Authenticate with the provided request token
                    var isAuthenticated = await _kiteService.AuthenticateWithRequestTokenAsync(requestToken);
                    
                    if (!isAuthenticated)
                    {
                        Console.ForegroundColor = ConsoleColor.Yellow;
                        Console.WriteLine("⚠️ (auth failed - service starts in token-required mode)");
                        Console.ResetColor();
                        
                        _logger.LogWarning("Failed to authenticate with provided request token. Service will start in token-required mode.");
                        _logger.LogWarning("Please provide valid token via web interface at http://localhost:5000/token-management.html");
                        
                        Console.ForegroundColor = ConsoleColor.Cyan;
                        Console.WriteLine("\n📋 Next Steps:");
                        Console.WriteLine("1. Service will start and web interface will be available");
                        Console.WriteLine("2. Go to: http://localhost:5000/token-management.html");
                        Console.WriteLine("3. Provide a valid request token via web interface");
                        Console.ResetColor();
                    }
                    else
                    {
                        _logger.LogInformation("Authentication successful! Service is ready to collect data.");
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine("✓");
                        Console.ResetColor();
                    }
                }

                // STEP 5: Load initial instruments
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write("✓  Instruments Loading................... ");
                Console.ResetColor();
                await LoadInstrumentsAsync();
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("✓");
                Console.ResetColor();

                // STEP 6: Collect historical spot data (needed for business date calculation)
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write("✓  Historical Spot Data Collection....... ");
                Console.ResetColor();
                
                // Only collect historical data if we have authentication
                var hasToken = !string.IsNullOrEmpty(_configuration["KiteConnect:RequestToken"]);
                if (hasToken)
                {
                    await _historicalSpotDataService.CollectAndStoreHistoricalDataAsync();
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("✓");
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("⚠️ (skipped - need authentication)");
                }
                Console.ResetColor();

                // STEP 7: Calculate business date (using spot data)
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write("✓  Business Date Calculation............. ");
                Console.ResetColor();
                var calculatedBusinessDate = await _businessDateCalculationService.CalculateBusinessDateAsync();
                if (calculatedBusinessDate.HasValue)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("✓");
                    Console.ResetColor();
                    
                    // Show essential information on console
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine($"📅 Business Date: {calculatedBusinessDate.Value:yyyy-MM-dd}");
                    Console.ResetColor();
                    
                    _logger.LogInformation($"Business Date calculated: {calculatedBusinessDate.Value:yyyy-MM-dd}");
                }
                else
                {
                    calculatedBusinessDate = DateTime.UtcNow.AddHours(5.5).Date;
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("⚠️ (using fallback)");
                    Console.ResetColor();
                    
                    // Show essential information on console
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine($"📅 Business Date (Fallback): {calculatedBusinessDate.Value:yyyy-MM-dd}");
                    Console.ResetColor();
                    
                    _logger.LogWarning($"Using fallback business date: {calculatedBusinessDate.Value:yyyy-MM-dd}");
                }

                // STEP 8: Initialize circuit limits (pass calculated business date)
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write("✓  Circuit Limits Setup.................. ");
                Console.ResetColor();
                await _enhancedCircuitLimitService.InitializeBaselineFromLastTradingDayAsync(calculatedBusinessDate);
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("✓");
                Console.ResetColor();

                // Initialize Excel file protection (silent - no console output)
                await _excelFileProtectionService.EnsureExcelDirectoriesAreProtectedAsync();
                await _excelFileProtectionService.LogExcelFileStatusAsync();

                // Strategy Export - Silent processing (only log to file)
                try
                {
                    var enableStrategyExport = _configuration.GetValue<bool>("StrategyExport:EnableExport");
                    if (enableStrategyExport)
                    {
                        await _labelBackfillService.BackfillLabelsAsync();
                        await _strategyExcelExportService.ExportStrategyAnalysisAsync();
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to export strategy analysis at startup");
                }

                // STEP 9: Service Ready
                Console.ForegroundColor = ConsoleColor.White;
                Console.Write("✓  Service Ready......................... ");
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("✓");
                Console.ResetColor();
                
                // Show essential configuration information
                var primaryExpiry = _configuration["PrimaryExpiry"];
                if (!string.IsNullOrEmpty(primaryExpiry))
                {
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine($"🎯 Primary Expiry: {primaryExpiry}");
                    Console.ResetColor();
                }
                
                Console.WriteLine();
                Console.ForegroundColor = ConsoleColor.Green;
                Console.WriteLine("╔═══════════════════════════════════════════════════════════╗");
                Console.WriteLine("║                                                           ║");
                Console.WriteLine("║         🚀 SERVICE READY - DATA COLLECTION STARTED       ║");
                Console.WriteLine($"║            Business Date: {calculatedBusinessDate.Value:yyyy-MM-dd}                       ║");
                Console.WriteLine("║                                                           ║");
                Console.WriteLine("╚═══════════════════════════════════════════════════════════╝");
                Console.ResetColor();
                Console.WriteLine();

                var lastInstrumentUpdate = DateTime.UtcNow;


                while (!stoppingToken.IsCancellationRequested)
                {
                    try
                    {
                        // Update instruments dynamically based on market hours
                        var instrumentUpdateInterval = GetInstrumentUpdateInterval();
                        if (DateTime.UtcNow - lastInstrumentUpdate > instrumentUpdateInterval)
                        {
                            var istTime = DateTime.UtcNow.AddHours(5.5);
                            var intervalDesc = instrumentUpdateInterval.TotalMinutes < 60 
                                ? $"{instrumentUpdateInterval.TotalMinutes} minutes" 
                                : $"{instrumentUpdateInterval.TotalHours} hours";
                            
                            Console.ForegroundColor = ConsoleColor.Magenta;
                            Console.WriteLine($"\n🔄 [{istTime:HH:mm:ss}] Updating INSTRUMENTS from Kite API (every {intervalDesc})...");
                            Console.ResetColor();
                            
                            // Recalculate business date before updating instruments
                            var currentBusinessDate = await _businessDateCalculationService.CalculateBusinessDateAsync();
                            await LoadInstrumentsAsync(currentBusinessDate);
                            
                            lastInstrumentUpdate = DateTime.UtcNow;
                            Console.ForegroundColor = ConsoleColor.Green;
                            Console.WriteLine($"✅ [{istTime:HH:mm:ss}] INSTRUMENTS update completed!");
                            Console.ResetColor();
                        }

                        // Collect historical spot data periodically
                        Console.ForegroundColor = ConsoleColor.Yellow;
                        Console.WriteLine($"\n🔄 [{DateTime.Now:HH:mm:ss}] Collecting HISTORICAL SPOT DATA...");
                        Console.ResetColor();
                        await _historicalSpotDataService.CollectAndStoreHistoricalDataAsync();
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine($"✅ [{DateTime.Now:HH:mm:ss}] HISTORICAL SPOT DATA collection completed!");
                        Console.ResetColor();

                        // Use time-based data collection service
                        Console.ForegroundColor = ConsoleColor.Cyan;
                        Console.WriteLine($"\n🔄 [{DateTime.Now:HH:mm:ss}] Starting TIME-BASED DATA COLLECTION...");
                        Console.ResetColor();
                        await _timeBasedCollectionService.CollectDataAsync();
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine($"✅ [{DateTime.Now:HH:mm:ss}] TIME-BASED DATA COLLECTION completed!");
                        Console.ResetColor();

                        // Process circuit limit changes (after collecting quotes)
                        Console.ForegroundColor = ConsoleColor.Blue;
                        Console.WriteLine($"🔄 [{DateTime.Now:HH:mm:ss}] Processing LC/UC CHANGES...");
                        Console.ResetColor();
                        await ProcessCircuitLimitChangesAsync();
                        
                        // Store intraday tick data (every minute)
                        Console.ForegroundColor = ConsoleColor.Magenta;
                        Console.WriteLine($"🔄 [{DateTime.Now:HH:mm:ss}] Storing INTRADAY TICK DATA...");
                        Console.ResetColor();
                        await _intradayTickDataService.StoreIntradayTickDataAsync();
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine($"✅ [{DateTime.Now:HH:mm:ss}] INTRADAY TICK DATA storage completed!");
                        Console.ResetColor();
                        
                        // Export initial data (always export initial data for the day)
                        await ExportDailyInitialDataAsync();
                        
                        // Check if LC/UC changes occurred and trigger Excel export
                        var lcUcChangesDetected = await CheckForLCUCChangesAndExportAsync();
                        if (lcUcChangesDetected)
                        {
                            Console.ForegroundColor = ConsoleColor.Yellow;
                            Console.WriteLine($"📊 [{DateTime.Now:HH:mm:ss}] LC/UC changes detected - Creating consolidated Excel export...");
                            Console.ResetColor();
                            await _consolidatedExcelExportService.CreateDailyConsolidatedExportAsync();
                        }
                        
                        Console.ForegroundColor = ConsoleColor.Green;
                        Console.WriteLine($"✅ [{DateTime.Now:HH:mm:ss}] All processing completed! Waiting for next cycle...");
                        Console.ResetColor();

                                    // TEMPORARILY DISABLED: Historical data enhancement to fix service
                // Enhance quotes with historical data (every 5 minutes)
                /*
                if (DateTime.UtcNow.Minute % 5 == 0)
                {
                    await EnhanceQuotesWithHistoricalDataAsync();
                }
                */

                        // Cleanup old data (once per day)
                        if (DateTime.UtcNow.Hour == 2 && DateTime.UtcNow.Minute == 0)
                        {
                            await _marketDataService.CleanupOldDataAsync(30);
                        }

                        // TODO: Download daily close data after market closes (4:00 PM IST = 10:30 AM UTC)
                        // var istTime = DateTime.UtcNow.AddHours(5.5);
                        // if (istTime.Hour == 16 && istTime.Minute == 0) // 4:00 PM IST
                        // {
                        //     var previousTradingDay = GetPreviousTradingDay(istTime);
                        //     _logger.LogInformation($"Market closed - downloading daily close data for {previousTradingDay:yyyy-MM-dd}");
                        //     await _dailyCloseDataService.SaveDailyCloseDataAsync(previousTradingDay);
                        // }

                        // Archive today's options data DAILY (preserves data before Kite API discontinues it)
                        var currentIstTime = DateTime.UtcNow.AddHours(5.5);
                        if (currentIstTime.Hour == 16 && currentIstTime.Minute == 0) // 4:00 PM IST
                        {
                            try
                            {
                                var todayBusinessDate = currentIstTime.Date;
                                
                                _logger.LogInformation($"📦 Running DAILY options data archival for {todayBusinessDate:yyyy-MM-dd}...");
                                
                                // Archive TODAY's data (last record of each instrument)
                                // This captures final LC/UC values including after-hours changes
                                await _historicalOptionsDataService.ArchiveDailyOptionsDataAsync(todayBusinessDate);
                                
                                _logger.LogInformation("✅ Daily options data archival completed!");
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, "Failed to run daily options data archival");
                            }
                        }

                        // Use dynamic interval based on market hours
                        var nextInterval = _timeBasedCollectionService.GetNextCollectionInterval();
                        await Task.Delay(nextInterval, stoppingToken);
                    }
                    catch (OperationCanceledException)
                    {
                        break;
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error in main service loop");
                        await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken); // Wait 5 minutes before retrying
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Fatal error in worker service");
            }
            finally
            {
                // Release the mutex when the service stops
                _instanceMutex.ReleaseMutex();
                _logger.LogInformation("Service instance mutex released");
            }
        }

        /// <summary>
        /// Get dynamic instrument update interval based on market hours
        /// Market hours (9:15 AM - 3:30 PM IST): Every 30 minutes (to catch intraday strike additions)
        /// After hours: Every 6 hours (less frequent, save API calls)
        /// </summary>
        private TimeSpan GetInstrumentUpdateInterval()
        {
            var istTime = DateTime.UtcNow.AddHours(5.5);
            var timeOfDay = istTime.TimeOfDay;
            
            // Market hours: 9:15 AM - 3:30 PM IST
            var marketOpen = new TimeSpan(9, 15, 0);
            var marketClose = new TimeSpan(15, 30, 0);
            
            if (timeOfDay >= marketOpen && timeOfDay <= marketClose)
            {
                // During market hours: refresh every 30 minutes to catch new strikes
                return TimeSpan.FromMinutes(30);
            }
            else
            {
                // After market hours: refresh every 6 hours (less frequent)
                return TimeSpan.FromHours(6);
            }
        }

        private async Task LoadInstrumentsAsync(DateTime? businessDate = null)
        {
            try
            {
                // Use provided business date or fallback to current IST date
                var effectiveBusinessDate = businessDate ?? DateTime.UtcNow.AddHours(5.5).Date;
                
                _logger.LogInformation($"📅 Loading/Updating instruments for business date: {effectiveBusinessDate:yyyy-MM-dd}");
                
                // Get fresh instruments from Kite Connect API
                _logger.LogInformation("📡 Fetching fresh instruments from Kite Connect API...");
                var apiInstruments = await _kiteService.GetInstrumentsListAsync();
                
                if (!apiInstruments.Any())
                {
                    _logger.LogWarning("⚠️ No instruments returned by Kite API - likely authentication issue. Will retry when token is provided.");
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("⚠️ (no instruments - need authentication)");
                    Console.ResetColor();
                    return;
                }

                // OPTIMIZED: Check which instruments are new (no date filter - check ALL existing instruments)
                using var scope = _serviceScopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();
                
                // Query ALL existing tokens (no LoadDate filter)
                var existingTokens = await context.Instruments
                    .Select(i => i.InstrumentToken)
                    .ToHashSetAsync();

                _logger.LogInformation($"Found {existingTokens.Count} existing instruments in database");

                // Filter only NEW instruments
                var newInstruments = apiInstruments
                    .Where(i => !existingTokens.Contains(i.InstrumentToken))
                    .ToList();

                if (newInstruments.Any())
                {
                    // Save ONLY new instruments with FirstSeenDate = today
                    await _marketDataService.SaveInstrumentsAsync(newInstruments, effectiveBusinessDate);
                    _logger.LogInformation($"✅ Added {newInstruments.Count} NEW instruments (FirstSeenDate: {effectiveBusinessDate:yyyy-MM-dd})");
                    
                    Console.ForegroundColor = ConsoleColor.Cyan;
                    Console.WriteLine($"✅ Added {newInstruments.Count} NEW instruments (Total in DB: {existingTokens.Count + newInstruments.Count})");
                    Console.ResetColor();
                }
                else
                {
                    _logger.LogInformation($"✅ No new instruments found - all {apiInstruments.Count} instruments already exist in database");
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine($"✅ No new instruments - using existing {existingTokens.Count} instruments");
                    Console.ResetColor();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to load instruments");
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine($"❌ Error loading instruments: {ex.Message}");
                Console.ResetColor();
            }
        }

        private async Task CollectMarketQuotesAsync()
        {
            try
            {
                _logger.LogInformation("=== STARTING MARKET QUOTE COLLECTION ===");
                _logger.LogInformation($"Collection started at: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");

                // Get real instruments from database with their tokens (options only)
                var instruments = await _marketDataService.GetOptionInstrumentsAsync();
                
                if (!instruments.Any())
                {
                    _logger.LogWarning("No instruments available for quote collection");
                    return;
                }

                _logger.LogInformation($"Total instruments found in database: {instruments.Count}");
                
                // Log instrument distribution by type and underlying
                var instrumentTypeGroups = instruments.GroupBy(i => i.InstrumentType).ToList();
                _logger.LogInformation($"Instrument type distribution:");
                foreach (var group in instrumentTypeGroups)
                {
                    _logger.LogInformation($"  {group.Key}: {group.Count()} instruments");
                }

                var instrumentGroups = instruments.GroupBy(i => i.TradingSymbol.Substring(0, Math.Min(10, i.TradingSymbol.Length))).ToList();
                _logger.LogInformation($"Instrument distribution by underlying:");
                foreach (var group in instrumentGroups.Take(5)) // Log first 5 groups
                {
                    _logger.LogInformation($"  {group.Key}: {group.Count()} instruments");
                }

                // Get quotes from Kite Connect using real instrument tokens
                var instrumentTokens = instruments.Select(i => i.InstrumentToken.ToString()).ToList();
                _logger.LogInformation($"Requesting quotes for {instrumentTokens.Count} instrument tokens from Kite Connect API");
                
                var quoteResponse = await _kiteService.GetMarketQuotesAsync(instrumentTokens);
                
                if (quoteResponse?.Data == null)
                {
                    _logger.LogWarning("No quote response received from Kite Connect");
                    return;
                }

                _logger.LogInformation($"API Response Status: {quoteResponse.Status}");

                if (!quoteResponse.Data.Any())
                {
                    _logger.LogWarning($"Quote response received but no data. Response status: {quoteResponse.Status}");
                    _logger.LogInformation("This might be normal if market is closed or instruments are not trading");
                    return;
                }

                _logger.LogInformation($"Received quotes for {quoteResponse.Data.Count} instruments out of {instrumentTokens.Count} requested");
                _logger.LogInformation($"Success rate: {(double)quoteResponse.Data.Count / instrumentTokens.Count * 100:F1}%");

                // Log which instruments got quotes vs which didn't
                var receivedTokens = quoteResponse.Data.Keys.ToHashSet();
                var missingTokens = instrumentTokens.Except(receivedTokens).ToList();
                
                if (missingTokens.Any())
                {
                    _logger.LogWarning($"Missing quotes for {missingTokens.Count} instruments:");
                    foreach (var missingToken in missingTokens.Take(10)) // Log first 10 missing
                    {
                        var instrument = instruments.FirstOrDefault(i => i.InstrumentToken.ToString() == missingToken);
                        _logger.LogWarning($"  Token {missingToken}: {instrument?.TradingSymbol ?? "Unknown"}");
                    }
                    if (missingTokens.Count > 10)
                    {
                        _logger.LogWarning($"  ... and {missingTokens.Count - 10} more missing instruments");
                    }
                }

                // Convert to MarketQuote entities
                var marketQuotes = new List<MarketQuote>();
                var instrumentsWithoutLCUC = new List<string>();
                
                // Create a lookup dictionary for instrument tokens to instrument details
                var instrumentLookup = instruments.ToDictionary(i => i.InstrumentToken.ToString(), i => i);
                
                foreach (var quote in quoteResponse.Data)
                {
                    var marketQuote = ConvertToMarketQuote(quote.Key, quote.Value, instrumentLookup, quoteResponse.Data);
                    if (marketQuote != null)
                    {
                        // Check if LC/UC values are available
                        if (marketQuote.LowerCircuitLimit == 0 && marketQuote.UpperCircuitLimit == 0)
                        {
                            instrumentsWithoutLCUC.Add($"{marketQuote.TradingSymbol}");
                        }
                        marketQuotes.Add(marketQuote);
                    }
                }

                _logger.LogInformation($"Successfully converted {marketQuotes.Count} quotes to MarketQuote entities");
                
                // Log instruments without LC/UC values
                if (instrumentsWithoutLCUC.Any())
                {
                    var logMessage = $"Instruments without LC/UC values ({instrumentsWithoutLCUC.Count}):\n{string.Join("\n", instrumentsWithoutLCUC)}";
                    _logger.LogWarning(logMessage);
                    
                    // Write to separate log file
                    var logFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs", $"instruments_without_lcuc_{DateTime.Now:yyyyMMdd}.log");
                    var logDirectory = Path.GetDirectoryName(logFilePath);
                    if (!string.IsNullOrEmpty(logDirectory))
                    {
                        Directory.CreateDirectory(logDirectory);
                    }
                    File.AppendAllText(logFilePath, $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] {logMessage}\n");
                }

                        // ENHANCED: Create fallback quotes for missing strikes with LC/UC from last available database data
        var fallbackQuotes = await CreateFallbackQuotesForMissingStrikesAsync(instruments, receivedTokens, instrumentLookup);
        if (fallbackQuotes.Any())
        {
            marketQuotes.AddRange(fallbackQuotes);
            _logger.LogInformation($"Added {fallbackQuotes.Count} fallback quotes for missing strikes using last available data");
        }

                // CRITICAL: Verify we have data for ALL strikes
                await VerifyAllStrikesHaveDataAsync(instruments, marketQuotes);

                // Calculate correct business date and update all quotes
                if (marketQuotes.Any())
                {
                    var correctBusinessDate = await _businessDateCalculationService.CalculateBusinessDateAsync();
                    if (correctBusinessDate.HasValue)
                    {
                        _logger.LogInformation($"✅ Using calculated business date: {correctBusinessDate.Value:yyyy-MM-dd}");
                        
                        // Update all quotes with the correct business date
                        foreach (var quote in marketQuotes)
                        {
                            quote.BusinessDate = correctBusinessDate.Value;
                        }
                    }
                    else
                    {
                        _logger.LogWarning("⚠️ Could not calculate business date - quotes will use default date");
                    }
                }

                // Save to database
                if (marketQuotes.Any())
                {
                    await _marketDataService.SaveMarketQuotesAsync(marketQuotes);
                    _logger.LogInformation($"Collected and saved {marketQuotes.Count} market quotes to database");
                    
                    // Update StrikeLatestRecords table (maintain only latest 3 records per strike)
                    try
                    {
                        await _strikeLatestRecordsService.UpdateStrikeLatestRecordsAsync(marketQuotes);
                        _logger.LogInformation($"✅ Updated latest 3 records for {marketQuotes.Count} strikes");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "❌ Error updating StrikeLatestRecords");
                    }
                    
                    // Process enhanced circuit limit tracking
                    await _enhancedCircuitLimitService.ProcessEnhancedCircuitLimitsAsync(marketQuotes);
                    
                    // Log summary by underlying
                    var quoteGroups = marketQuotes.GroupBy(q => q.TradingSymbol.Substring(0, Math.Min(10, q.TradingSymbol.Length))).ToList();
                    _logger.LogInformation($"Saved quotes by underlying:");
                    foreach (var group in quoteGroups.Take(5))
                    {
                        _logger.LogInformation($"  {group.Key}: {group.Count()} quotes");
                    }
                }
                else
                {
                    _logger.LogInformation("No valid quotes to save");
                }
                
                _logger.LogInformation("=== MARKET QUOTE COLLECTION COMPLETED ===");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to collect market quotes");
            }
        }

        private async Task VerifyAllStrikesHaveDataAsync(List<Instrument> allInstruments, List<MarketQuote> collectedQuotes)
        {
            try
            {
                _logger.LogInformation("=== VERIFYING ALL STRIKES HAVE DATA ===");
                
                var collectedTokens = collectedQuotes.Select(q => q.InstrumentToken).ToHashSet();
                var missingInstruments = allInstruments.Where(i => !collectedTokens.Contains(i.InstrumentToken)).ToList();
                
                if (missingInstruments.Any())
                {
                    _logger.LogWarning($"CRITICAL: {missingInstruments.Count} instruments still missing data after fallback!");
                    
                    // Log missing instruments by underlying
                    var missingGroups = missingInstruments.GroupBy(i => i.TradingSymbol.Substring(0, Math.Min(10, i.TradingSymbol.Length))).ToList();
                    foreach (var group in missingGroups)
                    {
                        _logger.LogWarning($"  {group.Key}: {group.Count()} missing instruments");
                        foreach (var instrument in group.Take(5))
                        {
                            _logger.LogWarning($"    {instrument.TradingSymbol} (Token: {instrument.InstrumentToken})");
                        }
                    }
                    
                    // Attempt to fetch missing data with individual API calls
                    await FetchMissingDataIndividuallyAsync(missingInstruments, collectedQuotes);
                }
                else
                {
                    _logger.LogInformation("✅ SUCCESS: All instruments have data!");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to verify all strikes have data");
            }
        }

        private async Task FetchMissingDataIndividuallyAsync(List<Instrument> missingInstruments, List<MarketQuote> existingQuotes)
        {
            try
            {
                _logger.LogInformation($"=== FETCHING MISSING DATA INDIVIDUALLY ===");
                _logger.LogInformation($"Attempting to fetch data for {missingInstruments.Count} missing instruments individually");
                
                var additionalQuotes = new List<MarketQuote>();
                var successCount = 0;
                var failureCount = 0;
                
                foreach (var instrument in missingInstruments) // Process ALL missing instruments
                {
                    try
                    {
                        _logger.LogInformation($"Fetching individual data for {instrument.TradingSymbol} (Token: {instrument.InstrumentToken})");
                        
                        // Make individual API call for this instrument
                        var individualResponse = await _kiteService.GetMarketQuotesAsync(new List<string> { instrument.InstrumentToken.ToString() });
                        
                        if (individualResponse?.Data != null && individualResponse.Data.Any())
                        {
                            var quote = individualResponse.Data.First();
                            var marketQuote = ConvertToMarketQuote(quote.Key, quote.Value, new Dictionary<string, Instrument> { { instrument.InstrumentToken.ToString(), instrument } });
                            
                            if (marketQuote != null)
                            {
                                additionalQuotes.Add(marketQuote);
                                successCount++;
                                _logger.LogInformation($"✅ Successfully fetched data for {instrument.TradingSymbol}");
                            }
                        }
                        else
                        {
                            failureCount++;
                            _logger.LogWarning($"❌ Failed to fetch data for {instrument.TradingSymbol}");
                        }
                        
                        // Add delay between individual calls
                        await Task.Delay(500);
                    }
                    catch (Exception ex)
                    {
                        failureCount++;
                        _logger.LogError(ex, $"Failed to fetch individual data for {instrument.TradingSymbol}");
                    }
                }
                
                if (additionalQuotes.Any())
                {
                    existingQuotes.AddRange(additionalQuotes);
                    _logger.LogInformation($"Added {additionalQuotes.Count} additional quotes from individual API calls");
                    _logger.LogInformation($"Success: {successCount}, Failures: {failureCount}");
                }
                else
                {
                    _logger.LogWarning("No additional data could be fetched individually");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to fetch missing data individually");
            }
        }

        private async Task<List<MarketQuote>> CreateFallbackQuotesForMissingStrikesAsync(List<Instrument> allInstruments, HashSet<string> receivedTokens, Dictionary<string, Instrument> instrumentLookup)
        {
            var fallbackQuotes = new List<MarketQuote>();
            
            try
            {
                // Get missing instruments
                var missingInstruments = allInstruments.Where(i => !receivedTokens.Contains(i.InstrumentToken.ToString())).ToList();
                
                if (!missingInstruments.Any())
                {
                    return fallbackQuotes;
                }

                _logger.LogInformation($"Creating fallback quotes for {missingInstruments.Count} missing strikes");

                // Get latest LC/UC data from previous trading day or today's existing data
                var latestQuotes = await _marketDataService.GetLatestQuotesForInstrumentsAsync(missingInstruments.Select(i => i.InstrumentToken).ToList());
                
                var currentTime = DateTime.UtcNow.AddHours(5.5); // Use IST time
                
                foreach (var instrument in missingInstruments)
                {
                    // Try to find existing quote data for this instrument
                    var existingQuote = latestQuotes.FirstOrDefault(q => q.InstrumentToken == instrument.InstrumentToken);
                    
                    if (existingQuote != null)
                    {
                        // Create fallback quote with existing LC/UC but current timestamp
                        var fallbackQuote = new MarketQuote
                        {
                            // Essential Properties Only (Cleaned Schema)
                            TradingSymbol = instrument.TradingSymbol,
                            InstrumentToken = instrument.InstrumentToken, // CRITICAL: Keep for API integration
                            Strike = instrument.Strike,
                            OptionType = instrument.InstrumentType,
                            ExpiryDate = instrument.Expiry ?? DateTime.MinValue,
                            
                            // Use existing OHLC and LC/UC data
                            OpenPrice = existingQuote.OpenPrice,
                            HighPrice = existingQuote.HighPrice,
                            LowPrice = existingQuote.LowPrice,
                            ClosePrice = existingQuote.ClosePrice,
                            LastPrice = existingQuote.LastPrice,
                            LowerCircuitLimit = existingQuote.LowerCircuitLimit,
                            UpperCircuitLimit = existingQuote.UpperCircuitLimit,
                            
                            // Timing
                            LastTradeTime = existingQuote.LastTradeTime,
                            RecordDateTime = DateTime.UtcNow.AddHours(5.5), // Current IST time
                            BusinessDate = DateTime.UtcNow.AddHours(5.5).Date, // Will be updated by BusinessDateCalculationService
                            InsertionSequence = 1 // Will be updated by sequence logic
                        };
                        
                        fallbackQuotes.Add(fallbackQuote);
                    }
                    else
                    {
                        // If no existing data, create minimal quote with default LC/UC based on strike
                        var fallbackQuote = new MarketQuote
                        {
                            // Essential Properties Only (Cleaned Schema)
                            TradingSymbol = instrument.TradingSymbol,
                            InstrumentToken = instrument.InstrumentToken, // CRITICAL: Keep for API integration
                            Strike = instrument.Strike,
                            OptionType = instrument.InstrumentType,
                            ExpiryDate = instrument.Expiry ?? DateTime.MinValue,
                            
                            // Default values for non-traded strikes
                            OpenPrice = 0,
                            HighPrice = 0,
                            LowPrice = 0,
                            ClosePrice = 0,
                            LastPrice = 0,
                            LowerCircuitLimit = 0, // Will be updated by circuit limit service
                            UpperCircuitLimit = 0, // Will be updated by circuit limit service
                            
                            // Timing
                            LastTradeTime = DateTime.MinValue,
                            RecordDateTime = DateTime.UtcNow.AddHours(5.5), // Current IST time
                            BusinessDate = DateTime.UtcNow.AddHours(5.5).Date, // Will be updated by BusinessDateCalculationService
                            InsertionSequence = 1 // Will be updated by sequence logic
                        };
                        
                        fallbackQuotes.Add(fallbackQuote);
                    }
                }
                
                _logger.LogInformation($"Created {fallbackQuotes.Count} fallback quotes for missing strikes");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create fallback quotes for missing strikes");
            }
            
            return fallbackQuotes;
        }

        // Aggressive window helper intentionally removed for stability today

        private MarketQuote? ConvertToMarketQuote(string instrumentKey, QuoteData quoteData, Dictionary<string, Instrument> instrumentLookup, Dictionary<string, QuoteData>? allQuotes = null)
        {
            try
            {
                // The instrumentKey is actually the instrument token from Kite Connect
                if (!long.TryParse(instrumentKey, out var instrumentToken))
                {
                    _logger.LogWarning($"Invalid instrument token format: {instrumentKey}");
                    return null;
                }

                // Look up the instrument details from our database
                if (!instrumentLookup.TryGetValue(instrumentKey, out var instrument))
                {
                    _logger.LogWarning($"Instrument not found in database for token: {instrumentKey}");
                    return null;
                }

                var quoteTimestamp = GetValidTimestamp(quoteData.Timestamp, quoteData.LastTradeTime, allQuotes);
                var tradingTimestamp = GetTradingTimestamp(quoteData.LastTradeTime, quoteData.Timestamp);
                
                // TEMPORARILY DISABLED: Historical data enhancement to fix service
                // Check if we need to use historical data for missing OHLC values
                /*
                var useHistoricalData = (quoteData.OHLC?.Open == 0 || 
                                        quoteData.OHLC?.High == 0 || 
                                        quoteData.OHLC?.Low == 0 || 
                                        quoteData.OHLC?.Close == 0) &&
                                       !string.IsNullOrEmpty(quoteData.LastTradeTime); // Only if LTT exists

                if (useHistoricalData)
                {
                    _logger.LogDebug($"Instrument {instrument.TradingSymbol} has zero values, will use historical data if available");
                }
                */
                
                var marketQuote = new MarketQuote
                {
                    // Essential Properties Only (Cleaned Schema)
                    TradingSymbol = instrument.TradingSymbol,
                    InstrumentToken = quoteData.InstrumentToken, // CRITICAL: Keep for API integration
                    Strike = instrument.Strike,
                    OptionType = instrument.InstrumentType,
                    ExpiryDate = instrument.Expiry?.Date ?? DateTime.MinValue,
                    
                    // OHLC Data
                    OpenPrice = quoteData.OHLC?.Open ?? 0,
                    HighPrice = quoteData.OHLC?.High ?? 0,
                    LowPrice = quoteData.OHLC?.Low ?? 0,
                    ClosePrice = quoteData.OHLC?.Close ?? 0,
                    LastPrice = quoteData.LastPrice,
                    
                    // Circuit Limits (CRITICAL)
                    LowerCircuitLimit = quoteData.LowerCircuitLimit,
                    UpperCircuitLimit = quoteData.UpperCircuitLimit,
                    
                    // Timing
                    LastTradeTime = !string.IsNullOrEmpty(quoteData.LastTradeTime) && DateTime.TryParse(quoteData.LastTradeTime, out var ltt) ? ltt : DateTime.MinValue,
                    RecordDateTime = DateTime.UtcNow.AddHours(5.5), // Current IST time
                    BusinessDate = DateTime.UtcNow.AddHours(5.5).Date, // Will be updated by BusinessDateCalculationService
                    InsertionSequence = 1 // Will be updated by sequence logic
                };

                // Market depth data removed - not needed for LC/UC monitoring

                // TEMPORARILY DISABLED: Historical data enhancement to fix service
                // If this instrument has zero values, mark it for historical data enhancement
                /*
                if (useHistoricalData)
                {
                    marketQuote.CreatedAt = DateTime.UtcNow.AddHours(5.5); // Set IST timestamp
                    _logger.LogDebug($"Marked {instrument.TradingSymbol} for historical data enhancement");
                }
                */

                // All market depth data removed - not needed for LC/UC monitoring

                return marketQuote;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to convert quote data for {instrumentKey}");
                return null;
            }
        }

        private async Task ProcessSmartCircuitLimitsAsync()
        {
            try
            {
                _logger.LogInformation("Processing smart circuit limits...");
                
                await _smartCircuitLimitsService.ProcessSmartCircuitLimitsAsync();
                
                _logger.LogInformation("Smart circuit limits processing completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process smart circuit limits");
            }
        }

        private async Task ProcessCircuitLimitChangesAsync()
        {
            try
            {
                _logger.LogInformation("=== STARTING CIRCUIT LIMIT CHANGE PROCESSING ===");
                
                // Get current quotes from database for processing
                using var scope = _serviceScopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();
                
                var currentQuotes = await context.MarketQuotes
                    .Where(q => q.RecordDateTime >= DateTime.UtcNow.AddMinutes(-5)) // Last 5 minutes
                    .ToListAsync();
                
                _logger.LogInformation($"Found {currentQuotes.Count} quotes from last 5 minutes for circuit limit processing");
                
                if (currentQuotes.Any())
                {
                    // Log sample data for debugging
                    var sampleQuotes = currentQuotes.Take(3).ToList();
                    _logger.LogInformation("Sample quotes for circuit limit processing:");
                    foreach (var quote in sampleQuotes)
                    {
                        _logger.LogInformation($"  {quote.TradingSymbol}: LC={quote.LowerCircuitLimit}, UC={quote.UpperCircuitLimit}, LTP={quote.LastPrice}");
                    }
                    
                    // Check how many have valid circuit limits
                    var validCircuitLimitQuotes = currentQuotes.Where(q => q.LowerCircuitLimit > 0 || q.UpperCircuitLimit > 0).ToList();
                    _logger.LogInformation($"Quotes with valid circuit limits: {validCircuitLimitQuotes.Count}/{currentQuotes.Count}");
                    
                    if (validCircuitLimitQuotes.Any())
                    {
                        _logger.LogInformation("Calling CircuitLimitChangeService.ProcessCircuitLimitChangesAsync...");
                        await _circuitLimitChangeService.ProcessCircuitLimitChangesAsync(validCircuitLimitQuotes);
                        _logger.LogInformation("CircuitLimitChangeService processing completed");
                    }
                    else
                    {
                        _logger.LogWarning("No quotes with valid circuit limits found - skipping circuit limit change processing");
                    }
                }
                else
                {
                    _logger.LogWarning("No recent quotes found for circuit limit processing");
                }
                
                _logger.LogInformation("=== CIRCUIT LIMIT CHANGE PROCESSING COMPLETED ===");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to process circuit limit changes");
            }
        }

        /// <summary>
        /// Get the previous trading day (skip weekends)
        /// </summary>
        private DateTime GetPreviousTradingDay(DateTime currentDate)
        {
            var previousDay = currentDate.AddDays(-1);
            
            // Skip weekends
            while (previousDay.DayOfWeek == DayOfWeek.Saturday || previousDay.DayOfWeek == DayOfWeek.Sunday)
            {
                previousDay = previousDay.AddDays(-1);
            }
            
            return previousDay.Date;
        }

        /// <summary>
        /// Enhance quotes with historical data when current data has zero values
        /// </summary>
        private async Task EnhanceQuotesWithHistoricalDataAsync()
        {
            try
            {
                _logger.LogInformation("Enhancing quotes with historical data...");
                
                using var scope = _serviceScopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();
                
                // Find quotes with missing OHLC values that need historical data (don't care about LC/UC)
                var quotesNeedingHistoricalData = await context.MarketQuotes
                    .Where(q => (q.OpenPrice == 0 || q.HighPrice == 0 || q.LowPrice == 0 || q.ClosePrice == 0) &&
                               q.RecordDateTime >= DateTime.UtcNow.AddHours(-1)) // Last hour
                    .ToListAsync();

                if (!quotesNeedingHistoricalData.Any())
                {
                    _logger.LogDebug("No quotes need historical data enhancement");
                    return;
                }

                _logger.LogInformation($"Found {quotesNeedingHistoricalData.Count} quotes needing historical data");

                // Get unique instrument tokens
                var instrumentTokens = quotesNeedingHistoricalData
                    .Select(q => q.InstrumentToken)
                    .Distinct()
                    .ToList();

                // For each quote, use its specific LTT date to get spot data
                var quotesWithLTT = quotesNeedingHistoricalData
                    .Where(q => q.LastTradeTime != DateTime.MinValue)
                    .ToList();

                if (!quotesWithLTT.Any())
                {
                    _logger.LogDebug("No quotes with LTT found for historical data enhancement");
                    return;
                }

                _logger.LogInformation($"Found {quotesWithLTT.Count} quotes with LTT for historical data enhancement");

                // Group quotes by their LTT date to fetch historical data efficiently
                var quotesByDate = quotesWithLTT
                    .GroupBy(q => q.LastTradeTime.Date)
                    .ToDictionary(g => g.Key, g => g.ToList());

                var historicalData = new Dictionary<long, HistoricalQuoteData>();
                
                foreach (var dateGroup in quotesByDate)
                {
                    var lttDate = dateGroup.Key;
                    var quotesForDate = dateGroup.Value;
                    var tokensForDate = quotesForDate.Select(q => q.InstrumentToken).ToList();
                    
                    _logger.LogDebug($"Fetching historical data for {tokensForDate.Count} instruments from LTT date: {lttDate:yyyy-MM-dd}");
                    
                    var dateHistoricalData = await _historicalDataService.GetHistoricalDataForInstrumentsAsync(
                        tokensForDate, lttDate, lttDate); // Use specific LTT date
                    
                    foreach (var kvp in dateHistoricalData)
                    {
                        historicalData[kvp.Key] = kvp.Value;
                    }
                }

                var enhancedCount = 0;
                foreach (var quote in quotesNeedingHistoricalData)
                {
                    if (historicalData.TryGetValue(quote.InstrumentToken, out var historicalQuote))
                    {
                        // Update quote with historical data - only fill missing values
                        if (quote.OpenPrice == 0) quote.OpenPrice = historicalQuote.Open;
                        if (quote.HighPrice == 0) quote.HighPrice = historicalQuote.High;
                        if (quote.LowPrice == 0) quote.LowPrice = historicalQuote.Low;
                        if (quote.ClosePrice == 0) quote.ClosePrice = historicalQuote.Close;
                        // Volume and TradingDate/TradeTime removed - not needed for LC/UC monitoring

                        enhancedCount++;
                        _logger.LogDebug($"Enhanced {quote.TradingSymbol} with historical data: O={historicalQuote.Open}, H={historicalQuote.High}, L={historicalQuote.Low}, C={historicalQuote.Close}");
                    }
                }

                if (enhancedCount > 0)
                {
                    await context.SaveChangesAsync();
                    _logger.LogInformation($"Enhanced {enhancedCount} quotes with historical data");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to enhance quotes with historical data");
            }
        }

        private DateTime GetValidTimestamp(string? timestamp, string? lastTradeTime, Dictionary<string, QuoteData>? allQuotes = null)
        {
            // Try to parse the main timestamp first
            if (!string.IsNullOrEmpty(timestamp) && DateTime.TryParse(timestamp, out var parsedTimestamp))
            {
                // Check if it's a valid date (not 1970-01-01 or similar)
                if (parsedTimestamp.Year > 1970)
                {
                    // Kite API sends timestamps in IST (no conversion needed)
                    _logger.LogDebug($"Using valid timestamp: {timestamp} -> IST: {parsedTimestamp}");
                    return parsedTimestamp;
                }
            }
            
            // Try to parse LastTradeTime as fallback - this is more reliable
            if (!string.IsNullOrEmpty(lastTradeTime) && DateTime.TryParse(lastTradeTime, out var parsedLastTradeTime))
            {
                if (parsedLastTradeTime.Year > 1970)
                {
                    // LastTradeTime from Kite API is already in IST, no conversion needed
                    _logger.LogDebug($"Using LastTradeTime fallback: {lastTradeTime} -> IST: {parsedLastTradeTime}");
                    return parsedLastTradeTime;
                }
            }
            
            // If both are invalid, try to find a valid timestamp from other instruments in the same response
            if (allQuotes != null && allQuotes.Any())
            {
                foreach (var quote in allQuotes.Values)
                {
                    // Try timestamp first
                    if (!string.IsNullOrEmpty(quote.Timestamp) && DateTime.TryParse(quote.Timestamp, out var otherTimestamp))
                    {
                        if (otherTimestamp.Year > 1970)
                        {
                            // Kite API sends timestamps in UTC, convert to IST (+5:30)
                            var istOtherTimestamp = otherTimestamp.AddHours(5.5);
                            _logger.LogWarning($"Using timestamp from other instrument: {quote.Timestamp} -> UTC: {otherTimestamp} -> IST: {istOtherTimestamp}");
                            return istOtherTimestamp;
                        }
                    }
                    
                    // Try LastTradeTime from other instrument
                    if (!string.IsNullOrEmpty(quote.LastTradeTime) && DateTime.TryParse(quote.LastTradeTime, out var otherLastTradeTime))
                    {
                        if (otherLastTradeTime.Year > 1970)
                        {
                            // LastTradeTime from Kite API is already in IST, no conversion needed
                            _logger.LogWarning($"Using LastTradeTime from other instrument: {quote.LastTradeTime} -> IST: {otherLastTradeTime}");
                            return otherLastTradeTime;
                        }
                    }
                }
            }
            
            // If still no valid timestamp found, use current time as last resort
            var currentTime = DateTime.UtcNow.AddHours(5.5); // Explicitly convert UTC to IST (+5:30)
            _logger.LogWarning($"No valid timestamp found in API response, using current IST time: {currentTime}");
            return currentTime;
        }

        private DateTime? GetTradingTimestamp(string? lastTradeTime, string? quoteTimestamp, string? tradingSymbol = null)
        {
            // Only use LastTradeTime (LTT) - no fallback
            if (!string.IsNullOrEmpty(lastTradeTime) && DateTime.TryParse(lastTradeTime, out var parsedLastTradeTime))
            {
                if (parsedLastTradeTime.Year > 1970)
                {
                    // LastTradeTime from Kite API is already in IST, no conversion needed
                    _logger.LogDebug($"Using LastTradeTime for trading timestamp: {lastTradeTime} -> IST: {parsedLastTradeTime}");
                    return parsedLastTradeTime;
                }
            }
            
            // Log missing LTT for specific instruments
            if (string.IsNullOrEmpty(lastTradeTime) && !string.IsNullOrEmpty(tradingSymbol))
            {
                _logger.LogWarning($"No valid LastTradeTime found for {tradingSymbol}, returning null for trading timestamp");
            }
            else if (string.IsNullOrEmpty(lastTradeTime))
            {
                _logger.LogWarning($"No valid LastTradeTime found, returning null for trading timestamp");
            }
            
            return null;
        }

        /// <summary>
        /// Collect spot data for indices (NIFTY, SENSEX, etc.)
        /// </summary>
        private async Task CollectSpotDataAsync()
        {
            try
            {
                _logger.LogInformation("=== STARTING SPOT DATA COLLECTION ===");
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine($"  📊 Getting INDEX instruments from database...");
                Console.ResetColor();

                // Get spot instruments from database
                var spotInstruments = await _spotDataService.GetSpotInstrumentsAsync();
                
                if (!spotInstruments.Any())
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"  ❌ No INDEX instruments available for collection");
                    Console.ResetColor();
                    _logger.LogWarning("No spot instruments available for collection");
                    return;
                }

                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine($"  📈 Found {spotInstruments.Count} INDEX instruments to collect");
                Console.ResetColor();
                _logger.LogInformation($"Found {spotInstruments.Count} spot instruments to collect");

                // Get instrument tokens for spot data
                var spotTokens = spotInstruments.Select(i => i.InstrumentToken.ToString()).ToList();
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine($"  🔄 Requesting spot data from Kite API...");
                Console.ResetColor();
                _logger.LogInformation($"Requesting spot data for tokens: {string.Join(", ", spotTokens)}");

                // Get quotes from Kite Connect
                var quoteResponse = await _kiteService.GetMarketQuotesAsync(spotTokens);
                
                if (quoteResponse?.Data == null || !quoteResponse.Data.Any())
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"  ❌ No spot data received from Kite Connect");
                    Console.ResetColor();
                    _logger.LogWarning("No spot data received from Kite Connect");
                    return;
                }

                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine($"  📊 Received spot data for {quoteResponse.Data.Count} indices");
                Console.ResetColor();
                _logger.LogInformation($"Received spot data for {quoteResponse.Data.Count} indices");

                // Convert to IntradaySpotData entities
                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine($"  🔄 Converting and saving spot data...");
                Console.ResetColor();
                var intradaySpotDataList = _spotDataService.ConvertToSpotData(quoteResponse.Data, spotInstruments);
                
                if (intradaySpotDataList.Any())
                {
                    // Save spot data to IntradaySpotData table
                    await _spotDataService.SaveSpotDataAsync(intradaySpotDataList);
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine($"  💾 Successfully saved intraday spot data for {intradaySpotDataList.Count} indices");
                    Console.ResetColor();
                    _logger.LogInformation($"Successfully collected and saved intraday spot data for {intradaySpotDataList.Count} indices");
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine($"  ❌ No valid spot data to save");
                    Console.ResetColor();
                    _logger.LogWarning("No valid spot data to save");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to collect spot data");
            }
        }


        /// <summary>
        /// Store intraday tick data for all instruments every minute
        /// </summary>
        private async Task StoreIntradayTickDataAsync()
        {
            try
            {
                _logger.LogInformation("=== STARTING INTRADAY TICK DATA STORAGE ===");
                _logger.LogInformation($"Tick data storage started at: {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} UTC");

                await _intradayTickDataService.StoreIntradayTickDataAsync();

                _logger.LogInformation("=== INTRADAY TICK DATA STORAGE COMPLETED ===");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to store intraday tick data");
            }
        }

        /// <summary>
        /// Check if LC/UC changes occurred and determine if Excel export should be triggered
        /// </summary>
        private async Task<bool> CheckForLCUCChangesAndExportAsync()
        {
            try
            {
                using var scope = _serviceScopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var currentIST = DateTime.UtcNow.AddHours(5.5);
                var currentBusinessDate = currentIST.Date;

                // Check if we have any new LC/UC changes since last export
                var lastExportThreshold = _lastExportTime == DateTime.MinValue 
                    ? currentBusinessDate.AddHours(6) // If never exported, check from 6 AM today
                    : _lastExportTime.AddMinutes(-5); // Check 5 minutes before last export to avoid missing changes

                // Get latest market quotes with LC/UC changes
                var recentChanges = await context.MarketQuotes
                    .Where(q => q.BusinessDate == currentBusinessDate &&
                               q.RecordDateTime > lastExportThreshold &&
                               q.InsertionSequence > 1) // Only changes (sequence > 1)
                    .OrderByDescending(q => q.RecordDateTime)
                    .Take(10) // Check last 10 changes
                    .ToListAsync();

                if (recentChanges.Any())
                {
                    _logger.LogInformation($"🔄 LC/UC changes detected: {recentChanges.Count} changes since {lastExportThreshold:HH:mm:ss}");
                    
                    // Update last export time
                    _lastExportTime = currentIST;
                    
                    // Log sample changes
                    foreach (var change in recentChanges.Take(3))
                    {
                        _logger.LogInformation($"  📊 {change.TradingSymbol}: LC={change.LowerCircuitLimit}, UC={change.UpperCircuitLimit} at {change.RecordDateTime:HH:mm:ss}");
                    }
                    
                    return true; // Trigger export
                }

                return false; // No changes detected
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking for LC/UC changes");
                return false;
            }
        }

        /// <summary>
        /// Clear log file for fresh start on each service run
        /// </summary>
        private void ClearLogFile()
        {
            try
            {
                var logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs", "KiteMarketDataService.log");
                
                if (File.Exists(logPath))
                {
                    File.WriteAllText(logPath, string.Empty);
                    // Log to file only, no console output (tick mark shown in main flow)
                }
                // If file doesn't exist, it will be created automatically - no message needed
            }
            catch (Exception ex)
            {
                // Log error to file only
                _logger.LogError(ex, "Could not clear log file");
            }
        }

        /// <summary>
        /// Export daily initial data to Excel files
        /// </summary>
        private async Task ExportDailyInitialDataAsync()
        {
            try
            {
                var currentIST = DateTime.UtcNow.AddHours(5.5);
                var currentBusinessDate = currentIST.Date;

                // Check if we already exported initial data for today
                var exportPath = _dailyInitialDataExportService.GetExportPath();
                var todayExportDir = Path.Combine(exportPath, currentBusinessDate.ToString("yyyy-MM-dd"));
                
                if (Directory.Exists(todayExportDir) && Directory.GetFiles(todayExportDir, "*.xlsx").Any())
                {
                    _logger.LogDebug($"Initial data already exported for {currentBusinessDate:yyyy-MM-dd}");
                    return;
                }

                Console.ForegroundColor = ConsoleColor.Cyan;
                Console.WriteLine($"📊 [{DateTime.Now:HH:mm:ss}] Exporting daily initial data for {currentBusinessDate:yyyy-MM-dd}...");
                Console.ResetColor();

                var createdFiles = await _dailyInitialDataExportService.ExportDailyInitialDataAsync(currentBusinessDate);
                
                if (createdFiles.Any())
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine($"✅ [{DateTime.Now:HH:mm:ss}] Daily initial data exported: {createdFiles.Count} files created");
                    Console.ResetColor();
                    _logger.LogInformation($"Daily initial data export completed: {createdFiles.Count} files created");
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine($"⚠️ [{DateTime.Now:HH:mm:ss}] No initial data to export for {currentBusinessDate:yyyy-MM-dd}");
                    Console.ResetColor();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to export daily initial data");
            }
        }

        public override void Dispose()
        {
            try
            {
                _instanceMutex?.ReleaseMutex();
                _instanceMutex?.Dispose();
            }
            catch (Exception ex)
            {
                _logger?.LogError(ex, "Error disposing mutex");
            }
            finally
            {
                base.Dispose();
            }
        }

    }
}
