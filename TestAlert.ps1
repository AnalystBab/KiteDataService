# Test Alert - Shows what you'll see when LC/UC changes

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form for notification
$form = New-Object System.Windows.Forms.Form
$form.Text = "LC/UC Change Alert - TEST"
$form.Size = New-Object System.Drawing.Size(450, 250)
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
$titleLabel.Size = New-Object System.Drawing.Size(430, 35)
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)

# Add message label - Example change
$exampleMessage = @"
Symbol: SENSEX25OCT77800CE
Strike: 77800 | Type: CE

Upper Circuit CHANGE:
LC: 1106.35 >> 1106.35
UC: 5326.95 >> 5500.00 (+173.05)

Close Price: 2479.90 >> 2550.00
Sequence: 2
"@

$messageLabel = New-Object System.Windows.Forms.Label
$messageLabel.Text = $exampleMessage
$messageLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$messageLabel.ForeColor = [System.Drawing.Color]::White
$messageLabel.Size = New-Object System.Drawing.Size(430, 130)
$messageLabel.Location = New-Object System.Drawing.Point(10, 50)
$messageLabel.TextAlign = "TopLeft"
$form.Controls.Add($messageLabel)

# Add timestamp
$timeLabel = New-Object System.Windows.Forms.Label
$timeLabel.Text = "Time: $(Get-Date -Format 'HH:mm:ss') - THIS IS A TEST ALERT"
$timeLabel.Font = New-Object System.Drawing.Font("Arial", 9, [System.Drawing.FontStyle]::Bold)
$timeLabel.ForeColor = [System.Drawing.Color]::Orange
$timeLabel.Size = New-Object System.Drawing.Size(430, 25)
$timeLabel.Location = New-Object System.Drawing.Point(10, 185)
$timeLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($timeLabel)

# Add close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close Alert"
$closeButton.Size = New-Object System.Drawing.Size(120, 35)
$closeButton.Location = New-Object System.Drawing.Point(165, 145)
$closeButton.BackColor = [System.Drawing.Color]::Orange
$closeButton.ForeColor = [System.Drawing.Color]::Black
$closeButton.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

# Play sound
Write-Host "Playing test alert sound..." -ForegroundColor Yellow
[System.Console]::Beep(800, 300)
Start-Sleep -Milliseconds 100
[System.Console]::Beep(1000, 300)
Start-Sleep -Milliseconds 100
[System.Console]::Beep(800, 300)

Write-Host "Showing test alert window..." -ForegroundColor Green
Write-Host "This is exactly what you'll see when LC/UC changes happen!" -ForegroundColor Cyan
Write-Host ""

# Show form (modal - blocks until closed)
$form.ShowDialog()

Write-Host ""
Write-Host "Test complete! You closed the alert." -ForegroundColor Green
Write-Host "This is how you'll be notified for REAL LC/UC changes." -ForegroundColor Yellow
