# LC/UC Changes Monitor for Business Date 2025-10-01
# This script monitors circuit limit changes and alerts immediately

$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"
$BusinessDate = "2025-10-01"

# Function to get current LC/UC data
function Get-CurrentLCUCData {
    $query = @"
SELECT 
    mq.InstrumentToken,
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
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query -TrustServerCertificate
}

# Function to detect changes
function Detect-LCUCChanges {
    param($CurrentData, $PreviousData)
    
    $changes = @()
    
    foreach ($current in $CurrentData) {
        $previous = $PreviousData | Where-Object { $_.InstrumentToken -eq $current.InstrumentToken }
        
        if ($previous) {
            $lcChanged = $current.LowerCircuitLimit -ne $previous.LowerCircuitLimit
            $ucChanged = $current.UpperCircuitLimit -ne $previous.UpperCircuitLimit
            
            if ($lcChanged -or $ucChanged) {
                $change = [PSCustomObject]@{
                    TradingSymbol = $current.TradingSymbol
                    InstrumentType = $current.InstrumentType
                    Strike = $current.Strike
                    OldLC = $previous.LowerCircuitLimit
                    NewLC = $current.LowerCircuitLimit
                    OldUC = $previous.UpperCircuitLimit
                    NewUC = $current.UpperCircuitLimit
                    InsertionSequence = $current.InsertionSequence
                    RecordTime = $current.RecordDateTime
                    ChangeType = if ($lcChanged -and $ucChanged) { "Both LC & UC" } 
                                elseif ($lcChanged) { "Lower Circuit" }
                                else { "Upper Circuit" }
                }
                $changes += $change
            }
        }
    }
    
    return $changes
}

# Function to send alert
function Send-Alert {
    param($Changes)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    Write-Host "`n🚨 LC/UC CHANGES DETECTED! - $timestamp" -ForegroundColor Red
    Write-Host "=" * 60 -ForegroundColor Red
    
    foreach ($change in $Changes) {
        Write-Host "`n📊 $($change.TradingSymbol) - $($change.ChangeType) Change" -ForegroundColor Yellow
        Write-Host "   Strike: $($change.Strike)" -ForegroundColor White
        Write-Host "   Lower Circuit: $($change.OldLC) → $($change.NewLC)" -ForegroundColor Cyan
        Write-Host "   Upper Circuit: $($change.OldUC) → $($change.NewUC)" -ForegroundColor Cyan
        Write-Host "   Sequence: $($change.InsertionSequence)" -ForegroundColor Gray
        Write-Host "   Time: $($change.RecordTime)" -ForegroundColor Gray
    }
    
    Write-Host "`n" + "=" * 60 -ForegroundColor Red
    
    # Also write to file for persistent logging
    $logEntry = "$timestamp - LC/UC Changes: $($Changes.Count) instruments`n"
    foreach ($change in $Changes) {
        $logEntry += "  $($change.TradingSymbol) - $($change.ChangeType): LC $($change.OldLC)→$($change.NewLC), UC $($change.OldUC)→$($change.NewUC)`n"
    }
    $logEntry += "`n"
    
    Add-Content -Path "LCUC_Changes_$BusinessDate.log" -Value $logEntry
}

# Main monitoring loop
Write-Host "🔍 Starting LC/UC Monitoring for Business Date: $BusinessDate" -ForegroundColor Green
Write-Host "⏰ Monitoring every 30 seconds..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

$previousData = @()

while ($true) {
    try {
        $currentData = Get-CurrentLCUCData
        
        if ($previousData.Count -gt 0) {
            $changes = Detect-LCUCChanges -CurrentData $currentData -PreviousData $previousData
            
            if ($changes.Count -gt 0) {
                Send-Alert -Changes $changes
            } else {
                Write-Host "$(Get-Date -Format 'HH:mm:ss') - No LC/UC changes detected" -ForegroundColor Green
            }
        } else {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') - Initial data loaded: $($currentData.Count) instruments" -ForegroundColor Blue
        }
        
        $previousData = $currentData
        Start-Sleep -Seconds 30
        
    } catch {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') - Error: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 10
    }
}
