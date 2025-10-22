using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Text.Json;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class TokenManagementController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<TokenManagementController> _logger;

        public TokenManagementController(IConfiguration configuration, ILogger<TokenManagementController> logger)
        {
            _configuration = configuration;
            _logger = logger;
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

                // Update the appsettings.json file
                var appSettingsPath = Path.Combine(Directory.GetCurrentDirectory(), "appsettings.json");
                var appSettingsJson = System.IO.File.ReadAllText(appSettingsPath);
                var appSettings = JsonSerializer.Deserialize<JsonElement>(appSettingsJson);
                
                // Create a new configuration object with updated token
                var configDict = new Dictionary<string, object>();
                
                foreach (var property in appSettings.EnumerateObject())
                {
                    if (property.Name == "KiteConnect")
                    {
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
                    else
                    {
                        configDict[property.Name] = property.Value.ToString() ?? "";
                    }
                }

                // Write back to file
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
    }

    public class TokenUpdateRequest
    {
        public string RequestToken { get; set; } = string.Empty;
    }
}





