# NIFTY 25100 CE Upper Circuit Alert Script
# Monitors UC changes and provides desktop notifications with sound alerts

# Configuration
$token = 12096514  # NIFTY 25100 CE tomorrow expiry token
$expiry = '2025-08-21'  # Tomorrow expiry
$prev = $null
$initialized = $false

# Load Windows Forms for desktop notifications
Add-Type -AssemblyName System.Windows.Forms

function Play-AlertSound {
    try {
        # Try Windows Forms sound first
        [System.Windows.Forms.SystemSounds]::Asterisk.Play()
    }
    catch {
        # Fallback to console beep
        [console]::beep(1200, 300)
        [console]::beep(1400, 300)
    }
}

function Show-DesktopNotification {
    param(
        [string]$Title,
        [string]$Message
    )
    
    try {
        # Show persistent message box
        [System.Windows.Forms.MessageBox]::Show($Message, $Title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        Write-Host "Notification failed: $Message"
    }
}

Write-Host "Starting NIFTY 25100 CE UC Alert Monitor..."
Write-Host "Token: $token"
Write-Host "Expiry: $expiry"
Write-Host "Press Ctrl+C to stop monitoring"
Write-Host ""

while ($true) {
    try {
        # Get current UC value from database
        $uc = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT TOP 1 CONVERT(varchar(32), UpperCircuitLimit) FROM dbo.MarketQuotes WHERE InstrumentToken=$token AND CAST(ExpiryDate AS date)='$expiry' AND CAST(TradingDate AS date)=CAST(GETDATE() AS date) ORDER BY QuoteTimestamp DESC, Id DESC"
        
        # Clean up the output - handle array properly
        if ($uc -is [array]) {
            $uc = $uc[0]  # Take first element if it's an array
        }
        $uc = $uc -replace "\([^)]*\)", "" -replace "rows affected", "" -replace "`n", "" -replace "`r", "" -replace " ", ""
        
        if ($uc -and $uc -ne "NULL" -and $uc -ne "") {
            # Convert to decimal for comparison
            $ucDecimal = $null
            if ([decimal]::TryParse($uc, [ref]$ucDecimal)) {
                $ucDecimal = [decimal]$uc
                
                # Check if this is the first run (initialization)
                if (-not $initialized) {
                    Write-Host "Initialized with UC: $ucDecimal at $(Get-Date -Format 'HH:mm:ss')"
                    $prev = $ucDecimal
                    $initialized = $true
                }
                # Check if UC has changed
                elseif ($ucDecimal -ne $prev) {
                    # Play alert sound
                    Play-AlertSound
                    
                    # Show desktop notification
                    $notificationTitle = "NIFTY 25100 CE UC Alert"
                    $notificationMessage = "Upper Circuit Changed!`n`nPrevious: $prev`nCurrent: $ucDecimal`nTime: $(Get-Date -Format 'HH:mm:ss')`n`nClick OK to acknowledge"
                    Show-DesktopNotification -Title $notificationTitle -Message $notificationMessage
                    
                    # Log the change
                    Write-Host "🚨 UC CHANGED: $prev → $ucDecimal at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Red
                    
                    # Update previous value
                    $prev = $ucDecimal
                }
                else {
                    # No change, just log status
                    Write-Host "Monitoring... UC: $ucDecimal at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
                }
            }
        }
        else {
            Write-Host "No data available for NIFTY 25100 CE at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message) at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Red
    }
    
    # Wait 5 seconds before next check
    Start-Sleep -Seconds 5
}
