# NIFTY 24850 CE & PE LC/UC Alert Monitor (Based on existing DualStrike script)
param(
    [int]$CheckIntervalSeconds = 30  # Check every 30 seconds
)

$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"
$BusinessDate = "2025-10-03"  # Current business date
$ExpiryDate = "2025-10-28"    # October 28, 2025 expiry
$TargetStrike = 24850         # Your target strike

# Function to show persistent notification for BOTH CE and PE
function Show-NIFTY24850DualAlert {
    param($CEChange, $PEChange, $Strike)
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    # Create form for notification - BIGGER SIZE for dual display
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "NIFTY 24850 LC/UC Change Alert"
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
    $titleLabel.Text = "*** NIFTY 24850 LC/UC CHANGE DETECTED! ***"
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
        $cePanel.BackColor = [System.Drawing.Color]::DarkRed  # Default red
        $cePanel.Size = New-Object System.Drawing.Size(450, 250)
        $cePanel.Location = New-Object System.Drawing.Point(10, 50)
        $form.Controls.Add($cePanel)
        
        $ceTitle = New-Object System.Windows.Forms.Label
        $ceTitle.Text = "CALL (CE) - Strike $($CEChange.Strike)"
        $ceTitle.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $ceTitle.ForeColor = [System.Drawing.Color]::Lime
        $ceTitle.Size = New-Object System.Drawing.Size(430, 30)
        $ceTitle.Location = New-Object System.Drawing.Point(10, 10)
        $ceTitle.TextAlign = "MiddleCenter"
        $cePanel.Controls.Add($ceTitle)
        
        # Check for UC increase - GREEN background for UC increase
        $isUCIncrease = $CEChange.NewUC -gt $CEChange.OldUC
        $ucDiff = $CEChange.NewUC - $CEChange.OldUC
        
        if ($isUCIncrease) {
            $cePanel.BackColor = [System.Drawing.Color]::DarkGreen  # GREEN for UC increase
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
Time: $($CEChange.RecordTime)
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
        $pePanel.BackColor = [System.Drawing.Color]::DarkRed  # Default red
        $pePanel.Size = New-Object System.Drawing.Size(450, 250)
        $pePanel.Location = New-Object System.Drawing.Point(480, 50)
        $form.Controls.Add($pePanel)
        
        $peTitle = New-Object System.Windows.Forms.Label
        $peTitle.Text = "PUT (PE) - Strike $($PEChange.Strike)"
        $peTitle.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $peTitle.ForeColor = [System.Drawing.Color]::Orange
        $peTitle.Size = New-Object System.Drawing.Size(430, 30)
        $peTitle.Location = New-Object System.Drawing.Point(10, 10)
        $peTitle.TextAlign = "MiddleCenter"
        $pePanel.Controls.Add($peTitle)
        
        # Check for UC increase - GREEN background for UC increase
        $isUCIncrease = $PEChange.NewUC -gt $PEChange.OldUC
        $ucDiff = $PEChange.NewUC - $PEChange.OldUC
        
        if ($isUCIncrease) {
            $pePanel.BackColor = [System.Drawing.Color]::DarkGreen  # GREEN for UC increase
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
Time: $($PEChange.RecordTime)
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
    
    # Time label at bottom
    $timeLabel = New-Object System.Windows.Forms.Label
    $timeLabel.Text = "Alert Time: $(Get-Date -Format 'HH:mm:ss') - NIFTY 24850 MONITOR - Strike: $Strike"
    $timeLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $timeLabel.ForeColor = [System.Drawing.Color]::Cyan
    $timeLabel.Size = New-Object System.Drawing.Size(930, 30)
    $timeLabel.Location = New-Object System.Drawing.Point(10, 360)
    $timeLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($timeLabel)
    
    # Close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close Alert"
    $closeButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $closeButton.Size = New-Object System.Drawing.Size(150, 40)
    $closeButton.Location = New-Object System.Drawing.Point(400, 305)
    $closeButton.BackColor = [System.Drawing.Color]::Red
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.Add_Click({ $form.Close() })
    $form.Controls.Add($closeButton)
    
    # Play enhanced sound based on change type
    if ($CEChange -and ($CEChange.NewUC -gt $CEChange.OldUC)) {
        # UC increase sound - 6 beeps
        for ($i = 1; $i -le 6; $i++) {
            [Console]::Beep(1000, 200)
            Start-Sleep -Milliseconds 100
        }
    }
    if ($PEChange -and ($PEChange.NewUC -gt $PEChange.OldUC)) {
        # UC increase sound - 6 beeps
        for ($i = 1; $i -le 6; $i++) {
            [Console]::Beep(1200, 200)
            Start-Sleep -Milliseconds 100
        }
    }
    
    # Show the form (modal - blocks until closed)
    $form.ShowDialog()
}

# Function to get current NIFTY 24850 data
function Get-CurrentNIFTY24850Data {
    $query = @"
    SELECT 
        mq.TradingSymbol,
        mq.Strike,
        mq.OptionType as InstrumentType,
        mq.LowerCircuitLimit,
        mq.UpperCircuitLimit,
        mq.ClosePrice,
        mq.InsertionSequence,
        mq.RecordDateTime,
        mq.BusinessDate
    FROM MarketQuotes mq
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
    WHERE i.TradingSymbol LIKE 'NIFTY%'
        AND i.Strike = $TargetStrike
        AND CAST(i.Expiry AS DATE) = '$ExpiryDate'
        AND mq.InsertionSequence = (
            SELECT MAX(mq2.InsertionSequence) 
            FROM MarketQuotes mq2 
            WHERE mq2.InstrumentToken = mq.InstrumentToken 
                AND mq2.BusinessDate = mq.BusinessDate
        )
    ORDER BY mq.OptionType, mq.InsertionSequence DESC
"@
    
    return Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query -TrustServerCertificate
}

# Function to detect changes between current and previous data
function Detect-Changes {
    param($CurrentData, $PreviousData)
    
    $changes = @()
    
    foreach ($current in $CurrentData) {
        $previous = $PreviousData | Where-Object { 
            $_.TradingSymbol -eq $current.TradingSymbol -and 
            $_.InstrumentType -eq $current.InstrumentType 
        } | Select-Object -First 1
        
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
Write-Host "NIFTY 24850 CE & PE LC/UC Alert Monitor" -ForegroundColor Green
Write-Host "Business Date: $BusinessDate" -ForegroundColor Blue
Write-Host "Expiry Date: $ExpiryDate" -ForegroundColor Blue
Write-Host "Target Strike: $TargetStrike" -ForegroundColor Blue
Write-Host "Check Interval: $CheckIntervalSeconds seconds" -ForegroundColor Blue
Write-Host ""
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

$previousData = @()

while ($true) {
    try {
        $currentData = Get-CurrentNIFTY24850Data
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
                    
                    Show-NIFTY24850DualAlert -CEChange $ceChange -PEChange $peChange -Strike $strike
                }
            }
        } else {
            Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Initial data loaded for NIFTY 24850" -ForegroundColor Blue
        }
        
        $timestamp = Get-Date -Format "HH:mm:ss"
        $totalInstruments = $currentData.Count
        $withChanges = ($currentData | Where-Object { $_.InsertionSequence -gt 1 }).Count
        $maxSequence = if ($currentData.Count -gt 0) { ($currentData | Measure-Object -Property InsertionSequence -Maximum).Maximum } else { 0 }
        
        Write-Host "[$timestamp] Monitoring NIFTY 24850... | Instruments: $totalInstruments | Changes: $withChanges | MaxSeq: $maxSequence | New Changes: $($changes.Count)" -ForegroundColor Green
        
        $previousData = $currentData
        Start-Sleep -Seconds $CheckIntervalSeconds
        
    } catch {
        $errorMsg = "Error: $($_.Exception.Message)"
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $errorMsg" -ForegroundColor Red
        Start-Sleep -Seconds 10
    }
}
