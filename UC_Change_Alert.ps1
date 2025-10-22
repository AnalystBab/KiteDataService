# UC Change Alert Script
# This script monitors Upper Circuit Limit changes for a specific instrument token
# and provides audio alerts when changes are detected

param(
    [Parameter(Mandatory=$true)]
    [string]$Token,
    
    [Parameter(Mandatory=$true)]
    [string]$Expiry
)

# Validate parameters
if (-not $Token -or $Token -eq "<PUT_TOKEN_HERE>") {
    Write-Host "Error: Please provide a valid token. Usage: .\UC_Change_Alert.ps1 -Token 12345 -Expiry 2025-08-26" -ForegroundColor Red
    exit 1
}

if (-not $Expiry -or $Expiry -eq "<PUT_EXPIRY_HERE>") {
    Write-Host "Error: Please provide a valid expiry date. Usage: .\UC_Change_Alert.ps1 -Token 12345 -Expiry 2025-08-26" -ForegroundColor Red
    exit 1
}

Write-Host "Starting UC Change Monitor..." -ForegroundColor Green
Write-Host "Token: $Token" -ForegroundColor Yellow
Write-Host "Expiry: $Expiry" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Cyan
Write-Host ""

$prev = $null
$errorCount = 0

try {
    while ($true) {
        try {
            # Query the database for UC value
            $uc = sqlcmd -S localhost -d KiteMarketData -h -1 -W -Q "SELECT TOP 1 CONVERT(varchar(32), UpperCircuitLimit) FROM dbo.MarketQuotes WHERE InstrumentToken=$Token AND CAST(ExpiryDate AS date)='$Expiry' AND CAST(TradingDate AS date)=CAST(GETDATE() AS date) ORDER BY QuoteTimestamp DESC, Id DESC"
            
            # Clean up the result (remove extra whitespace and newlines)
            $uc = $uc.Trim()
            
            if ($uc -and $uc -ne $prev) {
                # Play alert sound
                [console]::beep(1200,300)
                [console]::beep(1400,300)
                
                # Display the change
                $timestamp = Get-Date -Format 'HH:mm:ss'
                Write-Host "UC changed: $prev -> $uc at $timestamp" -ForegroundColor Red
                Write-Host "----------------------------------------" -ForegroundColor Gray
                
                $prev = $uc
                $errorCount = 0  # Reset error count on successful query
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
    Write-Host "UC Change Monitor stopped." -ForegroundColor Green
}


