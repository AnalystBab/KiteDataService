# Export SENSEX Options Data from Existing Database
# This script exports data from your existing MarketQuotes table

param(
    [string]$FromDate = "2025-10-01",
    [string]$ToDate = "2025-10-09",
    [string]$OutputPath = "$env:USERPROFILE\Desktop\sensex_09_10_2025"
)

Write-Host "=== EXPORT SENSEX DATA FROM DATABASE ===" -ForegroundColor Green
Write-Host "Date Range: $FromDate to $ToDate" -ForegroundColor Yellow

# Create output directory
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

try {
    # Connect to database
    $connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    Write-Host "Connected to database successfully" -ForegroundColor Green
    
    # Check what SENSEX data exists
    $checkQuery = @"
SELECT 
    COUNT(*) as TotalRecords,
    MIN(BusinessDate) as EarliestDate,
    MAX(BusinessDate) as LatestDate,
    COUNT(DISTINCT TradingSymbol) as UniqueSymbols,
    COUNT(DISTINCT ExpiryDate) as UniqueExpiries
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%'
"@
    
    $command = New-Object System.Data.SqlClient.SqlCommand($checkQuery, $connection)
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        Write-Host "`nSENSEX Data Summary:" -ForegroundColor Cyan
        Write-Host "  Total Records: $($reader['TotalRecords'])" -ForegroundColor White
        Write-Host "  Date Range: $($reader['EarliestDate']) to $($reader['LatestDate'])" -ForegroundColor White
        Write-Host "  Unique Symbols: $($reader['UniqueSymbols'])" -ForegroundColor White
        Write-Host "  Unique Expiries: $($reader['UniqueExpiries'])" -ForegroundColor White
    }
    $reader.Close()
    
    # Get sample SENSEX data
    $sampleQuery = @"
SELECT TOP 10 
    TradingSymbol,
    Strike,
    OptionType,
    ExpiryDate,
    BusinessDate,
    OpenPrice,
    HighPrice,
    LowPrice,
    ClosePrice,
    LastPrice,
    Volume,
    LowerCircuitLimit,
    UpperCircuitLimit
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%'
ORDER BY BusinessDate DESC, TradingSymbol
"@
    
    $command = New-Object System.Data.SqlClient.SqlCommand($sampleQuery, $connection)
    $reader = $command.ExecuteReader()
    
    Write-Host "`nSample SENSEX Data:" -ForegroundColor Cyan
    while ($reader.Read()) {
        Write-Host "  $($reader['TradingSymbol']) - Strike: $($reader['Strike']) - Type: $($reader['OptionType']) - Expiry: $($reader['ExpiryDate']) - Date: $($reader['BusinessDate'])" -ForegroundColor White
    }
    $reader.Close()
    
    # Get all SENSEX data for the specified date range
    $exportQuery = @"
SELECT 
    BusinessDate as Date,
    TradingSymbol,
    Strike as StrikePrice,
    OptionType,
    ExpiryDate,
    OpenPrice,
    HighPrice,
    LowPrice,
    ClosePrice,
    LastPrice,
    Volume,
    LowerCircuitLimit,
    UpperCircuitLimit,
    LastTradeTime,
    RecordDateTime as LastTradeTime
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%'
AND BusinessDate >= '$FromDate'
AND BusinessDate <= '$ToDate'
ORDER BY BusinessDate, TradingSymbol
"@
    
    Write-Host "`nExporting SENSEX data for date range $FromDate to $ToDate..." -ForegroundColor Cyan
    $command = New-Object System.Data.SqlClient.SqlCommand($exportQuery, $connection)
    $reader = $command.ExecuteReader()
    
    $allData = @()
    while ($reader.Read()) {
        $allData += [PSCustomObject]@{
            Date = $reader['Date'].ToString('yyyy-MM-dd')
            TradingSymbol = $reader['TradingSymbol']
            StrikePrice = $reader['StrikePrice']
            OptionType = $reader['OptionType']
            ExpiryDate = $reader['ExpiryDate'].ToString('yyyy-MM-dd')
            OpenPrice = $reader['OpenPrice']
            HighPrice = $reader['HighPrice']
            LowPrice = $reader['LowPrice']
            ClosePrice = $reader['ClosePrice']
            LastPrice = $reader['LastPrice']
            Volume = $reader['Volume']
            LowerCircuitLimit = $reader['LowerCircuitLimit']
            UpperCircuitLimit = $reader['UpperCircuitLimit']
            LastTradeTime = $reader['LastTradeTime'].ToString('yyyy-MM-dd HH:mm:ss')
        }
    }
    $reader.Close()
    
    Write-Host "Exported $($allData.Count) SENSEX records" -ForegroundColor Green
    
    if ($allData.Count -eq 0) {
        Write-Host "No SENSEX data found for the specified date range" -ForegroundColor Red
        Write-Host "The service may not have collected SENSEX data yet" -ForegroundColor Yellow
        Write-Host "`nPress any key to exit..." -ForegroundColor White
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 0
    }
    
    # Separate Call and Put data
    $callData = $allData | Where-Object { $_.OptionType -eq "CE" }
    $putData = $allData | Where-Object { $_.OptionType -eq "PE" }
    
    Write-Host "Call options: $($callData.Count)" -ForegroundColor Green
    Write-Host "Put options: $($putData.Count)" -ForegroundColor Green
    
    # Create CSV files
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    
    # Call options CSV
    if ($callData.Count -gt 0) {
        $fileName = "SENSEX_CALL_Options_DATABASE_${FromDate}_to_${ToDate}_${timestamp}.csv"
        $filePath = Join-Path $OutputPath $fileName
        
        $csvContent = "Date,Trading Symbol,Strike Price,Option Type,Expiry Date,Open Price,High Price,Low Price,Close Price,Last Price,Volume,Lower Circuit Limit,Upper Circuit Limit,Last Trade Time`n"
        
        foreach ($record in $callData) {
            $csvContent += "$($record.Date),$($record.TradingSymbol),$($record.StrikePrice),$($record.OptionType),$($record.ExpiryDate),$($record.OpenPrice),$($record.HighPrice),$($record.LowPrice),$($record.ClosePrice),$($record.LastPrice),$($record.Volume),$($record.LowerCircuitLimit),$($record.UpperCircuitLimit),$($record.LastTradeTime)`n"
        }
        
        $csvContent | Out-File -FilePath $filePath -Encoding UTF8
        Write-Host "Call options saved: $fileName" -ForegroundColor Green
    }
    
    # Put options CSV
    if ($putData.Count -gt 0) {
        $fileName = "SENSEX_PUT_Options_DATABASE_${FromDate}_to_${ToDate}_${timestamp}.csv"
        $filePath = Join-Path $OutputPath $fileName
        
        $csvContent = "Date,Trading Symbol,Strike Price,Option Type,Expiry Date,Open Price,High Price,Low Price,Close Price,Last Price,Volume,Lower Circuit Limit,Upper Circuit Limit,Last Trade Time`n"
        
        foreach ($record in $putData) {
            $csvContent += "$($record.Date),$($record.TradingSymbol),$($record.StrikePrice),$($record.OptionType),$($record.ExpiryDate),$($record.OpenPrice),$($record.HighPrice),$($record.LowPrice),$($record.ClosePrice),$($record.LastPrice),$($record.Volume),$($record.LowerCircuitLimit),$($record.UpperCircuitLimit),$($record.LastTradeTime)`n"
        }
        
        $csvContent | Out-File -FilePath $filePath -Encoding UTF8
        Write-Host "Put options saved: $fileName" -ForegroundColor Green
    }
    
    Write-Host "`nSUCCESS! Files saved to: $OutputPath" -ForegroundColor Green
    Write-Host "Total records exported: $($allData.Count)" -ForegroundColor Cyan
    
    # Show files created
    Write-Host "`nFiles created:" -ForegroundColor Yellow
    Get-ChildItem $OutputPath -Filter "*.csv" | ForEach-Object {
        Write-Host "  $($_.Name) ($($_.Length) bytes)" -ForegroundColor White
    }
    
    $connection.Close()
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..." -ForegroundColor White
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
