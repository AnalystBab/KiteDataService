# Monitor Service Status and Database Fixes
# This script helps you verify that the service is working correctly with the fixes

param(
    [string]$ConnectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"
)

Write-Host "=== Kite Market Data Service Monitor ===" -ForegroundColor Green
Write-Host ""

# Function to check database status
function Check-DatabaseStatus {
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        # Check if tables have data
        $command = New-Object System.Data.SqlClient.SqlCommand("
            SELECT 
                'Instruments' as TableName, COUNT(*) as RecordCount FROM Instruments
            UNION ALL
            SELECT 'MarketQuotes' as TableName, COUNT(*) as RecordCount FROM MarketQuotes
            UNION ALL
            SELECT 'CircuitLimits' as TableName, COUNT(*) as RecordCount FROM CircuitLimits
        ", $connection)
        
        $reader = $command.ExecuteReader()
        
        Write-Host "=== DATABASE STATUS ===" -ForegroundColor Yellow
        while ($reader.Read()) {
            $tableName = $reader["TableName"]
            $recordCount = $reader["RecordCount"]
            
            if ($recordCount -gt 0) {
                Write-Host "✅ $tableName`: $recordCount records" -ForegroundColor Green
            } else {
                Write-Host "❌ $tableName`: No records found" -ForegroundColor Red
            }
        }
        $reader.Close()
        
        # Check expiry data specifically
        $command = New-Object System.Data.SqlClient.SqlCommand("
            SELECT 
                COUNT(*) as TotalQuotes,
                COUNT(Expiry) as QuotesWithExpiry,
                COUNT(CASE WHEN Expiry IS NOT NULL THEN 1 END) as ValidExpiryCount
            FROM MarketQuotes
        ", $connection)
        
        $reader = $command.ExecuteReader()
        if ($reader.Read()) {
            $totalQuotes = $reader["TotalQuotes"]
            $quotesWithExpiry = $reader["QuotesWithExpiry"]
            $validExpiryCount = $reader["ValidExpiryCount"]
            
            Write-Host ""
            Write-Host "=== EXPIRY DATA STATUS ===" -ForegroundColor Yellow
            Write-Host "Total Market Quotes: $totalQuotes" -ForegroundColor White
            Write-Host "Quotes with Expiry: $quotesWithExpiry" -ForegroundColor White
            Write-Host "Valid Expiry Count: $validExpiryCount" -ForegroundColor White
            
            if ($totalQuotes -gt 0 -and $quotesWithExpiry -eq $totalQuotes) {
                Write-Host "✅ EXPIRY FIX WORKING - All quotes have expiry data!" -ForegroundColor Green
            } elseif ($totalQuotes -gt 0 -and $quotesWithExpiry -gt 0) {
                Write-Host "⚠️ PARTIAL SUCCESS - Some quotes have expiry data" -ForegroundColor Yellow
            } else {
                Write-Host "❌ ISSUE - No expiry data found" -ForegroundColor Red
            }
        }
        $reader.Close()
        
        # Check timestamp format
        $command = New-Object System.Data.SqlClient.SqlCommand("
            SELECT 
                COUNT(*) as TotalQuotes,
                COUNT(CASE WHEN QuoteTimestamp > '1970-01-01' THEN 1 END) as ValidTimestamps,
                COUNT(CASE WHEN QuoteTimestamp <= '1970-01-01' THEN 1 END) as InvalidTimestamps
            FROM MarketQuotes
        ", $connection)
        
        $reader = $command.ExecuteReader()
        if ($reader.Read()) {
            $totalQuotes = $reader["TotalQuotes"]
            $validTimestamps = $reader["ValidTimestamps"]
            $invalidTimestamps = $reader["InvalidTimestamps"]
            
            Write-Host ""
            Write-Host "=== TIMESTAMP STATUS ===" -ForegroundColor Yellow
            Write-Host "Total Quotes: $totalQuotes" -ForegroundColor White
            Write-Host "Valid Timestamps: $validTimestamps" -ForegroundColor White
            Write-Host "Invalid Timestamps: $invalidTimestamps" -ForegroundColor White
            
            if ($totalQuotes -gt 0 -and $validTimestamps -eq $totalQuotes) {
                Write-Host "✅ TIMESTAMP FIX WORKING - All timestamps are valid!" -ForegroundColor Green
            } elseif ($totalQuotes -gt 0 -and $validTimestamps -gt 0) {
                Write-Host "⚠️ PARTIAL SUCCESS - Some timestamps are valid" -ForegroundColor Yellow
            } else {
                Write-Host "❌ ISSUE - Invalid timestamps found" -ForegroundColor Red
            }
        }
        $reader.Close()
        
        # Show sample data
        $command = New-Object System.Data.SqlClient.SqlCommand("
            SELECT TOP 3
                TradingSymbol,
                Expiry,
                QuoteTimestamp,
                LastTradeTime,
                LastPrice
            FROM MarketQuotes 
            WHERE Expiry IS NOT NULL
            ORDER BY CreatedAt DESC
        ", $connection)
        
        $reader = $command.ExecuteReader()
        
        Write-Host ""
        Write-Host "=== SAMPLE DATA ===" -ForegroundColor Yellow
        $hasData = $false
        while ($reader.Read()) {
            $hasData = $true
            $symbol = $reader["TradingSymbol"]
            $expiry = $reader["Expiry"]
            $timestamp = $reader["QuoteTimestamp"]
            $lastTrade = $reader["LastTradeTime"]
            $price = $reader["LastPrice"]
            
            Write-Host "Symbol: $symbol" -ForegroundColor Cyan
            Write-Host "  Expiry: $expiry" -ForegroundColor White
            Write-Host "  Timestamp: $timestamp" -ForegroundColor White
            Write-Host "  Last Trade: $lastTrade" -ForegroundColor White
            Write-Host "  Price: $price" -ForegroundColor White
            Write-Host ""
        }
        
        if (-not $hasData) {
            Write-Host "No data found yet. Service may still be starting..." -ForegroundColor Yellow
        }
        
        $connection.Close()
        
    } catch {
        Write-Host "Error checking database: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Check service process
Write-Host "=== SERVICE STATUS ===" -ForegroundColor Yellow
$serviceProcess = Get-Process -Name "KiteMarketDataService.Worker" -ErrorAction SilentlyContinue

if ($serviceProcess) {
    Write-Host "✅ Service is running (PID: $($serviceProcess.Id))" -ForegroundColor Green
    Write-Host "Start Time: $($serviceProcess.StartTime)" -ForegroundColor White
} else {
    Write-Host "❌ Service is not running" -ForegroundColor Red
    Write-Host "Start the service with: dotnet run" -ForegroundColor Yellow
}

Write-Host ""

# Check database status
Check-DatabaseStatus

Write-Host ""
Write-Host "=== MONITORING COMPLETE ===" -ForegroundColor Green
Write-Host "Run this script again to check progress as the service collects data." -ForegroundColor White
Write-Host ""

# Ask if user wants to run verification script
$runVerification = Read-Host "Do you want to run the full verification script? (y/n)"
if ($runVerification -eq 'y' -or $runVerification -eq 'Y') {
    Write-Host ""
    Write-Host "Running full verification..." -ForegroundColor Yellow
    
    $verificationScript = "VerifyDatabaseFixes.sql"
    if (Test-Path $verificationScript) {
        try {
            $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
            $connection.Open()
            
            $sqlContent = Get-Content $verificationScript -Raw
            $command = New-Object System.Data.SqlClient.SqlCommand($sqlContent, $connection)
            $command.CommandTimeout = 300
            
            Write-Host "Executing verification script..." -ForegroundColor Yellow
            $command.ExecuteNonQuery() | Out-Null
            
            $connection.Close()
            Write-Host "Verification completed!" -ForegroundColor Green
        } catch {
            Write-Host "Error running verification: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Verification script not found: $verificationScript" -ForegroundColor Red
    }
}

Read-Host "Press Enter to close"
