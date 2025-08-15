using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
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
                .ConfigureLogging((hostContext, logging) =>
                {
                    // Clear existing log providers
                    logging.ClearProviders();
                    
                    // Add console logging
                    logging.AddConsole();
                    
                    // Add custom file logging
                    var logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "logs", "KiteMarketDataService.log");
                    var logDir = Path.GetDirectoryName(logPath);
                    if (!Directory.Exists(logDir))
                        Directory.CreateDirectory(logDir!);
                    
                    // Clear the log file on startup
                    if (File.Exists(logPath))
                        File.Delete(logPath);
                    
                    // Add custom file logger
                    logging.AddProvider(new CustomFileLoggerProvider(logPath));
                })
                .ConfigureServices((hostContext, services) =>
                {
                    // Configure Entity Framework
                    services.AddDbContext<MarketDataContext>(options =>
                        options.UseSqlServer(hostContext.Configuration.GetConnectionString("DefaultConnection")));

                    // Register services as singleton to work with hosted service
                    services.AddHttpClient<KiteConnectService>();
                    services.AddHttpClient<KiteAuthService>();
                    services.AddSingleton<KiteConnectService>();
                    services.AddSingleton<KiteAuthService>();
                    services.AddSingleton<MarketDataService>();
                    services.AddSingleton<SmartCircuitLimitsService>();
                    services.AddSingleton<EnhancedCircuitLimitService>();

                    // Register the worker service
                    services.AddHostedService<Worker>();
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

        public bool IsEnabled(LogLevel logLevel) => true;

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
}
