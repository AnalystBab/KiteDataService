# SENSEX 81600 CE UC Change Alert Script
# This script monitors Upper Circuit Limit changes for SENSEX 81600 CE monthly expiry
# and provides audio alerts when changes are detected

# Hardcoded values for SENSEX 81600 CE monthly expiry
$Token = "211607813"  # SENSEX25AUG81600CE
$Expiry = "2025-08-26"  # Monthly expiry date

Write-Host "Starting SENSEX 81600 CE UC Change Monitor..." -ForegroundColor Green
Write-Host "Token: $Token (SENSEX25AUG81600CE)" -ForegroundColor Yellow
Write-Host "Expiry: $Expiry" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Cyan
Write-Host ""

$prev = $null
$errorCount = 0
$initialized = $false

# Function to play alert sound
function Play-AlertSound {
    try {
        # Try Windows Media Player sound
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SystemSounds]::Asterisk.Play()
        Start-Sleep -Milliseconds 200
        [System.Windows.Forms.SystemSounds]::Asterisk.Play()
    } catch {
        # Fallback to console beep
        [console]::beep(800,200)
        [console]::beep(1000,200)
    }
}

# Function to show desktop notification - SIMPLIFIED VERSION
function Show-DesktopNotification {
    param(
        [string]$Title,
        [string]$Message
    )
    
    try {
        # Load Windows Forms
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        # Create a simple message box that stays on top
        $result = [System.Windows.Forms.MessageBox]::Show(
            $Message,
            $Title,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
    } catch {
        Write-Host "Notification error: $($_.Exception.Message)" -ForegroundColor Yellow
        
        # Fallback: Simple console message
        Write-Host "=== NOTIFICATION ===" -ForegroundColor Red
        Write-Host "Title: $Title" -ForegroundColor Yellow
        Write-Host "Message: $Message" -ForegroundColor Yellow
        Write-Host "===================" -ForegroundColor Red
    }
}

try {
    while ($true) {
        try {
            # Query the database for UC value - IMPROVED QUERY
            $uc = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT TOP 1 UpperCircuitLimit FROM dbo.MarketQuotes WHERE InstrumentToken=$Token AND CAST(ExpiryDate AS date)='$Expiry' AND CAST(TradingDate AS date)=CAST(GETDATE() AS date) ORDER BY QuoteTimestamp DESC, Id DESC"
            
            # Clean up the result and get first line only
            $uc = ($uc -split "`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1).Trim()
            
            # Only proceed if we got a valid UC value
            if ($uc -and $uc -ne "" -and $uc -ne "NULL") {
                # Convert to decimal for proper comparison
                $ucDecimal = 0
                if ([decimal]::TryParse($uc, [ref]$ucDecimal)) {
                    if (-not $initialized) {
                        # First time getting data - just initialize
                        $prev = $ucDecimal
                        $initialized = $true
                        Write-Host "Initialized with UC value: $ucDecimal" -ForegroundColor Green
                    } elseif ($ucDecimal -ne $prev -and $ucDecimal -gt 0) {
                        # Only alert if there's an actual change and new value is valid
                        # Play alert sound
                        Play-AlertSound
                        
                        # Display the change
                        $timestamp = Get-Date -Format 'HH:mm:ss'
                        $changeMessage = "SENSEX 81600 CE UC changed:`n$prev → $ucDecimal`nTime: $timestamp"
                        
                        Write-Host "🔔 SENSEX 81600 CE UC changed: $prev -> $ucDecimal at $timestamp" -ForegroundColor Red
                        Write-Host "----------------------------------------" -ForegroundColor Gray
                        
                        # Show desktop notification
                        Show-DesktopNotification -Title "UC Change Alert" -Message $changeMessage
                        
                        $prev = $ucDecimal
                        $errorCount = 0  # Reset error count on successful query
                    }
                } else {
                    Write-Host "Invalid UC value received: '$uc'" -ForegroundColor Yellow
                }
            } else {
                Write-Host "No UC data found for today" -ForegroundColor Yellow
            }
            
            Start-Sleep -Seconds 5
            
        } catch {
            $errorCount++
            Write-Host "Database query error (attempt $errorCount): $($_.Exception.Message)" -ForegroundColor Yellow
            
            if ($errorCount -ge 5) {
                Write-Host "Too many consecutive errors. Stopping monitor." -ForegroundColor Red
                break
            }
            
            Start-Sleep -Seconds 10  # Wait longer on error
        }
    }
} catch {
    Write-Host "Script interrupted or error occurred: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Write-Host "SENSEX 81600 CE UC Change Monitor stopped." -ForegroundColor Green
}
