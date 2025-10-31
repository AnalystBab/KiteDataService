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
                // Check if process is actually running
                var processStatus = CheckProcessStatus();
                
                var status = new
                {
                    ServiceStatus = processStatus.IsRunning ? "Running" : "Not Running",
                    ProcessId = processStatus.ProcessId,
                    StartTime = processStatus.StartTime,
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

        private (bool IsRunning, int? ProcessId, string StartTime) CheckProcessStatus()
        {
            try
            {
                // Get current process info
                var process = Process.GetCurrentProcess();
                if (process != null)
                {
                    return (true, process.Id, process.StartTime.ToString("yyyy-MM-dd HH:mm:ss"));
                }
            }
            catch
            {
                // Ignore errors
            }
            return (false, null, "N/A");
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

        [HttpGet("latest-lc-uc-changes")]
        public async Task<IActionResult> GetLatestLcUcChanges()
        {
            try
            {
                var changes = await GetLatestLcUcChangesData();
                return Ok(changes);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting latest LC/UC changes");
                return StatusCode(500, new { Error = "Failed to get latest LC/UC changes" });
            }
        }

        [HttpGet("lc-uc-html")]
        public async Task<IActionResult> GetLcUcHtml()
        {
            try
            {
                var changes = await GetLatestLcUcChangesData();
                var html = GenerateSimpleLcUcHtml(changes);
                return Content(html, "text/html");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating LC/UC HTML");
                return StatusCode(500, "Error generating LC/UC HTML");
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

        private async Task<object> GetLatestLcUcChangesData()
        {
            try
            {
                var indices = new[] { "NIFTY", "SENSEX", "BANKNIFTY" };
                var result = new Dictionary<string, object>();

                foreach (var index in indices)
                {
                    try
                    {
                        // Get latest spot data for the index
                        var spotData = await _context.SpotData
                            .Where(s => s.IndexName == index)
                            .OrderByDescending(s => s.QuoteTimestamp)
                            .FirstOrDefaultAsync();

                        // Get latest 3 LC/UC changes for this index
                        var lcUcChanges = await _context.MarketQuotes
                            .Where(m => m.TradingSymbol.Contains(index) && 
                                       (m.TradingSymbol.Contains("CE") || m.TradingSymbol.Contains("PE")))
                            .OrderByDescending(m => m.RecordDateTime)
                            .Take(3)
                            .Select(m => new
                            {
                                TradingSymbol = m.TradingSymbol,
                                Strike = m.Strike,
                                OptionType = m.TradingSymbol.Contains("CE") ? "CE" : "PE",
                                LowerCircuitLimit = m.LowerCircuitLimit,
                                UpperCircuitLimit = m.UpperCircuitLimit,
                                LastPrice = m.LastPrice,
                                QuoteTimestamp = m.RecordDateTime,
                                BusinessDate = m.BusinessDate
                            })
                            .ToListAsync();

                        // Calculate base strikes (spot close ± UC)
                        var spotClose = spotData?.ClosePrice ?? 0;
                        var ucValue = lcUcChanges.FirstOrDefault()?.UpperCircuitLimit ?? 0;
                        var callBaseStrike = spotClose - ucValue;
                        var putBaseStrike = spotClose + ucValue;

                        result[index] = new
                        {
                            SpotClose = spotClose,
                            UcValue = ucValue,
                            CallBaseStrike = callBaseStrike,
                            PutBaseStrike = putBaseStrike,
                            LcUcChanges = lcUcChanges.Select(c => new
                            {
                                c.TradingSymbol,
                                c.Strike,
                                c.OptionType,
                                c.LowerCircuitLimit,
                                c.UpperCircuitLimit,
                                c.LastPrice,
                                QuoteTime = c.QuoteTimestamp.ToString("HH:mm:ss"),
                                Date = c.BusinessDate.ToString("yyyy-MM-dd")
                            }).ToList(),
                            LastUpdate = DateTime.Now
                        };
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, $"Error getting LC/UC data for {index}");
                        result[index] = new
                        {
                            Error = $"Failed to get data for {index}",
                            SpotClose = 0,
                            UcValue = 0,
                            CallBaseStrike = 0,
                            PutBaseStrike = 0,
                            LcUcChanges = new List<object>(),
                            LastUpdate = DateTime.Now
                        };
                    }
                }

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting latest LC/UC changes data");
                return new { Error = "Failed to get LC/UC changes data" };
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

        private string GenerateSimpleLcUcHtml(object data)
        {
            if (data == null)
            {
                return "<div style='color: red; text-align: center; padding: 20px;'>No data available</div>";
            }

            var html = "<div style='font-family: Arial, sans-serif;'>";
            
            try
            {
                // Convert to JSON and parse back to get proper structure
                var jsonString = System.Text.Json.JsonSerializer.Serialize(data);
                var jsonDoc = System.Text.Json.JsonDocument.Parse(jsonString);
                var root = jsonDoc.RootElement;
                
                foreach (var indexProperty in root.EnumerateObject())
                {
                    var indexName = indexProperty.Name;
                    var indexData = indexProperty.Value;
                    
                    html += $@"
                        <div style='background: #f8f9fa; border-radius: 8px; padding: 15px; margin: 15px 0; border: 1px solid #dee2e6;'>
                            <h4 style='margin: 0 0 15px 0; color: #4facfe; font-size: 1.2em;'>📊 {indexName}</h4>
                            
                            <div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 10px; margin-bottom: 15px;'>
                                <div style='text-align: center; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;'>
                                    <div style='font-size: 0.9em; color: #6c757d; margin-bottom: 6px; font-weight: bold;'>Spot Close</div>
                                    <div style='font-weight: bold; color: #333; font-size: 1.2em;'>{GetJsonValue(indexData, "spotClose")}</div>
                                </div>
                                <div style='text-align: center; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;'>
                                    <div style='font-size: 0.9em; color: #6c757d; margin-bottom: 6px; font-weight: bold;'>UC Value</div>
                                    <div style='font-weight: bold; color: #333; font-size: 1.2em;'>{GetJsonValue(indexData, "ucValue")}</div>
                                </div>
                                <div style='text-align: center; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;'>
                                    <div style='font-size: 0.9em; color: #6c757d; margin-bottom: 6px; font-weight: bold;'>Call Base</div>
                                    <div style='font-weight: bold; color: #333; font-size: 1.2em;'>{GetJsonValue(indexData, "callBaseStrike")}</div>
                                </div>
                                <div style='text-align: center; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;'>
                                    <div style='font-size: 0.9em; color: #6c757d; margin-bottom: 6px; font-weight: bold;'>Put Base</div>
                                    <div style='font-weight: bold; color: #333; font-size: 1.2em;'>{GetJsonValue(indexData, "putBaseStrike")}</div>
                                </div>
                            </div>
                    ";
                    
                    // Add LC/UC changes
                    if (indexData.TryGetProperty("lcUcChanges", out var lcUcChanges) && lcUcChanges.ValueKind == System.Text.Json.JsonValueKind.Array)
                    {
                        var hasChanges = false;
                        foreach (var change in lcUcChanges.EnumerateArray())
                        {
                            hasChanges = true;
                            var optionType = GetJsonValue(change, "optionType");
                            var strike = GetJsonValue(change, "strike");
                            var lc = GetJsonValue(change, "lowerCircuitLimit");
                            var uc = GetJsonValue(change, "upperCircuitLimit");
                            var quoteTime = GetJsonValue(change, "quoteTime");
                            
                            var borderColor = optionType == "CE" ? "#28a745" : "#dc3545";
                            
                            html += $@"
                                <div style='background: white; padding: 12px; border-radius: 6px; border: 1px solid #dee2e6; border-left: 4px solid {borderColor}; margin: 8px 0; display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px; align-items: center;'>
                                    <div style='text-align: center;'>
                                        <div style='font-weight: bold; font-size: 1.2em; color: #333;'>{strike}</div>
                                        <div style='font-size: 0.9em; color: #6c757d; margin-top: 4px;'>{optionType}</div>
                                    </div>
                                    <div style='color: #dc3545; text-align: center; font-weight: bold;'>LC: {lc}</div>
                                    <div style='color: #28a745; text-align: center; font-weight: bold;'>UC: {uc}</div>
                                    <div style='text-align: center; font-size: 0.9em; color: #6c757d;'>{quoteTime}</div>
                                </div>
                            ";
                        }
                        
                        if (!hasChanges)
                        {
                            html += $@"
                                <div style='text-align: center; color: #6c757d; padding: 20px;'>
                                    No LC/UC changes found for {indexName}
                                </div>
                            ";
                        }
                    }
                    else
                    {
                        html += $@"
                            <div style='text-align: center; color: #6c757d; padding: 20px;'>
                                No LC/UC changes found for {indexName}
                            </div>
                        ";
                    }
                    
                    html += "</div>";
                }
            }
            catch (Exception ex)
            {
                html += $"<div style='color: red; text-align: center; padding: 20px;'>Error processing data: {ex.Message}</div>";
            }
            
            html += "</div>";
            return html;
        }

        private string GetJsonValue(System.Text.Json.JsonElement element, string propertyName)
        {
            try
            {
                if (element.TryGetProperty(propertyName, out var property))
                {
                    if (property.ValueKind == System.Text.Json.JsonValueKind.Number)
                    {
                        var numValue = property.GetDecimal();
                        if (numValue == 0) return "0";
                        return numValue.ToString("N2");
                    }
                    else if (property.ValueKind == System.Text.Json.JsonValueKind.String)
                    {
                        return property.GetString() ?? "N/A";
                    }
                    else
                    {
                        return property.ToString();
                    }
                }
                _logger.LogWarning($"Property {propertyName} not found in JSON element");
                return "N/A";
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Error getting JSON value for {propertyName}: {ex.Message}");
                return "N/A";
            }
        }

        private string GenerateLcUcHtml(object data)
        {
            if (data == null)
            {
                return "<div style='color: red; text-align: center; padding: 20px;'>No data available</div>";
            }

            var html = "<div style='font-family: Arial, sans-serif;'>";
            
            try
            {
                var dataDict = (Dictionary<string, object>)data;
                
                foreach (var kvp in dataDict)
                {
                    var indexName = kvp.Key;
                    var indexData = kvp.Value;
                    
                    html += $@"
                        <div style='background: #f8f9fa; border-radius: 8px; padding: 15px; margin: 15px 0; border: 1px solid #dee2e6;'>
                            <h4 style='margin: 0 0 15px 0; color: #4facfe; font-size: 1.2em;'>📊 {indexName}</h4>
                            
                            <div style='display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 10px; margin-bottom: 15px;'>
                                <div style='text-align: center; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;'>
                                    <div style='font-size: 0.9em; color: #6c757d; margin-bottom: 6px; font-weight: bold;'>Spot Close</div>
                                    <div style='font-weight: bold; color: #333; font-size: 1.2em;'>{GetValue(indexData, "SpotClose")}</div>
                                </div>
                                <div style='text-align: center; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;'>
                                    <div style='font-size: 0.9em; color: #6c757d; margin-bottom: 6px; font-weight: bold;'>UC Value</div>
                                    <div style='font-weight: bold; color: #333; font-size: 1.2em;'>{GetValue(indexData, "UcValue")}</div>
                                </div>
                                <div style='text-align: center; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;'>
                                    <div style='font-size: 0.9em; color: #6c757d; margin-bottom: 6px; font-weight: bold;'>Call Base</div>
                                    <div style='font-weight: bold; color: #333; font-size: 1.2em;'>{GetValue(indexData, "CallBaseStrike")}</div>
                                </div>
                                <div style='text-align: center; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;'>
                                    <div style='font-size: 0.9em; color: #6c757d; margin-bottom: 6px; font-weight: bold;'>Put Base</div>
                                    <div style='font-weight: bold; color: #333; font-size: 1.2em;'>{GetValue(indexData, "PutBaseStrike")}</div>
                                </div>
                            </div>
                    ";
                    
                    // Add LC/UC changes
                    var lcUcChanges = GetLcUcChanges(indexData);
                    if (lcUcChanges != null && lcUcChanges.Count > 0)
                    {
                        foreach (var change in lcUcChanges)
                        {
                            var optionType = GetValue(change, "OptionType");
                            var strike = GetValue(change, "Strike");
                            var lc = GetValue(change, "LowerCircuitLimit");
                            var uc = GetValue(change, "UpperCircuitLimit");
                            var quoteTime = GetValue(change, "QuoteTime");
                            
                            var borderColor = optionType == "CE" ? "#28a745" : "#dc3545";
                            
                            html += $@"
                                <div style='background: white; padding: 12px; border-radius: 6px; border: 1px solid #dee2e6; border-left: 4px solid {borderColor}; margin: 8px 0; display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 12px; align-items: center;'>
                                    <div style='text-align: center;'>
                                        <div style='font-weight: bold; font-size: 1.2em; color: #333;'>{strike}</div>
                                        <div style='font-size: 0.9em; color: #6c757d; margin-top: 4px;'>{optionType}</div>
                                    </div>
                                    <div style='color: #dc3545; text-align: center; font-weight: bold;'>LC: {lc}</div>
                                    <div style='color: #28a745; text-align: center; font-weight: bold;'>UC: {uc}</div>
                                    <div style='text-align: center; font-size: 0.9em; color: #6c757d;'>{quoteTime}</div>
                                </div>
                            ";
                        }
                    }
                    else
                    {
                        html += $@"
                            <div style='text-align: center; color: #6c757d; padding: 20px;'>
                                No LC/UC changes found for {indexName}
                            </div>
                        ";
                    }
                    
                    html += "</div>";
                }
            }
            catch (Exception ex)
            {
                html += $"<div style='color: red; text-align: center; padding: 20px;'>Error processing data: {ex.Message}</div>";
            }
            
            html += "</div>";
            return html;
        }

        private string GetValue(object data, string propertyName)
        {
            try
            {
                if (data == null) return "N/A";
                
                // Handle JsonElement from System.Text.Json
                if (data is System.Text.Json.JsonElement jsonElement)
                {
                    if (jsonElement.TryGetProperty(propertyName, out var property))
                    {
                        if (property.ValueKind == System.Text.Json.JsonValueKind.Number)
                        {
                            var numValue = property.GetDecimal();
                            if (numValue == 0) return "0";
                            return numValue.ToString("N2");
                        }
                        else if (property.ValueKind == System.Text.Json.JsonValueKind.String)
                        {
                            return property.GetString() ?? "N/A";
                        }
                        else
                        {
                            return property.ToString();
                        }
                    }
                }
                // Handle Dictionary<string, object>
                else if (data is Dictionary<string, object> dataDict)
                {
                    if (dataDict.ContainsKey(propertyName))
                    {
                        var value = dataDict[propertyName];
                        if (value == null) return "N/A";
                        
                        if (value is decimal || value is double || value is float)
                        {
                            var numValue = Convert.ToDecimal(value);
                            if (numValue == 0) return "0";
                            return numValue.ToString("N2");
                        }
                        
                        return value.ToString();
                    }
                }
                // Handle anonymous objects
                else
                {
                    var property = data.GetType().GetProperty(propertyName);
                    if (property != null)
                    {
                        var value = property.GetValue(data);
                        if (value == null) return "N/A";
                        
                        if (value is decimal || value is double || value is float)
                        {
                            var numValue = Convert.ToDecimal(value);
                            if (numValue == 0) return "0";
                            return numValue.ToString("N2");
                        }
                        
                        return value.ToString();
                    }
                }
                
                return "N/A";
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Error getting value for {propertyName}: {ex.Message}");
                return "N/A";
            }
        }

        private List<object> GetLcUcChanges(object indexData)
        {
            try
            {
                // Handle JsonElement
                if (indexData is System.Text.Json.JsonElement jsonElement)
                {
                    if (jsonElement.TryGetProperty("lcUcChanges", out var lcUcProperty))
                    {
                        if (lcUcProperty.ValueKind == System.Text.Json.JsonValueKind.Array)
                        {
                            var changesList = new List<object>();
                            foreach (var item in lcUcProperty.EnumerateArray())
                            {
                                changesList.Add(item);
                            }
                            return changesList;
                        }
                    }
                }
                // Handle Dictionary<string, object>
                else if (indexData is Dictionary<string, object> dataDict)
                {
                    if (dataDict.ContainsKey("LcUcChanges"))
                    {
                        var changes = dataDict["LcUcChanges"];
                        if (changes is List<object> changesList)
                        {
                            return changesList;
                        }
                    }
                }
                // Handle anonymous objects
                else
                {
                    var lcUcProperty = indexData.GetType().GetProperty("LcUcChanges");
                    if (lcUcProperty != null)
                    {
                        var changes = lcUcProperty.GetValue(indexData);
                        if (changes is List<object> changesList)
                        {
                            return changesList;
                        }
                    }
                }
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Error getting LC/UC changes: {ex.Message}");
                return null;
            }
        }
    }
}
