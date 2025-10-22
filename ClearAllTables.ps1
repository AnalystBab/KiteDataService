# Clear All Table Data using PowerShell
# This will clear all tables for a fresh start

Write-Host "Clearing All Table Data for Fresh Start..." -ForegroundColor Green

# Database connection string
$connectionString = "Server=LAPTOP-B68L4IP9;Database=KiteMarketData;Integrated Security=true;TrustServerCertificate=true;"

try {
    # Create SQL connection
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    Write-Host "Connected to database successfully" -ForegroundColor Green
    
    # Define tables to clear (in order to respect foreign key constraints)
    $tables = @(
        "CircuitLimitChangeDetails",
        "MarketQuotes", 
        "IntradayTickData",
        "SpotData",
        "FullInstruments",
        "Instruments",
        "ExcelExportData"
    )
    
    # Clear each table
    foreach ($table in $tables) {
        try {
            $command = $connection.CreateCommand()
            $command.CommandText = "DELETE FROM $table"
            $rowsAffected = $command.ExecuteNonQuery()
            Write-Host "✅ Cleared $table table ($rowsAffected rows affected)" -ForegroundColor Cyan
        }
        catch {
            Write-Host "⚠️  $table table not found or already empty: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    # Reset identity columns
    $identityTables = @("MarketQuotes", "IntradayTickData", "SpotData", "FullInstruments", "ExcelExportData")
    
    foreach ($table in $identityTables) {
        try {
            $command = $connection.CreateCommand()
            $command.CommandText = "DBCC CHECKIDENT ('$table', RESEED, 0)"
            $command.ExecuteNonQuery()
            Write-Host "✅ Reset $table identity column" -ForegroundColor Cyan
        }
        catch {
            Write-Host "⚠️  $table identity column reset failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    
    Write-Host ""
    Write-Host "🎉 All Tables Cleared Successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Tables cleared:" -ForegroundColor Yellow
    foreach ($table in $tables) {
        Write-Host "   - $table" -ForegroundColor Cyan
    }
    Write-Host ""
    Write-Host "Ready for fresh data collection!" -ForegroundColor Green
    Write-Host "You can now run your service: dotnet run" -ForegroundColor White
    
}
catch {
    Write-Host "❌ Database connection failed: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
        $connection.Close()
        Write-Host "Database connection closed" -ForegroundColor Gray
    }
}


