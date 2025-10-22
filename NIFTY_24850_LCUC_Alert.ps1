# NIFTY 24850 CE & PE LC/UC Change Alert Monitor
# Monitors specific strikes for LC/UC changes and shows persistent alerts

param(
    [int]$RefreshIntervalSeconds = 30  # Check every 30 seconds
)

# Database connection parameters
$ServerInstance = "localhost"
$DatabaseName = "KiteMarketData"

# Target strikes to monitor
$TargetStrikes = @(24850)
$TargetExpiry = "2025-10-28"

Write-Host "🚨 NIFTY 24850 CE & PE LC/UC ALERT MONITOR STARTED" -ForegroundColor Red
Write-Host "📊 Monitoring Strikes: $($TargetStrikes -join ', ')" -ForegroundColor Yellow
Write-Host "📅 Expiry: $TargetExpiry" -ForegroundColor Yellow
Write-Host "⏱️ Refresh Interval: $RefreshIntervalSeconds seconds" -ForegroundColor Yellow
Write-Host "🔄 Press Ctrl+C to stop monitoring" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# Function to show persistent alert window
function Show-NIFTY24850Alert {
    param($CEChange, $PEChange)
    
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "NIFTY 24850 LC/UC CHANGE ALERT"
    $form.Size = New-Object System.Drawing.Size(800, 450)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.BackColor = [System.Drawing.Color]::Black
    
    # Title
    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = "*** NIFTY 24850 LC/UC CHANGE DETECTED! ***"
    $titleLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::Lime
    $titleLabel.Size = New-Object System.Drawing.Size(780, 40)
    $titleLabel.Location = New-Object System.Drawing.Point(10, 10)
    $titleLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($titleLabel)
    
    # LEFT PANEL - CE (Call)
    if ($CEChange) {
        $cePanel = New-Object System.Windows.Forms.Panel
        $cePanel.Size = New-Object System.Drawing.Size(380, 300)
        $cePanel.Location = New-Object System.Drawing.Point(10, 60)
        $cePanel.BackColor = [System.Drawing.Color]::DarkRed
        $form.Controls.Add($cePanel)
        
        $ceTitle = New-Object System.Windows.Forms.Label
        $ceTitle.Text = "CALL (CE) - Strike 24850"
        $ceTitle.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $ceTitle.ForeColor = [System.Drawing.Color]::Lime
        $ceTitle.Size = New-Object System.Drawing.Size(360, 30)
        $ceTitle.Location = New-Object System.Drawing.Point(10, 10)
        $ceTitle.TextAlign = "MiddleCenter"
        $cePanel.Controls.Add($ceTitle)
        
        $isUCIncrease = $CEChange.NewUC -gt $CEChange.OldUC
        $ucDiff = $CEChange.NewUC - $CEChange.OldUC
        
        if ($isUCIncrease) {
            $cePanel.BackColor = [System.Drawing.Color]::DarkGreen
            $ceTitle.ForeColor = [System.Drawing.Color]::Yellow
            $ceTitle.Text = "*** CALL (CE) - UC INCREASED! ***"
        }
        
        $ceMessage = @"
Symbol: $($CEChange.TradingSymbol)

$(if ($isUCIncrease) { "!!! UPPER CIRCUIT INCREASED !!!" } else { "LC/UC CHANGE:" })

LC: $($CEChange.OldLC) >> $($CEChange.NewLC)
UC: $($CEChange.OldUC) >> $($CEChange.NewUC)$(if ($isUCIncrease) { " +$ucDiff" } else { "" })

Close: $($CEChange.OldClose) >> $($CEChange.NewClose)
Seq: $($CEChange.InsertionSequence)
Time: $($CEChange.RecordDateTime)
"@
        
        $ceLabel = New-Object System.Windows.Forms.Label
        $ceLabel.Text = $ceMessage
        $ceLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $ceLabel.ForeColor = if ($isUCIncrease) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::White }
        $ceLabel.Size = New-Object System.Drawing.Size(360, 250)
        $ceLabel.Location = New-Object System.Drawing.Point(10, 50)
        $ceLabel.TextAlign = "TopLeft"
        $cePanel.Controls.Add($ceLabel)
    }
    
    # RIGHT PANEL - PE (Put)
    if ($PEChange) {
        $pePanel = New-Object System.Windows.Forms.Panel
        $pePanel.Size = New-Object System.Drawing.Size(380, 300)
        $pePanel.Location = New-Object System.Drawing.Point(400, 60)
        $pePanel.BackColor = [System.Drawing.Color]::DarkRed
        $form.Controls.Add($pePanel)
        
        $peTitle = New-Object System.Windows.Forms.Label
        $peTitle.Text = "PUT (PE) - Strike 24850"
        $peTitle.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $peTitle.ForeColor = [System.Drawing.Color]::Orange
        $peTitle.Size = New-Object System.Drawing.Size(360, 30)
        $peTitle.Location = New-Object System.Drawing.Point(10, 10)
        $peTitle.TextAlign = "MiddleCenter"
        $pePanel.Controls.Add($peTitle)
        
        $isUCIncrease = $PEChange.NewUC -gt $PEChange.OldUC
        $ucDiff = $PEChange.NewUC - $PEChange.OldUC
        
        if ($isUCIncrease) {
            $pePanel.BackColor = [System.Drawing.Color]::DarkGreen
            $peTitle.ForeColor = [System.Drawing.Color]::Yellow
            $peTitle.Text = "*** PUT (PE) - UC INCREASED! ***"
        }
        
        $peMessage = @"
Symbol: $($PEChange.TradingSymbol)

$(if ($isUCIncrease) { "!!! UPPER CIRCUIT INCREASED !!!" } else { "LC/UC CHANGE:" })

LC: $($PEChange.OldLC) >> $($PEChange.NewLC)
UC: $($PEChange.OldUC) >> $($PEChange.NewUC)$(if ($isUCIncrease) { " +$ucDiff" } else { "" })

Close: $($PEChange.OldClose) >> $($PEChange.NewClose)
Seq: $($PEChange.InsertionSequence)
Time: $($PEChange.RecordDateTime)
"@
        
        $peLabel = New-Object System.Windows.Forms.Label
        $peLabel.Text = $peMessage
        $peLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
        $peLabel.ForeColor = if ($isUCIncrease) { [System.Drawing.Color]::Yellow } else { [System.Drawing.Color]::White }
        $peLabel.Size = New-Object System.Drawing.Size(360, 250)
        $peLabel.Location = New-Object System.Drawing.Point(10, 50)
        $peLabel.TextAlign = "TopLeft"
        $pePanel.Controls.Add($peLabel)
    }
    
    # Time label
    $timeLabel = New-Object System.Windows.Forms.Label
    $timeLabel.Text = "Alert Time: $(Get-Date -Format 'HH:mm:ss') - NIFTY 24850 MONITOR"
    $timeLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $timeLabel.ForeColor = [System.Drawing.Color]::Cyan
    $timeLabel.Size = New-Object System.Drawing.Size(780, 25)
    $timeLabel.Location = New-Object System.Drawing.Point(10, 380)
    $timeLabel.TextAlign = "MiddleCenter"
    $form.Controls.Add($timeLabel)
    
    # Close button
    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close Alert"
    $closeButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
    $closeButton.Size = New-Object System.Drawing.Size(150, 40)
    $closeButton.Location = New-Object System.Drawing.Point(325, 410)
    $closeButton.BackColor = [System.Drawing.Color]::Red
    $closeButton.ForeColor = [System.Drawing.Color]::White
    $closeButton.Add_Click({ $form.Close() })
    $form.Controls.Add($closeButton)
    
    # Play sound for UC increases
    if ($CEChange -and ($CEChange.NewUC -gt $CEChange.OldUC)) {
        for ($i = 1; $i -le 6; $i++) {
            [Console]::Beep(1000, 200)
            Start-Sleep -Milliseconds 100
        }
    }
    if ($PEChange -and ($PEChange.NewUC -gt $PEChange.OldUC)) {
        for ($i = 1; $i -le 6; $i++) {
            [Console]::Beep(1200, 200)
            Start-Sleep -Milliseconds 100
        }
    }
    
    $form.ShowDialog()
}

# Store previous values for comparison
$previousValues = @{}

try {
    while ($true) {
        $currentTime = Get-Date -Format "HH:mm:ss"
        Write-Host "[$currentTime] Checking NIFTY 24850 LC/UC changes..." -ForegroundColor Cyan
        
        try {
            # Query for NIFTY 24850 CE and PE with latest InsertionSequence
            $query = @"
            SELECT 
                mq.TradingSymbol,
                mq.Strike,
                mq.OptionType,
                mq.LowerCircuitLimit,
                mq.UpperCircuitLimit,
                mq.ClosePrice,
                mq.InsertionSequence,
                mq.RecordDateTime,
                mq.BusinessDate
            FROM MarketQuotes mq
            INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
            WHERE i.TradingSymbol LIKE 'NIFTY%'
                AND i.Strike = 24850
                AND CAST(i.Expiry AS DATE) = '$TargetExpiry'
                AND mq.InsertionSequence = (
                    SELECT MAX(mq2.InsertionSequence) 
                    FROM MarketQuotes mq2 
                    WHERE mq2.InstrumentToken = mq.InstrumentToken 
                        AND mq2.BusinessDate = mq.BusinessDate
                )
            ORDER BY mq.OptionType, mq.InsertionSequence DESC
"@
            
            $currentData = Invoke-Sqlcmd -ServerInstance $ServerInstance -Database $DatabaseName -Query $query -TrustServerCertificate
            
            $changesDetected = @()
            
            foreach ($row in $currentData) {
                $symbol = $row.TradingSymbol
                $optionType = $row.OptionType
                $strike = $row.Strike
                
                # Create unique key for this instrument
                $key = "$symbol-$strike-$optionType"
                
                $currentLC = [decimal]$row.LowerCircuitLimit
                $currentUC = [decimal]$row.UpperCircuitLimit
                $currentClose = [decimal]$row.ClosePrice
                $currentSeq = $row.InsertionSequence
                $recordTime = $row.RecordDateTime
                
                # Check if we have previous values
                if ($previousValues.ContainsKey($key)) {
                    $prev = $previousValues[$key]
                    
                    # Check for LC/UC changes
                    if ($prev.LC -ne $currentLC -or $prev.UC -ne $currentUC) {
                        $change = [PSCustomObject]@{
                            TradingSymbol = $symbol
                            Strike = $strike
                            OptionType = $optionType
                            OldLC = $prev.LC
                            NewLC = $currentLC
                            OldUC = $prev.UC
                            NewUC = $currentUC
                            OldClose = $prev.Close
                            NewClose = $currentClose
                            InsertionSequence = $currentSeq
                            RecordDateTime = $recordTime
                        }
                        
                        $changesDetected += $change
                        
                        Write-Host "🚨 LC/UC CHANGE DETECTED for $symbol ($optionType):" -ForegroundColor Red
                        Write-Host "   LC: $($prev.LC) → $currentLC" -ForegroundColor Yellow
                        Write-Host "   UC: $($prev.UC) → $currentUC" -ForegroundColor Yellow
                        Write-Host "   Close: $($prev.Close) → $currentClose" -ForegroundColor Yellow
                        Write-Host "   Seq: $currentSeq at $recordTime" -ForegroundColor Yellow
                    }
                }
                
                # Update previous values
                $previousValues[$key] = @{
                    LC = $currentLC
                    UC = $currentUC
                    Close = $currentClose
                    Seq = $currentSeq
                    Time = $recordTime
                }
            }
            
            # Show alert if changes detected
            if ($changesDetected.Count -gt 0) {
                $ceChange = $changesDetected | Where-Object { $_.OptionType -eq "CE" } | Select-Object -First 1
                $peChange = $changesDetected | Where-Object { $_.OptionType -eq "PE" } | Select-Object -First 1
                
                Write-Host "🚨 SHOWING ALERT for NIFTY 24850 LC/UC CHANGES!" -ForegroundColor Red
                Show-NIFTY24850Alert -CEChange $ceChange -PEChange $peChange
                
                Write-Host "✅ Alert displayed. Continuing monitoring..." -ForegroundColor Green
            } else {
                Write-Host "✅ No LC/UC changes detected for NIFTY 24850" -ForegroundColor Green
            }
            
        } catch {
            Write-Host "❌ Error checking database: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "⏳ Waiting $RefreshIntervalSeconds seconds for next check..." -ForegroundColor Gray
        Write-Host "-" * 60 -ForegroundColor Gray
        
        Start-Sleep -Seconds $RefreshIntervalSeconds
    }
} catch {
    Write-Host "❌ Monitoring stopped: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Write-Host "🛑 NIFTY 24850 LC/UC Alert Monitor stopped." -ForegroundColor Yellow
}
