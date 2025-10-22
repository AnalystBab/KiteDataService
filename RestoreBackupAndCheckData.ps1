# Quick Database Restore and Data Check Script
# Run this in PowerShell as Administrator

Write-Host "=== QUICK DATABASE RESTORE AND DATA CHECK ===" -ForegroundColor Green
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Yellow

# Configuration
$ServerInstance = "localhost"
$BackupFile = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\DatabaseBackups\KiteMarketData_Backup_20250821_200628.bak"
$NewDatabaseName = "KiteMarketData_Backup_Check"

Write-Host "Backup File: $BackupFile" -ForegroundColor Cyan
Write-Host "New Database: $NewDatabaseName" -ForegroundColor Cyan

# Step 1: Check if backup file exists
if (-not (Test-Path $BackupFile)) {
    Write-Host "ERROR: Backup file not found!" -ForegroundColor Red
    Write-Host "Available backups:" -ForegroundColor Yellow
    Get-ChildItem "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\DatabaseBackups\*.bak" | ForEach-Object {
        Write-Host "  $($_.Name) - $($_.Length/1MB) MB" -ForegroundColor Gray
    }
    exit 1
}

# Step 2: Restore database using simple SQL
Write-Host "`nRestoring database..." -ForegroundColor Yellow

$RestoreQuery = "RESTORE DATABASE [$NewDatabaseName] FROM DISK = '$BackupFile' WITH MOVE 'KiteMarketData' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\${NewDatabaseName}.mdf', MOVE 'KiteMarketData_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\${NewDatabaseName}_log.ldf', REPLACE"

try {
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $RestoreQuery -QueryTimeout 300 -ConnectionTimeout 30 -TrustServerCertificate
    Write-Host "Database restored successfully!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Database restore failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Step 3: Check 82200 CE data
Write-Host "`nChecking 82200 CE data..." -ForegroundColor Yellow

$CheckQuery = "USE [$NewDatabaseName]; SELECT TOP 10 TradingDate, Strike, OptionType, OpenPrice, HighPrice, LowPrice, ClosePrice, LastPrice, LowerCircuitLimit, UpperCircuitLimit, ExpiryDate, InstrumentToken, TradingSymbol FROM MarketQuotes WHERE Strike = 82200 AND OptionType = 'CE' AND ExpiryDate = '2025-08-26' ORDER BY TradingDate DESC, QuoteTimestamp DESC"

try {
    $Results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $CheckQuery -TrustServerCertificate
    Write-Host "`n82200 CE Data Found:" -ForegroundColor Green
    $Results | Format-Table -AutoSize
} catch {
    Write-Host "ERROR: Data check failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Step 4: Check circuit limit changes for 82200 CE
Write-Host "`nChecking Circuit Limit Changes for 82200 CE..." -ForegroundColor Yellow

$CircuitQuery = "USE [$NewDatabaseName]; SELECT TOP 10 TradingDate, Strike, OptionType, LowerCircuitLimit, UpperCircuitLimit, IndexName, ChangeTimestamp FROM CircuitLimitChangeHistory WHERE Strike = 82200 AND OptionType = 'CE' AND ExpiryDate = '2025-08-26' ORDER BY TradingDate DESC, ChangeTimestamp DESC"

try {
    $CircuitResults = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $CircuitQuery -TrustServerCertificate
    Write-Host "`nCircuit Limit Changes for 82200 CE:" -ForegroundColor Green
    $CircuitResults | Format-Table -AutoSize
} catch {
    Write-Host "ERROR: Circuit limit check failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

Write-Host "`n=== COMPLETED ===" -ForegroundColor Green
Write-Host "Database: $NewDatabaseName" -ForegroundColor Cyan
Write-Host "Finished at: $(Get-Date)" -ForegroundColor Yellow
Write-Host "`nTo clean up later, run: DROP DATABASE [$NewDatabaseName]" -ForegroundColor Gray
