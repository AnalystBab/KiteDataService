# Fixed PowerShell Script to Export 4 Days SENSEX Data
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "📊 EXPORTING 4 DAYS SENSEX DATA TO EXCEL" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Set the database connection parameters
$ServerName = "localhost"
$DatabaseName = "KiteMarketData"
$ConnectionString = "Server=$ServerName;Database=$DatabaseName;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"

# Set the output directory
$OutputDir = ".\4_Days_Data_Export"
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force
    Write-Host "📁 Created output directory: $OutputDir" -ForegroundColor Green
}

# Function to run SQL query and export to CSV
function Export-ToCSV {
    param(
        [string]$Query,
        [string]$FileName,
        [string]$Description
    )
    
    try {
        Write-Host "📊 Exporting data for $Description..." -ForegroundColor Yellow
        
        # Create connection
        $Connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $Connection.Open()
        
        # Create command
        $Command = New-Object System.Data.SqlClient.SqlCommand($Query, $Connection)
        $Command.CommandTimeout = 300
        
        # Create adapter
        $Adapter = New-Object System.Data.SqlClient.SqlDataAdapter($Command)
        $DataSet = New-Object System.Data.DataSet
        
        # Fill dataset
        $Adapter.Fill($DataSet) | Out-Null
        
        # Close connection
        $Connection.Close()
        
        if ($DataSet.Tables[0].Rows.Count -gt 0) {
            # Export to CSV
            $CsvFile = "$OutputDir\$FileName.csv"
            $DataSet.Tables[0] | Export-Csv -Path $CsvFile -NoTypeInformation
            
            Write-Host "✅ Successfully exported $($DataSet.Tables[0].Rows.Count) rows to $FileName.csv" -ForegroundColor Green
            
        } else {
            Write-Host "⚠️  No data found for $Description" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "❌ Error exporting $Description : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Define queries for each day
$Day15Query = @"
SELECT 
    'SPOT_DATA' as DataType,
    '2025-10-15' as BusinessDate,
    'SENSEX' as IndexName,
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol = 'SENSEX' 
  AND BusinessDate = '2025-10-15'
  AND OptionType IS NULL

UNION ALL

SELECT 
    'OPTION_DATA' as DataType,
    '2025-10-15' as BusinessDate,
    TradingSymbol as IndexName,
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    Strike,
    OptionType,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%' 
  AND BusinessDate = '2025-10-15'
  AND OptionType IN ('CE', 'PE')
GROUP BY TradingSymbol, Strike, OptionType

ORDER BY DataType, Strike, OptionType;
"@

$Day16Query = @"
SELECT 
    'SPOT_DATA' as DataType,
    '2025-10-16' as BusinessDate,
    'SENSEX' as IndexName,
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol = 'SENSEX' 
  AND BusinessDate = '2025-10-16'
  AND OptionType IS NULL

UNION ALL

SELECT 
    'OPTION_DATA' as DataType,
    '2025-10-16' as BusinessDate,
    TradingSymbol as IndexName,
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    Strike,
    OptionType,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%' 
  AND BusinessDate = '2025-10-16'
  AND OptionType IN ('CE', 'PE')
GROUP BY TradingSymbol, Strike, OptionType

ORDER BY DataType, Strike, OptionType;
"@

$Day21Query = @"
SELECT 
    'SPOT_DATA' as DataType,
    '2025-10-21' as BusinessDate,
    'SENSEX' as IndexName,
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol = 'SENSEX' 
  AND BusinessDate = '2025-10-21'
  AND OptionType IS NULL

UNION ALL

SELECT 
    'OPTION_DATA' as DataType,
    '2025-10-21' as BusinessDate,
    TradingSymbol as IndexName,
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    Strike,
    OptionType,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%' 
  AND BusinessDate = '2025-10-21'
  AND OptionType IN ('CE', 'PE')
GROUP BY TradingSymbol, Strike, OptionType

ORDER BY DataType, Strike, OptionType;
"@

$Day23Query = @"
SELECT 
    'SPOT_DATA' as DataType,
    '2025-10-23' as BusinessDate,
    'SENSEX' as IndexName,
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol = 'SENSEX' 
  AND BusinessDate = '2025-10-23'
  AND OptionType IS NULL

UNION ALL

SELECT 
    'OPTION_DATA' as DataType,
    '2025-10-23' as BusinessDate,
    TradingSymbol as IndexName,
    MAX(OpenPrice) as Open,
    MAX(HighPrice) as High,
    MIN(LowPrice) as Low,
    MAX(ClosePrice) as Close,
    MAX(LastPrice) as LastPrice,
    Strike,
    OptionType,
    COUNT(*) as RecordCount,
    MAX(RecordDateTime) as LastUpdate
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%' 
  AND BusinessDate = '2025-10-23'
  AND OptionType IN ('CE', 'PE')
GROUP BY TradingSymbol, Strike, OptionType

ORDER BY DataType, Strike, OptionType;
"@

$SummaryQuery = @"
SELECT 
    BusinessDate,
    COUNT(*) as TotalRecords,
    COUNT(DISTINCT Strike) as UniqueStrikes,
    COUNT(DISTINCT OptionType) as OptionTypes,
    MIN(RecordDateTime) as FirstRecord,
    MAX(RecordDateTime) as LastRecord
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE i.TradingSymbol LIKE 'SENSEX%'
  AND mq.BusinessDate IN ('2025-10-15', '2025-10-16', '2025-10-21', '2025-10-23')
  AND i.OptionType IN ('CE', 'PE')
GROUP BY BusinessDate
ORDER BY BusinessDate;
"@

# Export data for each day
Export-ToCSV -Query $Day15Query -FileName "SENSEX_Data_2025-10-15" -Description "2025-10-15 (Previous Trading Day for 16th Expiry)"
Export-ToCSV -Query $Day16Query -FileName "SENSEX_Data_2025-10-16" -Description "2025-10-16 (Expiry Day for 16th Expiry)"
Export-ToCSV -Query $Day21Query -FileName "SENSEX_Data_2025-10-21" -Description "2025-10-21 (Previous Trading Day for 23rd Expiry)"
Export-ToCSV -Query $Day23Query -FileName "SENSEX_Data_2025-10-23" -Description "2025-10-23 (Expiry Day for 23rd Expiry)"
Export-ToCSV -Query $SummaryQuery -FileName "SENSEX_4_Days_Summary" -Description "4 Days Summary"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "✅ EXPORT COMPLETED!" -ForegroundColor Green
Write-Host "📁 Files saved to: $OutputDir" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Files created:" -ForegroundColor Yellow

# List created files
$CsvFiles = Get-ChildItem $OutputDir -Filter "*.csv" -ErrorAction SilentlyContinue

if ($CsvFiles.Count -gt 0) {
    Write-Host "📄 CSV Files:" -ForegroundColor Green
    foreach ($file in $CsvFiles) {
        Write-Host "   📊 $($file.Name)" -ForegroundColor White
    }
} else {
    Write-Host "❌ No files found. Check the error messages above." -ForegroundColor Red
}

Write-Host ""
