using System;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace KiteMarketDataService.Worker.Services
{
    public class KiteAuthService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<KiteAuthService> _logger;
        private readonly string _apiKey;
        private readonly string _apiSecret;

        public KiteAuthService(ILogger<KiteAuthService> logger, HttpClient httpClient)
        {
            _logger = logger;
            _httpClient = httpClient;
            _apiKey = "kw3ptb0zmocwupmo";
            _apiSecret = "q6iqhpb3lx2sw9tomkrljb5fmczdx6mv";
        }

        public string GetLoginUrl()
        {
            return $"https://kite.trade/connect/login?api_key={_apiKey}&v=3";
        }

        public async Task<string?> ExchangeRequestTokenForAccessTokenAsync(string requestToken)
        {
            try
            {
                _logger.LogInformation($"Exchanging request token for access token: {requestToken}");

                var url = "https://api.kite.trade/session/token";
                var content = new FormUrlEncodedContent(new[]
                {
                    new KeyValuePair<string, string>("api_key", _apiKey),
                    new KeyValuePair<string, string>("request_token", requestToken),
                    new KeyValuePair<string, string>("checksum", GenerateChecksum(requestToken))
                });

                _httpClient.DefaultRequestHeaders.Remove("X-Kite-Version");
                _httpClient.DefaultRequestHeaders.Add("X-Kite-Version", "3");

                var response = await _httpClient.PostAsync(url, content);
                
                if (response.IsSuccessStatusCode)
                {
                    var responseContent = await response.Content.ReadAsStringAsync();
                    var tokenResponse = JsonConvert.DeserializeObject<TokenResponse>(responseContent);
                    
                    if (tokenResponse?.Data?.AccessToken != null)
                    {
                        _logger.LogInformation("Successfully obtained access token");
                        return tokenResponse.Data.AccessToken;
                    }
                    else
                    {
                        _logger.LogError($"Failed to get access token. Response: {responseContent}");
                        return null;
                    }
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"Failed to exchange request token. Status: {response.StatusCode}, Content: {errorContent}");
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to exchange request token for access token");
                return null;
            }
        }

        private string GenerateChecksum(string requestToken)
        {
            // For Kite Connect v3, checksum is SHA256(api_key + request_token + api_secret)
            var data = _apiKey + requestToken + _apiSecret;
            using (var sha256 = System.Security.Cryptography.SHA256.Create())
            {
                var hashBytes = sha256.ComputeHash(System.Text.Encoding.UTF8.GetBytes(data));
                return Convert.ToHexString(hashBytes).ToLower();
            }
        }

        public void PrintAuthenticationInstructions()
        {
            Console.WriteLine("=== Kite Connect Authentication Instructions ===");
            Console.WriteLine();
            Console.WriteLine($"1. Visit this URL to login: {GetLoginUrl()}");
            Console.WriteLine("2. Login with your Zerodha credentials");
            Console.WriteLine("3. You'll be redirected to: http://127.0.0.1:3000?action=login&status=success&request_token=YOUR_REQUEST_TOKEN");
            Console.WriteLine("4. Copy the request_token from the URL");
            Console.WriteLine("5. Update the request token in the configuration");
            Console.WriteLine();
            Console.WriteLine("Note: The access token will be automatically obtained when you provide the request token.");
            Console.WriteLine();
        }
    }

    public class TokenResponse
    {
        [JsonProperty("status")]
        public string? Status { get; set; }

        [JsonProperty("data")]
        public TokenData? Data { get; set; }
    }

    public class TokenData
    {
        [JsonProperty("access_token")]
        public string? AccessToken { get; set; }

        [JsonProperty("refresh_token")]
        public string? RefreshToken { get; set; }

        [JsonProperty("api_key")]
        public string? ApiKey { get; set; }

        [JsonProperty("public_token")]
        public string? PublicToken { get; set; }

        [JsonProperty("user_id")]
        public string? UserId { get; set; }

        [JsonProperty("user_name")]
        public string? UserName { get; set; }

        [JsonProperty("user_shortname")]
        public string? UserShortname { get; set; }

        [JsonProperty("user_type")]
        public string? UserType { get; set; }

        [JsonProperty("email")]
        public string? Email { get; set; }

        [JsonProperty("broker")]
        public string? Broker { get; set; }

        [JsonProperty("exchanges")]
        public string[]? Exchanges { get; set; }

        [JsonProperty("products")]
        public string[]? Products { get; set; }

        [JsonProperty("order_types")]
        public string[]? OrderTypes { get; set; }

        [JsonProperty("avatar_url")]
        public string? AvatarUrl { get; set; }

        [JsonProperty("meta")]
        public object? Meta { get; set; }
    }
} 