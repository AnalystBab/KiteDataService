using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.IO;
using System.Windows.Forms;
using System.Drawing;
using System.Runtime.InteropServices;

namespace KiteMarketDataService.Worker.Services
{
    public class TokenManagementService : BackgroundService
    {
        private readonly ILogger<TokenManagementService> _logger;
        private readonly IConfiguration _configuration;
        private readonly KiteAuthService _kiteAuthService;
        private readonly InteractiveNotificationService _interactiveNotificationService;
        private readonly string _tokenFilePath;
        private System.Threading.Timer? _tokenCheckTimer;
        private System.Threading.Timer? _fileMonitorTimer;
        private const int TOKEN_CHECK_INTERVAL_MINUTES = 30; // Check every 30 minutes
        private const int FILE_MONITOR_INTERVAL_SECONDS = 10; // Check for new tokens every 10 seconds

        public TokenManagementService(
            ILogger<TokenManagementService> logger,
            IConfiguration configuration,
            KiteAuthService kiteAuthService,
            InteractiveNotificationService interactiveNotificationService)
        {
            _logger = logger;
            _configuration = configuration;
            _kiteAuthService = kiteAuthService;
            _interactiveNotificationService = interactiveNotificationService;
            _tokenFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "tokens.json");
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Token Management Service started");

            // Start token monitoring
            _tokenCheckTimer = new System.Threading.Timer(CheckTokenStatus, null, TimeSpan.Zero, TimeSpan.FromMinutes(TOKEN_CHECK_INTERVAL_MINUTES));
            
            // Start file monitoring for new request tokens
            _fileMonitorTimer = new System.Threading.Timer(MonitorForNewTokens, null, TimeSpan.Zero, TimeSpan.FromSeconds(FILE_MONITOR_INTERVAL_SECONDS));

            // Keep the service running
            while (!stoppingToken.IsCancellationRequested)
            {
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }

            _tokenCheckTimer?.Dispose();
            _fileMonitorTimer?.Dispose();
        }

        private async void CheckTokenStatus(object state)
        {
            try
            {
                var accessToken = _configuration["KiteConnect:AccessToken"];
                var requestToken = _configuration["KiteConnect:RequestToken"];

                // Check if we have a valid access token
                if (string.IsNullOrEmpty(accessToken) || IsTokenExpired(accessToken))
                {
                    _logger.LogWarning("Access token is missing or expired");

                    // Check if we have a request token to exchange
                    if (!string.IsNullOrEmpty(requestToken))
                    {
                        _logger.LogInformation("Attempting to exchange request token for access token");
                        var accessTokenResult = await _kiteAuthService.ExchangeRequestTokenForAccessTokenAsync(requestToken);
                        bool success = !string.IsNullOrEmpty(accessTokenResult);
                        
                        if (success)
                        {
                            _logger.LogInformation("Successfully renewed access token");
                            SaveTokenCreationTime();
                            ShowNotification("Kite Market Data Service", "Access token renewed successfully", NotificationType.Success);
                        }
                        else
                        {
                            _logger.LogError("Failed to renew access token - request token may be expired");
                            
                            // Show interactive dialog for token input
                            _ = Task.Run(async () =>
                            {
                                var success = await _interactiveNotificationService.ShowTokenInputDialogAsync(
                                    "Token Expired - Action Required",
                                    "Your access token has expired and the request token is invalid.\n\nPlease provide a new request token to continue service operation."
                                );
                                
                                if (!success)
                                {
                                    // Fallback to file-based notification
                                    ShowNotification("Kite Market Data Service", 
                                        "Failed to renew access token. Request token may be expired. Please provide a new request token.", 
                                        NotificationType.Error);
                                    CreateTokenRequestFile();
                                }
                            });
                        }
                    }
                    else
                    {
                        _logger.LogError("No request token available for token renewal");
                        
                        // Show interactive dialog for token input
                        _ = Task.Run(async () =>
                        {
                            var success = await _interactiveNotificationService.ShowTokenInputDialogAsync(
                                "Token Missing - Action Required",
                                "Your access token has expired and no request token is available.\n\nPlease provide a new request token to continue service operation."
                            );
                            
                            if (!success)
                            {
                                // Fallback to file-based notification
                                ShowNotification("Kite Market Data Service", 
                                    "Access token expired and no request token available. Please provide a new request token.", 
                                    NotificationType.Error);
                                CreateTokenRequestFile();
                            }
                        });
                    }
                }
                else
                {
                    _logger.LogDebug("Access token is valid");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking token status");
                ShowNotification("Kite Market Data Service", $"Token check error: {ex.Message}", NotificationType.Error);
            }
        }

        private void MonitorForNewTokens(object state)
        {
            try
            {
                var newTokenFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "new_request_token.txt");
                var tokenUpdateTrigger = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "token_update_trigger.txt");

                // Check for new request token file
                if (File.Exists(newTokenFile))
                {
                    _logger.LogInformation("New request token file detected");
                    
                    try
                    {
                        var newToken = File.ReadAllText(newTokenFile).Trim();
                        if (!string.IsNullOrEmpty(newToken))
                        {
                            _logger.LogInformation("Processing new request token");
                            
                            // Process the new token asynchronously
                            _ = Task.Run(async () =>
                            {
                                var success = await UpdateRequestTokenAsync(newToken);
                                if (success)
                                {
                                    // Delete the file after successful processing
                                    File.Delete(newTokenFile);
                                    _logger.LogInformation("New request token processed successfully");
                                }
                            });
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error processing new request token file");
                    }
                }

                // Check for token update trigger
                if (File.Exists(tokenUpdateTrigger))
                {
                    _logger.LogInformation("Token update trigger detected");
                    
                    try
                    {
                        var triggerContent = File.ReadAllText(tokenUpdateTrigger);
                        if (triggerContent.Contains("Request Token:"))
                        {
                            var lines = triggerContent.Split('\n');
                            foreach (var line in lines)
                            {
                                if (line.StartsWith("Request Token:"))
                                {
                                    var newToken = line.Replace("Request Token:", "").Trim();
                                    if (!string.IsNullOrEmpty(newToken))
                                    {
                                        _logger.LogInformation("Processing request token from trigger file");
                                        
                                        // Process the new token asynchronously
                                        _ = Task.Run(async () =>
                                        {
                                            var success = await UpdateRequestTokenAsync(newToken);
                                            if (success)
                                            {
                                                // Delete the trigger file after successful processing
                                                File.Delete(tokenUpdateTrigger);
                                                _logger.LogInformation("Request token from trigger processed successfully");
                                            }
                                        });
                                    }
                                    break;
                                }
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error processing token update trigger");
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error monitoring for new tokens");
            }
        }

        private void CreateTokenRequestFile()
        {
            try
            {
                var tokenRequestFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "token_request_needed.txt");
                var content = $@"TOKEN REQUEST NEEDED
Time: {DateTime.Now:yyyy-MM-dd HH:mm:ss}
Status: Access token expired and request token is invalid or missing
Action Required: Please provide a new request token

To provide a new request token, you can:

1. Use the PowerShell script:
   PowerShell -ExecutionPolicy Bypass -File 'UpdateRequestToken.ps1' -RequestToken 'YOUR_NEW_TOKEN'

2. Create a file named 'new_request_token.txt' in the service directory with just the token

3. Get a new request token from: https://kite.trade/connect/login?api_key=kw3ptb0zmocwupmo&v=3
";
                
                File.WriteAllText(tokenRequestFile, content);
                _logger.LogInformation("Token request file created");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to create token request file");
            }
        }

        private bool IsTokenExpired(string accessToken)
        {
            try
            {
                // Kite Connect access tokens typically expire after 24 hours
                // We'll check if the token is older than 23 hours to be safe
                var tokenCreationTime = GetTokenCreationTime(accessToken);
                return DateTime.UtcNow.Subtract(tokenCreationTime).TotalHours > 23;
            }
            catch
            {
                // If we can't determine the token age, assume it's expired
                return true;
            }
        }

        private DateTime GetTokenCreationTime(string accessToken)
        {
            // This is a simplified approach - in practice, you might want to store
            // the token creation time when you first receive it
            var tokenFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "token_created.txt");
            
            if (File.Exists(tokenFile))
            {
                var content = File.ReadAllText(tokenFile);
                if (DateTime.TryParse(content, out var creationTime))
                {
                    return creationTime;
                }
            }

            // If we can't determine the creation time, assume it's old
            return DateTime.UtcNow.AddHours(-25);
        }

        public void SaveTokenCreationTime()
        {
            try
            {
                var tokenFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "token_created.txt");
                File.WriteAllText(tokenFile, DateTime.UtcNow.ToString("O"));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to save token creation time");
            }
        }

        public void ShowNotification(string title, string message, NotificationType type)
        {
            try
            {
                // Try to show Windows notification
                ShowWindowsNotification(title, message, type);
                
                // Also log to file for service environment
                LogNotificationToFile(title, message, type);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to show notification");
            }
        }

        private void ShowWindowsNotification(string title, string message, NotificationType type)
        {
            try
            {
                // Use Windows Forms for system tray notification
                var icon = type switch
                {
                    NotificationType.Success => SystemIcons.Information,
                    NotificationType.Warning => SystemIcons.Warning,
                    NotificationType.Error => SystemIcons.Error,
                    _ => SystemIcons.Information
                };

                // Create a temporary form for notification
                using var form = new Form();
                form.ShowInTaskbar = false;
                form.WindowState = FormWindowState.Minimized;
                form.FormBorderStyle = FormBorderStyle.None;
                form.Opacity = 0;

                var notifyIcon = new NotifyIcon();
                notifyIcon.Icon = icon;
                notifyIcon.Visible = true;
                notifyIcon.ShowBalloonTip(5000, title, message, ToolTipIcon.Info);

                // Clean up after showing notification
                Task.Delay(6000).ContinueWith(_ =>
                {
                    notifyIcon.Dispose();
                    form.Dispose();
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to show Windows notification");
            }
        }

        private void LogNotificationToFile(string title, string message, NotificationType type)
        {
            try
            {
                var logFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "token_notifications.log");
                var logEntry = $"[{DateTime.Now:yyyy-MM-dd HH:mm:ss}] [{type}] {title}: {message}";
                File.AppendAllText(logFile, logEntry + Environment.NewLine);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to log notification to file");
            }
        }

        public async Task<bool> UpdateRequestTokenAsync(string newRequestToken)
        {
            try
            {
                _logger.LogInformation("Updating request token");

                // Update the configuration
                var configPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "appsettings.json");
                var json = await File.ReadAllTextAsync(configPath);
                
                // Simple JSON update - in production, use proper JSON manipulation
                var updatedJson = json.Replace(
                    $"\"RequestToken\": \"{_configuration["KiteConnect:RequestToken"]}\"",
                    $"\"RequestToken\": \"{newRequestToken}\""
                );
                
                await File.WriteAllTextAsync(configPath, updatedJson);

                // Attempt to exchange the new request token
                var accessTokenResult = await _kiteAuthService.ExchangeRequestTokenForAccessTokenAsync(newRequestToken);
                bool success = !string.IsNullOrEmpty(accessTokenResult);
                
                if (success)
                {
                    SaveTokenCreationTime();
                    ShowNotification("Kite Market Data Service", "New request token processed successfully", NotificationType.Success);
                    
                    // Remove any token request files
                    var tokenRequestFile = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "token_request_needed.txt");
                    if (File.Exists(tokenRequestFile))
                    {
                        File.Delete(tokenRequestFile);
                    }
                }
                else
                {
                    ShowNotification("Kite Market Data Service", "Failed to process new request token", NotificationType.Error);
                }

                return success;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to update request token");
                ShowNotification("Kite Market Data Service", $"Error updating request token: {ex.Message}", NotificationType.Error);
                return false;
            }
        }
    }

    public enum NotificationType
    {
        Success,
        Warning,
        Error
    }
} 