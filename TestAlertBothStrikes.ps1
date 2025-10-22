# Test Alert - Shows CE and PE strikes together in bigger window

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form for notification
$form = New-Object System.Windows.Forms.Form
$form.Text = "LC/UC Change Alert - TEST"
$form.Size = New-Object System.Drawing.Size(900, 350)
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
$titleLabel.Size = New-Object System.Drawing.Size(880, 40)
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)

# Left panel - CE Strike
$cePanel = New-Object System.Windows.Forms.Panel
$cePanel.BorderStyle = "FixedSingle"
$cePanel.BackColor = [System.Drawing.Color]::Maroon
$cePanel.Size = New-Object System.Drawing.Size(420, 200)
$cePanel.Location = New-Object System.Drawing.Point(10, 60)
$form.Controls.Add($cePanel)

$ceTitle = New-Object System.Windows.Forms.Label
$ceTitle.Text = "CALL (CE) - 80200"
$ceTitle.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$ceTitle.ForeColor = [System.Drawing.Color]::Lime
$ceTitle.Size = New-Object System.Drawing.Size(400, 25)
$ceTitle.Location = New-Object System.Drawing.Point(10, 5)
$ceTitle.TextAlign = "MiddleCenter"
$cePanel.Controls.Add($ceTitle)

$ceMessage = @"
Symbol: SENSEX25OCT80200CE
Strike: 80200 | Type: CE

Upper Circuit CHANGE:
LC: 0.05 >> 0.05
UC: 5047.60 >> 5200.00 (+152.40)

Close Price: 2479.90 >> 2550.00
Last Price: 2479.90 >> 2550.00
Sequence: 2
"@

$ceLabel = New-Object System.Windows.Forms.Label
$ceLabel.Text = $ceMessage
$ceLabel.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$ceLabel.ForeColor = [System.Drawing.Color]::White
$ceLabel.Size = New-Object System.Drawing.Size(400, 160)
$ceLabel.Location = New-Object System.Drawing.Point(10, 35)
$ceLabel.TextAlign = "TopLeft"
$cePanel.Controls.Add($ceLabel)

# Right panel - PE Strike
$pePanel = New-Object System.Windows.Forms.Panel
$pePanel.BorderStyle = "FixedSingle"
$pePanel.BackColor = [System.Drawing.Color]::Maroon
$pePanel.Size = New-Object System.Drawing.Size(420, 200)
$pePanel.Location = New-Object System.Drawing.Point(460, 60)
$form.Controls.Add($pePanel)

$peTitle = New-Object System.Windows.Forms.Label
$peTitle.Text = "PUT (PE) - 80200"
$peTitle.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
$peTitle.ForeColor = [System.Drawing.Color]::Orange
$peTitle.Size = New-Object System.Drawing.Size(400, 25)
$peTitle.Location = New-Object System.Drawing.Point(10, 5)
$peTitle.TextAlign = "MiddleCenter"
$pePanel.Controls.Add($peTitle)

$peMessage = @"
Symbol: SENSEX25OCT80200PE
Strike: 80200 | Type: PE

Lower Circuit CHANGE:
LC: 0.05 >> 0.05
UC: 154.95 >> 165.00 (+10.05)

Close Price: 154.95 >> 160.00
Last Price: 154.95 >> 160.00
Sequence: 2
"@

$peLabel = New-Object System.Windows.Forms.Label
$peLabel.Text = $peMessage
$peLabel.Font = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$peLabel.ForeColor = [System.Drawing.Color]::White
$peLabel.Size = New-Object System.Drawing.Size(400, 160)
$peLabel.Location = New-Object System.Drawing.Point(10, 35)
$peLabel.TextAlign = "TopLeft"
$pePanel.Controls.Add($peLabel)

# Add timestamp
$timeLabel = New-Object System.Windows.Forms.Label
$timeLabel.Text = "Time: $(Get-Date -Format 'HH:mm:ss') - THIS IS A TEST ALERT"
$timeLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$timeLabel.ForeColor = [System.Drawing.Color]::Orange
$timeLabel.Size = New-Object System.Drawing.Size(880, 30)
$timeLabel.Location = New-Object System.Drawing.Point(10, 270)
$timeLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($timeLabel)

# Add close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close Alert"
$closeButton.Size = New-Object System.Drawing.Size(150, 40)
$closeButton.Location = New-Object System.Drawing.Point(375, 235)
$closeButton.BackColor = [System.Drawing.Color]::Orange
$closeButton.ForeColor = [System.Drawing.Color]::Black
$closeButton.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

# Play sound
Write-Host "Playing test alert sound..." -ForegroundColor Yellow
[System.Console]::Beep(800, 300)
Start-Sleep -Milliseconds 100
[System.Console]::Beep(1000, 300)
Start-Sleep -Milliseconds 100
[System.Console]::Beep(800, 300)

Write-Host "Showing BIGGER test alert window with CE and PE strikes..." -ForegroundColor Green
Write-Host "This is exactly what you'll see when both CE and PE LC/UC changes happen!" -ForegroundColor Cyan
Write-Host ""

# Show form (modal - blocks until closed)
$form.ShowDialog()

Write-Host ""
Write-Host "Test complete! You closed the alert." -ForegroundColor Green
Write-Host "This is how you'll see BOTH CE and PE changes together." -ForegroundColor Yellow
