# Clear All Table Data Script
# This script clears all data from both KiteMarketData and CircuitLimitTracking databases

Write-Host "Starting table data clearing process..." -ForegroundColor Yellow
Write-Host "WARNING: This will delete ALL data from both databases!" -ForegroundColor Red

# Confirmation prompt
$confirmation = Read-Host "Are you sure you want to proceed? Type 'YES' to continue"
if ($confirmation -ne "YES") {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit
}

try {
    Write-Host "`nClearing KiteMarketData database tables..." -ForegroundColor Cyan
    
    # Clear KiteMarketData tables
    $kiteClearQuery = @"
-- Disable foreign key constraints temporarily
EXEC sp_MSforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT all"

-- Clear all tables
TRUNCATE TABLE [KiteMarketData].[dbo].[MarketQuotes]
TRUNCATE TABLE [KiteMarketData].[dbo].[CircuitLimitChanges]
TRUNCATE TABLE [KiteMarketData].[dbo].[DailyMarketSnapshots]
TRUNCATE TABLE [KiteMarketData].[dbo].[Instruments]

-- Re-enable foreign key constraints
EXEC sp_MSforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT all"

-- Reset identity columns
DBCC CHECKIDENT ('[KiteMarketData].[dbo].[MarketQuotes]', RESEED, 0)
DBCC CHECKIDENT ('[KiteMarketData].[dbo].[CircuitLimitChanges]', RESEED, 0)
DBCC CHECKIDENT ('[KiteMarketData].[dbo].[DailyMarketSnapshots]', RESEED, 0)
DBCC CHECKIDENT ('[KiteMarketData].[dbo].[Instruments]', RESEED, 0)
"@
    
    sqlcmd -S localhost -d KiteMarketData -Q $kiteClearQuery
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ KiteMarketData tables cleared successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Error clearing KiteMarketData tables" -ForegroundColor Red
    }
    
    Write-Host "`nClearing CircuitLimitTracking database tables..." -ForegroundColor Cyan
    
    # Clear CircuitLimitTracking tables
    $circuitClearQuery = @"
-- Clear all tables
TRUNCATE TABLE [CircuitLimitTracking].[dbo].[CircuitLimitChangeDetails]

-- Reset identity columns
DBCC CHECKIDENT ('[CircuitLimitTracking].[dbo].[CircuitLimitChangeDetails]', RESEED, 0)
"@
    
    sqlcmd -S localhost -d CircuitLimitTracking -Q $circuitClearQuery
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ CircuitLimitTracking tables cleared successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Error clearing CircuitLimitTracking tables" -ForegroundColor Red
    }
    
    # Verify tables are empty
    Write-Host "`nVerifying tables are empty..." -ForegroundColor Cyan
    
    $verifyQuery = @"
SELECT 
    'KiteMarketData' as DatabaseName,
    'MarketQuotes' as TableName,
    COUNT(*) as RecordCount
FROM [KiteMarketData].[dbo].[MarketQuotes]
UNION ALL
SELECT 
    'KiteMarketData' as DatabaseName,
    'CircuitLimitChanges' as TableName,
    COUNT(*) as RecordCount
FROM [KiteMarketData].[dbo].[CircuitLimitChanges]
UNION ALL
SELECT 
    'KiteMarketData' as DatabaseName,
    'Instruments' as TableName,
    COUNT(*) as RecordCount
FROM [KiteMarketData].[dbo].[Instruments]
UNION ALL
SELECT 
    'CircuitLimitTracking' as DatabaseName,
    'CircuitLimitChangeDetails' as TableName,
    COUNT(*) as RecordCount
FROM [CircuitLimitTracking].[dbo].[CircuitLimitChangeDetails]
"@
    
    Write-Host "`nTable Record Counts:" -ForegroundColor Yellow
    sqlcmd -S localhost -Q $verifyQuery
    
    Write-Host "`n✅ All table data cleared successfully!" -ForegroundColor Green
    Write-Host "You can now run the service to populate fresh data." -ForegroundColor White
    
} catch {
    Write-Host "❌ Error during table clearing: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")





