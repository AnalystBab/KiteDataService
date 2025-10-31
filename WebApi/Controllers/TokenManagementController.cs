using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using KiteMarketDataService.Worker.Services;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TokenManagementController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<TokenManagementController> _logger;
        private readonly KiteConnectService _kiteConnectService;

        public TokenManagementController(IConfiguration configuration, ILogger<TokenManagementController> logger, KiteConnectService kiteConnectService)
        {
            _configuration = configuration;
            _logger = logger;
            _kiteConnectService = kiteConnectService;
        }

        [HttpGet("status")]
        public IActionResult GetServiceStatus()
        {
            try
            {
                // Check if service is running by checking if we can access configuration
                var apiKey = _configuration["KiteConnect:ApiKey"];
                var requestToken = _configuration["KiteConnect:RequestToken"];
                
                var status = new
                {
                    IsRunning = true,
                    HasApiKey = !string.IsNullOrEmpty(apiKey),
                    HasRequestToken = !string.IsNullOrEmpty(requestToken),
                    Timestamp = DateTime.Now,
                    Message = "Service is running"
                };

                return Ok(status);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking service status");
                return StatusCode(500, new { IsRunning = false, Message = "Service error" });
            }
        }

        [HttpPost("update")]
        public IActionResult UpdateToken([FromBody] TokenUpdateRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.RequestToken))
                {
                    return BadRequest(new { Message = "Request token is required" });
                }

                // Use a simpler, more reliable approach - directly update the token in the configuration
                var appSettingsPath = Path.Combine(Directory.GetCurrentDirectory(), "appsettings.json");
                
                // Read the current configuration
                var appSettingsJson = System.IO.File.ReadAllText(appSettingsPath);
                var appSettings = JsonSerializer.Deserialize<JsonElement>(appSettingsJson);
                
                // Create a clean configuration object
                var configDict = new Dictionary<string, object>();
                
                // Process each property carefully
                foreach (var property in appSettings.EnumerateObject())
                {
                    if (property.Name == "KiteConnect")
                    {
                        // Handle KiteConnect section
                        var kiteConnectDict = new Dictionary<string, object>();
                        foreach (var kiteProperty in property.Value.EnumerateObject())
                        {
                            if (kiteProperty.Name == "RequestToken")
                            {
                                kiteConnectDict[kiteProperty.Name] = request.RequestToken;
                            }
                            else
                            {
                                kiteConnectDict[kiteProperty.Name] = kiteProperty.Value.GetString() ?? "";
                            }
                        }
                        configDict[property.Name] = kiteConnectDict;
                    }
                    else if (property.Name == "ConnectionStrings")
                    {
                        // Handle ConnectionStrings section - preserve as object
                        if (property.Value.ValueKind == JsonValueKind.Object)
                        {
                            var connectionDict = new Dictionary<string, object>();
                            foreach (var connProperty in property.Value.EnumerateObject())
                            {
                                connectionDict[connProperty.Name] = connProperty.Value.GetString() ?? "";
                            }
                            configDict[property.Name] = connectionDict;
                        }
                        else
                        {
                            // If it's a string, try to parse it
                            try
                            {
                                var connectionStringJson = property.Value.GetString() ?? "{}";
                                var connectionElement = JsonSerializer.Deserialize<JsonElement>(connectionStringJson);
                                var connectionDict = new Dictionary<string, object>();
                                foreach (var connProperty in connectionElement.EnumerateObject())
                                {
                                    connectionDict[connProperty.Name] = connProperty.Value.GetString() ?? "";
                                }
                                configDict[property.Name] = connectionDict;
                            }
                            catch
                            {
                                // Fallback to default connection strings
                                configDict[property.Name] = new Dictionary<string, object>
                                {
                                    ["DefaultConnection"] = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true",
                                    ["CircuitLimitTrackingConnection"] = "Server=localhost;Database=CircuitLimitTracking;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"
                                };
                            }
                        }
                    }
                    else
                    {
                        // Handle other properties based on their type
                        if (property.Value.ValueKind == JsonValueKind.String)
                        {
                            configDict[property.Name] = property.Value.GetString() ?? "";
                        }
                        else if (property.Value.ValueKind == JsonValueKind.Number)
                        {
                            configDict[property.Name] = property.Value.GetDecimal();
                        }
                        else if (property.Value.ValueKind == JsonValueKind.True || property.Value.ValueKind == JsonValueKind.False)
                        {
                            configDict[property.Name] = property.Value.GetBoolean();
                        }
                        else if (property.Value.ValueKind == JsonValueKind.Object)
                        {
                            var nestedDict = new Dictionary<string, object>();
                            foreach (var nestedProperty in property.Value.EnumerateObject())
                            {
                                if (nestedProperty.Value.ValueKind == JsonValueKind.String)
                                {
                                    nestedDict[nestedProperty.Name] = nestedProperty.Value.GetString() ?? "";
                                }
                                else if (nestedProperty.Value.ValueKind == JsonValueKind.Number)
                                {
                                    nestedDict[nestedProperty.Name] = nestedProperty.Value.GetDecimal();
                                }
                                else if (nestedProperty.Value.ValueKind == JsonValueKind.True || nestedProperty.Value.ValueKind == JsonValueKind.False)
                                {
                                    nestedDict[nestedProperty.Name] = nestedProperty.Value.GetBoolean();
                                }
                                else if (nestedProperty.Value.ValueKind == JsonValueKind.Array)
                                {
                                    var arrayList = new List<object>();
                                    foreach (var arrayItem in nestedProperty.Value.EnumerateArray())
                                    {
                                        if (arrayItem.ValueKind == JsonValueKind.String)
                                        {
                                            arrayList.Add(arrayItem.GetString() ?? "");
                                        }
                                        else if (arrayItem.ValueKind == JsonValueKind.Number)
                                        {
                                            arrayList.Add(arrayItem.GetDecimal());
                                        }
                                        else if (arrayItem.ValueKind == JsonValueKind.True || arrayItem.ValueKind == JsonValueKind.False)
                                        {
                                            arrayList.Add(arrayItem.GetBoolean());
                                        }
                                    }
                                    nestedDict[nestedProperty.Name] = arrayList;
                                }
                            }
                            configDict[property.Name] = nestedDict;
                        }
                    }
                }

                // Write back to file with proper formatting
                var updatedJson = JsonSerializer.Serialize(configDict, new JsonSerializerOptions { WriteIndented = true });
                System.IO.File.WriteAllText(appSettingsPath, updatedJson);

                // Log the token update
                _logger.LogInformation("Request token updated via web interface and saved to appsettings.json");

                return Ok(new { Message = "Token updated successfully" });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating token: {Error}", ex.Message);
                return StatusCode(500, new { Message = "Failed to update token. Please try again." });
            }
        }

        [HttpGet("current")]
        public IActionResult GetCurrentToken()
        {
            try
            {
                var requestToken = _configuration["KiteConnect:RequestToken"];
                var apiKey = _configuration["KiteConnect:ApiKey"];
                
                return Ok(new
                {
                    HasApiKey = !string.IsNullOrEmpty(apiKey),
                    HasRequestToken = !string.IsNullOrEmpty(requestToken),
                    RequestTokenLength = requestToken?.Length ?? 0,
                    LastUpdated = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting current token");
                return StatusCode(500, new { Message = "Failed to get token info" });
            }
        }

        [HttpPost("refresh")]
        public async Task<IActionResult> RefreshAccessToken()
        {
            try
            {
                // Get the current request token from configuration
                var requestToken = _configuration["KiteConnect:RequestToken"];
                
                if (string.IsNullOrEmpty(requestToken))
                {
                    return BadRequest(new { Message = "No request token found. Please update the token first." });
                }

                _logger.LogInformation("Attempting to authenticate with current request token...");
                
                // Actually authenticate with the KiteConnectService
                var isAuthenticated = await _kiteConnectService.AuthenticateWithRequestTokenAsync(requestToken);
                
                if (isAuthenticated)
                {
                    _logger.LogInformation("Authentication successful! Service can now collect live data.");
                    return Ok(new { 
                        Message = "Authentication successful! Service can now collect live data.",
                        Timestamp = DateTime.Now,
                        Authenticated = true
                    });
                }
                else
                {
                    _logger.LogWarning("Authentication failed. Please check if the request token is valid and not expired.");
                    return BadRequest(new { 
                        Message = "Authentication failed. Please check if the request token is valid and not expired.",
                        Timestamp = DateTime.Now,
                        Authenticated = false
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error refreshing token");
                return StatusCode(500, new { Message = "Failed to refresh token", Error = ex.Message });
            }
        }
    }

    public class TokenUpdateRequest
    {
        public string RequestToken { get; set; } = string.Empty;
    }
}





