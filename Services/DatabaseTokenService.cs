using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Data;

namespace KiteMarketDataService.Worker.Services
{
    public class DatabaseTokenService
    {
        private readonly ILogger<DatabaseTokenService> _logger;
        private readonly IConfiguration _configuration;
        private readonly IServiceScopeFactory _scopeFactory;

        public DatabaseTokenService(
            ILogger<DatabaseTokenService> logger,
            IConfiguration configuration,
            IServiceScopeFactory scopeFactory)
        {
            _logger = logger;
            _configuration = configuration;
            _scopeFactory = scopeFactory;
        }

        /// <summary>
        /// Store new request token in database - CLEAR ALL OLD VALUES, INSERT ONLY ONE RECORD
        /// </summary>
        public async Task<bool> StoreRequestTokenAsync(string requestToken)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // STEP 1: DELETE ALL OLD RECORDS (not just deactivate - truly delete everything)
                await context.Database.ExecuteSqlRawAsync("DELETE FROM AuthConfiguration");

                // STEP 2: INSERT ONLY ONE NEW RECORD with request token
                await context.Database.ExecuteSqlRawAsync(
                    "INSERT INTO AuthConfiguration (ApiKey, ApiSecret, RequestToken, IsActive, CreatedAt, UpdatedAt) VALUES ({0}, {1}, {2}, 1, GETDATE(), GETDATE())",
                    _configuration["KiteConnect:ApiKey"],
                    _configuration["KiteConnect:ApiSecret"],
                    requestToken);

                _logger.LogInformation("✅ [DB-AUTH] Deleted ALL old records, inserted ONE new request token record");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to store request token in database");
                return false;
            }
        }

        /// <summary>
        /// Get the latest active request token from database - THERE SHOULD ONLY BE ONE RECORD
        /// </summary>
        public async Task<string?> GetLatestRequestTokenAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // There should only be ONE record (after our DeleteAll + Insert fix above)
                var token = await context.AuthConfiguration
                    .Where(a => a.IsActive == true)
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => a.RequestToken)
                    .FirstOrDefaultAsync();

                if (!string.IsNullOrEmpty(token))
                {
                    _logger.LogInformation("✅ [DB-AUTH] Retrieved request token from database (should be only one)");
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No request token found in database");
                }

                return token;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to get request token from database");
                return null;
            }
        }

        /// <summary>
        /// Update access token for the latest request token
        /// </summary>
        public async Task<bool> UpdateAccessTokenAsync(string accessToken)
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
                    _logger.LogInformation("✅ [DB-AUTH] Access token updated in database");
                    return true;
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No active configuration found to update access token");
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to update access token in database");
                return false;
            }
        }

        /// <summary>
        /// Get the latest access token from database - THERE SHOULD ONLY BE ONE RECORD
        /// </summary>
        public async Task<string?> GetLatestAccessTokenAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // There should only be ONE record (after our DeleteAll + Insert fix above)
                var token = await context.AuthConfiguration
                    .Where(a => a.IsActive == true && !string.IsNullOrEmpty(a.AccessToken))
                    .Select(a => a.AccessToken)
                    .FirstOrDefaultAsync();

                if (!string.IsNullOrEmpty(token))
                {
                    _logger.LogInformation("✅ [DB-AUTH] Retrieved access token from database (should be only one)");
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No access token found in database");
                }

                return token;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to get access token from database");
                return null;
            }
        }

        /// <summary>
        /// Get API Key from database
        /// </summary>
        public async Task<string?> GetApiKeyAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var apiKey = await context.AuthConfiguration
                    .Where(a => a.IsActive == true)
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => a.ApiKey)
                    .FirstOrDefaultAsync();

                if (!string.IsNullOrEmpty(apiKey))
                {
                    _logger.LogInformation("✅ [DB-AUTH] Retrieved API key from database");
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No API key found in database");
                }

                return apiKey;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to get API key from database");
                return null;
            }
        }

        /// <summary>
        /// Get API Secret from database
        /// </summary>
        public async Task<string?> GetApiSecretAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var apiSecret = await context.AuthConfiguration
                    .Where(a => a.IsActive == true)
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => a.ApiSecret)
                    .FirstOrDefaultAsync();

                if (!string.IsNullOrEmpty(apiSecret))
                {
                    _logger.LogInformation("✅ [DB-AUTH] Retrieved API secret from database");
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No API secret found in database");
                }

                return apiSecret;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to get API secret from database");
                return null;
            }
        }

        /// <summary>
        /// Clear all old configurations (keep only the latest active one)
        /// </summary>
        public async Task<bool> CleanupOldConfigurationsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Keep only the latest active configuration, delete all others
                await context.Database.ExecuteSqlRawAsync(
                    "DELETE FROM AuthConfiguration WHERE Id NOT IN (SELECT TOP 1 Id FROM AuthConfiguration WHERE IsActive = 1 ORDER BY CreatedAt DESC)");

                _logger.LogInformation("✅ [DB-AUTH] Old configurations cleaned up from database");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to cleanup old configurations");
                return false;
            }
        }
    }
}



using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Data;

namespace KiteMarketDataService.Worker.Services
{
    public class DatabaseTokenService
    {
        private readonly ILogger<DatabaseTokenService> _logger;
        private readonly IConfiguration _configuration;
        private readonly IServiceScopeFactory _scopeFactory;

        public DatabaseTokenService(
            ILogger<DatabaseTokenService> logger,
            IConfiguration configuration,
            IServiceScopeFactory scopeFactory)
        {
            _logger = logger;
            _configuration = configuration;
            _scopeFactory = scopeFactory;
        }

        /// <summary>
        /// Store new request token in database - CLEAR ALL OLD VALUES, INSERT ONLY ONE RECORD
        /// </summary>
        public async Task<bool> StoreRequestTokenAsync(string requestToken)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // STEP 1: DELETE ALL OLD RECORDS (not just deactivate - truly delete everything)
                await context.Database.ExecuteSqlRawAsync("DELETE FROM AuthConfiguration");

                // STEP 2: INSERT ONLY ONE NEW RECORD with request token
                await context.Database.ExecuteSqlRawAsync(
                    "INSERT INTO AuthConfiguration (ApiKey, ApiSecret, RequestToken, IsActive, CreatedAt, UpdatedAt) VALUES ({0}, {1}, {2}, 1, GETDATE(), GETDATE())",
                    _configuration["KiteConnect:ApiKey"],
                    _configuration["KiteConnect:ApiSecret"],
                    requestToken);

                _logger.LogInformation("✅ [DB-AUTH] Deleted ALL old records, inserted ONE new request token record");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to store request token in database");
                return false;
            }
        }

        /// <summary>
        /// Get the latest active request token from database - THERE SHOULD ONLY BE ONE RECORD
        /// </summary>
        public async Task<string?> GetLatestRequestTokenAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // There should only be ONE record (after our DeleteAll + Insert fix above)
                var token = await context.AuthConfiguration
                    .Where(a => a.IsActive == true)
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => a.RequestToken)
                    .FirstOrDefaultAsync();

                if (!string.IsNullOrEmpty(token))
                {
                    _logger.LogInformation("✅ [DB-AUTH] Retrieved request token from database (should be only one)");
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No request token found in database");
                }

                return token;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to get request token from database");
                return null;
            }
        }

        /// <summary>
        /// Update access token for the latest request token
        /// </summary>
        public async Task<bool> UpdateAccessTokenAsync(string accessToken)
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
                    _logger.LogInformation("✅ [DB-AUTH] Access token updated in database");
                    return true;
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No active configuration found to update access token");
                    return false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to update access token in database");
                return false;
            }
        }

        /// <summary>
        /// Get the latest access token from database - THERE SHOULD ONLY BE ONE RECORD
        /// </summary>
        public async Task<string?> GetLatestAccessTokenAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // There should only be ONE record (after our DeleteAll + Insert fix above)
                var token = await context.AuthConfiguration
                    .Where(a => a.IsActive == true && !string.IsNullOrEmpty(a.AccessToken))
                    .Select(a => a.AccessToken)
                    .FirstOrDefaultAsync();

                if (!string.IsNullOrEmpty(token))
                {
                    _logger.LogInformation("✅ [DB-AUTH] Retrieved access token from database (should be only one)");
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No access token found in database");
                }

                return token;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to get access token from database");
                return null;
            }
        }

        /// <summary>
        /// Get API Key from database
        /// </summary>
        public async Task<string?> GetApiKeyAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var apiKey = await context.AuthConfiguration
                    .Where(a => a.IsActive == true)
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => a.ApiKey)
                    .FirstOrDefaultAsync();

                if (!string.IsNullOrEmpty(apiKey))
                {
                    _logger.LogInformation("✅ [DB-AUTH] Retrieved API key from database");
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No API key found in database");
                }

                return apiKey;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to get API key from database");
                return null;
            }
        }

        /// <summary>
        /// Get API Secret from database
        /// </summary>
        public async Task<string?> GetApiSecretAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                var apiSecret = await context.AuthConfiguration
                    .Where(a => a.IsActive == true)
                    .OrderByDescending(a => a.CreatedAt)
                    .Select(a => a.ApiSecret)
                    .FirstOrDefaultAsync();

                if (!string.IsNullOrEmpty(apiSecret))
                {
                    _logger.LogInformation("✅ [DB-AUTH] Retrieved API secret from database");
                }
                else
                {
                    _logger.LogWarning("⚠️ [DB-AUTH] No API secret found in database");
                }

                return apiSecret;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to get API secret from database");
                return null;
            }
        }

        /// <summary>
        /// Clear all old configurations (keep only the latest active one)
        /// </summary>
        public async Task<bool> CleanupOldConfigurationsAsync()
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Keep only the latest active configuration, delete all others
                await context.Database.ExecuteSqlRawAsync(
                    "DELETE FROM AuthConfiguration WHERE Id NOT IN (SELECT TOP 1 Id FROM AuthConfiguration WHERE IsActive = 1 ORDER BY CreatedAt DESC)");

                _logger.LogInformation("✅ [DB-AUTH] Old configurations cleaned up from database");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [DB-AUTH] Failed to cleanup old configurations");
                return false;
            }
        }
    }
}
