using Microsoft.AspNetCore.Mvc;
using KiteMarketDataService.Worker.Data;
using Microsoft.EntityFrameworkCore;
using System.Diagnostics;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class SystemMonitorController : ControllerBase
    {
        private readonly ILogger<SystemMonitorController> _logger;
        private readonly MarketDataContext _context;
        private readonly IConfiguration _configuration;

        public SystemMonitorController(ILogger<SystemMonitorController> logger, MarketDataContext context, IConfiguration configuration)
        {
            _logger = logger;
            _context = context;
            _configuration = configuration;
        }

        [HttpGet("status")]
        public async Task<IActionResult> GetSystemStatus()
        {
            try
            {
                var status = new
                {
                    ServiceStatus = "Running",
                    Uptime = GetServiceUptime(),
                    TokenStatus = GetTokenStatus(),
                    DatabaseStatus = await GetDatabaseStatus(),
                    ApiStatus = GetApiStatus(),
                    DataCollection = await GetDataCollectionStatus(),
                    SystemStats = await GetSystemStats(),
                    LcUcAlerts = GetLcUcAlerts(),
                    LastUpdate = DateTime.Now
                };

                return Ok(status);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting system status");
                return StatusCode(500, new { Error = "Failed to get system status" });
            }
        }

        [HttpGet("logs")]
        public IActionResult GetRecentLogs(int count = 50)
        {
            try
            {
                // For now, return simulated logs
                // In a real implementation, you would read from a log file or database
                var logs = GenerateSimulatedLogs(count);
                return Ok(logs);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting logs");
                return StatusCode(500, new { Error = "Failed to get logs" });
            }
        }

        [HttpGet("data-collection")]
        public async Task<IActionResult> GetDataCollectionStatusEndpoint()
        {
            try
            {
                var status = await GetDataCollectionStatus();
                return Ok(status);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting data collection status");
                return StatusCode(500, new { Error = "Failed to get data collection status" });
            }
        }

        [HttpGet("lc-uc-alerts")]
        public IActionResult GetLcUcAlertsEndpoint()
        {
            try
            {
                var alerts = GetLcUcAlerts();
                return Ok(alerts);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting LC/UC alerts");
                return StatusCode(500, new { Error = "Failed to get LC/UC alerts" });
            }
        }

        private string GetServiceUptime()
        {
            var process = Process.GetCurrentProcess();
            var uptime = DateTime.Now - process.StartTime;
            return $"{uptime.Days}d {uptime.Hours}h {uptime.Minutes}m";
        }

        private string GetTokenStatus()
        {
            var requestToken = _configuration["KiteConnect:RequestToken"];
            return string.IsNullOrEmpty(requestToken) ? "Not Set" : "Configured";
        }

        private async Task<string> GetDatabaseStatus()
        {
            try
            {
                await _context.Database.OpenConnectionAsync();
                await _context.Database.CloseConnectionAsync();
                return "Connected";
            }
            catch
            {
                return "Disconnected";
            }
        }

        private string GetApiStatus()
        {
            var apiKey = _configuration["KiteConnect:ApiKey"];
            return string.IsNullOrEmpty(apiKey) ? "Not Configured" : "Active";
        }

        private async Task<object> GetDataCollectionStatus()
        {
            try
            {
                var indices = new[] { "NIFTY", "SENSEX", "BANKNIFTY" };
                var status = new Dictionary<string, object>();

                foreach (var index in indices)
                {
                    try
                    {
                        var lastTick = await _context.IntradayTickData
                            .Where(t => t.IndexName.Contains(index))
                            .OrderByDescending(t => t.TickTimestamp)
                            .FirstOrDefaultAsync();

                        status[index] = new
                        {
                            Status = lastTick != null ? "Active" : "Inactive",
                            LastTick = lastTick?.TickTimestamp.ToString("HH:mm:ss") ?? "Never",
                            RecordCount = await _context.IntradayTickData.CountAsync(t => t.IndexName.Contains(index))
                        };
                    }
                    catch
                    {
                        status[index] = new
                        {
                            Status = "Error",
                            LastTick = "Error",
                            RecordCount = 0
                        };
                    }
                }

                return status;
            }
            catch
            {
                return new { Error = "Unable to fetch data collection status" };
            }
        }

        private async Task<object> GetSystemStats()
        {
            try
            {
                var totalTicks = await _context.IntradayTickData.CountAsync();
                var totalInstruments = await _context.Instruments.CountAsync();
                var todayTicks = await _context.IntradayTickData
                    .CountAsync(t => t.TickTimestamp.Date == DateTime.Today);

                return new
                {
                    TotalTicks = totalTicks,
                    TotalInstruments = totalInstruments,
                    TodayTicks = todayTicks,
                    DatabaseSize = "Unknown", // Would need to query database size
                    MemoryUsage = GC.GetTotalMemory(false) / 1024 / 1024 // MB
                };
            }
            catch
            {
                return new
                {
                    TotalTicks = 0,
                    TotalInstruments = 0,
                    TodayTicks = 0,
                    DatabaseSize = "Unknown",
                    MemoryUsage = 0
                };
            }
        }

        private object GetLcUcAlerts()
        {
            // Simulate LC/UC alerts
            var alerts = new List<object>
            {
                new
                {
                    Message = "NIFTY 50 options showing increased volatility",
                    Type = "Info",
                    Timestamp = DateTime.Now.AddMinutes(-5),
                    Severity = "Low"
                },
                new
                {
                    Message = "SENSEX circuit limit monitoring active",
                    Type = "Info",
                    Timestamp = DateTime.Now.AddMinutes(-10),
                    Severity = "Low"
                }
            };

            return alerts;
        }

        private List<object> GenerateSimulatedLogs(int count)
        {
            var logTypes = new[] { "Info", "Warning", "Error", "Success" };
            var logMessages = new[]
            {
                "Data collection cycle started",
                "Processing NIFTY options data",
                "Tick data stored successfully",
                "LC/UC monitoring active",
                "No spot price available for SENSEX5025OCT26150CE",
                "Pattern discovery cycle running",
                "Intraday tick data storage completed",
                "Waiting for next cycle...",
                "Service health check passed",
                "Database connection established",
                "API rate limit reached",
                "Circuit limit change detected",
                "Data export completed",
                "Service restart initiated"
            };

            var logs = new List<object>();
            var random = new Random();

            for (int i = 0; i < count; i++)
            {
                logs.Add(new
                {
                    Timestamp = DateTime.Now.AddMinutes(-random.Next(60)),
                    Type = logTypes[random.Next(logTypes.Length)],
                    Message = logMessages[random.Next(logMessages.Length)]
                });
            }

            return logs.OrderByDescending(l => ((dynamic)l).Timestamp).ToList();
        }
    }
}
