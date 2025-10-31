using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.FileProviders;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Services;

namespace KiteMarketDataService.Worker
{
    public class Program
    {
        public static void Main(string[] args)
        {
            CreateHostBuilder(args).Build().Run();
        }

        public static IHostBuilder CreateHostBuilder(string[] args) =>
            Host.CreateDefaultBuilder(args)
                // Add Web API hosting
                .ConfigureWebHostDefaults(webBuilder =>
                {
                    webBuilder.ConfigureServices((context, services) =>
                    {
                        // Add Web API controllers
                        services.AddControllers();
                        
                        // Add authentication services
                        services.AddAuthentication();
                        
                        // Add CORS
                        services.AddCors(options =>
                        {
                            options.AddDefaultPolicy(builder =>
                            {
                                builder.AllowAnyOrigin()
                                       .AllowAnyMethod()
                                       .AllowAnyHeader();
                            });
                        });
                        
                        // Add Swagger for API documentation (optional)
                        services.AddEndpointsApiExplorer();
                        services.AddSwaggerGen();
                    });
                    
                    webBuilder.Configure((context, app) =>
                    {
                        // Enable CORS
                        app.UseCors();
                        
                        // Enable static files from wwwroot
                        app.UseStaticFiles();
                        
                        // Enable routing
                        app.UseRouting();
                        
                        // Add authentication middleware
                        app.UseAuthentication();
                        app.UseAuthorization();
                        
                        // Enable Swagger UI
                        app.UseSwagger();
                        app.UseSwaggerUI(c =>
                        {
                            c.SwaggerEndpoint("/swagger/v1/swagger.json", "Market Prediction API V1");
                            c.RoutePrefix = "api-docs"; // Access at /api-docs
                        });
                        
                        // Map controllers
                        app.UseEndpoints(endpoints =>
                        {
                            endpoints.MapControllers();
                        });
                        
                        // Default page redirect
                app.Use(async (context, next) =>
                {
                    if (context.Request.Path == "/")
                    {
                        context.Response.Redirect("/AdvancedDashboard.html");
                        return;
                    }
                    await next();
                });
                    });
                    
                    // Listen on port 5000 with explicit HTTP configuration
                    webBuilder.UseUrls("http://localhost:5000");
                    webBuilder.UseKestrel(options =>
                    {
                        options.ConfigureEndpointDefaults(listenOptions =>
                        {
                            listenOptions.Protocols = Microsoft.AspNetCore.Server.Kestrel.Core.HttpProtocols.Http1;
                        });
                    });
                })
                .ConfigureLogging((hostContext, logging) =>
                {
                    // Clear existing log providers
                    logging.ClearProviders();
                    
                    // Add custom file logging that captures ALL logs
                    // Rotate logs per run: create a fresh timestamped log file each service start
                    var logsRoot = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs");
                    var logFileName = $"KiteMarketDataService_{DateTime.Now:yyyyMMdd_HHmmss}.log";
                    var logPath = Path.Combine(logsRoot, logFileName);
                    var logDir = Path.GetDirectoryName(logPath);
                    if (!Directory.Exists(logDir))
                        Directory.CreateDirectory(logDir!);

                    // Also write/update a small pointer file so tools/UI can discover the latest log quickly
                    try
                    {
                        File.WriteAllText(Path.Combine(logsRoot, "latest_log_path.txt"), logPath);
                    }
                    catch { /* non-fatal */ }
                    
                    // Add custom file logger that captures all log levels
                    logging.AddProvider(new CustomFileLoggerProvider(logPath));
                    
                    // Add custom console logger that only shows essential messages
                    logging.AddProvider(new CustomConsoleLoggerProvider());
                })
                .ConfigureServices((hostContext, services) =>
                {
                    // Configure Entity Framework for OLD database
                    services.AddDbContext<MarketDataContext>(options =>
                        options.UseSqlServer(hostContext.Configuration.GetConnectionString("DefaultConnection")));

                    // Configure Entity Framework for NEW database
                    services.AddDbContext<CircuitLimitTrackingContext>(options =>
                        options.UseSqlServer(hostContext.Configuration.GetConnectionString("CircuitLimitTrackingConnection")));

                        // Register RELIABLE authentication services
                        services.AddHttpClient<ReliableAuthService>();
                        services.AddSingleton<ReliableAuthService>();
                        
                        // Register core data collection services
                        services.AddHttpClient<KiteConnectService>();
                        services.AddSingleton<KiteConnectService>();
                        services.AddSingleton<BusinessDateCalculationService>();
                        services.AddSingleton<MarketDataService>();
                        
                        // Register service separation architecture
                        services.AddHostedService<CoreDataCollectionService>();
                        // services.AddHostedService<IndependentPatternDiscoveryService>(); // DISABLED - Missing dependencies
                        // services.AddSingleton<ServiceManager>(); // DISABLED - Missing dependencies
                        
                        // Legacy services (for backward compatibility)
                        services.AddHttpClient<KiteAuthService>();
                        services.AddHttpClient<RobustKiteAuthService>();
                        services.AddSingleton<KiteAuthService>();
                        services.AddSingleton<RobustKiteAuthService>();
                        services.AddSingleton<DatabaseTokenService>();
                    services.AddSingleton<ManualNiftySpotDataService>();
                    services.AddSingleton<MarketDataService>();
                    services.AddSingleton<SmartCircuitLimitsService>();
                    services.AddSingleton<EnhancedCircuitLimitService>();
                    services.AddSingleton<CircuitLimitChangeService>();
                    services.AddSingleton<SpotDataService>();
                    services.AddSingleton<FullInstrumentService>();
                    services.AddSingleton<HistoricalDataService>();
                    services.AddSingleton<ExcelExportService>();
                    services.AddSingleton<IntradayTickDataService>();
                    services.AddSingleton<TimeBasedDataCollectionService>();
                    services.AddSingleton<ConsolidatedExcelExportService>();
                    services.AddSingleton<FlexibleExcelDataService>();
        services.AddSingleton<DailyInitialDataExportService>();
                    services.AddSingleton<ExcelFileProtectionService>();
                    services.AddSingleton<HistoricalSpotDataService>();
                    services.AddSingleton<HistoricalOptionsDataService>();
        // services.AddSingleton<DailyCloseDataService>(); // TODO: Implement GetHistoricalDataAsync in KiteConnectService

                    // Strike Latest Records Service (Track latest 3 records per strike)
                    // services.AddSingleton<StrikeLatestRecordsService>(); // DISABLED - Database schema errors

                    // Strategy System Services (SEPARATE - No impact on data collection!)
                    // ========================================
                    // STRATEGY SERVICES - COMPLETELY DISABLED
                    // ========================================
                    // These services are intentionally disabled to prevent interference 
                    // with core data collection. Strategy processing should be handled
                    // by a separate service/application.
                    // services.AddSingleton<StrategyCalculatorService>(); // DISABLED - Database schema errors
                    // services.AddSingleton<StrategyExcelExportService>(); // DISABLED - Depends on StrategyCalculatorService
                    // services.AddSingleton<PatternDiscoveryService>(); // DISABLED - Database schema errors
                    // services.AddSingleton<LabelBackfillService>(); // DISABLED - Database schema errors
                    // services.AddHostedService<AdvancedPatternDiscoveryEngine>(); // DISABLED - Database schema errors
                    
                    // Core data collection services only
                    services.AddSingleton<PatternEngine>();
                    services.AddSingleton<DynamicLabelCreationService>();

                    // Register the worker service
                    services.AddHostedService<Worker>();
                    
                    // Advanced Pattern Discovery Engine (Background Learning)
                    // services.AddHostedService<AdvancedPatternDiscoveryEngine>(); // DISABLED - Database schema errors
                });
    }

    // Custom file logger provider
    public class CustomFileLoggerProvider : ILoggerProvider
    {
        private readonly string _logFilePath;
        private readonly object _lock = new object();

        public CustomFileLoggerProvider(string logFilePath)
        {
            _logFilePath = logFilePath;
        }

        public ILogger CreateLogger(string categoryName)
        {
            return new CustomFileLogger(_logFilePath, _lock);
        }

        public void Dispose()
        {
            // Nothing to dispose
        }
    }

    // Custom console logger provider that only shows essential messages
    public class CustomConsoleLoggerProvider : ILoggerProvider
    {
        public ILogger CreateLogger(string categoryName)
        {
            return new CustomConsoleLogger(categoryName);
        }

        public void Dispose()
        {
            // Nothing to dispose
        }
    }

    public class CustomFileLogger : ILogger
    {
        private readonly string _logFilePath;
        private readonly object _lock;

        public CustomFileLogger(string logFilePath, object lockObj)
        {
            _logFilePath = logFilePath;
            _lock = lockObj;
        }

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel) => logLevel >= LogLevel.Information;

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
        {
            if (!IsEnabled(logLevel))
                return;

            var message = formatter(state, exception);
            var logEntry = $"{DateTime.Now:yyyy-MM-dd HH:mm:ss.fff} [{logLevel}] {message}";
            
            if (exception != null)
                logEntry += $"\n{exception}";

            lock (_lock)
            {
                File.AppendAllText(_logFilePath, logEntry + Environment.NewLine);
            }
        }
    }

    public class CustomConsoleLogger : ILogger
    {
        private readonly string _categoryName;

        public CustomConsoleLogger(string categoryName)
        {
            _categoryName = categoryName;
        }

        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

        public bool IsEnabled(LogLevel logLevel)
        {
            // Only show console output for:
            // 1. Errors and warnings from any service
            // 2. Microsoft.Hosting.Lifetime (essential framework messages only)
            // NO detailed process logs - tick marks show completion
            
            if (logLevel >= LogLevel.Error) return true;
            if (logLevel >= LogLevel.Warning) return true;
            
            // Only show essential framework messages, not detailed process logs
            if (_categoryName.Contains("Microsoft.Hosting.Lifetime") && logLevel >= LogLevel.Information) return true;
            
            return false;
        }

        public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
        {
            if (!IsEnabled(logLevel))
                return;

            var message = formatter(state, exception);
            
            // Color coding for console output
            switch (logLevel)
            {
                case LogLevel.Error:
                    Console.ForegroundColor = ConsoleColor.Red;
                    break;
                case LogLevel.Warning:
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    break;
                case LogLevel.Information:
                    Console.ForegroundColor = ConsoleColor.White;
                    break;
                default:
                    Console.ForegroundColor = ConsoleColor.Gray;
                    break;
            }

            Console.WriteLine($"[{logLevel}] {message}");
            Console.ResetColor();
            
            if (exception != null)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(exception);
                Console.ResetColor();
            }
        }
    }
}

            {
                case LogLevel.Error:
                    Console.ForegroundColor = ConsoleColor.Red;
                    break;
                case LogLevel.Warning:
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    break;
                case LogLevel.Information:
                    Console.ForegroundColor = ConsoleColor.White;
                    break;
                default:
                    Console.ForegroundColor = ConsoleColor.Gray;
                    break;
            }

            Console.WriteLine($"[{logLevel}] {message}");
            Console.ResetColor();
            
            if (exception != null)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(exception);
                Console.ResetColor();
            }
        }
    }
}

            {
                case LogLevel.Error:
                    Console.ForegroundColor = ConsoleColor.Red;
                    break;
                case LogLevel.Warning:
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    break;
                case LogLevel.Information:
                    Console.ForegroundColor = ConsoleColor.White;
                    break;
                default:
                    Console.ForegroundColor = ConsoleColor.Gray;
                    break;
            }

            Console.WriteLine($"[{logLevel}] {message}");
            Console.ResetColor();
            
            if (exception != null)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine(exception);
                Console.ResetColor();
            }
        }
    }
}
