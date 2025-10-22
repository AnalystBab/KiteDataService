# Debug script to check SENSEX expiries from Kite API

param(
    [string]$RequestToken = ""
)

Write-Host "=== DEBUG SENSEX EXPIRIES ===" -ForegroundColor Green

# Read credentials
try {
    $appSettings = Get-Content ".\appsettings.json" | ConvertFrom-Json
    $apiKey = $appSettings.KiteConnect.ApiKey
    $apiSecret = $appSettings.KiteConnect.ApiSecret
    Write-Host "API Key: $apiKey" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Cannot read appsettings.json" -ForegroundColor Red
    exit 1
}

# Get fresh token if not provided
if ([string]::IsNullOrWhiteSpace($RequestToken)) {
    $loginUrl = "https://kite.trade/connect/login?api_key=$apiKey&v=3"
    Write-Host "Please get fresh token from: $loginUrl" -ForegroundColor Cyan
    $RequestToken = Read-Host "Enter request token"
}

# Get access token
try {
    $data = $apiKey + $RequestToken + $apiSecret
    $hashBytes = [System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($data))
    $checksum = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
    
    $url = "https://api.kite.trade/session/token"
    $body = @{
        api_key = $apiKey
        request_token = $RequestToken
        checksum = $checksum
    }
    
    $response = Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType "application/x-www-form-urlencoded" -Headers @{"X-Kite-Version" = "3"}
    
    if ($response.status -eq "success") {
        $accessToken = $response.data.access_token
        Write-Host "Access token obtained: $($accessToken.Substring(0,8))..." -ForegroundColor Green
    } else {
        Write-Host "Failed to get access token: $($response.message)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR getting access token: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Get instruments
try {
    $url = "https://api.kite.trade/instruments"
    $headers = @{
        "Authorization" = "token $apiKey`:$accessToken"
        "X-Kite-Version" = "3"
    }
    
    Write-Host "Fetching instruments..." -ForegroundColor Cyan
    $response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers
    $csvContent = $response.Content
    
    # Parse CSV
    $lines = $csvContent -split "`n"
    $instruments = @()
    
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim()) {
            $fields = $lines[$i] -split ","
            if ($fields.Count -ge 13) {
                $instruments += [PSCustomObject]@{
                    instrument_token = $fields[0]
                    tradingsymbol = $fields[2]
                    expiry = $fields[5]
                    instrument_type = $fields[9]
                    exchange = $fields[11]
                }
            }
        }
    }
    
    Write-Host "Total instruments parsed: $($instruments.Count)" -ForegroundColor Green
    
    # Get SENSEX instruments
    $sensexInstruments = $instruments | Where-Object { $_.tradingsymbol -like "SENSEX*" }
    Write-Host "Total SENSEX instruments: $($sensexInstruments.Count)" -ForegroundColor Green
    
    # Get unique expiries
    $expiries = $sensexInstruments | Select-Object expiry -Unique | Sort-Object expiry
    Write-Host "`nSENSEX Expiries found:" -ForegroundColor Yellow
    foreach ($expiry in $expiries) {
        $count = ($sensexInstruments | Where-Object { $_.expiry -eq $expiry.expiry }).Count
        Write-Host "  $($expiry.expiry) ($count instruments)" -ForegroundColor White
    }
    
    # Show sample SENSEX instruments
    Write-Host "`nSample SENSEX instruments:" -ForegroundColor Yellow
    $sensexInstruments | Select-Object -First 10 | ForEach-Object {
        Write-Host "  $($_.tradingsymbol) - Expiry: $($_.expiry) - Type: $($_.instrument_type) - Exchange: $($_.exchange)" -ForegroundColor White
    }
    
    # Check for October 2025 expiries specifically
    Write-Host "`nOctober 2025 SENSEX options:" -ForegroundColor Cyan
    $oct2025 = $sensexInstruments | Where-Object { $_.expiry -like "*2025-10*" -or $_.expiry -like "*OCT*2025*" -or $_.expiry -like "*10-2025*" }
    if ($oct2025.Count -gt 0) {
        Write-Host "Found $($oct2025.Count) October 2025 SENSEX options:" -ForegroundColor Green
        $oct2025 | Select-Object -First 5 | ForEach-Object {
            Write-Host "  $($_.tradingsymbol) - Expiry: $($_.expiry)" -ForegroundColor White
        }
    } else {
        Write-Host "No October 2025 SENSEX options found" -ForegroundColor Red
        Write-Host "Checking for any 2025 expiries:" -ForegroundColor Yellow
        $all2025 = $sensexInstruments | Where-Object { $_.expiry -like "*2025*" }
        if ($all2025.Count -gt 0) {
            Write-Host "Found $($all2025.Count) 2025 SENSEX options:" -ForegroundColor Green
            $all2025 | Select-Object -First 5 | ForEach-Object {
                Write-Host "  $($_.tradingsymbol) - Expiry: $($_.expiry)" -ForegroundColor White
            }
        }
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
