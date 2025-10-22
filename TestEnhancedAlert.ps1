# Test Enhanced Alert - Shows Upper Circuit Increase Alert

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form for notification
$form = New-Object System.Windows.Forms.Form
$form.Text = "LC/UC Change Alert - ENHANCED TEST"
$form.Size = New-Object System.Drawing.Size(550, 320)
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

# Example Upper Circuit Increase message
$detailMessage = @"
Symbol: SENSEX25OCT80200CE
Strike: 80200 | Type: CE

*** UPPER CIRCUIT INCREASED! ***

Lower Circuit: 0.05 >> 0.05
Upper Circuit: 5047.60 >> 5200.00 ^ INCREASED!

Close Price: 2479.90 >> 2550.00
Insertion Sequence: 2
"@

# Add message label with bright green color for UC increase
$messageLabel = New-Object System.Windows.Forms.Label
$messageLabel.Text = $detailMessage
$messageLabel.Font = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
$messageLabel.ForeColor = [System.Drawing.Color]::Lime  # Bright green for UC increase
$messageLabel.Size = New-Object System.Drawing.Size(530, 160)
$messageLabel.Location = New-Object System.Drawing.Point(10, 50)
$messageLabel.TextAlign = "TopLeft"
$form.Controls.Add($messageLabel)

# Add special emphasis label for UC increase
$emphasisLabel = New-Object System.Windows.Forms.Label
$emphasisLabel.Text = "!!! UPPER CIRCUIT INCREASE DETECTED! !!!"
$emphasisLabel.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$emphasisLabel.ForeColor = [System.Drawing.Color]::Lime
$emphasisLabel.BackColor = [System.Drawing.Color]::DarkRed
$emphasisLabel.Size = New-Object System.Drawing.Size(530, 25)
$emphasisLabel.Location = New-Object System.Drawing.Point(10, 210)
$emphasisLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($emphasisLabel)

# Add timestamp
$timeLabel = New-Object System.Windows.Forms.Label
$timeLabel.Text = "Time: $(Get-Date -Format 'HH:mm:ss') - ENHANCED TEST ALERT"
$timeLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$timeLabel.ForeColor = [System.Drawing.Color]::Orange
$timeLabel.Size = New-Object System.Drawing.Size(530, 25)
$timeLabel.Location = New-Object System.Drawing.Point(10, 275)
$timeLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($timeLabel)

# Add close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close Alert"
$closeButton.Size = New-Object System.Drawing.Size(120, 35)
$closeButton.Location = New-Object System.Drawing.Point(215, 245)
$closeButton.BackColor = [System.Drawing.Color]::Orange
$closeButton.ForeColor = [System.Drawing.Color]::Black
$closeButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

# Play enhanced sound for UC increase
Write-Host "Playing ENHANCED alert sound for Upper Circuit increase..." -ForegroundColor Yellow
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

Write-Host "Showing ENHANCED alert window for Upper Circuit increase..." -ForegroundColor Green
Write-Host "Notice the BRIGHT GREEN text and special emphasis!" -ForegroundColor Cyan
Write-Host ""

# Show form (modal - blocks until closed)
$form.ShowDialog()

Write-Host ""
Write-Host "Enhanced test complete! You saw the bright green UC increase alert." -ForegroundColor Green
Write-Host "This is how you'll be notified for REAL Upper Circuit increases!" -ForegroundColor Yellow
