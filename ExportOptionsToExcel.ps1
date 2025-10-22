# Export Options Data to Excel
# This script exports options data for a specific business date to Excel format

param(
    [Parameter(Mandatory=$false)]
    [DateTime]$BusinessDate = (Get-Date).Date
)

Write-Host "=============================================" -ForegroundColor Green
Write-Host "OPTIONS DATA EXCEL EXPORT" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Database connection
$connectionString = "Server=.;Database=KiteMarketData;Integrated Security=true;TrustServerCertificate=true"

try {
    # Connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    Write-Host "Connected to database successfully" -ForegroundColor Green
    Write-Host "Exporting data for Business Date: $($BusinessDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan
    
    # Create Excel object
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false
    
    # Create new workbook
    $workbook = $excel.Workbooks.Add()
    
    # 1. All Options Data Sheet
    Write-Host "Creating All Options Data sheet..." -ForegroundColor Yellow
    $worksheet = $workbook.Worksheets.Item(1)
    $worksheet.Name = "All Options Data"
    
    $query = @"
SELECT 
    BusinessDate,
    ExpiryDate,
    TickerSymbol,
    StrikePrice,
    OptionType,
    [Open],
    [High],
    [Low],
    [Close],
    LastPrice,
    LC,
    UC,
    Volume,
    OpenInterest
FROM vw_OptionsData 
WHERE BusinessDate = '$($BusinessDate.ToString('yyyy-MM-dd'))'
ORDER BY ExpiryDate, OptionType, SortStrike
"@
    
    $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
    $dataTable = New-Object System.Data.DataTable
    $adapter.Fill($dataTable)
    
    if ($dataTable.Rows.Count -gt 0) {
        # Add headers
        $headers = @("BusinessDate", "ExpiryDate", "TickerSymbol", "StrikePrice", "OptionType", 
                    "Open", "High", "Low", "Close", "LastPrice", "LC", "UC", "Volume", "OpenInterest")
        
        for ($i = 0; $i -lt $headers.Count; $i++) {
            $worksheet.Cells.Item(1, $i + 1) = $headers[$i]
            $worksheet.Cells.Item(1, $i + 1).Font.Bold = $true
            $worksheet.Cells.Item(1, $i + 1).Interior.Color = 0xCCCCFF
        }
        
        # Add data
        for ($row = 0; $row -lt $dataTable.Rows.Count; $row++) {
            for ($col = 0; $col -lt $headers.Count; $col++) {
                $worksheet.Cells.Item($row + 2, $col + 1) = $dataTable.Rows[$row][$col]
            }
        }
        
        # Auto-fit columns
        $worksheet.Columns.AutoFit()
        
        Write-Host "Added $($dataTable.Rows.Count) options records" -ForegroundColor Green
    } else {
        $worksheet.Cells.Item(1, 1) = "No data available for the specified business date"
        Write-Host "No options data found for $($BusinessDate.ToString('yyyy-MM-dd'))" -ForegroundColor Yellow
    }
    
    # 2. Strike Summary Sheet
    Write-Host "Creating Strike Summary sheet..." -ForegroundColor Yellow
    $worksheet2 = $workbook.Worksheets.Add()
    $worksheet2.Name = "Strike Summary"
    
    $query2 = @"
SELECT * FROM vw_StrikeSummary 
WHERE BusinessDate = '$($BusinessDate.ToString('yyyy-MM-dd'))'
ORDER BY ExpiryDate, StrikePrice
"@
    
    $command2 = New-Object System.Data.SqlClient.SqlCommand($query2, $connection)
    $adapter2 = New-Object System.Data.SqlClient.SqlDataAdapter($command2)
    $dataTable2 = New-Object System.Data.DataTable
    $adapter2.Fill($dataTable2)
    
    if ($dataTable2.Rows.Count -gt 0) {
        # Add headers for strike summary
        $headers2 = @("BusinessDate", "ExpiryDate", "StrikePrice", 
                     "CallSymbol", "CallOpen", "CallHigh", "CallLow", "CallClose", "CallLC", "CallUC", "CallVolume", "CallOI",
                     "PutSymbol", "PutOpen", "PutHigh", "PutLow", "PutClose", "PutLC", "PutUC", "PutVolume", "PutOI")
        
        for ($i = 0; $i -lt $headers2.Count; $i++) {
            $worksheet2.Cells.Item(1, $i + 1) = $headers2[$i]
            $worksheet2.Cells.Item(1, $i + 1).Font.Bold = $true
            $worksheet2.Cells.Item(1, $i + 1).Interior.Color = 0xCCFFCC
        }
        
        # Add data
        for ($row = 0; $row -lt $dataTable2.Rows.Count; $row++) {
            for ($col = 0; $col -lt $headers2.Count; $col++) {
                $worksheet2.Cells.Item($row + 2, $col + 1) = $dataTable2.Rows[$row][$col]
            }
        }
        
        $worksheet2.Columns.AutoFit()
        Write-Host "Added $($dataTable2.Rows.Count) strike summary records" -ForegroundColor Green
    }
    
    # 3. LC/UC Changes Sheet
    Write-Host "Creating LC/UC Changes sheet..." -ForegroundColor Yellow
    $worksheet3 = $workbook.Worksheets.Add()
    $worksheet3.Name = "LC UC Changes"
    
    $query3 = @"
SELECT * FROM vw_LC_UC_Changes 
WHERE BusinessDate = '$($BusinessDate.ToString('yyyy-MM-dd'))'
ORDER BY ExpiryDate, StrikePrice, ChangeTime
"@
    
    $command3 = New-Object System.Data.SqlClient.SqlCommand($query3, $connection)
    $adapter3 = New-Object System.Data.SqlClient.SqlDataAdapter($command3)
    $dataTable3 = New-Object System.Data.DataTable
    $adapter3.Fill($dataTable3)
    
    if ($dataTable3.Rows.Count -gt 0) {
        # Add headers
        $headers3 = @("BusinessDate", "ExpiryDate", "TickerSymbol", "StrikePrice", "OptionType",
                     "LC", "UC", "PrevLC", "PrevUC", "ChangeType", "ChangeTime")
        
        for ($i = 0; $i -lt $headers3.Count; $i++) {
            $worksheet3.Cells.Item(1, $i + 1) = $headers3[$i]
            $worksheet3.Cells.Item(1, $i + 1).Font.Bold = $true
            $worksheet3.Cells.Item(1, $i + 1).Interior.Color = 0xFFCCCC
        }
        
        # Add data
        for ($row = 0; $row -lt $dataTable3.Rows.Count; $row++) {
            for ($col = 0; $col -lt $headers3.Count; $col++) {
                $worksheet3.Cells.Item($row + 2, $col + 1) = $dataTable3.Rows[$row][$col]
            }
        }
        
        $worksheet3.Columns.AutoFit()
        Write-Host "Added $($dataTable3.Rows.Count) LC/UC change records" -ForegroundColor Green
    }
    
    # Save the file
    $exportPath = Join-Path $PSScriptRoot "Exports"
    if (!(Test-Path $exportPath)) {
        New-Item -ItemType Directory -Path $exportPath -Force
    }
    
    $fileName = "OptionsData_$($BusinessDate.ToString('yyyyMMdd')).xlsx"
    $filePath = Join-Path $exportPath $fileName
    
    $workbook.SaveAs($filePath)
    $workbook.Close()
    $excel.Quit()
    
    # Release COM objects
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet3) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet2) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($worksheet) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbook) | Out-Null
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
    
    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "EXPORT COMPLETED SUCCESSFULLY!" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "File saved to: $filePath" -ForegroundColor Cyan
    Write-Host "Business Date: $($BusinessDate.ToString('yyyy-MM-dd'))" -ForegroundColor Cyan
    
    if ($dataTable.Rows.Count -gt 0) {
        Write-Host "Options Records: $($dataTable.Rows.Count)" -ForegroundColor Green
    }
    if ($dataTable2.Rows.Count -gt 0) {
        Write-Host "Strike Summary Records: $($dataTable2.Rows.Count)" -ForegroundColor Green
    }
    if ($dataTable3.Rows.Count -gt 0) {
        Write-Host "LC/UC Change Records: $($dataTable3.Rows.Count)" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Excel file is ready for analysis!" -ForegroundColor Yellow
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.Exception.StackTrace)" -ForegroundColor Red
} finally {
    if ($connection) {
        $connection.Close()
        $connection.Dispose()
    }
}

Write-Host ""
Write-Host "Press any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")




