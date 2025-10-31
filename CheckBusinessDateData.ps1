# Check Data Collection for Today's Business Date
$connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check data collection for today's business date (2025-10-29)
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            COUNT(*) as TodayQuotes,
            MIN(RecordDateTime) as FirstRecordToday,
            MAX(RecordDateTime) as LastRecordToday,
            COUNT(DISTINCT TradingSymbol) as ActiveSymbolsToday
        FROM MarketQuotes 
        WHERE BusinessDate = '2025-10-29'
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    Write-Host "=== TODAY'S BUSINESS DATE DATA COLLECTION ===" -ForegroundColor Green
    Write-Host "Business Date: 2025-10-29" -ForegroundColor Cyan
    Write-Host ""
    
    if ($reader.Read()) {
        $todayQuotes = $reader["TodayQuotes"]
        $firstRecord = $reader["FirstRecordToday"]
        $lastRecord = $reader["LastRecordToday"]
        $activeSymbols = $reader["ActiveSymbolsToday"]
        
        Write-Host "Today's Data Collection:" -ForegroundColor Yellow
        Write-Host "  Quotes Collected Today: $todayQuotes" -ForegroundColor White
        Write-Host "  Active Symbols Today: $activeSymbols" -ForegroundColor White
        Write-Host "  First Record Today: $firstRecord" -ForegroundColor White
        Write-Host "  Last Record Today: $lastRecord" -ForegroundColor White
        Write-Host ""
        
        if ($todayQuotes -gt 0) {
            Write-Host "✅ SERVICE IS COLLECTING DATA FOR TODAY!" -ForegroundColor Green
            Write-Host "Business date 2025-10-29 data collection is active." -ForegroundColor Green
        } else {
            Write-Host "❌ NO DATA COLLECTED FOR TODAY" -ForegroundColor Red
            Write-Host "Service may not be collecting data for business date 2025-10-29." -ForegroundColor Red
        }
    }
    
    $reader.Close()
    
    # Check what business dates exist in the database
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            BusinessDate,
            COUNT(*) as QuoteCount,
            MIN(RecordDateTime) as FirstRecord,
            MAX(RecordDateTime) as LastRecord
        FROM MarketQuotes 
        GROUP BY BusinessDate
        ORDER BY BusinessDate DESC
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "=== BUSINESS DATES IN DATABASE ===" -ForegroundColor Green
    Write-Host ""
    
    while ($reader.Read()) {
        $businessDate = $reader["BusinessDate"]
        $quoteCount = $reader["QuoteCount"]
        $firstRecord = $reader["FirstRecord"]
        $lastRecord = $reader["LastRecord"]
        
        $isToday = if ($businessDate -eq "2025-10-29") { " (TODAY)" } else { "" }
        
        Write-Host "Business Date: $businessDate$isToday" -ForegroundColor White
        Write-Host "  Quotes: $quoteCount" -ForegroundColor Gray
        Write-Host "  Time Range: $firstRecord to $lastRecord" -ForegroundColor Gray
        Write-Host ""
    }
    
    $reader.Close()
    $connection.Close()
    
} catch {
    Write-Host "Error checking business date data: $($_.Exception.Message)" -ForegroundColor Red
}

$connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check data collection for today's business date (2025-10-29)
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            COUNT(*) as TodayQuotes,
            MIN(RecordDateTime) as FirstRecordToday,
            MAX(RecordDateTime) as LastRecordToday,
            COUNT(DISTINCT TradingSymbol) as ActiveSymbolsToday
        FROM MarketQuotes 
        WHERE BusinessDate = '2025-10-29'
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    Write-Host "=== TODAY'S BUSINESS DATE DATA COLLECTION ===" -ForegroundColor Green
    Write-Host "Business Date: 2025-10-29" -ForegroundColor Cyan
    Write-Host ""
    
    if ($reader.Read()) {
        $todayQuotes = $reader["TodayQuotes"]
        $firstRecord = $reader["FirstRecordToday"]
        $lastRecord = $reader["LastRecordToday"]
        $activeSymbols = $reader["ActiveSymbolsToday"]
        
        Write-Host "Today's Data Collection:" -ForegroundColor Yellow
        Write-Host "  Quotes Collected Today: $todayQuotes" -ForegroundColor White
        Write-Host "  Active Symbols Today: $activeSymbols" -ForegroundColor White
        Write-Host "  First Record Today: $firstRecord" -ForegroundColor White
        Write-Host "  Last Record Today: $lastRecord" -ForegroundColor White
        Write-Host ""
        
        if ($todayQuotes -gt 0) {
            Write-Host "✅ SERVICE IS COLLECTING DATA FOR TODAY!" -ForegroundColor Green
            Write-Host "Business date 2025-10-29 data collection is active." -ForegroundColor Green
        } else {
            Write-Host "❌ NO DATA COLLECTED FOR TODAY" -ForegroundColor Red
            Write-Host "Service may not be collecting data for business date 2025-10-29." -ForegroundColor Red
        }
    }
    
    $reader.Close()
    
    # Check what business dates exist in the database
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            BusinessDate,
            COUNT(*) as QuoteCount,
            MIN(RecordDateTime) as FirstRecord,
            MAX(RecordDateTime) as LastRecord
        FROM MarketQuotes 
        GROUP BY BusinessDate
        ORDER BY BusinessDate DESC
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    Write-Host ""
    Write-Host "=== BUSINESS DATES IN DATABASE ===" -ForegroundColor Green
    Write-Host ""
    
    while ($reader.Read()) {
        $businessDate = $reader["BusinessDate"]
        $quoteCount = $reader["QuoteCount"]
        $firstRecord = $reader["FirstRecord"]
        $lastRecord = $reader["LastRecord"]
        
        $isToday = if ($businessDate -eq "2025-10-29") { " (TODAY)" } else { "" }
        
        Write-Host "Business Date: $businessDate$isToday" -ForegroundColor White
        Write-Host "  Quotes: $quoteCount" -ForegroundColor Gray
        Write-Host "  Time Range: $firstRecord to $lastRecord" -ForegroundColor Gray
        Write-Host ""
    }
    
    $reader.Close()
    $connection.Close()
    
} catch {
    Write-Host "Error checking business date data: $($_.Exception.Message)" -ForegroundColor Red
}
