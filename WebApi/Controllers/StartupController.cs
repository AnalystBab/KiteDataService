using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Services;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    /// <summary>
    /// Startup Controller - Manages service startup and authentication
    /// Provides web-first approach to service management
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    public class StartupController : ControllerBase
    {
        private readonly ILogger<StartupController> _logger;
        private readonly ReliableAuthService _authService;
        private readonly ServiceManager _serviceManager;

        public StartupController(
            ILogger<StartupController> logger,
            ReliableAuthService authService,
            ServiceManager serviceManager)
        {
            _logger = logger;
            _authService = authService;
            _serviceManager = serviceManager;
        }

        /// <summary>
        /// Get startup status
        /// </summary>
        [HttpGet("status")]
        public async Task<IActionResult> GetStatus()
        {
            try
            {
                var isAuthenticated = await _authService.IsAuthenticatedAsync();
                
                return Ok(new
                {
                    serviceStatus = "Running",
                    authenticationStatus = isAuthenticated ? "Authenticated" : "Not Authenticated",
                    isAuthenticated = isAuthenticated,
                    timestamp = DateTime.Now,
                    message = isAuthenticated ? "Service ready for data collection" : "Authentication required"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting startup status");
                return StatusCode(500, new { error = "Failed to get startup status" });
            }
        }

        /// <summary>
        /// Update request token
        /// </summary>
        [HttpPost("update-token")]
        public async Task<IActionResult> UpdateToken([FromBody] UpdateTokenRequest request)
        {
            try
            {
                if (string.IsNullOrEmpty(request.RequestToken))
                {
                    return BadRequest(new { error = "Request token is required" });
                }

                _logger.LogInformation("Updating request token via startup controller");

                var success = await _authService.StoreRequestTokenAsync(request.RequestToken);
                
                if (success)
                {
                    return Ok(new
                    {
                        success = true,
                        message = "Token updated successfully",
                        timestamp = DateTime.Now
                    });
                }
                else
                {
                    return BadRequest(new
                    {
                        success = false,
                        message = "Failed to update token",
                        timestamp = DateTime.Now
                    });
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating token");
                return StatusCode(500, new { error = "Failed to update token" });
            }
        }

        /// <summary>
        /// Test authentication
        /// </summary>
        [HttpPost("test-auth")]
        public async Task<IActionResult> TestAuthentication()
        {
            try
            {
                _logger.LogInformation("Testing authentication via startup controller");

                var isAuthenticated = await _authService.IsAuthenticatedAsync();
                
                return Ok(new
                {
                    success = isAuthenticated,
                    message = isAuthenticated ? "Authentication successful" : "Authentication failed",
                    timestamp = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error testing authentication");
                return StatusCode(500, new { error = "Failed to test authentication" });
            }
        }

        /// <summary>
        /// Start core data collection service
        /// </summary>
        [HttpPost("start-data-collection")]
        public async Task<IActionResult> StartDataCollection()
        {
            try
            {
                _logger.LogInformation("Starting core data collection service");

                await _serviceManager.StartCoreDataCollectionAsync();
                
                return Ok(new
                {
                    success = true,
                    message = "Core data collection service started",
                    timestamp = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error starting data collection service");
                return StatusCode(500, new { error = "Failed to start data collection service" });
            }
        }

        /// <summary>
        /// Start pattern discovery service
        /// </summary>
        [HttpPost("start-pattern-discovery")]
        public async Task<IActionResult> StartPatternDiscovery()
        {
            try
            {
                _logger.LogInformation("Starting pattern discovery service");

                await _serviceManager.StartPatternDiscoveryAsync();
                
                return Ok(new
                {
                    success = true,
                    message = "Pattern discovery service started",
                    timestamp = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error starting pattern discovery service");
                return StatusCode(500, new { error = "Failed to start pattern discovery service" });
            }
        }

        /// <summary>
        /// Clear authentication cache
        /// </summary>
        [HttpPost("clear-cache")]
        public IActionResult ClearCache()
        {
            try
            {
                _logger.LogInformation("Clearing authentication cache");

                _authService.ClearCache();
                
                return Ok(new
                {
                    success = true,
                    message = "Authentication cache cleared",
                    timestamp = DateTime.Now
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error clearing cache");
                return StatusCode(500, new { error = "Failed to clear cache" });
            }
        }
    }

    /// <summary>
    /// Update token request model
    /// </summary>
    public class UpdateTokenRequest
    {
        public string RequestToken { get; set; }
    }
}






