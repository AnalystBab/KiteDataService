# Simple LC/UC Monitor for 2025-10-01
$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"

Write-Host "LC/UC Monitor for Business Date: 2025-10-01" -ForegroundColor Green
Write-Host "Current Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Blue
Write-Host ""

# Check for recent changes
$query = "SELECT COUNT(*) as TotalRecords FROM MarketQuotes WHERE BusinessDate = '2025-10-01'"
$totalRecords = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query -TrustServerCertificate

$query2 = "SELECT COUNT(*) as ChangesCount FROM MarketQuotes WHERE BusinessDate = '2025-10-01' AND InsertionSequence > 1"
$changesCount = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query2 -TrustServerCertificate

$query3 = "SELECT MAX(InsertionSequence) as MaxSequence FROM MarketQuotes WHERE BusinessDate = '2025-10-01'"
$maxSequence = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query3 -TrustServerCertificate

Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  Total Records: $($totalRecords.TotalRecords)" -ForegroundColor White
Write-Host "  Records with Changes: $($changesCount.ChangesCount)" -ForegroundColor White
Write-Host "  Max Insertion Sequence: $($maxSequence.MaxSequence)" -ForegroundColor White

# Check for SENSEX 77800 CE specifically
$query4 = "SELECT mq.LowerCircuitLimit, mq.UpperCircuitLimit, mq.InsertionSequence, mq.RecordDateTime FROM MarketQuotes mq INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken WHERE mq.BusinessDate = '2025-10-01' AND i.TradingSymbol LIKE 'SENSEX%' AND i.Strike = 77800 AND i.InstrumentType = 'CE' ORDER BY mq.InsertionSequence DESC"
$sensexData = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query4 -TrustServerCertificate

if ($sensexData) {
    Write-Host ""
    Write-Host "SENSEX 77800 CE Status:" -ForegroundColor Cyan
    Write-Host "  Lower Circuit: $($sensexData[0].LowerCircuitLimit)" -ForegroundColor White
    Write-Host "  Upper Circuit: $($sensexData[0].UpperCircuitLimit)" -ForegroundColor White
    Write-Host "  Insertion Sequence: $($sensexData[0].InsertionSequence)" -ForegroundColor White
    Write-Host "  Last Update: $($sensexData[0].RecordDateTime)" -ForegroundColor White
}

Write-Host ""
Write-Host "Run this script every few minutes to monitor changes" -ForegroundColor Green
