using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using System.Text;

namespace KiteMarketDataService.Worker.Services
{
    public class RobustKiteAuthService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<RobustKiteAuthService> _logger;
        private readonly IConfiguration _configuration;
        private readonly DatabaseTokenService _dbTokenService;

        public RobustKiteAuthService(
            ILogger<RobustKiteAuthService> logger, 
            HttpClient httpClient, 
            IConfiguration configuration,
            DatabaseTokenService dbTokenService)
        {
            _logger = logger;
            _httpClient = httpClient;
            _configuration = configuration;
            _dbTokenService = dbTokenService;
        }

        /// <summary>
        /// Store new request token in database and clean up old ones
        /// </summary>
        public async Task<bool> StoreNewRequestTokenAsync(string requestToken)
        {
            try
            {
                _logger.LogInformation("🔄 [AUTH] Storing new request token in database...");
                
                // StoreNewRequestTokenAsync now handles DeleteAll + Insert in one call
                // No need for cleanup - DB only has ONE record always
                var success = await _dbTokenService.StoreRequestTokenAsync(requestToken);
                
                if (success)
                {
                    _logger.LogInformation("✅ [AUTH] New request token stored successfully");
                    return true;
                }
                else
                {
                    _logger.LogError("❌ [AUTH] Failed to store new request token");
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Exception storing new request token: {Error}", ex.Message);
                return false;
            }
        }

        public async Task<string> GetLoginUrlAsync()
        {
            var apiKey = await _dbTokenService.GetApiKeyAsync();
            return $"https://kite.trade/connect/login?api_key={apiKey}&v=3";
        }

        public async Task<bool> IsAuthenticatedAsync()
        {
            try
            {
                _logger.LogInformation("🔍 [AUTH] Starting authentication check...");
                
                // STEP 1: First check if we have a valid access token in database
                var existingAccessToken = await _dbTokenService.GetLatestAccessTokenAsync();
                if (!string.IsNullOrEmpty(existingAccessToken))
                {
                    // STEP 2: Validate the existing access token (lightweight check)
                    if (await ValidateAccessTokenAsync(existingAccessToken))
                    {
                        _logger.LogInformation("✅ [AUTH] Existing access token is valid - no refresh needed");
                        return true;
                    }
                    else
                    {
                        _logger.LogWarning("⚠️ [AUTH] Existing access token is invalid - will try to refresh");
                    }
                }
                
                // STEP 3: Only if no valid access token, try to exchange request token
                var requestToken = await _dbTokenService.GetLatestRequestTokenAsync();
                if (!string.IsNullOrEmpty(requestToken))
                {
                    _logger.LogInformation("🔄 [AUTH] Attempting to exchange request token for new access token...");
                    var newAccessToken = await ExchangeRequestTokenForAccessTokenAsync(requestToken);
                    if (!string.IsNullOrEmpty(newAccessToken))
                    {
                        _logger.LogInformation("✅ [AUTH] Successfully generated fresh access token");
                        
                        // Update database with new access token
                        await _dbTokenService.UpdateAccessTokenAsync(newAccessToken);
                        return true;
                    }
                    else
                    {
                        _logger.LogError("❌ [AUTH] Failed to generate fresh access token from request token");
                    }
                }
                else
                {
                    _logger.LogError("❌ [AUTH] No request token found in database");
                }

                _logger.LogError("❌ [AUTH] Authentication failed - no valid tokens available");
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [AUTH] Exception during authentication check: {Error}", ex.Message);
                return false;
            }
        }

        /// <summary>
        /// Validate access token by making a lightweight API call
        /// </summary>
        private async Task<bool> ValidateAccessTokenAsync(string accessToken)
        {
            try
            {
                _httpClient.DefaultRequestHeaders.Clear();
                _httpClient.DefaultRequestHeaders.Add("Authorization", $"token {accessToken}");
                _httpClient.DefaultRequestHeaders.Add("X-Kite-Version", "3");

                var response = await _httpClient.GetAsync("https://api.kite.trade/user/profile");
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogDebug("✅ [AUTH] Access token validation successful");
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
                _logger.LogError(ex, "❌ [AUTH] Error validating access token: {Error}", ex.Message);
                return false;
            }
        }

        public async Task<string?> ExchangeRequestTokenForAccessTokenAsync(string requestToken, int maxRetries = 3)
        {
            for (int attempt = 1; attempt <= maxRetries; attempt++)
            {
                try
                {
                    _logger.LogInformation("🔄 [AUTH] Attempt {Attempt}/{MaxRetries}: Exchanging request token for access token", attempt, maxRetries);

                    // Get API key and secret from database
                    var apiKey = await _dbTokenService.GetApiKeyAsync();
                    var apiSecret = await _dbTokenService.GetApiSecretAsync();

                    if (string.IsNullOrEmpty(apiKey) || string.IsNullOrEmpty(apiSecret))
                    {
                        _logger.LogError("❌ [AUTH] API key or secret not found in database");
                        return null;
                    }

                    var url = "https://api.kite.trade/session/token";
                    var checksum = GenerateChecksum(apiKey, requestToken, apiSecret);
                    
                    var content = new FormUrlEncodedContent(new[]
                    {
                        new KeyValuePair<string, string>("api_key", apiKey),
                        new KeyValuePair<string, string>("request_token", requestToken),
                        new KeyValuePair<string, string>("checksum", checksum)
                    });

                    // Clear and set headers
                    _httpClient.DefaultRequestHeaders.Remove("X-Kite-Version");
                    _httpClient.DefaultRequestHeaders.Add("X-Kite-Version", "3");

                    _logger.LogInformation($"Making request to: {url}");
                    _logger.LogInformation($"API Key: {apiKey}");
                    _logger.LogInformation($"Request Token: {requestToken.Substring(0, 4)}...{requestToken.Substring(requestToken.Length - 4)}");
                    _logger.LogInformation($"Checksum: {checksum}");

                    var response = await _httpClient.PostAsync(url, content);
                    var responseContent = await response.Content.ReadAsStringAsync();
                    
                    _logger.LogInformation($"Response Status: {response.StatusCode}");
                    _logger.LogInformation($"Response Content: {responseContent}");

                    if (response.IsSuccessStatusCode)
                    {
                        var tokenResponse = JsonConvert.DeserializeObject<TokenResponse>(responseContent);
                        
                        if (tokenResponse?.Data?.AccessToken != null)
                        {
                            _logger.LogInformation("✅ Successfully obtained access token");
                            return tokenResponse.Data.AccessToken;
                        }
                        else
                        {
                            _logger.LogError($"❌ Failed to get access token from response: {responseContent}");
                        }
                    }
                    else
                    {
                        _logger.LogError($"❌ HTTP Error {response.StatusCode}: {responseContent}");
                        
                        // If it's a token error, don't retry
                        if (responseContent.Contains("Token is invalid") || responseContent.Contains("TokenException"))
                        {
                            _logger.LogError("Token is invalid or expired, no point in retrying");
                            break;
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"❌ Exception during token exchange (attempt {attempt}/{maxRetries})");
                }

                if (attempt < maxRetries)
                {
                    _logger.LogInformation($"⏳ Waiting 2 seconds before retry...");
                    await Task.Delay(2000);
                }
            }

            _logger.LogError("❌ All authentication attempts failed");
            return null;
        }

        private string GenerateChecksum(string apiKey, string requestToken, string apiSecret)
        {
            var data = apiKey + requestToken + apiSecret;
            using (var sha256 = System.Security.Cryptography.SHA256.Create())
            {
                var hashBytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(data));
                return Convert.ToHexString(hashBytes).ToLower();
            }
        }
    }
}
