# Simple Fast Table Clear
Write-Host "=== FAST TABLE CLEAR ===" -ForegroundColor Green

$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"

# Clear tables using TRUNCATE (much faster than DELETE)
Write-Host "Clearing tables..." -ForegroundColor Yellow
$Tables = @("CircuitLimitChanges", "CircuitLimitChangeHistory", "MarketQuotes", "CircuitLimits", "DailyMarketSnapshots", "Instruments")

foreach ($Table in $Tables) {
    Write-Host "Clearing: $Table" -ForegroundColor Yellow
    $TruncateQuery = "USE [$DatabaseName]; TRUNCATE TABLE [$Table]"
    Invoke-Sqlcmd -ServerInstance $ServerInstance -Query $TruncateQuery -TrustServerCertificate
    Write-Host "  ✓ Cleared: $Table" -ForegroundColor Green
}

Write-Host "Done! All tables cleared quickly with TRUNCATE." -ForegroundColor Green
