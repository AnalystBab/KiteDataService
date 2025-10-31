using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Reliable Authentication Service with comprehensive error handling and validation
    /// Addresses root causes of persistent authentication issues
    /// </summary>
    public class ReliableAuthService
    {
        private readonly ILogger<ReliableAuthService> _logger;
        private readonly IConfiguration _configuration;
        private readonly HttpClient _httpClient;
        private readonly IServiceScopeFactory _scopeFactory;

        // Authentication state tracking
        private bool _isAuthenticated = false;
        private DateTime _lastAuthCheck = DateTime.MinValue;
        private string _currentAccessToken = null;
        private DateTime _tokenExpiry = DateTime.MinValue;

        public ReliableAuthService(
            ILogger<ReliableAuthService> logger,
            IConfiguration configuration,
            HttpClient httpClient,
            IServiceScopeFactory scopeFactory)
        {
            _logger = logger;
            _configuration = configuration;
            _httpClient = httpClient;
            _scopeFactory = scopeFactory;
        }

        /// <summary>
        /// Comprehensive authentication check with caching and validation
        /// </summary>
        public async Task<bool> IsAuthenticatedAsync()
        {
            try
            {
                // Use cached result if recent (within 5 minutes)
                if (_isAuthenticated && DateTime.Now.Subtract(_lastAuthCheck).TotalMinutes < 5)
                {
                    _logger.LogDebug("✅ [AUTH] Using cached authentication result");
                    return true;
                }

                _logger.LogInformation("🔍 [AUTH] Performing fresh authentication check");

                // Get credentials from database
                var credentials = await GetCredentialsFromDatabaseAsync();
                if (credentials == null)
                {
                    _logger.LogWarning("⚠️ [AUTH] No credentials found in database");
                    _isAuthenticated = false;
                    return false;
                }

                // Validate access token if available
                if (!string.IsNullOrEmpty(credentials.AccessToken))
                {
                    var isValid = await ValidateAccessTokenAsync(credentials.AccessToken);
                    if (isValid)
                    {
                        _isAuthenticated = true;
                        _lastAuthCheck = DateTime.Now;
                        _currentAccessToken = credentials.AccessToken;
                        _logger.LogInformation("✅ [AUTH] Access token is valid");
                        return true;
                    }
                }

                // Try to refresh access token if request token is available
                if (!string.IsNullOrEmpty(credentials.RequestToken))
                {
                    _logger.LogInformation("🔄 [AUTH] Attempting to refresh access token");
                    var newAccessToken = await ExchangeRequestTokenForAccessTokenAsync(
                        credentials.RequestToken, 
                        credentials.ApiKey, 
                        credentials.ApiSecret);

                    if (!string.IsNullOrEmpty(newAccessToken))
                    {
                        await UpdateAccessTokenInDatabaseAsync(newAccessToken);
                        _isAuthenticated = true;
                        _lastAuthCheck = DateTime.Now;
                        _currentAccessToken = newAccessToken;
                        _logger.LogInformation("✅ [AUTH] Successfully refreshed access token");
                        return true;
                    }
                }

                _isAuthenticated = false;
                _logger.LogWarning("❌ [AUTH] Authentication failed - no valid tokens");
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Error during authentication check");
                _isAuthenticated = false;
                return false;
            }
        }

        /// <summary>
        /// Get fresh access token from request token
        /// </summary>
        public async Task<string> GetAccessTokenAsync()
        {
            if (await IsAuthenticatedAsync())
            {
                return _currentAccessToken;
            }

            // Try to get from database
            var credentials = await GetCredentialsFromDatabaseAsync();
            return credentials?.AccessToken;
        }

        /// <summary>
        /// Store new request token and exchange for access token
        /// </summary>
        public async Task<bool> StoreRequestTokenAsync(string requestToken)
        {
            try
            {
                _logger.LogInformation("🔄 [AUTH] Storing new request token");

                var credentials = await GetCredentialsFromDatabaseAsync();
                if (credentials == null)
                {
                    _logger.LogError("❌ [AUTH] No API credentials found in database");
                    return false;
                }

                // Exchange request token for access token
                var accessToken = await ExchangeRequestTokenForAccessTokenAsync(
                    requestToken, 
                    credentials.ApiKey, 
                    credentials.ApiSecret);

                if (string.IsNullOrEmpty(accessToken))
                {
                    _logger.LogError("❌ [AUTH] Failed to exchange request token for access token");
                    return false;
                }

                // Store both tokens in database
                await StoreTokensInDatabaseAsync(requestToken, accessToken);

                // Update cached state
                _isAuthenticated = true;
                _lastAuthCheck = DateTime.Now;
                _currentAccessToken = accessToken;

                _logger.LogInformation("✅ [AUTH] Successfully stored request token and obtained access token");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Error storing request token");
                return false;
            }
        }

        /// <summary>
        /// Get credentials from database with proper error handling
        /// </summary>
        private async Task<AuthCredentials> GetCredentialsFromDatabaseAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var config = await context.AuthConfiguration
                    .Where(a => a.IsActive == true)
                    .OrderByDescending(a => a.CreatedAt)
                    .FirstOrDefaultAsync();

                if (config == null)
                {
                    _logger.LogWarning("⚠️ [AUTH] No active configuration found in database");
                    return null;
                }

                return new AuthCredentials
                {
                    ApiKey = config.ApiKey,
                    ApiSecret = config.ApiSecret,
                    RequestToken = config.RequestToken,
                    AccessToken = config.AccessToken
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Error retrieving credentials from database");
                return null;
            }
        }

        /// <summary>
        /// Exchange request token for access token with comprehensive error handling
        /// </summary>
        private async Task<string> ExchangeRequestTokenForAccessTokenAsync(string requestToken, string apiKey, string apiSecret)
        {
            try
            {
                _logger.LogInformation("🔄 [AUTH] Exchanging request token for access token");

                var checksum = GenerateChecksum(apiKey, requestToken, apiSecret);
                
                var formData = new List<KeyValuePair<string, string>>
                {
                    new KeyValuePair<string, string>("api_key", apiKey),
                    new KeyValuePair<string, string>("request_token", requestToken),
                    new KeyValuePair<string, string>("checksum", checksum)
                };

                var content = new FormUrlEncodedContent(formData);
                var response = await _httpClient.PostAsync("https://api.kite.trade/session/token", content);

                if (response.IsSuccessStatusCode)
                {
                    var responseContent = await response.Content.ReadAsStringAsync();
                    var tokenResponse = JsonSerializer.Deserialize<TokenResponse>(responseContent);
                    
                    if (tokenResponse?.Data?.AccessToken != null)
                    {
                        _logger.LogInformation("✅ [AUTH] Successfully obtained access token");
                        return tokenResponse.Data.AccessToken;
                    }
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError("❌ [AUTH] Token exchange failed: {StatusCode} - {Error}", 
                        response.StatusCode, errorContent);
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Error during token exchange");
                return null;
            }
        }

        /// <summary>
        /// Validate access token by making a test API call
        /// </summary>
        private async Task<bool> ValidateAccessTokenAsync(string accessToken)
        {
            try
            {
                _logger.LogDebug("🔍 [AUTH] Validating access token");

                _httpClient.DefaultRequestHeaders.Clear();
                _httpClient.DefaultRequestHeaders.Add("Authorization", $"token {accessToken}");

                var response = await _httpClient.GetAsync("https://api.kite.trade/user/profile");
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogDebug("✅ [AUTH] Access token is valid");
                    return true;
                }
                else
                {
                    _logger.LogWarning("⚠️ [AUTH] Access token validation failed: {StatusCode}", response.StatusCode);
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Error validating access token");
                return false;
            }
        }

        /// <summary>
        /// Store tokens in database with proper error handling
        /// </summary>
        private async Task StoreTokensInDatabaseAsync(string requestToken, string accessToken)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Deactivate all existing configurations
                await context.Database.ExecuteSqlRawAsync("UPDATE AuthConfiguration SET IsActive = 0");

                // Get API credentials from configuration
                var apiKey = _configuration["KiteConnect:ApiKey"];
                var apiSecret = _configuration["KiteConnect:ApiSecret"];

                // Create new configuration
                var newConfig = new AuthConfiguration
                {
                    ApiKey = apiKey,
                    ApiSecret = apiSecret,
                    RequestToken = requestToken,
                    AccessToken = accessToken,
                    IsActive = true,
                    CreatedAt = DateTime.Now,
                    UpdatedAt = DateTime.Now,
                    Notes = "Created by ReliableAuthService"
                };

                context.AuthConfiguration.Add(newConfig);
                await context.SaveChangesAsync();

                _logger.LogInformation("✅ [AUTH] Tokens stored in database successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Error storing tokens in database");
                throw;
            }
        }

        /// <summary>
        /// Update access token in database
        /// </summary>
        private async Task UpdateAccessTokenInDatabaseAsync(string accessToken)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var config = await context.AuthConfiguration
                    .Where(a => a.IsActive == true)
                    .FirstOrDefaultAsync();

                if (config != null)
                {
                    config.AccessToken = accessToken;
                    config.UpdatedAt = DateTime.Now;
                    await context.SaveChangesAsync();
                    _logger.LogInformation("✅ [AUTH] Access token updated in database");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Error updating access token in database");
                throw;
            }
        }

        /// <summary>
        /// Generate checksum for Kite Connect API
        /// </summary>
        private string GenerateChecksum(string apiKey, string requestToken, string apiSecret)
        {
            try
            {
                var input = $"{apiKey}{requestToken}{apiSecret}";
                using var sha256 = System.Security.Cryptography.SHA256.Create();
                var hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(input));
                return Convert.ToHexString(hashBytes).ToLower();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Error generating checksum");
                throw;
            }
        }

        /// <summary>
        /// Clear authentication cache
        /// </summary>
        public void ClearCache()
        {
            _isAuthenticated = false;
            _lastAuthCheck = DateTime.MinValue;
            _currentAccessToken = null;
            _tokenExpiry = DateTime.MinValue;
            _logger.LogInformation("🔄 [AUTH] Authentication cache cleared");
        }
    }

    /// <summary>
    /// Authentication credentials model
    /// </summary>
    public class AuthCredentials
    {
        public string ApiKey { get; set; }
        public string ApiSecret { get; set; }
        public string RequestToken { get; set; }
        public string AccessToken { get; set; }
    }
}
