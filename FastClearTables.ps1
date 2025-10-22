# Fast Table Clear - Uses TRUNCATE for better performance
Write-Host "=== FAST TABLE CLEAR ===" -ForegroundColor Green

$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"

# Disable foreign key constraints temporarily for faster clearing
Write-Host "Disabling foreign key constraints..." -ForegroundColor Yellow
$DisableFKQuery = "USE [$DatabaseName]; EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL'"
Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $DisableFKQuery -TrustServerCertificate

# Clear tables using TRUNCATE (much faster than DELETE)
Write-Host "Clearing tables with TRUNCATE..." -ForegroundColor Yellow
$Tables = @("CircuitLimitChanges", "CircuitLimitChangeHistory", "MarketQuotes", "CircuitLimits", "DailyMarketSnapshots", "Instruments")

foreach ($Table in $Tables) {
    Write-Host "Clearing: $Table" -ForegroundColor Yellow
    try {
        $TruncateQuery = "USE [$DatabaseName]; TRUNCATE TABLE [$Table]"
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $TruncateQuery -TrustServerCertificate
        Write-Host "  ✓ Cleared: $Table" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠ Failed TRUNCATE on $Table, trying DELETE..." -ForegroundColor Yellow
        $DeleteQuery = "USE [$DatabaseName]; DELETE FROM [$Table]"
        Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $DeleteQuery -TrustServerCertificate
        Write-Host "  ✓ Cleared with DELETE: $Table" -ForegroundColor Green
    }
}

# Re-enable foreign key constraints
Write-Host "Re-enabling foreign key constraints..." -ForegroundColor Yellow
$EnableFKQuery = "USE [$DatabaseName]; EXEC sp_MSforeachtable 'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL'"
Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $EnableFKQuery -TrustServerCertificate

Write-Host "Done! All tables cleared quickly." -ForegroundColor Green
