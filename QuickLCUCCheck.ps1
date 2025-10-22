# Quick LC/UC Changes Check for 2025-10-01
$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"
$BusinessDate = "2025-10-01"

Write-Host "🔍 Checking LC/UC Changes for Business Date: $BusinessDate" -ForegroundColor Green
Write-Host "⏰ Current Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Blue
Write-Host ""

$query = @"
SELECT TOP 50
    i.TradingSymbol,
    i.InstrumentType,
    i.Strike,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.InsertionSequence,
    mq.RecordDateTime
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE mq.BusinessDate = '$BusinessDate'
    AND (mq.LowerCircuitLimit > 0 OR mq.UpperCircuitLimit > 0)
    AND i.TradingSymbol LIKE 'SENSEX%'
ORDER BY mq.InsertionSequence DESC, mq.RecordDateTime DESC
"@

try {
    $results = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query -TrustServerCertificate
    
    if ($results.Count -gt 0) {
        Write-Host "📊 Found $($results.Count) SENSEX instruments with LC/UC data:" -ForegroundColor Yellow
        Write-Host ""
        
        # Show top 10 recent changes
        $recentChanges = $results | Where-Object { $_.InsertionSequence -gt 1 } | Select-Object -First 10
        
        if ($recentChanges.Count -gt 0) {
            Write-Host "🚨 Recent LC/UC Changes (Last 10):" -ForegroundColor Red
            Write-Host "-" * 80 -ForegroundColor Red
            
            foreach ($change in $recentChanges) {
                Write-Host "📈 $($change.TradingSymbol) - Seq: $($change.InsertionSequence)" -ForegroundColor Yellow
                Write-Host "   Strike: $($change.Strike) | LC: $($change.LowerCircuitLimit) | UC: $($change.UpperCircuitLimit)" -ForegroundColor White
                Write-Host "   Time: $($change.RecordDateTime)" -ForegroundColor Gray
                Write-Host ""
            }
        } else {
            Write-Host "✅ No recent LC/UC changes detected" -ForegroundColor Green
        }
        
        # Show summary
        $totalInstruments = $results.Count
        $withChanges = ($results | Where-Object { $_.InsertionSequence -gt 1 }).Count
        $maxSequence = ($results | Measure-Object -Property InsertionSequence -Maximum).Maximum
        
        Write-Host "📈 Summary:" -ForegroundColor Cyan
        Write-Host "   Total Instruments: $totalInstruments" -ForegroundColor White
        Write-Host "   With Changes: $withChanges" -ForegroundColor White
        Write-Host "   Max Sequence: $maxSequence" -ForegroundColor White
        
    } else {
        Write-Host "❌ No data found for Business Date: $BusinessDate" -ForegroundColor Red
    }
    
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "🔄 Run this script every few minutes to monitor changes" -ForegroundColor Green
Write-Host "📝 Changes are logged to: LCUC_Changes_$BusinessDate.log" -ForegroundColor Blue
