# Check Data Collection Status
$connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check recent data collection
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            COUNT(*) as RecentQuotes,
            MAX(RecordDateTime) as LastRecordTime,
            COUNT(DISTINCT TradingSymbol) as ActiveSymbols
        FROM MarketQuotes 
        WHERE RecordDateTime >= DATEADD(minute, -10, GETUTCDATE())
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    Write-Host "=== DATA COLLECTION STATUS ===" -ForegroundColor Green
    Write-Host ""
    
    if ($reader.Read()) {
        $recentQuotes = $reader["RecentQuotes"]
        $lastRecordTime = $reader["LastRecordTime"]
        $activeSymbols = $reader["ActiveSymbols"]
        
        Write-Host "Recent Data Collection (last 10 minutes):" -ForegroundColor Yellow
        Write-Host "  Quotes Collected: $recentQuotes" -ForegroundColor White
        Write-Host "  Active Symbols: $activeSymbols" -ForegroundColor White
        Write-Host "  Last Record Time: $lastRecordTime" -ForegroundColor White
        Write-Host ""
        
        if ($recentQuotes -gt 0) {
            Write-Host "✅ SERVICE IS COLLECTING DATA!" -ForegroundColor Green
            Write-Host "Data collection is active and working properly." -ForegroundColor Green
        } else {
            Write-Host "⚠️ NO RECENT DATA COLLECTION" -ForegroundColor Yellow
            Write-Host "Service may not be collecting data currently." -ForegroundColor Yellow
        }
    }
    
    $reader.Close()
    
    # Check total data
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT COUNT(*) as TotalQuotes FROM MarketQuotes
    ", $connection)
    
    $totalQuotes = $command.ExecuteScalar()
    Write-Host "Total Market Quotes in Database: $totalQuotes" -ForegroundColor Cyan
    
    $connection.Close()
    
} catch {
    Write-Host "Error checking data collection: $($_.Exception.Message)" -ForegroundColor Red
}

$connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Check recent data collection
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            COUNT(*) as RecentQuotes,
            MAX(RecordDateTime) as LastRecordTime,
            COUNT(DISTINCT TradingSymbol) as ActiveSymbols
        FROM MarketQuotes 
        WHERE RecordDateTime >= DATEADD(minute, -10, GETUTCDATE())
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    Write-Host "=== DATA COLLECTION STATUS ===" -ForegroundColor Green
    Write-Host ""
    
    if ($reader.Read()) {
        $recentQuotes = $reader["RecentQuotes"]
        $lastRecordTime = $reader["LastRecordTime"]
        $activeSymbols = $reader["ActiveSymbols"]
        
        Write-Host "Recent Data Collection (last 10 minutes):" -ForegroundColor Yellow
        Write-Host "  Quotes Collected: $recentQuotes" -ForegroundColor White
        Write-Host "  Active Symbols: $activeSymbols" -ForegroundColor White
        Write-Host "  Last Record Time: $lastRecordTime" -ForegroundColor White
        Write-Host ""
        
        if ($recentQuotes -gt 0) {
            Write-Host "✅ SERVICE IS COLLECTING DATA!" -ForegroundColor Green
            Write-Host "Data collection is active and working properly." -ForegroundColor Green
        } else {
            Write-Host "⚠️ NO RECENT DATA COLLECTION" -ForegroundColor Yellow
            Write-Host "Service may not be collecting data currently." -ForegroundColor Yellow
        }
    }
    
    $reader.Close()
    
    # Check total data
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT COUNT(*) as TotalQuotes FROM MarketQuotes
    ", $connection)
    
    $totalQuotes = $command.ExecuteScalar()
    Write-Host "Total Market Quotes in Database: $totalQuotes" -ForegroundColor Cyan
    
    $connection.Close()
    
} catch {
    Write-Host "Error checking data collection: $($_.Exception.Message)" -ForegroundColor Red
}
