using System;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using System.Diagnostics;
using System.IO;

namespace KiteMarketDataService.Worker.Services
{
    public class TokenInputDialog
    {
        private readonly ILogger<TokenInputDialog> _logger;
        private readonly string _apiKey;

        public TokenInputDialog(ILogger<TokenInputDialog> logger)
        {
            _logger = logger;
            _apiKey = "kw3ptb0zmocwupmo";
        }

        public Task<string?> ShowTokenInputDialogAsync(string title, string message)
        {
            try
            {
                _logger.LogInformation("=== TOKEN INPUT REQUIRED ===");
                _logger.LogInformation(title);
                _logger.LogInformation(message);
                
                // Create the login URL
                var loginUrl = $"https://kite.trade/connect/login?api_key={_apiKey}&v=3";
                
                _logger.LogInformation("Step 1: Copy and open this URL in your browser:");
                _logger.LogInformation($"URL: {loginUrl}");
                _logger.LogInformation("");
                _logger.LogInformation("Step 2: After login, you'll get a request token");
                _logger.LogInformation("Step 3: Please provide the request token below");
                _logger.LogInformation("=== END TOKEN INPUT ===");
                
                // Create a PowerShell script that shows a Windows Forms dialog
                var tempFile = Path.GetTempFileName();
                var scriptFile = CreatePowerShellDialogScript(title, message, loginUrl, tempFile);
                
                _logger.LogInformation("Launching Windows Forms dialog...");
                
                // Launch PowerShell to show the dialog
                var process = new Process
                {
                    StartInfo = new ProcessStartInfo
                    {
                        FileName = "powershell.exe",
                        Arguments = $"-ExecutionPolicy Bypass -File \"{scriptFile}\"",
                        UseShellExecute = true,
                        CreateNoWindow = false
                    }
                };
                
                process.Start();
                process.WaitForExit();
                
                // Read the result
                if (File.Exists(tempFile))
                {
                    var result = File.ReadAllText(tempFile).Trim();
                    File.Delete(tempFile);
                    File.Delete(scriptFile);
                    
                    if (!string.IsNullOrEmpty(result))
                    {
                        _logger.LogInformation("Request token received from dialog");
                        return Task.FromResult<string?>(result);
                    }
                }
                
                _logger.LogWarning("No token received from dialog, falling back to console input");
                
                // Fallback to console input
                Console.WriteLine("\n" + new string('=', 60));
                Console.WriteLine("  KITE CONNECT AUTHENTICATION REQUIRED");
                Console.WriteLine(new string('=', 60));
                Console.WriteLine();
                Console.WriteLine(title);
                Console.WriteLine(message);
                Console.WriteLine();
                Console.WriteLine("Step 1: Copy and open this URL in your browser:");
                Console.WriteLine($"URL: {loginUrl}");
                Console.WriteLine();
                Console.WriteLine("Step 2: After login, paste the request token below:");
                Console.Write("Request Token: ");
                
                var consoleToken = Console.ReadLine();
                return Task.FromResult<string?>(string.IsNullOrWhiteSpace(consoleToken) ? null : consoleToken.Trim());
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to show token input dialog");
                return Task.FromResult<string?>(null);
            }
        }
        
        private string CreatePowerShellDialogScript(string title, string message, string loginUrl, string tempFile)
        {
            var script = $@"
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = '{title}'
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = 'CenterScreen'
$form.TopMost = $true
$form.ShowInTaskbar = $true
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(20,20)
$label.Size = New-Object System.Drawing.Size(540,60)
$label.Text = '{message}'
$form.Controls.Add($label)

$urlLabel = New-Object System.Windows.Forms.Label
$urlLabel.Location = New-Object System.Drawing.Point(20,100)
$urlLabel.Size = New-Object System.Drawing.Size(540,20)
$urlLabel.Text = 'Step 1: Copy and open this URL in your browser:'
$urlLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($urlLabel)

$urlBox = New-Object System.Windows.Forms.TextBox
$urlBox.Location = New-Object System.Drawing.Point(20,125)
$urlBox.Size = New-Object System.Drawing.Size(400,25)
$urlBox.Text = '{loginUrl}'
$urlBox.ReadOnly = $true
$form.Controls.Add($urlBox)

$copyBtn = New-Object System.Windows.Forms.Button
$copyBtn.Location = New-Object System.Drawing.Point(430,125)
$copyBtn.Size = New-Object System.Drawing.Size(70,25)
$copyBtn.Text = 'Copy URL'
$copyBtn.Add_Click({{ [System.Windows.Forms.Clipboard]::SetText('{loginUrl}'); [System.Windows.Forms.MessageBox]::Show('URL copied to clipboard!') }})
$form.Controls.Add($copyBtn)

$openBtn = New-Object System.Windows.Forms.Button
$openBtn.Location = New-Object System.Drawing.Point(510,125)
$openBtn.Size = New-Object System.Drawing.Size(70,25)
$openBtn.Text = 'Open URL'
$openBtn.Add_Click({{ Start-Process '{loginUrl}' }})
$form.Controls.Add($openBtn)

$tokenLabel = New-Object System.Windows.Forms.Label
$tokenLabel.Location = New-Object System.Drawing.Point(20,170)
$tokenLabel.Size = New-Object System.Drawing.Size(540,20)
$tokenLabel.Text = 'Step 2: After login, paste the request token here:'
$tokenLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($tokenLabel)

$tokenBox = New-Object System.Windows.Forms.TextBox
$tokenBox.Location = New-Object System.Drawing.Point(20,195)
$tokenBox.Size = New-Object System.Drawing.Size(540,25)
$tokenBox.Font = New-Object System.Drawing.Font('Consolas', 10)
$form.Controls.Add($tokenBox)

$submitBtn = New-Object System.Windows.Forms.Button
$submitBtn.Location = New-Object System.Drawing.Point(400,240)
$submitBtn.Size = New-Object System.Drawing.Size(80,30)
$submitBtn.Text = 'Submit'
$submitBtn.DialogResult = [System.Windows.Forms.DialogResult]::OK
$submitBtn.Add_Click({{ 
    if ([string]::IsNullOrWhiteSpace($tokenBox.Text)) {{
        [System.Windows.Forms.MessageBox]::Show('Please enter a request token.', 'Validation Error')
        return
    }}
    $tokenBox.Text.Trim() | Out-File -FilePath '{tempFile}' -Encoding UTF8
}})
$form.Controls.Add($submitBtn)

$cancelBtn = New-Object System.Windows.Forms.Button
$cancelBtn.Location = New-Object System.Drawing.Point(490,240)
$cancelBtn.Size = New-Object System.Drawing.Size(80,30)
$cancelBtn.Text = 'Cancel'
$cancelBtn.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.Controls.Add($cancelBtn)

$tokenBox.Focus()
$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {{
    if (Test-Path '{tempFile}') {{ Remove-Item '{tempFile}' }}
}}
";
            
            var scriptFile = Path.GetTempFileName() + ".ps1";
            File.WriteAllText(scriptFile, script);
            return scriptFile;
        }
    }
} 