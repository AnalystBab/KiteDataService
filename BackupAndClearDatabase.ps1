# Database Backup and Clear Tables Script
# Run this in PowerShell as Administrator

Write-Host "=== DATABASE BACKUP AND CLEAR TABLES ===" -ForegroundColor Green
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Yellow

# Configuration
$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"
$BackupDirectory = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\DatabaseBackups"
$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFileName = "KiteMarketData_Backup_${Timestamp}.bak"
$BackupFilePath = Join-Path $BackupDirectory $BackupFileName

Write-Host "Database: $DatabaseName" -ForegroundColor Cyan
Write-Host "Backup File: $BackupFilePath" -ForegroundColor Cyan

# Step 1: Check if database exists
Write-Host "`nChecking if database exists..." -ForegroundColor Yellow
$CheckDbQuery = "SELECT name FROM sys.databases WHERE name = '$DatabaseName'"
try {
    $DbExists = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $CheckDbQuery -TrustServerCertificate
    if (-not $DbExists) {
        Write-Host "ERROR: Database '$DatabaseName' not found!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Database found successfully!" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to check database!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Step 2: Create backup directory if it doesn't exist
if (-not (Test-Path $BackupDirectory)) {
    Write-Host "Creating backup directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
}

# Step 3: Take database backup
Write-Host "`nTaking database backup..." -ForegroundColor Yellow
$BackupQuery = "BACKUP DATABASE [$DatabaseName] TO DISK = '$BackupFilePath' WITH FORMAT, COMPRESSION, STATS = 10"

try {
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $BackupQuery -QueryTimeout 600 -ConnectionTimeout 30 -TrustServerCertificate
    Write-Host "Database backup completed successfully!" -ForegroundColor Green
    Write-Host "Backup file: $BackupFilePath" -ForegroundColor Cyan
    
    # Show backup file size
    $BackupFile = Get-Item $BackupFilePath
    Write-Host "Backup size: $([math]::Round($BackupFile.Length/1MB, 2)) MB" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Database backup failed!" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Step 4: Clear all tables
Write-Host "`nClearing all tables..." -ForegroundColor Yellow

# List of tables to clear (in order to avoid foreign key constraints)
$TablesToClear = @(
    "CircuitLimitChanges",
    "CircuitLimitChangeHistory", 
    "MarketQuotes",
    "CircuitLimits",
    "DailyMarketSnapshots",
    "Instruments"
)

foreach ($Table in $TablesToClear) {
    Write-Host "Clearing table: $Table" -ForegroundColor Yellow
    $ClearQuery = "USE [$DatabaseName]; DELETE FROM [$Table]"
    
    try {
        $Result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $ClearQuery -TrustServerCertificate
        Write-Host "  ✓ Cleared table: $Table" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to clear table: $Table" -ForegroundColor Red
        $ErrorMessage = $_.Exception.Message
        Write-Host "    Error: $ErrorMessage" -ForegroundColor Red
    }
}

# Step 5: Reset identity columns
Write-Host "`nResetting identity columns..." -ForegroundColor Yellow

$IdentityTables = @(
    "CircuitLimitChanges",
    "CircuitLimitChangeHistory",
    "MarketQuotes", 
    "CircuitLimits",
    "DailyMarketSnapshots",
    "Instruments"
)

foreach ($Table in $IdentityTables) {
    Write-Host "Resetting identity for: $Table" -ForegroundColor Yellow
    $ResetQuery = "USE [$DatabaseName]; DBCC CHECKIDENT ('[$Table]', RESEED, 0)"
    
    try {
        $Result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $ResetQuery -TrustServerCertificate
        Write-Host "  ✓ Reset identity for: $Table" -ForegroundColor Green
    } catch {
        Write-Host "  ✗ Failed to reset identity for: $Table" -ForegroundColor Red
        $ErrorMessage = $_.Exception.Message
        Write-Host "    Error: $ErrorMessage" -ForegroundColor Red
    }
}

# Step 6: Verify tables are empty
Write-Host "`nVerifying tables are empty..." -ForegroundColor Yellow

foreach ($Table in $TablesToClear) {
    $CountQuery = "USE [$DatabaseName]; SELECT COUNT(*) as RecordCount FROM [$Table]"
    
    try {
        $Result = Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $CountQuery -TrustServerCertificate
        $Count = $Result.RecordCount
        if ($Count -eq 0) {
            Write-Host "  ✓ $Table: $Count records" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ $Table: $Count records (should be 0)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  ✗ Failed to check $Table" -ForegroundColor Red
    }
}

# Step 7: Summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Green
Write-Host "✓ Database backup completed: $BackupFileName" -ForegroundColor Green
Write-Host "✓ All tables cleared" -ForegroundColor Green
Write-Host "✓ Identity columns reset" -ForegroundColor Green
Write-Host "`nBackup location: $BackupFilePath" -ForegroundColor Cyan
$BackupFileSize = [math]::Round((Get-Item $BackupFilePath).Length/1MB, 2)
Write-Host "Backup size: $BackupFileSize MB" -ForegroundColor Cyan
Write-Host "`nDatabase is now ready for fresh data collection!" -ForegroundColor Green
Write-Host "Finished at: $(Get-Date)" -ForegroundColor Yellow
