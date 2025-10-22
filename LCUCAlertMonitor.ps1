# LC/UC Alert Monitor with Persistent Notifications
param(
    [int]$CheckIntervalSeconds = 15
)

$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"
$BusinessDate = "2025-10-01"
$ExpiryDate = "2025-10-01"

# Function to show persistent notification
function Show-PersistentAlert {
    param($Change)
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Create form for notification - BIGGER SIZE
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "LC/UC Change Alert - LIVE"
    $form.Size = New-Object System.Drawing.Size(550, 300)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    
    # Make it red and attention-grabbing
    $form.BackColor = [System.Drawing.Color]::DarkRed
    $form.ForeColor = [System.Drawing.Color]::White
    
    # Add title label
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "*** LC/UC CHANGE DETECTED! ***"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::Yellow
    $titleLabel.Size = New-Object System.Drawing.Size(530, 35)
    $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
    $titleLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($titleLabel)
    
    # Determine if it's UC increase (most important)
    $isUCIncrease = $Change.NewUC -gt $Change.OldUC
    $isLCIncrease = $Change.NewLC -gt $Change.OldLC
    
    # Create detailed message with emphasis
    if ($isUCIncrease) {
        $detailMessage = @"
Symbol: $($Change.TradingSymbol)
Strike: $($Change.Strike) | Type: $($Change.InstrumentType)

*** UPPER CIRCUIT INCREASED! ***

Lower Circuit: $($Change.OldLC) >> $($Change.NewLC)
Upper Circuit: $($Change.OldUC) >> $($Change.NewUC) ^ INCREASED!

Close Price: $($Change.OldClose) >> $($Change.NewClose)
Insertion Sequence: $($Change.InsertionSequence)
"@
    } elseif ($isLCIncrease) {
        $detailMessage = @"
Symbol: $($Change.TradingSymbol)
Strike: $($Change.Strike) | Type: $($Change.InstrumentType)

*** LOWER CIRCUIT INCREASED! ***

Lower Circuit: $($Change.OldLC) >> $($Change.NewLC) ^ INCREASED!
Upper Circuit: $($Change.OldUC) >> $($Change.NewUC)

Close Price: $($Change.OldClose) >> $($Change.NewClose)
Insertion Sequence: $($Change.InsertionSequence)
"@
    } else {
        $detailMessage = @"
Symbol: $($Change.TradingSymbol)
Strike: $($Change.Strike) | Type: $($Change.InstrumentType)

$($Change.ChangeType) CHANGE:

Lower Circuit: $($Change.OldLC) >> $($Change.NewLC)
Upper Circuit: $($Change.OldUC) >> $($Change.NewUC)

Close Price: $($Change.OldClose) >> $($Change.NewClose)
Insertion Sequence: $($Change.InsertionSequence)
"@
    }
    
    # Add message label with enhanced styling
    $messageLabel = New-Object System.Windows.Forms.Label
    $messageLabel.Text = $detailMessage
    $messageLabel.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
    
    # Color coding based on change type
    if ($isUCIncrease) {
        $messageLabel.ForeColor = [System.Drawing.Color]::Lime  # Bright green for UC increase
    } elseif ($isLCIncrease) {
        $messageLabel.ForeColor = [System.Drawing.Color]::Yellow  # Yellow for LC increase
    } else {
        $messageLabel.ForeColor = [System.Drawing.Color]::White  # White for other changes
    }
    
    $messageLabel.Size = New-Object System.Drawing.Size(530, 160)
    $messageLabel.Location = New-Object System.Drawing.Point(10, 50)
    $messageLabel.TextAlign = "TopLeft"
    $form.Controls.Add($messageLabel)
    
    # Add special emphasis for UC increase
    if ($isUCIncrease) {
        $emphasisLabel = New-Object System.Windows.Forms.Label
        $emphasisLabel.Text = "!!! UPPER CIRCUIT INCREASE DETECTED! !!!"
        $emphasisLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $emphasisLabel.ForeColor = [System.Drawing.Color]::Lime
        $emphasisLabel.BackColor = [System.Drawing.Color]::DarkRed
        $emphasisLabel.Size = New-Object System.Drawing.Size(530, 25)
        $emphasisLabel.Location = New-Object System.Drawing.Point(10, 210)
        $emphasisLabel.TextAlign = "MiddleCenter"
        $form.Controls.Add($emphasisLabel)
        
        # Adjust form size for emphasis label
        $form.Size = New-Object System.Drawing.Size(550, 320)
        
        # Move close button down
        $closeButton.Location = New-Object System.Drawing.Point(215, 245)
    }
    
    # Add timestamp
    $timeLabel = New-Object System.Windows.Forms.Label
    $timeLabel.Text = "Time: $(Get-Date -Format 'HH:mm:ss') - LIVE ALERT"
    $timeLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $timeLabel.ForeColor = [System.Drawing.Color]::Orange
    $timeLabel.Size = New-Object System.Drawing.Size(530, 25)
    $timeLabel.Location = New-Object System.Drawing.Point(10, 215)
    $timeLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($timeLabel)
    
    # Add close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close Alert"
    $closeButton.Size = New-Object System.Drawing.Size(120, 35)
    $closeButton.Location = New-Object System.Drawing.Point(215, 175)
    $closeButton.BackColor = [System.Drawing.Color]::Orange
    $closeButton.ForeColor = [System.Drawing.Color]::Black
    $closeButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $closeButton.Add_Click({ $form.Close() })
    $form.Controls.Add($closeButton)
    
    # Play enhanced sound based on change type
    if ($isUCIncrease) {
        # Special sound for UC increase - more urgent
        [System.Console]::Beep(1000, 200)
        Start-Sleep -Milliseconds 50
        [System.Console]::Beep(1200, 200)
        Start-Sleep -Milliseconds 50
        [System.Console]::Beep(1400, 300)
        Start-Sleep -Milliseconds 100
        [System.Console]::Beep(1000, 200)
        Start-Sleep -Milliseconds 50
        [System.Console]::Beep(1200, 200)
        Start-Sleep -Milliseconds 50
        [System.Console]::Beep(1400, 300)
    } else {
        # Standard sound for other changes
        [System.Console]::Beep(800, 300)
        Start-Sleep -Milliseconds 100
        [System.Console]::Beep(1000, 300)
        Start-Sleep -Milliseconds 100
        [System.Console]::Beep(800, 300)
    }
    
    # Show form (modal - blocks until closed)
    $form.ShowDialog()
}

# Function to get current SENSEX data
function Get-CurrentSENSEXData {
    $query = "SELECT mq.InstrumentToken, i.TradingSymbol, i.InstrumentType, i.Strike, mq.LowerCircuitLimit, mq.UpperCircuitLimit, mq.InsertionSequence, mq.RecordDateTime, mq.ClosePrice, mq.LastPrice FROM MarketQuotes mq INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken WHERE mq.BusinessDate = '$BusinessDate' AND i.TradingSymbol LIKE 'SENSEX%' AND i.TradingSymbol NOT LIKE 'SENSEX50%' AND CAST(i.Expiry AS DATE) = '$ExpiryDate' AND (mq.LowerCircuitLimit > 0 OR mq.UpperCircuitLimit > 0) ORDER BY mq.InsertionSequence DESC, mq.RecordDateTime DESC"
    
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
                    InsertionSequence = $current.InsertionSequence
                    RecordTime = $current.RecordDateTime
                    ChangeType = if ($lcChanged -and $ucChanged) { "Both LC & UC" } elseif ($lcChanged) { "Lower Circuit" } else { "Upper Circuit" }
                }
                $changes += $change
            }
        }
    }
    
    return $changes
}

# Main monitoring loop
Clear-Host
Write-Host "LC/UC Alert Monitor for SENSEX 01-10-2025 Expiry" -ForegroundColor Green
Write-Host "Business Date: $BusinessDate" -ForegroundColor Blue
Write-Host "Check Interval: $CheckIntervalSeconds seconds" -ForegroundColor Blue
Write-Host ""
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

$previousData = @()

while ($true) {
    try {
        $currentData = Get-CurrentSENSEXData
        $changes = @()
        
        if ($previousData.Count -gt 0) {
            $changes = Detect-Changes -CurrentData $currentData -PreviousData $previousData
            
            if ($changes.Count -gt 0) {
                foreach ($change in $changes) {
                    Show-PersistentAlert -Change $change
                }
            }
        } else {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Initial data loaded: $($currentData.Count) SENSEX instruments" -ForegroundColor Blue
        }
        
        $timestamp = Get-Date -Format "HH:mm:ss"
        $totalInstruments = $currentData.Count
        $withChanges = ($currentData | Where-Object { $_.InsertionSequence -gt 1 }).Count
        $maxSequence = if ($currentData.Count -gt 0) { ($currentData | Measure-Object -Property InsertionSequence -Maximum).Maximum } else { 0 }
        
        Write-Host "[$timestamp] Monitoring... | Instruments: $totalInstruments | Changes: $withChanges | MaxSeq: $maxSequence | New Changes: $($changes.Count)" -ForegroundColor Green
        
        $previousData = $currentData
        Start-Sleep -Seconds $CheckIntervalSeconds
        
    } catch {
        $errorMsg = "Error: $($_.Exception.Message)"
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $errorMsg" -ForegroundColor Red
        Start-Sleep -Seconds 10
    }
}
