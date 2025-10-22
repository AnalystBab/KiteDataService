# Download SENSEX Options Data - BULLETPROOF Version
# Console will NEVER close - always shows errors

param(
    [string]$RequestToken = "",
    [string]$FromDate = "2025-10-01",
    [string]$ToDate = "2025-10-09",
    [string]$ExpiryDate = "2025-10-09",
    [string]$OutputPath = "$env:USERPROFILE\Desktop\sensex_09_10_2025"
)

# Set console title and prevent closing
$Host.UI.RawUI.WindowTitle = "SENSEX Options Downloader - BULLETPROOF - DO NOT CLOSE"

# Function to pause and show error
function Show-ErrorAndPause {
    param($ErrorMessage, $FullError = "")
    
    Write-Host "`n" + "="*60 -ForegroundColor Red
    Write-Host "ERROR OCCURRED!" -ForegroundColor Red
    Write-Host "="*60 -ForegroundColor Red
    Write-Host $ErrorMessage -ForegroundColor Red
    
    if ($FullError) {
        Write-Host "`nFull Error Details:" -ForegroundColor Yellow
        Write-Host $FullError -ForegroundColor Gray
    }
    
    Write-Host "`n" + "="*60 -ForegroundColor Red
    Write-Host "ERROR MESSAGE (COPY THIS):" -ForegroundColor Yellow
    Write-Host "=========================" -ForegroundColor Yellow
    Write-Host $ErrorMessage -ForegroundColor White
    
    if ($FullError) {
        Write-Host "`nFULL ERROR DETAILS (COPY THIS):" -ForegroundColor Yellow
        Write-Host "================================" -ForegroundColor Yellow
        Write-Host $FullError -ForegroundColor White
    }
    
    # Save error to file for easy copying
    $errorFile = ".\ERROR_LOG_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $errorContent = @"
ERROR OCCURRED!
============================================================
$ErrorMessage

FULL ERROR DETAILS:
$FullError

Timestamp: $(Get-Date)
Script: DownloadSENSEXOptionsBulletproof.ps1
"@
    
    $errorContent | Out-File -FilePath $errorFile -Encoding UTF8
    
    # Try to copy error to clipboard
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.Clipboard]::SetText($ErrorMessage)
        Write-Host "`n" + "="*60 -ForegroundColor Red
        Write-Host "ERROR SAVED TO FILE: $errorFile" -ForegroundColor Yellow
        Write-Host "✅ Error message copied to clipboard automatically!" -ForegroundColor Green
    } catch {
        Write-Host "`n" + "="*60 -ForegroundColor Red
        Write-Host "ERROR SAVED TO FILE: $errorFile" -ForegroundColor Yellow
        Write-Host "⚠️ Could not copy to clipboard automatically" -ForegroundColor Yellow
    }
    
    # Try to open the error file in Notepad
    try {
        Start-Process notepad.exe -ArgumentList $errorFile
        Write-Host "✅ Notepad opened with error details - you can copy from there!" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Could not open Notepad automatically" -ForegroundColor Yellow
        Write-Host "Please manually open: $errorFile" -ForegroundColor Cyan
    }
    
    Write-Host "`nIMPORTANT: Copy the error message from Notepad or the error file" -ForegroundColor Cyan
    Write-Host "DO NOT use Ctrl+C in console (it will close console)" -ForegroundColor Cyan
    Write-Host "`nPress ANY KEY to exit..." -ForegroundColor White
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# Main script wrapped in try-catch
try {
    Write-Host "=== SENSEX OPTIONS DOWNLOADER (BULLETPROOF VERSION) ===" -ForegroundColor Green
    Write-Host "Date Range: $FromDate to $ToDate" -ForegroundColor Yellow
    Write-Host "Expiry: $ExpiryDate" -ForegroundColor Yellow

    # Read credentials first
    Write-Host "`nReading credentials from appsettings.json..." -ForegroundColor Cyan
    try {
        $appSettings = Get-Content ".\appsettings.json" | ConvertFrom-Json
        $apiKey = $appSettings.KiteConnect.ApiKey
        $apiSecret = $appSettings.KiteConnect.ApiSecret
        Write-Host "API Key: $apiKey" -ForegroundColor Green
    } catch {
        Show-ErrorAndPause "Cannot read appsettings.json" $_.Exception.Message
    }

    # Check if request token provided, if not get it from user
    if ([string]::IsNullOrWhiteSpace($RequestToken)) {
        Write-Host "`nSTEP 0: Getting Fresh Request Token..." -ForegroundColor Yellow
        Write-Host "=======================================" -ForegroundColor Yellow
        
        # Generate login URL
        $loginUrl = "https://kite.trade/connect/login?api_key=$apiKey&v=3"
        
        Write-Host "1. Click this link to get a fresh request token:" -ForegroundColor White
        Write-Host "   $loginUrl" -ForegroundColor Cyan
        Write-Host "`n2. After logging in, you'll be redirected to a URL like:" -ForegroundColor White
        Write-Host "   http://localhost:8080/?request_token=XXXXXX&action=login&status=success" -ForegroundColor Gray
        Write-Host "`n3. Copy the request_token value from the URL" -ForegroundColor White
        
        # Try to open the URL automatically
        try {
            Write-Host "`nOpening login URL in your default browser..." -ForegroundColor Green
            Start-Process $loginUrl
            Write-Host "✅ Login page opened in browser!" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Could not open browser automatically. Please click the link above." -ForegroundColor Yellow
        }
        
        Write-Host "`n4. Enter the request token below:" -ForegroundColor White
        $RequestToken = Read-Host "Request Token"
        
        if ([string]::IsNullOrWhiteSpace($RequestToken)) {
            Show-ErrorAndPause "No request token provided!"
        }
    }

    Write-Host "Request Token: $RequestToken" -ForegroundColor Cyan

    # Create output directory
    Write-Host "`nCreating output directory..." -ForegroundColor Cyan
    if (!(Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
    } else {
        Write-Host "Output directory exists: $OutputPath" -ForegroundColor Green
    }

    # Function to generate checksum
    function Generate-Checksum {
        param($apiKey, $requestToken, $apiSecret)
        $data = $apiKey + $requestToken + $apiSecret
        $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($data))
        return [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
    }

    # Get access token
    Write-Host "`nSTEP 1: Getting Access Token..." -ForegroundColor Yellow
    Write-Host "================================" -ForegroundColor Yellow
    
    try {
        $checksum = Generate-Checksum -apiKey $apiKey -requestToken $RequestToken -apiSecret $apiSecret
        Write-Host "Checksum calculated: $($checksum.Substring(0,8))..." -ForegroundColor Gray
        
        $url = "https://api.kite.trade/session/token"
        $body = @{
            api_key = $apiKey
            request_token = $RequestToken
            checksum = $checksum
        }
        
        Write-Host "Calling Kite API for access token..." -ForegroundColor Cyan
        $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -Headers @{"X-Kite-Version" = "3"}
        
        if ($response.status -eq "success") {
            $accessToken = $response.data.access_token
            Write-Host "SUCCESS! Access token: $($accessToken.Substring(0,8))..." -ForegroundColor Green
        } else {
            Show-ErrorAndPause "Failed to get access token: $($response.message)" ($response | ConvertTo-Json)
        }
    } catch {
        Show-ErrorAndPause "Error getting access token: $($_.Exception.Message)" $_.Exception.ToString()
    }

    # Get instruments
    Write-Host "`nSTEP 2: Getting SENSEX Instruments..." -ForegroundColor Yellow
    Write-Host "=====================================" -ForegroundColor Yellow
    
    try {
        $url = "https://api.kite.trade/instruments"
        $headers = @{
            "Authorization" = "token $apiKey`:$accessToken"
            "X-Kite-Version" = "3"
        }
        
        Write-Host "Fetching instruments from Kite API..." -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers
        $csvContent = $response.Content
        
        Write-Host "Raw CSV response length: $($csvContent.Length) characters" -ForegroundColor Gray
        
        # Parse CSV data
        $lines = $csvContent -split "`n"
        Write-Host "Total lines received: $($lines.Count)" -ForegroundColor Gray
        
        # Skip header line and parse data
        $instruments = @()
        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim()) {
                $fields = $lines[$i] -split ","
                if ($fields.Count -ge 13) {
                    $instruments += [PSCustomObject]@{
                        instrument_token = $fields[0]
                        exchange_token = $fields[1]
                        tradingsymbol = $fields[2]
                        name = $fields[3]
                        last_price = $fields[4]
                        expiry = $fields[5]
                        strike = if ($fields[6] -match '^\d+\.?\d*$') { [decimal]$fields[6] } else { 0 }
                        tick_size = $fields[7]
                        lot_size = $fields[8]
                        instrument_type = $fields[9]
                        segment = $fields[10]
                        exchange = $fields[11]
                    }
                }
            }
        }
        
        Write-Host "Parsed $($instruments.Count) total instruments" -ForegroundColor Green
        
        $sensexOptions = $instruments | Where-Object {
            $_.tradingsymbol -like "SENSEX*" -and 
            ($_.instrument_type -eq "CE" -or $_.instrument_type -eq "PE") -and
            $_.expiry -eq $ExpiryDate
        }
        
        Write-Host "Found $($sensexOptions.Count) SENSEX options for expiry $ExpiryDate" -ForegroundColor Green
        
        if ($sensexOptions.Count -eq 0) {
            Write-Host "No SENSEX options found for expiry $ExpiryDate" -ForegroundColor Red
            Write-Host "Available SENSEX expiries:" -ForegroundColor Yellow
            $availableExpiries = $instruments | Where-Object { $_.tradingsymbol -like "SENSEX*" } | Select-Object expiry -Unique | Sort-Object expiry
            Write-Host "Found $($availableExpiries.Count) unique SENSEX expiries:" -ForegroundColor Cyan
            foreach ($expiry in $availableExpiries) {
                Write-Host "  $($expiry.expiry)" -ForegroundColor White
            }
            
            # Also show some sample SENSEX instruments to debug
            $sampleSensex = $instruments | Where-Object { $_.tradingsymbol -like "SENSEX*" } | Select-Object -First 5
            Write-Host "`nSample SENSEX instruments:" -ForegroundColor Cyan
            foreach ($inst in $sampleSensex) {
                Write-Host "  $($inst.tradingsymbol) - Expiry: $($inst.expiry) - Type: $($inst.instrument_type)" -ForegroundColor White
            }
            
            Show-ErrorAndPause "No SENSEX options found for expiry $ExpiryDate. Please check available expiries above."
        }
        
        # Show sample instruments
        Write-Host "Sample instruments:" -ForegroundColor Cyan
        $sensexOptions | Select-Object -First 5 | ForEach-Object {
            Write-Host "  $($_.tradingsymbol) - Strike: $($_.strike) - Type: $($_.instrument_type)" -ForegroundColor White
        }
        
    } catch {
        Show-ErrorAndPause "Error getting instruments: $($_.Exception.Message)" $_.Exception.ToString()
    }

    # Get historical data
    Write-Host "`nSTEP 3: Downloading Historical Data..." -ForegroundColor Yellow
    Write-Host "======================================" -ForegroundColor Yellow
    $allData = @()

    foreach ($instrument in $sensexOptions) {
        try {
            Write-Host "Processing: $($instrument.tradingsymbol)" -ForegroundColor Cyan
            
            $url = "https://api.kite.trade/instruments/historical/$($instrument.instrument_token)/day?from=$FromDate&to=$ToDate"
            $headers = @{
                "Authorization" = "token $apiKey`:$accessToken"
                "X-Kite-Version" = "3"
            }
            
            $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
            
            if ($response.status -eq "success") {
                Write-Host "  Received $($response.data.candles.Count) records" -ForegroundColor Green
                
                foreach ($candle in $response.data.candles) {
                    $allData += [PSCustomObject]@{
                        Date = $candle[0]
                        TradingSymbol = $instrument.tradingsymbol
                        StrikePrice = $instrument.strike
                        OptionType = $instrument.instrument_type
                        ExpiryDate = $instrument.expiry
                        OpenPrice = $candle[1]
                        HighPrice = $candle[2]
                        LowPrice = $candle[3]
                        ClosePrice = $candle[4]
                        LastPrice = $candle[4]
                        Volume = if ($candle.Count -gt 5) { $candle[5] } else { 0 }
                        OpenInterest = if ($candle.Count -gt 6) { $candle[6] } else { 0 }
                        NetChange = 0
                        LastTradeTime = $candle[0]
                    }
                }
            } else {
                Write-Host "  API Error: $($response.message)" -ForegroundColor Red
            }
        } catch {
            Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Create Excel files
    Write-Host "`nSTEP 4: Creating Excel Files..." -ForegroundColor Yellow
    Write-Host "===============================" -ForegroundColor Yellow
    
    if ($allData.Count -eq 0) {
        Show-ErrorAndPause "No data to save! Check your date range and expiry date."
    }

    $callData = $allData | Where-Object { $_.OptionType -eq "CE" }
    $putData = $allData | Where-Object { $_.OptionType -eq "PE" }

    Write-Host "Total records: $($allData.Count)" -ForegroundColor Green
    Write-Host "Call options: $($callData.Count)" -ForegroundColor Green
    Write-Host "Put options: $($putData.Count)" -ForegroundColor Green

    # Save Call options
    if ($callData.Count -gt 0) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = "SENSEX_CALL_Options_REAL_DATA_${FromDate}_to_${ToDate}_${timestamp}.csv"
        $filePath = Join-Path $OutputPath $fileName
        
        $csvContent = "Date,Trading Symbol,Strike Price,Option Type,Expiry Date,Open Price,High Price,Low Price,Close Price,Last Price,Volume,Open Interest,Net Change,Last Trade Time`n"
        
        foreach ($record in $callData) {
            $csvContent += "$($record.Date),$($record.TradingSymbol),$($record.StrikePrice),$($record.OptionType),$($record.ExpiryDate),$($record.OpenPrice),$($record.HighPrice),$($record.LowPrice),$($record.ClosePrice),$($record.LastPrice),$($record.Volume),$($record.OpenInterest),$($record.NetChange),$($record.LastTradeTime)`n"
        }
        
        $csvContent | Out-File -FilePath $filePath -Encoding UTF8
        Write-Host "Call options saved: $fileName" -ForegroundColor Green
    }

    # Save Put options
    if ($putData.Count -gt 0) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $fileName = "SENSEX_PUT_Options_REAL_DATA_${FromDate}_to_${ToDate}_${timestamp}.csv"
        $filePath = Join-Path $OutputPath $fileName
        
        $csvContent = "Date,Trading Symbol,Strike Price,Option Type,Expiry Date,Open Price,High Price,Low Price,Close Price,Last Price,Volume,Open Interest,Net Change,Last Trade Time`n"
        
        foreach ($record in $putData) {
            $csvContent += "$($record.Date),$($record.TradingSymbol),$($record.StrikePrice),$($record.OptionType),$($record.ExpiryDate),$($record.OpenPrice),$($record.HighPrice),$($record.LowPrice),$($record.ClosePrice),$($record.LastPrice),$($record.Volume),$($record.OpenInterest),$($record.NetChange),$($record.LastTradeTime)`n"
        }
        
        $csvContent | Out-File -FilePath $filePath -Encoding UTF8
        Write-Host "Put options saved: $fileName" -ForegroundColor Green
    }

    Write-Host "`n" + "="*60 -ForegroundColor Green
    Write-Host "SUCCESS! Files saved to: $OutputPath" -ForegroundColor Green
    Write-Host "Total records downloaded: $($allData.Count)" -ForegroundColor Cyan
    Write-Host "="*60 -ForegroundColor Green
    
    Write-Host "`nFiles created:" -ForegroundColor Yellow
    Get-ChildItem $OutputPath -Filter "*.csv" | ForEach-Object {
        Write-Host "  $($_.Name) ($($_.Length) bytes)" -ForegroundColor White
    }

    Write-Host "`nPress ANY KEY to exit..." -ForegroundColor White
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

} catch {
    # Catch any unexpected errors
    Show-ErrorAndPause "Unexpected error occurred: $($_.Exception.Message)" $_.Exception.ToString()
}
