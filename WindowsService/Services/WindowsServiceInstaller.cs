using System.ServiceProcess;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.Hosting;
using Microsoft.EntityFrameworkCore;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Services;

namespace KiteMarketDataService.Worker.Services
{
    public class WindowsServiceInstaller : ServiceBase
    {
        private IHost? _host;
        private readonly ILogger<WindowsServiceInstaller> _logger;

        public WindowsServiceInstaller()
        {
            ServiceName = "KiteMarketDataService";
            CanStop = true;
            CanPauseAndContinue = false;
            AutoLog = true;
        }

        protected override void OnStart(string[] args)
        {
            try
            {
                // Create host builder
                var hostBuilder = Host.CreateDefaultBuilder(args)
                    .ConfigureWebHostDefaults(webBuilder =>
                    {
                        webBuilder.ConfigureServices((context, services) =>
                        {
                            // Add Web API controllers
                            services.AddControllers();
                            
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
                            
                            // Add Swagger for API documentation
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
                            
                            // Enable Swagger UI
                            app.UseSwagger();
                            app.UseSwaggerUI(c =>
                            {
                                c.SwaggerEndpoint("/swagger/v1/swagger.json", "Market Prediction API V1");
                                c.RoutePrefix = "api-docs";
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
                                    context.Response.Redirect("/token-management.html");
                                    return;
                                }
                                await next();
                            });
                        });
                        
                        // Listen on port 5000
                        webBuilder.UseUrls("http://localhost:5000");
                    })
                    .ConfigureServices((hostContext, services) =>
                    {
                        // Register all existing services (same as Program.cs)
                        services.AddDbContext<MarketDataContext>(options =>
                            options.UseSqlServer(hostContext.Configuration.GetConnectionString("DefaultConnection")));
                        services.AddDbContext<CircuitLimitTrackingContext>(options =>
                            options.UseSqlServer(hostContext.Configuration.GetConnectionString("CircuitLimitTrackingConnection")));
                        
                        // Register all services (same as Program.cs)
                        services.AddHttpClient<KiteConnectService>();
                        services.AddHttpClient<KiteAuthService>();
                        services.AddSingleton<KiteConnectService>();
                        services.AddSingleton<KiteAuthService>();
                        services.AddSingleton<BusinessDateCalculationService>();
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
                        services.AddSingleton<StrikeLatestRecordsService>();
                        services.AddSingleton<StrategyCalculatorService>();
                        services.AddSingleton<StrategyExcelExportService>();
                        services.AddSingleton<PatternEngine>();
                        services.AddSingleton<PatternDiscoveryService>();
                        services.AddSingleton<LabelBackfillService>();
                        services.AddSingleton<DynamicLabelCreationService>();
                        services.AddSingleton<InteractiveNotificationService>();
                        services.AddSingleton<TokenManagementService>();
                        
                        // Register the worker service
                        services.AddHostedService<Worker>();
                        services.AddHostedService<AdvancedPatternDiscoveryEngine>();
                    });

                _host = hostBuilder.Build();
                _host.Start();
                
                EventLog.WriteEntry("KiteMarketDataService started successfully", EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry($"Failed to start KiteMarketDataService: {ex.Message}", EventLogEntryType.Error);
                throw;
            }
        }

        protected override void OnStop()
        {
            try
            {
                _host?.StopAsync().Wait();
                _host?.Dispose();
                
                EventLog.WriteEntry("KiteMarketDataService stopped successfully", EventLogEntryType.Information);
            }
            catch (Exception ex)
            {
                EventLog.WriteEntry($"Error stopping KiteMarketDataService: {ex.Message}", EventLogEntryType.Error);
            }
        }
    }
}
