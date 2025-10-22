# Backup Both Databases Script
# This script creates backups of both KiteMarketData and CircuitLimitTracking databases

Write-Host "Starting database backup process..." -ForegroundColor Green

# Get current timestamp for backup file names
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "C:\DatabaseBackups"

# Create backup directory if it doesn't exist
if (!(Test-Path $backupPath)) {
    New-Item -ItemType Directory -Path $backupPath -Force
    Write-Host "Created backup directory: $backupPath" -ForegroundColor Yellow
}

try {
    # Backup KiteMarketData database
    Write-Host "Backing up KiteMarketData database..." -ForegroundColor Cyan
    $kiteBackupFile = "$backupPath\KiteMarketData_Backup_$timestamp.bak"
    
    $kiteBackupQuery = @"
BACKUP DATABASE [KiteMarketData] 
TO DISK = '$kiteBackupFile'
WITH FORMAT, INIT, NAME = 'KiteMarketData Full Backup', 
SKIP, NOREWIND, NOUNLOAD, STATS = 10
"@
    
    sqlcmd -S localhost -Q $kiteBackupQuery
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ KiteMarketData backup completed successfully: $kiteBackupFile" -ForegroundColor Green
    } else {
        Write-Host "❌ KiteMarketData backup failed!" -ForegroundColor Red
    }
    
    # Backup CircuitLimitTracking database
    Write-Host "Backing up CircuitLimitTracking database..." -ForegroundColor Cyan
    $circuitBackupFile = "$backupPath\CircuitLimitTracking_Backup_$timestamp.bak"
    
    $circuitBackupQuery = @"
BACKUP DATABASE [CircuitLimitTracking] 
TO DISK = '$circuitBackupFile'
WITH FORMAT, INIT, NAME = 'CircuitLimitTracking Full Backup', 
SKIP, NOREWIND, NOUNLOAD, STATS = 10
"@
    
    sqlcmd -S localhost -Q $circuitBackupQuery
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ CircuitLimitTracking backup completed successfully: $circuitBackupFile" -ForegroundColor Green
    } else {
        Write-Host "❌ CircuitLimitTracking backup failed!" -ForegroundColor Red
    }
    
    # Show backup file sizes
    Write-Host "`nBackup Summary:" -ForegroundColor Yellow
    if (Test-Path $kiteBackupFile) {
        $kiteSize = (Get-Item $kiteBackupFile).Length / 1MB
        Write-Host "KiteMarketData: $kiteSize MB" -ForegroundColor White
    }
    if (Test-Path $circuitBackupFile) {
        $circuitSize = (Get-Item $circuitBackupFile).Length / 1MB
        Write-Host "CircuitLimitTracking: $circuitSize MB" -ForegroundColor White
    }
    
    Write-Host "`n✅ Database backup process completed!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error during backup: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nPress any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")





