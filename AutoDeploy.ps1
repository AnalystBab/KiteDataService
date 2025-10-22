# Auto-Deploy Script for Kite Market Data Service
param(
    [switch]$Uninstall,
    [switch]$Install,
    [switch]$Restart
)

$ServiceName = "KiteMarketDataService"
$ServiceDisplayName = "Kite Market Data Service"
$ProjectPath = $PSScriptRoot
$ExePath = Join-Path $ProjectPath "bin\Release\net8.0\KiteMarketDataService.Worker.exe"

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    Write-Host "🎯 $Message" -ForegroundColor $Color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Build-Service {
    Write-Status "Building service..." "Yellow"
    
    Set-Location $ProjectPath
    
    # Clean and build
    dotnet clean --configuration Release
    dotnet build --configuration Release --verbosity quiet
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✅ Build successful!" "Green"
        return $true
    } else {
        Write-Status "❌ Build failed!" "Red"
        return $false
    }
}

function Install-Service {
    Write-Status "Installing Windows Service..." "Yellow"
    
    if (!(Test-Administrator)) {
        Write-Status "❌ Administrator privileges required for service installation" "Red"
        Write-Status "Please run PowerShell as Administrator" "Yellow"
        return $false
    }
    
    # Stop service if running
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        Write-Status "Stopping existing service..." "Yellow"
        Stop-Service -Name $ServiceName -Force
    }
    
    # Remove existing service if exists
    if ($service) {
        Write-Status "Removing existing service..." "Yellow"
        sc.exe delete $ServiceName
        Start-Sleep -Seconds 2
    }
    
    # Install new service
    Write-Status "Installing service..." "Yellow"
    sc.exe create $ServiceName binPath= "`"$ExePath`"" DisplayName= "`"$ServiceDisplayName`"" start= auto
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "✅ Service installed successfully!" "Green"
        Start-Service -Name $ServiceName
        Write-Status "✅ Service started!" "Green"
        return $true
    } else {
        Write-Status "❌ Service installation failed!" "Red"
        return $false
    }
}

function Uninstall-Service {
    Write-Status "Uninstalling Windows Service..." "Yellow"
    
    if (!(Test-Administrator)) {
        Write-Status "❌ Administrator privileges required for service uninstallation" "Red"
        Write-Status "Please run PowerShell as Administrator" "Yellow"
        return $false
    }
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -eq 'Running') {
            Write-Status "Stopping service..." "Yellow"
            Stop-Service -Name $ServiceName -Force
        }
        
        Write-Status "Removing service..." "Yellow"
        sc.exe delete $ServiceName
        
        if ($LASTEXITCODE -eq 0) {
            Write-Status "✅ Service uninstalled successfully!" "Green"
        } else {
            Write-Status "❌ Service uninstallation failed!" "Red"
        }
    } else {
        Write-Status "Service not found" "Yellow"
    }
}

function Restart-Service {
    Write-Status "Restarting service..." "Yellow"
    
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service) {
        if ($service.Status -eq 'Running') {
            Stop-Service -Name $ServiceName -Force
            Start-Sleep -Seconds 3
        }
        Start-Service -Name $ServiceName
        Write-Status "✅ Service restarted!" "Green"
    } else {
        Write-Status "❌ Service not found!" "Red"
    }
}

function Create-DesktopShortcuts {
    Write-Status "Creating desktop shortcuts..." "Yellow"
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $folderPath = Join-Path $desktopPath "Kite Market Data Service"
    
    # Create folder if it doesn't exist
    if (!(Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
    }
    
    # Create web dashboard shortcut
    $shortcutPath = Join-Path $folderPath "Open Web Dashboard.lnk"
    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "http://localhost:5000"
    $Shortcut.Description = "Open Kite Market Data Service Web Dashboard"
    $Shortcut.Save()
    
    # Create token management shortcut
    $tokenShortcutPath = Join-Path $folderPath "Manage Tokens.lnk"
    $TokenShortcut = $WshShell.CreateShortcut($tokenShortcutPath)
    $TokenShortcut.TargetPath = "http://localhost:5000/token-management.html"
    $TokenShortcut.Description = "Manage Kite Connect Tokens"
    $TokenShortcut.Save()
    
    Write-Status "✅ Desktop shortcuts created!" "Green"
    Write-Status "📁 Folder: $folderPath" "Cyan"
}

# Main execution
Write-Status "🚀 Kite Market Data Service Auto-Deploy" "Cyan"
Write-Status "=====================================" "Cyan"

if ($Uninstall) {
    Uninstall-Service
} elseif ($Install) {
    if (Build-Service) {
        if (Install-Service) {
            Create-DesktopShortcuts
            Write-Status "🎉 Deployment completed successfully!" "Green"
            Write-Status "🌐 Web Dashboard: http://localhost:5000" "Cyan"
            Write-Status "🔑 Token Management: http://localhost:5000/token-management.html" "Cyan"
        }
    }
} elseif ($Restart) {
    Restart-Service
} else {
    # Default: Build and deploy
    if (Build-Service) {
        if (Install-Service) {
            Create-DesktopShortcuts
            Write-Status "🎉 Deployment completed successfully!" "Green"
            Write-Status "🌐 Web Dashboard: http://localhost:5000" "Cyan"
            Write-Status "🔑 Token Management: http://localhost:5000/token-management.html" "Cyan"
        }
    }
}

Write-Status "=====================================" "Cyan"





