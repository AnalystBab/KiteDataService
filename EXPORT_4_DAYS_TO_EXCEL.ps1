# PowerShell Script to Export 4 Days SENSEX Data to Excel Files
# This script will run the SQL query and create separate Excel files for each day

# Set the database connection parameters
$ServerName = "localhost"
$DatabaseName = "KiteMarketData"
$ConnectionString = "Server=$ServerName;Database=$DatabaseName;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"

# Set the output directory
$OutputDir = ".\4_Days_Data_Export"
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force
}

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "📊 EXPORTING 4 DAYS SENSEX DATA TO EXCEL" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Function to run SQL query and export to Excel
function Export-ToExcel {
    param(
        [string]$Query,
        [string]$FileName,
        [string]$SheetName
    )
    
    try {
        Write-Host "📊 Exporting data for $SheetName..." -ForegroundColor Yellow
        
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
            # Export to Excel
            $Excel = New-Object -ComObject Excel.Application
            $Excel.Visible = $false
            $Excel.DisplayAlerts = $false
            
            # Create workbook
            $Workbook = $Excel.Workbooks.Add()
            $Worksheet = $Workbook.Worksheets.Item(1)
            $Worksheet.Name = $SheetName
            
            # Add headers
            $HeaderRange = $Worksheet.Range("A1:Z1")
            $HeaderRange.Font.Bold = $true
            $HeaderRange.Interior.Color = [System.Drawing.ColorTranslator]::ToOle([System.Drawing.Color]::LightBlue)
            
            # Add data
            $DataTable = $DataSet.Tables[0]
            $DataTable | Export-Csv -Path "$OutputDir\$FileName.csv" -NoTypeInformation
            
            # Open CSV in Excel
            $Workbook = $Excel.Workbooks.Open("$OutputDir\$FileName.csv")
            $Worksheet = $Workbook.Worksheets.Item(1)
            
            # Format the data
            $UsedRange = $Worksheet.UsedRange
            $UsedRange.AutoFit() | Out-Null
            
            # Save as Excel file
            $ExcelFile = "$OutputDir\$FileName.xlsx"
            $Workbook.SaveAs($ExcelFile, 51) # 51 = xlOpenXMLWorkbook
            $Workbook.Close()
            
            Write-Host "✅ Successfully exported $($DataTable.Rows.Count) rows to $FileName.xlsx" -ForegroundColor Green
            
        } else {
            Write-Host "⚠️  No data found for $SheetName" -ForegroundColor Yellow
        }
        
        # Quit Excel
        $Excel.Quit()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel) | Out-Null
        
    } catch {
        Write-Host "❌ Error exporting $SheetName : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Define the queries for each day
$Queries = @{
    "2025-10-15" = @{
        Query = @"
-- DAY 1: 2025-10-15 (Previous Trading Day for 16th Expiry)
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
        FileName = "SENSEX_Data_2025-10-15"
        SheetName = "2025-10-15"
    }
    
    "2025-10-16" = @{
        Query = @"
-- DAY 2: 2025-10-16 (Expiry Day for 16th Expiry)
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
        FileName = "SENSEX_Data_2025-10-16"
        SheetName = "2025-10-16"
    }
    
    "2025-10-21" = @{
        Query = @"
-- DAY 3: 2025-10-21 (Previous Trading Day for 23rd Expiry)
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
        FileName = "SENSEX_Data_2025-10-21"
        SheetName = "2025-10-21"
    }
    
    "2025-10-23" = @{
        Query = @"
-- DAY 4: 2025-10-23 (Expiry Day for 23rd Expiry)
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
        FileName = "SENSEX_Data_2025-10-23"
        SheetName = "2025-10-23"
    }
}

# Export data for each day
foreach ($Day in $Queries.Keys) {
    $QueryData = $Queries[$Day]
    Export-ToExcel -Query $QueryData.Query -FileName $QueryData.FileName -SheetName $QueryData.SheetName
    Write-Host ""
}

# Create a summary file
Write-Host "📊 Creating summary file..." -ForegroundColor Yellow

$SummaryQuery = @"
-- Summary of all 4 days data
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
  AND mqκ.BusinessDate IN ('2025-10-15', '2025-10-16', '2025-10-21', '2025-10-23')
  AND i.OptionType IN ('CE', 'PE')
GROUP BY BusinessDate
ORDER BY BusinessDate;
"@

Export-ToExcel -Query $SummaryQuery -FileName "SENSEX_4_Days_Summary" -SheetName "Summary"

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "✅ EXPORT COMPLETED!" -ForegroundColor Green
Write-Host "📁 Files saved to: $OutputDir" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Files created:" -ForegroundColor Yellow
Get-ChildItem $OutputDir -Filter "*.xlsx" | ForEach-Object {
    Write-Host "   📄 $($_.Name)" -ForegroundColor White
}
Write-Host ""
