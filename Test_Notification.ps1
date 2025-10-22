# Test Notification Script - FIXED VERSION
# This script will immediately show a desktop notification for testing

Write-Host "Testing Desktop Notification..." -ForegroundColor Green
Write-Host "You should see a popup window in the bottom-right corner" -ForegroundColor Yellow
Write-Host ""

# Function to show desktop notification - SIMPLIFIED VERSION
function Show-DesktopNotification {
    param(
        [string]$Title,
        [string]$Message
    )
    
    try {
        # Load Windows Forms
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        # Create a simple message box that stays on top
        $result = [System.Windows.Forms.MessageBox]::Show(
            $Message,
            $Title,
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        )
        
        Write-Host "✅ Notification closed by user" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Notification error: $($_.Exception.Message)" -ForegroundColor Red
        
        # Fallback: Simple console message
        Write-Host "=== NOTIFICATION ===" -ForegroundColor Red
        Write-Host "Title: $Title" -ForegroundColor Yellow
        Write-Host "Message: $Message" -ForegroundColor Yellow
        Write-Host "===================" -ForegroundColor Red
    }
}

# Test the notification
$testMessage = "This is a TEST notification!`n`nSENSEX 81600 CE UC changed:`n2023.70 → 2025.50`nTime: $(Get-Date -Format 'HH:mm:ss')`n`nClick OK to close this notification."

Show-DesktopNotification -Title "UC Change Alert - TEST" -Message $testMessage

Write-Host ""
Write-Host "Test completed!" -ForegroundColor Green
