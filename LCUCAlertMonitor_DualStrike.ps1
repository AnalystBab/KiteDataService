# LC/UC Alert Monitor with Dual Strike Display (CE & PE Side by Side)
param(
    [int]$CheckIntervalSeconds = 15
)

$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"
$BusinessDate = "2025-10-01"
$ExpiryDate = "2025-10-01"

# Function to show persistent notification for BOTH CE and PE
function Show-DualStrikeAlert {
    param($CEChange, $PEChange, $Strike)
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Create form for notification - BIGGER SIZE for dual display
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "LC/UC Change Alert - Strike $Strike"
    $form.Size = New-Object System.Drawing.Size(950, 420)
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
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::Yellow
    $titleLabel.Size = New-Object System.Drawing.Size(930, 40)
    $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
    $titleLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($titleLabel)
    
    # LEFT PANEL - CE (Call)
    if ($CEChange) {
        $cePanel = New-Object System.Windows.Forms.Panel
        $cePanel.BorderStyle = "FixedSingle"
        $cePanel.BackColor = [System.Drawing.Color]::Maroon
        $cePanel.Size = New-Object System.Drawing.Size(450, 230)
        $cePanel.Location = New-Object System.Drawing.Point(10, 60)
        $form.Controls.Add($cePanel)
        
        $ceTitle = New-Object System.Windows.Forms.Label
        $ceTitle.Text = "CALL (CE) - $Strike"
        $ceTitle.Font = New-Object System.Drawing.Font("Arial", 13, [System.Drawing.FontStyle]::Bold)
        $ceTitle.ForeColor = [System.Drawing.Color]::Lime
        $ceTitle.Size = New-Object System.Drawing.Size(430, 30)
        $ceTitle.Location = New-Object System.Drawing.Point(10, 5)
        $ceTitle.TextAlign = "MiddleCenter"
        $cePanel.Controls.Add($ceTitle)
        
        $isUCIncrease = $CEChange.NewUC -gt $CEChange.OldUC
        $ucDiff = $CEChange.NewUC - $CEChange.OldUC
        
        # Change panel color for UC increase
        if ($isUCIncrease) {
            $cePanel.BackColor = [System.Drawing.Color]::DarkGreen
            $ceTitle.ForeColor = [System.Drawing.Color]::Yellow
            $ceTitle.Text = "*** CALL (CE) - UC INCREASED! ***"
        }
        
        $ceMessage = @"
Symbol: $($CEChange.TradingSymbol)

$(if ($isUCIncrease) { "!!! UPPER CIRCUIT INCREASED !!!" } else { "$($CEChange.ChangeType) CHANGE:" })

LC: $($CEChange.OldLC) >> $($CEChange.NewLC)
UC: $($CEChange.OldUC) >> $($CEChange.NewUC)$(if ($isUCIncrease) { " +$ucDiff" } else { "" })

Close: $($CEChange.OldClose) >> $($CEChange.NewClose)
Seq: $($CEChange.InsertionSequence)
"@
        
        $ceLabel = New-Object System.Windows.Forms.Label
        $ceLabel.Text = $ceMessage
        $ceLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $ceLabel.ForeColor = if ($isUCIncrease) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::White }
        $ceLabel.Size = New-Object System.Drawing.Size(430, 190)
        $ceLabel.Location = New-Object System.Drawing.Point(10, 40)
        $ceLabel.TextAlign = "TopLeft"
        $cePanel.Controls.Add($ceLabel)
    }
    
    # RIGHT PANEL - PE (Put)
    if ($PEChange) {
        $pePanel = New-Object System.Windows.Forms.Panel
        $pePanel.BorderStyle = "FixedSingle"
        $pePanel.BackColor = [System.Drawing.Color]::Maroon
        $pePanel.Size = New-Object System.Drawing.Size(450, 230)
        $pePanel.Location = New-Object System.Drawing.Point(480, 60)
        $form.Controls.Add($pePanel)
        
        $peTitle = New-Object System.Windows.Forms.Label
        $peTitle.Text = "PUT (PE) - $Strike"
        $peTitle.Font = New-Object System.Drawing.Font("Arial", 13, [System.Drawing.FontStyle]::Bold)
        $peTitle.ForeColor = [System.Drawing.Color]::Orange
        $peTitle.Size = New-Object System.Drawing.Size(430, 30)
        $peTitle.Location = New-Object System.Drawing.Point(10, 5)
        $peTitle.TextAlign = "MiddleCenter"
        $pePanel.Controls.Add($peTitle)
        
        $isUCIncrease = $PEChange.NewUC -gt $PEChange.OldUC
        $ucDiff = $PEChange.NewUC - $PEChange.OldUC
        
        # Change panel color for UC increase
        if ($isUCIncrease) {
            $pePanel.BackColor = [System.Drawing.Color]::DarkGreen
            $peTitle.ForeColor = [System.Drawing.Color]::Yellow
            $peTitle.Text = "*** PUT (PE) - UC INCREASED! ***"
        }
        
        $peMessage = @"
Symbol: $($PEChange.TradingSymbol)

$(if ($isUCIncrease) { "!!! UPPER CIRCUIT INCREASED !!!" } else { "$($PEChange.ChangeType) CHANGE:" })

LC: $($PEChange.OldLC) >> $($PEChange.NewLC)
UC: $($PEChange.OldUC) >> $($PEChange.NewUC)$(if ($isUCIncrease) { " +$ucDiff" } else { "" })

Close: $($PEChange.OldClose) >> $($PEChange.NewClose)
Seq: $($PEChange.InsertionSequence)
"@
        
        $peLabel = New-Object System.Windows.Forms.Label
        $peLabel.Text = $peMessage
        $peLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $peLabel.ForeColor = if ($isUCIncrease) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::White }
        $peLabel.Size = New-Object System.Drawing.Size(430, 190)
        $peLabel.Location = New-Object System.Drawing.Point(10, 40)
        $peLabel.TextAlign = "TopLeft"
        $pePanel.Controls.Add($peLabel)
    }
    
    # Add timestamp
    $timeLabel = New-Object System.Windows.Forms.Label
    $timeLabel.Text = "Time: $(Get-Date -Format 'HH:mm:ss') - LIVE DUAL ALERT - Strike: $Strike"
    $timeLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $timeLabel.ForeColor = [System.Drawing.Color]::Orange
    $timeLabel.Size = New-Object System.Drawing.Size(930, 30)
    $timeLabel.Location = New-Object System.Drawing.Point(10, 360)
    $timeLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($timeLabel)
    
    # Add close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close Alert"
    $closeButton.Size = New-Object System.Drawing.Size(150, 40)
    $closeButton.Location = New-Object System.Drawing.Point(400, 305)
    $closeButton.BackColor = [System.Drawing.Color]::Orange
    $closeButton.ForeColor = [System.Drawing.Color]::Black
    $closeButton.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
    $closeButton.Add_Click({ $form.Close() })
    $form.Controls.Add($closeButton)
    
    # Play enhanced sound
    [System.Console]::Beep(1000, 200)
    Start-Sleep -Milliseconds 50
    [System.Console]::Beep(1200, 200)
    Start-Sleep -Milliseconds 50
    [System.Console]::Beep(1400, 300)
    
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
Write-Host "LC/UC Alert Monitor (DUAL STRIKE) for SENSEX 01-10-2025 Expiry" -ForegroundColor Green
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
                # Group changes by strike to show CE and PE together
                $strikeGroups = $changes | Group-Object -Property Strike
                
                foreach ($group in $strikeGroups) {
                    $strike = $group.Name
                    $ceChange = $group.Group | Where-Object { $_.InstrumentType -eq 'CE' } | Select-Object -First 1
                    $peChange = $group.Group | Where-Object { $_.InstrumentType -eq 'PE' } | Select-Object -First 1
                    
                    Show-DualStrikeAlert -CEChange $ceChange -PEChange $peChange -Strike $strike
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
