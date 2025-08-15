# Task 3: Store EOD Data Snapshot
# Purpose: Create daily snapshot of all instruments
# Icon: 🟡 Yellow Circle with "STORE EOD" text

Write-Host "🟡 TASK 3: STORING EOD DATA SNAPSHOT" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

# Database connection parameters
$Server = "localhost"
$Database = "KiteMarketData"

Write-Host "💾 Creating End of Day (EOD) data snapshot..." -ForegroundColor Cyan
Write-Host "🔗 Database: $Server\$Database" -ForegroundColor Yellow

try {
    # Get current date
    $CurrentDate = Get-Date -Format "yyyy-MM-dd"
    Write-Host "📅 Date: $CurrentDate" -ForegroundColor Cyan
    
    # Check if EOD data already exists for today
    $ExistingEODQuery = "SELECT COUNT(*) as ExistingCount FROM EODMarketData WHERE TradingDate = '$CurrentDate'"
    $ExistingCount = sqlcmd -S $Server -d $Database -Q $ExistingEODQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    if ([int]$ExistingCount -gt 0) {
        Write-Host "⚠️  WARNING: EOD data already exists for today ($ExistingCount records)" -ForegroundColor Yellow
        Write-Host "🔄 This will replace existing data with fresh snapshot" -ForegroundColor Yellow
        $Continue = Read-Host "Continue? (Y/N)"
        if ($Continue -ne "Y" -and $Continue -ne "y") {
            Write-Host "❌ Operation cancelled by user" -ForegroundColor Red
            exit 0
        }
    }
    
    Write-Host "⏳ Executing EOD data storage procedure..." -ForegroundColor Yellow
    
    # Execute the StoreEODData procedure
    $EODQuery = "EXEC StoreEODData"
    $Result = sqlcmd -S $Server -d $Database -Q $EODQuery
    
    # Check the result
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ EOD data stored successfully!" -ForegroundColor Green
        
        # Get the count of stored records
        $StoredCountQuery = "SELECT COUNT(*) as StoredCount FROM EODMarketData WHERE TradingDate = '$CurrentDate'"
        $StoredCount = sqlcmd -S $Server -d $Database -Q $StoredCountQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
        
        Write-Host ""
        Write-Host "📊 EOD SNAPSHOT SUMMARY:" -ForegroundColor Yellow
        Write-Host "=========================" -ForegroundColor Yellow
        Write-Host "📅 Date: $CurrentDate" -ForegroundColor Cyan
        Write-Host "📈 Instruments Stored: $StoredCount" -ForegroundColor Cyan
        Write-Host "💾 Snapshot Type: Latest quotes per instrument" -ForegroundColor Cyan
        Write-Host "💡 Next: Run Task 4 to compare circuit limits" -ForegroundColor Yellow
        
    } else {
        Write-Host "❌ ERROR: Failed to store EOD data" -ForegroundColor Red
        Write-Host "Check database connection and stored procedure" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ ERROR: Failed to execute EOD storage" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔍 Check database connection and stored procedure status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 TASK 3 COMPLETED: EOD snapshot stored" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
