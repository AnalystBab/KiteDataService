# Test Alert - UC INCREASE with Green Background

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "LC/UC Change Alert - UC INCREASE TEST"
$form.Size = New-Object System.Drawing.Size(950, 420)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.BackColor = [System.Drawing.Color]::DarkRed

# Title
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "*** LC/UC CHANGE DETECTED! ***"
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = [System.Drawing.Color]::Yellow
$titleLabel.Size = New-Object System.Drawing.Size(930, 40)
$titleLabel.Location = New-Object System.Drawing.Point(10, 10)
$titleLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($titleLabel)

# LEFT PANEL - CE with UC INCREASE (GREEN BACKGROUND!)
$cePanel = New-Object System.Windows.Forms.Panel
$cePanel.BorderStyle = "FixedSingle"
$cePanel.BackColor = [System.Drawing.Color]::DarkGreen  # GREEN for UC increase!
$cePanel.Size = New-Object System.Drawing.Size(450, 230)
$cePanel.Location = New-Object System.Drawing.Point(10, 60)
$form.Controls.Add($cePanel)

$ceTitle = New-Object System.Windows.Forms.Label
$ceTitle.Text = "*** CALL (CE) - UC INCREASED! ***"
$ceTitle.Font = New-Object System.Drawing.Font("Arial", 13, [System.Drawing.FontStyle]::Bold)
$ceTitle.ForeColor = [System.Drawing.Color]::Yellow  # YELLOW text!
$ceTitle.Size = New-Object System.Drawing.Size(430, 30)
$ceTitle.Location = New-Object System.Drawing.Point(10, 5)
$ceTitle.TextAlign = "MiddleCenter"
$cePanel.Controls.Add($ceTitle)

$ceMessage = @"
Symbol: SENSEX25OCT80200CE

!!! UPPER CIRCUIT INCREASED !!!

LC: 0.05 >> 0.05
UC: 5047.60 >> 5200.00 +152.40

Close: 2479.90 >> 2550.00
Seq: 2
"@

$ceLabel = New-Object System.Windows.Forms.Label
$ceLabel.Text = $ceMessage
$ceLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$ceLabel.ForeColor = [System.Drawing.Color]::Yellow  # YELLOW text!
$ceLabel.Size = New-Object System.Drawing.Size(430, 190)
$ceLabel.Location = New-Object System.Drawing.Point(10, 40)
$ceLabel.TextAlign = "TopLeft"
$cePanel.Controls.Add($ceLabel)

# RIGHT PANEL - PE normal (Maroon background)
$pePanel = New-Object System.Windows.Forms.Panel
$pePanel.BorderStyle = "FixedSingle"
$pePanel.BackColor = [System.Drawing.Color]::Maroon  # Normal maroon
$pePanel.Size = New-Object System.Drawing.Size(450, 230)
$pePanel.Location = New-Object System.Drawing.Point(480, 60)
$form.Controls.Add($pePanel)

$peTitle = New-Object System.Windows.Forms.Label
$peTitle.Text = "PUT (PE) - 80200"
$peTitle.Font = New-Object System.Drawing.Font("Arial", 13, [System.Drawing.FontStyle]::Bold)
$peTitle.ForeColor = [System.Drawing.Color]::Orange
$peTitle.Size = New-Object System.Drawing.Size(430, 30)
$peTitle.Location = New-Object System.Drawing.Point(10, 5)
$peTitle.TextAlign = "MiddleCenter"
$pePanel.Controls.Add($peTitle)

$peMessage = @"
Symbol: SENSEX25OCT80200PE

Upper Circuit CHANGE:

LC: 0.05 >> 0.05
UC: 154.95 >> 160.00

Close: 154.95 >> 160.00
Seq: 2
"@

$peLabel = New-Object System.Windows.Forms.Label
$peLabel.Text = $peMessage
$peLabel.Font = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$peLabel.ForeColor = [System.Drawing.Color]::White  # Normal white
$peLabel.Size = New-Object System.Drawing.Size(430, 190)
$peLabel.Location = New-Object System.Drawing.Point(10, 40)
$peLabel.TextAlign = "TopLeft"
$pePanel.Controls.Add($peLabel)

# Timestamp
$timeLabel = New-Object System.Windows.Forms.Label
$timeLabel.Text = "Time: $(Get-Date -Format 'HH:mm:ss') - UC INCREASE TEST - Strike: 80200"
$timeLabel.Font = New-Object System.Drawing.Font("Arial", 10, [System.Drawing.FontStyle]::Bold)
$timeLabel.ForeColor = [System.Drawing.Color]::Orange
$timeLabel.Size = New-Object System.Drawing.Size(930, 25)
$timeLabel.Location = New-Object System.Drawing.Point(10, 360)
$timeLabel.TextAlign = "MiddleCenter"
$form.Controls.Add($timeLabel)

# Close button
$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = "Close Alert"
$closeButton.Size = New-Object System.Drawing.Size(150, 40)
$closeButton.Location = New-Object System.Drawing.Point(400, 305)
$closeButton.BackColor = [System.Drawing.Color]::Orange
$closeButton.ForeColor = [System.Drawing.Color]::Black
$closeButton.Font = New-Object System.Drawing.Font("Arial", 11, [System.Drawing.FontStyle]::Bold)
$closeButton.Add_Click({ $form.Close() })
$form.Controls.Add($closeButton)

# Play sound
Write-Host "NOTICE THE LEFT PANEL!" -ForegroundColor Green
Write-Host "GREEN BACKGROUND = Upper Circuit Increased!" -ForegroundColor Yellow
Write-Host "YELLOW TEXT = Easy to spot!" -ForegroundColor Yellow
Write-Host "Shows the increase amount (+152.40)" -ForegroundColor Cyan
Write-Host ""

[System.Console]::Beep(1000, 200)
Start-Sleep -Milliseconds 50
[System.Console]::Beep(1200, 200)
Start-Sleep -Milliseconds 50
[System.Console]::Beep(1400, 300)

$form.ShowDialog()

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Green
Write-Host "Did you notice the GREEN BACKGROUND for UC increase?" -ForegroundColor Yellow
