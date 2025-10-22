# Continuous LC/UC Monitor with Immediate Alerts for SENSEX 01-10-2025 Expiry
param(
    [int]$CheckIntervalSeconds = 30,
    [switch]$UseSoundAlerts = $true,
    [switch]$UsePopupAlerts = $true,
    [switch]$UseFileLogging = $true
)

$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"
$BusinessDate = "2025-10-01"
$ExpiryDate = "2025-10-01"

# Function to play alert sound
function Play-AlertSound {
    if ($UseSoundAlerts) {
        try {
            # Play system beep sound
            [System.Console]::Beep(800, 500)
            Start-Sleep -Milliseconds 200
            [System.Console]::Beep(1000, 500)
            Start-Sleep -Milliseconds 200
            [System.Console]::Beep(800, 500)
        } catch {
            # Fallback to simple beep
            Write-Host "`a" -NoNewline
        }
    }
}

# Function to show popup alert
function Show-PopupAlert {
    param($Message)
    
    if ($UsePopupAlerts) {
        try {
            Add-Type -AssemblyName System.Windows.Forms
            $popup = New-Object System.Windows.Forms.NotifyIcon
            $popup.Icon = [System.Drawing.SystemIcons]::Warning
            $popup.Visible = $true
            $popup.ShowBalloonTip(10000, "LC/UC Alert", $Message, [System.Windows.Forms.ToolTipIcon]::Warning)
            Start-Sleep -Seconds 2
            $popup.Dispose()
        } catch {
            # Fallback to console alert
            Write-Host "`n🚨 ALERT: $Message" -ForegroundColor Red -BackgroundColor Yellow
        }
    }
}

# Function to log to file
function Log-ToFile {
    param($Message)
    
    if ($UseFileLogging) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] $Message"
        Add-Content -Path "LCUC_Alerts_$BusinessDate.log" -Value $logEntry
    }
}

# Function to get current SENSEX data
function Get-CurrentSENSEXData {
    $query = @"
SELECT 
    mq.InstrumentToken,
    i.TradingSymbol,
    i.InstrumentType,
    i.Strike,
    mq.LowerCircuitLimit,
    mq.UpperCircuitLimit,
    mq.InsertionSequence,
    mq.RecordDateTime,
    mq.ClosePrice,
    mq.LastPrice
FROM MarketQuotes mq
INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
WHERE mq.BusinessDate = '$BusinessDate'
    AND i.TradingSymbol LIKE 'SENSEX%'
    AND i.TradingSymbol NOT LIKE 'SENSEX50%'
    AND CAST(i.Expiry AS DATE) = '$ExpiryDate'
    AND (mq.LowerCircuitLimit > 0 OR mq.UpperCircuitLimit > 0)
ORDER BY mq.InsertionSequence DESC, mq.RecordDateTime DESC
"@
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query -TrustServerCertificate
}

# Function to detect changes
function Detect-Changes {
    param($CurrentData, $PreviousData)
    
    $changes = @()
    
    # Create hashtable for quick lookup
    $previousHash = @{}
    foreach ($item in $PreviousData) {
        $key = "$($item.InstrumentToken)"
        $previousHash[$key] = $item
    }
    
    foreach ($current in $CurrentData) {
        $key = "$($current.InstrumentToken)"
        $previous = $previousHash[$key]
        
        if ($previous -and $current.InsertionSequence -gt $previous.InsertionSequence) {
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
                    OldClose = $previous.ClosePrice
                    NewClose = $current.ClosePrice
                    OldLastPrice = $previous.LastPrice
                    NewLastPrice = $current.LastPrice
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

# Function to send immediate alerts
function Send-ImmediateAlert {
    param($Changes)
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Play sound alert
    Play-AlertSound
    
    # Console alert
    Write-Host "`n" + "=" * 80 -ForegroundColor Red
    Write-Host "🚨🚨🚨 IMMEDIATE LC/UC ALERT - $timestamp 🚨🚨🚨" -ForegroundColor Red -BackgroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Red
    
    foreach ($change in $Changes) {
        Write-Host "`n📊 $($change.TradingSymbol)" -ForegroundColor Yellow
        Write-Host "   Strike: $($change.Strike) | Type: $($change.InstrumentType)" -ForegroundColor White
        Write-Host "   $($change.ChangeType) CHANGE DETECTED!" -ForegroundColor Red
        Write-Host "   Lower Circuit: $($change.OldLC) → $($change.NewLC)" -ForegroundColor Cyan
        Write-Host "   Upper Circuit: $($change.OldUC) → $($change.NewUC)" -ForegroundColor Cyan
        Write-Host "   Close Price: $($change.OldClose) → $($change.NewClose)" -ForegroundColor Green
        Write-Host "   Last Price: $($change.OldLastPrice) → $($change.NewLastPrice)" -ForegroundColor Green
        Write-Host "   Sequence: $($change.InsertionSequence) | Time: $($change.RecordTime)" -ForegroundColor Gray
        
        # Show popup for each change
        $alertMessage = "$($change.TradingSymbol) - $($change.ChangeType) Change`nLC: $($change.OldLC)→$($change.NewLC) | UC: $($change.OldUC)→$($change.NewUC)"
        Show-PopupAlert -Message $alertMessage
        
        # Log to file
        $logMessage = "CHANGE: $($change.TradingSymbol) - $($change.ChangeType) | LC: $($change.OldLC)→$($change.NewLC) | UC: $($change.OldUC)→$($change.NewUC) | Seq: $($change.InsertionSequence)"
        Log-ToFile -Message $logMessage
    }
    
    Write-Host "`n" + "=" * 80 -ForegroundColor Red
    Write-Host "Total Changes: $($Changes.Count)" -ForegroundColor Yellow
    Write-Host "=" * 80 -ForegroundColor Red
    Write-Host ""
}

# Function to show status
function Show-Status {
    param($CurrentData, $ChangesCount)
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    $totalInstruments = $CurrentData.Count
    $withChanges = ($CurrentData | Where-Object { $_.InsertionSequence -gt 1 }).Count
    $maxSequence = if ($CurrentData.Count -gt 0) { ($CurrentData | Measure-Object -Property InsertionSequence -Maximum).Maximum } else { 0 }
    
    Write-Host "[$timestamp] Monitoring... | Instruments: $totalInstruments | Changes: $withChanges | MaxSeq: $maxSequence | New Changes: $ChangesCount" -ForegroundColor Green
}

# Main monitoring loop
Clear-Host
Write-Host "🔍 Starting Continuous LC/UC Monitor for SENSEX 01-10-2025 Expiry" -ForegroundColor Green
Write-Host "📅 Business Date: $BusinessDate" -ForegroundColor Blue
Write-Host "⏰ Check Interval: $CheckIntervalSeconds seconds" -ForegroundColor Blue
Write-Host "🔊 Sound Alerts: $UseSoundAlerts" -ForegroundColor Blue
Write-Host "💬 Popup Alerts: $UsePopupAlerts" -ForegroundColor Blue
Write-Host "📝 File Logging: $UseFileLogging" -ForegroundColor Blue
Write-Host ""
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

$previousData = @()
$alertCount = 0

while ($true) {
    try {
        $currentData = Get-CurrentSENSEXData
        $changes = @()
        
        if ($previousData.Count -gt 0) {
            $changes = Detect-Changes -CurrentData $currentData -PreviousData $previousData
            
            if ($changes.Count -gt 0) {
                $alertCount++
                Send-ImmediateAlert -Changes $changes
            }
        } else {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Initial data loaded: $($currentData.Count) SENSEX instruments" -ForegroundColor Blue
            Log-ToFile -Message "Monitoring started - Initial load: $($currentData.Count) instruments"
        }
        
        Show-Status -CurrentData $currentData -ChangesCount $changes.Count
        $previousData = $currentData
        
        Start-Sleep -Seconds $CheckIntervalSeconds
        
    } catch {
        $errorMsg = "Error: $($_.Exception.Message)"
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $errorMsg" -ForegroundColor Red
        Log-ToFile -Message "ERROR: $errorMsg"
        Start-Sleep -Seconds 10
    }
}
