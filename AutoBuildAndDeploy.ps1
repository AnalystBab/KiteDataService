# Auto-Build and Deploy Script - Watches for code changes and auto-deploys
param(
    [switch]$Watch,
    [switch]$Deploy
)

$ServiceName = "KiteMarketDataService"
$ProjectPath = $PSScriptRoot
$ExePath = Join-Path $ProjectPath "bin\Release\net8.0\KiteMarketDataService.Worker.exe"

function Write-Status {
    param([string]$Message, [string]$Color = "White")
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Build-Service {
    Write-Status "Building service..." "Yellow"
    
    Set-Location $ProjectPath
    
    # Build with error checking
    $output = dotnet build --configuration Release --verbosity quiet 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Build successful!" "Green"
        return $true
    } else {
        Write-Status "Build failed!" "Red"
        Write-Host $output
        return $false
    }
}

function Deploy-Service {
    if (!(Test-Administrator)) {
        Write-Status "Administrator privileges required for deployment" "Yellow"
        Write-Status "Attempting to elevate privileges..." "Cyan"
        
        # Restart script as administrator
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`" -Deploy" -Wait
        return
    }
    
    Write-Status "Deploying service..." "Cyan"
    
    # Stop service if running
    $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        Write-Status "Stopping existing service..." "Yellow"
        Stop-Service -Name $ServiceName -Force
        Start-Sleep -Seconds 2
    }
    
    # Remove existing service if exists
    if ($service) {
        Write-Status "Removing old service..." "Yellow"
        sc.exe delete $ServiceName | Out-Null
        Start-Sleep -Seconds 2
    }
    
    # Install new service
    Write-Status "Installing service..." "Yellow"
    sc.exe create $ServiceName binPath= "`"$ExePath`"" DisplayName= "Kite Market Data Service" start= auto | Out-Null
    
    # Configure service recovery options (auto-restart on failure)
    sc.exe failure $ServiceName reset= 86400 actions= restart/60000/restart/60000/restart/60000 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Status "Service installed successfully!" "Green"
        
        # Start service
        Write-Status "Starting service..." "Yellow"
        Start-Service -Name $ServiceName
        Start-Sleep -Seconds 2
        
        $service = Get-Service -Name $ServiceName
        if ($service.Status -eq 'Running') {
            Write-Status "Service is running!" "Green"
        } else {
            Write-Status "Service installed but not running. Check logs." "Yellow"
        }
    } else {
        Write-Status "Service installation failed!" "Red"
    }
}

function Create-DesktopFolder {
    Write-Status "Creating desktop folder with all files..." "Yellow"
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $folderPath = Join-Path $desktopPath "Kite Market Data Service"
    
    # Create folder if it doesn't exist
    if (!(Test-Path $folderPath)) {
        New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
    }
    
    $WshShell = New-Object -comObject WScript.Shell
    
    # 1. Create web dashboard shortcut
    $shortcutPath = Join-Path $folderPath "1. Open Web Dashboard.lnk"
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = "http://localhost:5000"
    $Shortcut.Description = "Open Kite Market Data Service Web Dashboard"
    $Shortcut.Save()
    
    # 2. Create token management shortcut
    $tokenShortcutPath = Join-Path $folderPath "2. Manage Tokens.lnk"
    $TokenShortcut = $WshShell.CreateShortcut($tokenShortcutPath)
    $TokenShortcut.TargetPath = "http://localhost:5000/token-management.html"
    $TokenShortcut.Description = "Manage Kite Connect Tokens"
    $TokenShortcut.Save()
    
    # 3. Copy QuickDeploy.bat to folder
    $quickDeploySource = Join-Path $ProjectPath "QuickDeploy.bat"
    $quickDeployDest = Join-Path $folderPath "3. Quick Deploy Service.bat"
    if (Test-Path $quickDeploySource) {
        Copy-Item $quickDeploySource $quickDeployDest -Force
    }
    
    # 4. Copy WatchAndAutoDeploy.bat to folder
    $watchDeploySource = Join-Path $ProjectPath "WatchAndAutoDeploy.bat"
    $watchDeployDest = Join-Path $folderPath "4. Auto-Deploy on Code Changes.bat"
    if (Test-Path $watchDeploySource) {
        Copy-Item $watchDeploySource $watchDeployDest -Force
    }
    
    # 5. Copy deployment guide to folder
    $guideSource = Join-Path $ProjectPath "DEPLOYMENT_GUIDE.txt"
    $guideDest = Join-Path $folderPath "READ ME FIRST.txt"
    if (Test-Path $guideSource) {
        Copy-Item $guideSource $guideDest -Force
    }
    
    # 6. Create service management shortcuts
    # Stop Service shortcut
    $stopServicePath = Join-Path $folderPath "5. Stop Service.lnk"
    $StopShortcut = $WshShell.CreateShortcut($stopServicePath)
    $StopShortcut.TargetPath = "powershell.exe"
    $StopShortcut.Arguments = "-Command `"Stop-Service -Name KiteMarketDataService -Force; Write-Host 'Service stopped!' -ForegroundColor Green; Read-Host 'Press Enter to close'`""
    $StopShortcut.Description = "Stop the Kite Market Data Service"
    $StopShortcut.Save()
    
    # Start Service shortcut
    $startServicePath = Join-Path $folderPath "6. Start Service.lnk"
    $StartShortcut = $WshShell.CreateShortcut($startServicePath)
    $StartShortcut.TargetPath = "powershell.exe"
    $StartShortcut.Arguments = "-Command `"Start-Service -Name KiteMarketDataService; Write-Host 'Service started!' -ForegroundColor Green; Read-Host 'Press Enter to close'`""
    $StartShortcut.Description = "Start the Kite Market Data Service"
    $StartShortcut.Save()
    
    # Check Service Status shortcut
    $statusPath = Join-Path $folderPath "7. Check Service Status.lnk"
    $StatusShortcut = $WshShell.CreateShortcut($statusPath)
    $StatusShortcut.TargetPath = "powershell.exe"
    $StatusShortcut.Arguments = "-Command `"`$s = Get-Service -Name KiteMarketDataService -ErrorAction SilentlyContinue; if (`$s) { if (`$s.Status -eq 'Running') { Write-Host 'Service is RUNNING' -ForegroundColor Green } else { Write-Host 'Service is STOPPED' -ForegroundColor Red } } else { Write-Host 'Service NOT INSTALLED' -ForegroundColor Red }; Read-Host 'Press Enter to close'`""
    $StatusShortcut.Description = "Check if Kite Market Data Service is running"
    $StatusShortcut.Save()
    
    Write-Status "Desktop folder created with all files!" "Green"
    Write-Status "Location: $folderPath" "Cyan"
}

function Watch-AndBuild {
    Write-Status "Watching for code changes..." "Cyan"
    Write-Status "Press Ctrl+C to stop watching" "Yellow"
    
    $lastBuildTime = (Get-Date).AddHours(-1)
    
    while ($true) {
        # Watch for .cs file changes
        $changedFiles = Get-ChildItem -Path $ProjectPath -Filter "*.cs" -Recurse |
            Where-Object { $_.LastWriteTime -gt $lastBuildTime }
        
        if ($changedFiles) {
            Write-Status "Code changes detected!" "Yellow"
            $lastBuildTime = Get-Date
            
            if (Build-Service) {
                Write-Status "Auto-deploying..." "Cyan"
                Deploy-Service
                Create-DesktopFolder
                Write-Status "Auto-deployment complete!" "Green"
                Write-Status "Web Dashboard: http://localhost:5000" "Cyan"
                Write-Status "Token Management: http://localhost:5000/token-management.html" "Cyan"
            }
        }
        
        Start-Sleep -Seconds 5
    }
}

# Main execution
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "      KITE MARKET DATA SERVICE - AUTO DEPLOY" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($Watch) {
    # Watch mode: Monitor for changes and auto-deploy
    Watch-AndBuild
} elseif ($Deploy) {
    # Deploy only (used by elevation)
    Deploy-Service
    Create-DesktopFolder
    Write-Status "Deployment complete!" "Green"
    Write-Host ""
    Write-Status "Press any key to close..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
} else {
    # Default: Build and deploy once
    if (Build-Service) {
        Deploy-Service
        Create-DesktopFolder
        
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "" -ForegroundColor Green
        Write-Host "              DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
        Write-Host "" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host ""
        Write-Status "Desktop Folder: Desktop/Kite Market Data Service/" "Cyan"
        Write-Status "Web Dashboard: http://localhost:5000" "Cyan"
        Write-Status "Token Management: http://localhost:5000/token-management.html" "Cyan"
        Write-Host ""
        Write-Status "TIP: All shortcuts and tools are in the desktop folder" "Yellow"
        Write-Host ""
    }
}
