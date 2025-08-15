using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using System.Windows.Forms;
using System.Drawing;
using System.IO;

namespace KiteMarketDataService.Worker.Services
{
    public class InteractiveNotificationService
    {
        private readonly ILogger<InteractiveNotificationService> _logger;
        private readonly TokenManagementService _tokenManagementService;

        public InteractiveNotificationService(
            ILogger<InteractiveNotificationService> logger,
            TokenManagementService tokenManagementService)
        {
            _logger = logger;
            _tokenManagementService = tokenManagementService;
        }

        public async Task<bool> ShowTokenInputDialogAsync(string title, string message)
        {
            try
            {
                _logger.LogInformation("Showing interactive token input dialog");

                // Run the dialog on the UI thread
                var result = await Task.Run(() =>
                {
                    return Application.OpenForms.Count > 0 
                        ? ShowDialogOnExistingThread(title, message)
                        : ShowDialogOnNewThread(title, message);
                });

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error showing interactive token input dialog");
                return false;
            }
        }

        private bool ShowDialogOnExistingThread(string title, string message)
        {
            try
            {
                var form = new Form
                {
                    Text = title,
                    Size = new Size(500, 300),
                    StartPosition = FormStartPosition.CenterScreen,
                    FormBorderStyle = FormBorderStyle.FixedDialog,
                    MaximizeBox = false,
                    MinimizeBox = false,
                    ShowInTaskbar = true,
                    TopMost = true
                };

                // Create message label
                var messageLabel = new Label
                {
                    Text = message,
                    Location = new Point(20, 20),
                    Size = new Size(440, 60),
                    Font = new Font("Segoe UI", 10),
                    ForeColor = Color.DarkRed
                };

                // Create instruction label
                var instructionLabel = new Label
                {
                    Text = "Please enter your new request token:",
                    Location = new Point(20, 90),
                    Size = new Size(440, 20),
                    Font = new Font("Segoe UI", 9, FontStyle.Bold)
                };

                // Create token input textbox
                var tokenTextBox = new TextBox
                {
                    Location = new Point(20, 120),
                    Size = new Size(440, 25),
                    Font = new Font("Consolas", 10),
                    UseSystemPasswordChar = true, // Hide token for security
                    TabIndex = 0
                };

                // Create buttons
                var submitButton = new Button
                {
                    Text = "Submit Token",
                    Location = new Point(20, 160),
                    Size = new Size(100, 30),
                    BackColor = Color.LightGreen,
                    TabIndex = 1
                };

                var cancelButton = new Button
                {
                    Text = "Cancel",
                    Location = new Point(140, 160),
                    Size = new Size(80, 30),
                    BackColor = Color.LightCoral,
                    TabIndex = 2
                };

                var getTokenButton = new Button
                {
                    Text = "Get New Token",
                    Location = new Point(240, 160),
                    Size = new Size(100, 30),
                    BackColor = Color.LightBlue,
                    TabIndex = 3
                };

                var helpButton = new Button
                {
                    Text = "Help",
                    Location = new Point(360, 160),
                    Size = new Size(80, 30),
                    BackColor = Color.LightYellow,
                    TabIndex = 4
                };

                // Create status label
                var statusLabel = new Label
                {
                    Location = new Point(20, 200),
                    Size = new Size(440, 40),
                    Font = new Font("Segoe UI", 8),
                    ForeColor = Color.Gray
                };

                bool dialogResult = false;

                // Event handlers
                submitButton.Click += async (sender, e) =>
                {
                    var token = tokenTextBox.Text.Trim();
                    if (string.IsNullOrEmpty(token))
                    {
                        statusLabel.Text = "Please enter a valid request token.";
                        statusLabel.ForeColor = Color.Red;
                        return;
                    }

                    statusLabel.Text = "Processing token...";
                    statusLabel.ForeColor = Color.Blue;
                    submitButton.Enabled = false;

                    try
                    {
                        var success = await _tokenManagementService.UpdateRequestTokenAsync(token);
                        if (success)
                        {
                            statusLabel.Text = "✅ Token processed successfully! Service will continue operating.";
                            statusLabel.ForeColor = Color.Green;
                            await Task.Delay(2000); // Show success message for 2 seconds
                            dialogResult = true;
                            form.Close();
                        }
                        else
                        {
                            statusLabel.Text = "❌ Failed to process token. Please check the token and try again.";
                            statusLabel.ForeColor = Color.Red;
                            submitButton.Enabled = true;
                        }
                    }
                    catch (Exception ex)
                    {
                        statusLabel.Text = $"❌ Error: {ex.Message}";
                        statusLabel.ForeColor = Color.Red;
                        submitButton.Enabled = true;
                    }
                };

                cancelButton.Click += (sender, e) =>
                {
                    dialogResult = false;
                    form.Close();
                };

                getTokenButton.Click += (sender, e) =>
                {
                    try
                    {
                        // Open Kite Connect login page in default browser
                        System.Diagnostics.Process.Start(new System.Diagnostics.ProcessStartInfo
                        {
                            FileName = "https://kite.trade/connect/login?api_key=kw3ptb0zmocwupmo&v=3",
                            UseShellExecute = true
                        });

                        statusLabel.Text = "🌐 Browser opened. Please login and copy the request token from the URL.";
                        statusLabel.ForeColor = Color.Blue;
                    }
                    catch (Exception ex)
                    {
                        statusLabel.Text = $"❌ Error opening browser: {ex.Message}";
                        statusLabel.ForeColor = Color.Red;
                    }
                };

                helpButton.Click += (sender, e) =>
                {
                    var helpMessage = @"HOW TO GET A REQUEST TOKEN:

1. Click 'Get New Token' button (opens browser)
2. Login with your Zerodha credentials
3. You'll be redirected to a URL like:
   http://127.0.0.1:3000?action=login&status=success&request_token=YOUR_TOKEN
4. Copy the request_token value from the URL
5. Paste it in the textbox above
6. Click 'Submit Token'

The service will automatically process the token and continue operating.";

                    MessageBox.Show(helpMessage, "Help - Getting Request Token", 
                        MessageBoxButtons.OK, MessageBoxIcon.Information);
                };

                // Add controls to form
                form.Controls.AddRange(new Control[]
                {
                    messageLabel,
                    instructionLabel,
                    tokenTextBox,
                    submitButton,
                    cancelButton,
                    getTokenButton,
                    helpButton,
                    statusLabel
                });

                // Set focus to textbox
                tokenTextBox.Focus();

                // Show dialog
                form.ShowDialog();

                return dialogResult;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in ShowDialogOnExistingThread");
                return false;
            }
        }

        private bool ShowDialogOnNewThread(string title, string message)
        {
            try
            {
                // Create a new STA thread for the dialog
                var thread = new System.Threading.Thread(() =>
                {
                    Application.EnableVisualStyles();
                    Application.SetCompatibleTextRenderingDefault(false);
                    
                    var result = ShowDialogOnExistingThread(title, message);
                    // Store result in thread-local storage or use a different mechanism
                });

                thread.SetApartmentState(System.Threading.ApartmentState.STA);
                thread.Start();
                thread.Join();

                return true; // Simplified for now
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error in ShowDialogOnNewThread");
                return false;
            }
        }

        public void ShowSimpleNotification(string title, string message, NotificationType type)
        {
            try
            {
                var icon = type switch
                {
                    NotificationType.Success => SystemIcons.Information,
                    NotificationType.Warning => SystemIcons.Warning,
                    NotificationType.Error => SystemIcons.Error,
                    _ => SystemIcons.Information
                };

                // Create a simple form for notification
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
                _logger.LogError(ex, "Failed to show simple notification");
            }
        }
    }
} 