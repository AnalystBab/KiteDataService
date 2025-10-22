# Quick Backup and Clear Database Script
# This script backs up the database and clears all table data for fresh data capture

Write-Host "=============================================" -ForegroundColor Green
Write-Host "DATABASE BACKUP AND CLEAR OPERATION" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Create backup directory if it doesn't exist
$backupDir = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\DatabaseBackups"
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force
    Write-Host "Created backup directory: $backupDir" -ForegroundColor Yellow
}

# Generate backup filename with timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = "$backupDir\KiteMarketData_Backup_BeforeClear_$timestamp.bak"

Write-Host ""
Write-Host "Step 1: Taking Database Backup..." -ForegroundColor Cyan
Write-Host "Backup File: $backupFile" -ForegroundColor Gray

try {
    # Take backup
    $backupQuery = "BACKUP DATABASE KiteMarketData TO DISK = '$backupFile'"
    sqlcmd -S . -Q $backupQuery
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Database backup completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "❌ Database backup failed!" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ Error during backup: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Step 2: Clearing All Table Data..." -ForegroundColor Cyan

# Clear all tables in the correct order (respecting foreign key constraints)
$clearQueries = @(
    "DELETE FROM CircuitLimitChanges",
    "DELETE FROM CircuitLimitChangeHistory", 
    "DELETE FROM DailyMarketSnapshots",
    "DELETE FROM CircuitLimits",
    "DELETE FROM MarketQuotes",
    "DELETE FROM Instruments"
)

foreach ($query in $clearQueries) {
    try {
        Write-Host "Executing: $query" -ForegroundColor Gray
        sqlcmd -S . -d KiteMarketData -Q $query
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Successfully cleared table" -ForegroundColor Green
        } else {
            Write-Host "⚠️ Warning: Table clear may have issues" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️ Warning: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Step 3: Verifying Tables Are Empty..." -ForegroundColor Cyan

# Check table counts
$tables = @("Instruments", "MarketQuotes", "CircuitLimits", "CircuitLimitChanges", "CircuitLimitChangeHistory", "DailyMarketSnapshots")

foreach ($table in $tables) {
    try {
        $countQuery = "SELECT COUNT(*) as Count FROM $table"
        $result = sqlcmd -S . -d KiteMarketData -Q $countQuery -h -1 -W
        
        if ($LASTEXITCODE -eq 0) {
            $count = ($result | Where-Object { $_ -match '^\d+$' } | Select-Object -First 1)
            Write-Host "$table`: $count records" -ForegroundColor $(if ($count -eq 0) { "Green" } else { "Yellow" })
        } else {
            Write-Host "$table`: Unable to verify" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "$table`: Error checking count" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "OPERATION COMPLETED!" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host "✅ Database backed up to: $backupFile" -ForegroundColor Green
Write-Host "✅ All tables cleared and ready for fresh data" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 You can now run the service to capture fresh data with BusinessDate!" -ForegroundColor Cyan
Write-Host ""