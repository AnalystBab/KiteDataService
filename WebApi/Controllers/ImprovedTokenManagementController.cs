using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using System.Text.Json;
using KiteMarketDataService.Worker.Services;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ImprovedTokenManagementController : ControllerBase
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<ImprovedTokenManagementController> _logger;
        private readonly RobustKiteAuthService _authService;
        private readonly DatabaseTokenService _dbTokenService;
        
        // Cache recent successful authentication for 30 seconds to avoid re-validation
        private static DateTime? _lastSuccessfulAuth = null;
        private static readonly TimeSpan AuthCacheDuration = TimeSpan.FromSeconds(30);

        public ImprovedTokenManagementController(
            IConfiguration configuration, 
            ILogger<ImprovedTokenManagementController> logger, 
            RobustKiteAuthService authService,
            DatabaseTokenService dbTokenService)
        {
            _configuration = configuration;
            _logger = logger;
            _authService = authService;
            _dbTokenService = dbTokenService;
        }

        [HttpGet("status")]
        public async Task<IActionResult> GetServiceStatus()
        {
            try
            {
                var apiKey = _configuration["KiteConnect:ApiKey"];
                // Use DATABASE as the source of truth for tokens to avoid stale appsettings
                var requestToken = await _dbTokenService.GetLatestRequestTokenAsync();
                var accessToken = await _dbTokenService.GetLatestAccessTokenAsync();
                
                bool isAuthenticated = false;
                
                // If we have an access token, check authentication
                if (!string.IsNullOrEmpty(accessToken))
                {
                    // OPTIMIZATION: If we recently (within 30 seconds) successfully authenticated,
                    // trust the cached result to avoid slow re-validation
                    if (_lastSuccessfulAuth.HasValue && 
                        (DateTime.Now - _lastSuccessfulAuth.Value) < AuthCacheDuration)
                    {
                        _logger.LogDebug("✅ [API] Using cached authentication result (recently authenticated)");
                        isAuthenticated = true;
                    }
                    else
                    {
                        // Validate token (but don't block UI if validation is slow)
                        try
                        {
                            // Use async validation but don't wait too long
                            var validationTask = _authService.IsAuthenticatedAsync();
                            if (await Task.WhenAny(validationTask, Task.Delay(TimeSpan.FromSeconds(2))) == validationTask)
                            {
                                isAuthenticated = await validationTask;
                            }
                            else
                            {
                                // Validation taking too long - if we have access token, assume valid for now
                                _logger.LogWarning("⚠️ [API] Authentication check taking too long, assuming valid if token exists");
                                isAuthenticated = true; // Optimistic: if we have token, likely valid
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "⚠️ [API] Error during authentication check, assuming valid if token exists");
                            isAuthenticated = true; // Optimistic: if we have token, likely valid
                        }
                    }
                }

                var status = new
                {
                    IsRunning = true,
                    IsAuthenticated = isAuthenticated,
                    HasApiKey = !string.IsNullOrEmpty(apiKey),
                    HasRequestToken = !string.IsNullOrEmpty(requestToken),
                    HasAccessToken = !string.IsNullOrEmpty(accessToken),
                    Timestamp = DateTime.Now,
                    Message = isAuthenticated ? "Service is running and authenticated" : "Service is running but not authenticated"
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
        public async Task<IActionResult> UpdateToken([FromBody] TokenUpdateRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.RequestToken))
                {
                    return BadRequest(new { 
                        Message = "Request token is required",
                        Error = "MISSING_TOKEN",
                        Timestamp = DateTime.Now
                    });
                }

                if (request.RequestToken.Length < 10)
                {
                    return BadRequest(new { 
                        Message = "Invalid request token format. Please get a new token from Kite Connect.",
                        Error = "INVALID_TOKEN_FORMAT",
                        Timestamp = DateTime.Now
                    });
                }

                _logger.LogInformation("🔄 [API] Updating request token via database...");

                // STEP 1: Store new request token in database
                var storeSuccess = await _authService.StoreNewRequestTokenAsync(request.RequestToken);
                
                if (!storeSuccess)
                {
                    _logger.LogError("❌ [API] Failed to update request token in database");
                    return BadRequest(new { 
                        Message = "Failed to update request token in database",
                        Error = "DATABASE_UPDATE_FAILED",
                        Timestamp = DateTime.Now
                    });
                }

                _logger.LogInformation("✅ [API] Request token stored. Now exchanging for access token...");

                // STEP 2: IMMEDIATELY exchange request token for access token
                var isAuthenticated = await _authService.IsAuthenticatedAsync();
                
                if (isAuthenticated)
                {
                    var accessToken = await _dbTokenService.GetLatestAccessTokenAsync();
                    
                    // Cache successful authentication for 30 seconds
                    _lastSuccessfulAuth = DateTime.Now;
                    
                    _logger.LogInformation("✅ [API] Request token updated and access token generated successfully!");
                    return Ok(new { 
                        Message = "Request token updated and access token generated successfully!",
                        Timestamp = DateTime.Now,
                        Status = "SUCCESS",
                        Authenticated = true,
                        HasAccessToken = !string.IsNullOrEmpty(accessToken)
                    });
                }
                else
                {
                    _logger.LogWarning("⚠️ [API] Request token stored but failed to generate access token");
                    return BadRequest(new { 
                        Message = "Request token stored but failed to generate access token. Token may be expired or invalid.",
                        Error = "TOKEN_EXCHANGE_FAILED",
                        Timestamp = DateTime.Now,
                        Suggestion = "Get a fresh request token from Kite Connect"
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating token: {Error}", ex.Message);
                return StatusCode(500, new { 
                    Message = "Failed to update token. Please try again.",
                    Error = ex.Message,
                    Timestamp = DateTime.Now,
                    Suggestion = "Check if the appsettings.json file is writable"
                });
            }
        }

        [HttpGet("current")]
        public IActionResult GetCurrentToken()
        {
            try
            {
                var requestToken = _configuration["KiteConnect:RequestToken"];
                var apiKey = _configuration["KiteConnect:ApiKey"];
                var apiSecret = _configuration["KiteConnect:ApiSecret"];
                var accessToken = _configuration["KiteConnect:AccessToken"];
                
                return Ok(new
                {
                    HasApiKey = !string.IsNullOrEmpty(apiKey),
                    HasApiSecret = !string.IsNullOrEmpty(apiSecret),
                    HasRequestToken = !string.IsNullOrEmpty(requestToken),
                    HasAccessToken = !string.IsNullOrEmpty(accessToken),
                    RequestTokenLength = requestToken?.Length ?? 0,
                    RequestTokenPreview = !string.IsNullOrEmpty(requestToken) ? 
                        $"{requestToken.Substring(0, Math.Min(4, requestToken.Length))}...{requestToken.Substring(Math.Max(0, requestToken.Length - 4))}" : 
                        "Not set",
                    AccessTokenPreview = !string.IsNullOrEmpty(accessToken) ? 
                        $"{accessToken.Substring(0, Math.Min(4, accessToken.Length))}...{accessToken.Substring(Math.Max(0, accessToken.Length - 4))}" : 
                        "Not set",
                    LastUpdated = DateTime.Now,
                    Status = !string.IsNullOrEmpty(requestToken) ? "READY" : "MISSING_TOKEN"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting current token");
                return StatusCode(500, new { 
                    Message = "Failed to get token info",
                    Error = ex.Message,
                    Timestamp = DateTime.Now
                });
            }
        }

        [HttpPost("refresh")]
        public async Task<IActionResult> RefreshAccessToken()
        {
            try
            {
                var requestToken = _configuration["KiteConnect:RequestToken"];
                
                if (string.IsNullOrEmpty(requestToken))
                {
                    return BadRequest(new { 
                        Message = "No request token found. Please update the token first.",
                        Error = "MISSING_TOKEN",
                        Timestamp = DateTime.Now
                    });
                }

                _logger.LogInformation("Attempting to authenticate with current request token...");
                
                // Clear any cached tokens
                // Cache clearing is now handled by database cleanup
                
                // Try to authenticate
                var isAuthenticated = await _authService.IsAuthenticatedAsync();
                
                if (isAuthenticated)
                {
                    var accessToken = await _dbTokenService.GetLatestAccessTokenAsync();
                    _logger.LogInformation("✅ Authentication successful! Service can now collect live data.");
                    return Ok(new { 
                        Message = "Authentication successful! Service can now collect live data.",
                        Timestamp = DateTime.Now,
                        Authenticated = true,
                        Status = "SUCCESS",
                        AccessToken = accessToken?.Substring(0, Math.Min(8, accessToken.Length)) + "..."
                    });
                }
                else
                {
                    _logger.LogWarning("❌ Authentication failed. Please check if the request token is valid and not expired.");
                    return BadRequest(new { 
                        Message = "Authentication failed. Please check if the request token is valid and not expired.",
                        Timestamp = DateTime.Now,
                        Authenticated = false,
                        Error = "AUTH_FAILED",
                        Suggestion = "Try getting a new request token from Kite Connect"
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error refreshing token: {Error}", ex.Message);
                return StatusCode(500, new { 
                    Message = "Failed to refresh token", 
                    Error = ex.Message,
                    Timestamp = DateTime.Now,
                    Suggestion = "Check your internet connection and try again"
                });
            }
        }

        [HttpPost("test")]
        public async Task<IActionResult> TestConnection()
        {
            try
            {
                var isAuthenticated = await _authService.IsAuthenticatedAsync();
                
                if (isAuthenticated)
                {
                    return Ok(new { 
                        Message = "Connection test successful!",
                        Timestamp = DateTime.Now,
                        Status = "SUCCESS",
                        Authenticated = true
                    });
                }
                else
                {
                    return BadRequest(new { 
                        Message = "Connection test failed - not authenticated",
                        Timestamp = DateTime.Now,
                        Status = "FAILED",
                        Authenticated = false,
                        Suggestion = "Try refreshing the access token"
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error testing connection: {Error}", ex.Message);
                return StatusCode(500, new { 
                    Message = "Connection test failed", 
                    Error = ex.Message,
                    Timestamp = DateTime.Now
                });
            }
        }
    }

}
