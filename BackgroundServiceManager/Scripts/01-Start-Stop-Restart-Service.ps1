# Run Kite Market Data Service in Background
# This script starts the service in the background and provides monitoring capabilities

param(
    [string]$ServicePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker",
    [string]$RequestToken = "",
    [switch]$Stop,
    [switch]$Status,
    [switch]$Restart,
    [switch]$Monitor
)

$ServiceName = "KiteMarketDataService"
$LogFile = "$ServicePath\logs\service_background.log"
$PidFile = "$ServicePath\service.pid"

# Ensure logs directory exists
if (-not (Test-Path "$ServicePath\logs")) {
    New-Item -ItemType Directory -Path "$ServicePath\logs" -Force | Out-Null
}

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $logEntry
    Write-Host $logEntry
}

function Get-ServiceStatus {
    $processId = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($processId) {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -eq "dotnet") {
            return @{
                Running = $true
                PID = $processId
                StartTime = $process.StartTime
                MemoryUsage = [math]::Round($process.WorkingSet64 / 1MB, 2)
            }
        }
    }
    return @{ Running = $false }
}

function Stop-Service {
    Write-Log "Stopping $ServiceName service..."
    
    # Get all dotnet processes that might be our service
    try {
        $allDotnetProcesses = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue
        foreach ($proc in $allDotnetProcesses) {
            try {
                # Check if this process is running from our service directory
                $procPath = $proc.Path
                if ($procPath -and $procPath.Contains("KiteMarketDataService.Worker")) {
                    Write-Log "Stopping dotnet process PID: $($proc.Id) (service process)"
                    Stop-Process -Id $proc.Id -Force
                }
            } catch {
                # Ignore errors accessing process details
            }
        }
    } catch {
        Write-Log "Error stopping dotnet processes: $($_.Exception.Message)" "WARN"
    }
    
    $processId = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($processId) {
        try {
            $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
            if ($process) {
                Write-Log "Stopping process with PID: $processId"
                Stop-Process -Id $processId -Force
            }
        } catch {
            Write-Log "Error stopping service: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Wait for processes to fully stop
    Start-Sleep -Seconds 2
    
    # Verify process stopped
    if ($processId) {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if (-not $process) {
            Write-Log "Service stopped successfully" "SUCCESS"
        } else {
            Write-Log "Process still running after stop attempt" "WARN"
        }
    }
    
    # Clean up PID file
    Remove-Item $PidFile -ErrorAction SilentlyContinue
}

function Start-Service {
    Write-Log "Starting $ServiceName service in background..."
    
    # Check if already running - AUTO-KILL and restart fresh
    $status = Get-ServiceStatus
    if ($status.Running) {
        Write-Log "Existing service found with PID: $($status.PID)" "WARN"
        Write-Log "Stopping existing service to start fresh..." "INFO"
        Stop-Service
        Start-Sleep -Seconds 2  # Wait for process to fully stop
    }
    
    # Update token if provided
    if ($RequestToken) {
        Write-Log "Updating configuration with new token..."
        $ConfigFile = "$ServicePath\appsettings.json"
        if (Test-Path $ConfigFile) {
            try {
                $Config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
                $Config.KiteConnect.RequestToken = $RequestToken
                $Config | ConvertTo-Json -Depth 10 | Set-Content $ConfigFile
                Write-Log "Configuration updated with token" "SUCCESS"
            } catch {
                Write-Log "Failed to update configuration: $($_.Exception.Message)" "ERROR"
                return $null
            }
        }
    }
    
    # Navigate to service directory
    Set-Location $ServicePath
    
    try {
        # Start the service in background
        Write-Log "Starting dotnet run in background..."
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "dotnet"
        $processInfo.Arguments = "run"
        $processInfo.WorkingDirectory = $ServicePath
        $processInfo.UseShellExecute = $false
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null
        
        # Save PID
        $process.Id | Out-File -FilePath $PidFile -Encoding ASCII
        
        Write-Log "Service started with PID: $($process.Id)" "SUCCESS"
        
        # Wait a moment and check if still running
        Start-Sleep -Seconds 5
        $runningProcess = Get-Process -Id $process.Id -ErrorAction SilentlyContinue
        if ($runningProcess) {
            Write-Log "Service is running successfully in background" "SUCCESS"
            return @{
                Running = $true
                PID = $process.Id
                StartTime = $runningProcess.StartTime
            }
        } else {
            Write-Log "Service failed to start or crashed immediately" "ERROR"
            Remove-Item $PidFile -ErrorAction SilentlyContinue
            return $null
        }
        
    } catch {
        Write-Log "Failed to start service: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Test-ServiceHealth {
    Write-Log "Testing service health..."
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/api/SystemMonitor/status" -UseBasicParsing -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Log "Service health check passed - Web API responding" "SUCCESS"
            return $true
        }
    } catch {
        Write-Log "Service health check failed - Web API not responding: $($_.Exception.Message)" "WARN"
    }
    
    return $false
}

function Show-ServiceStatus {
    Write-Host "=== $ServiceName Service Status ===" -ForegroundColor Green
    Write-Host ""
    
    $status = Get-ServiceStatus
    if ($status.Running) {
        Write-Host "✅ Service Status: RUNNING" -ForegroundColor Green
        Write-Host "   PID: $($status.PID)" -ForegroundColor White
        Write-Host "   Start Time: $($status.StartTime)" -ForegroundColor White
        Write-Host "   Memory Usage: $($status.MemoryUsage) MB" -ForegroundColor White
        
        # Test health
        $health = Test-ServiceHealth
        if ($health) {
            Write-Host "   Health: ✅ HEALTHY" -ForegroundColor Green
        } else {
            Write-Host "   Health: ⚠️ UNHEALTHY" -ForegroundColor Yellow
        }
        
        Write-Host ""
        Write-Host "Web Interface: http://localhost:5000" -ForegroundColor Cyan
        Write-Host "Log File: $LogFile" -ForegroundColor Cyan
        
    } else {
        Write-Host "❌ Service Status: NOT RUNNING" -ForegroundColor Red
        Write-Host ""
        Write-Host "To start the service, run:" -ForegroundColor Yellow
        Write-Host "  .\RunServiceInBackground.ps1" -ForegroundColor White
    }
    
    Write-Host ""
}

function Start-Monitoring {
    Write-Host "Starting continuous monitoring of $ServiceName..." -ForegroundColor Green
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
    Write-Host ""
    
    while ($true) {
        Clear-Host
        Show-ServiceStatus
        
        $status = Get-ServiceStatus
        if ($status.Running) {
            # Test health every 30 seconds
            $health = Test-ServiceHealth
            if (-not $health) {
                Write-Host "⚠️ Service appears unhealthy. Consider restarting." -ForegroundColor Yellow
            }
        }
        
        Write-Host "Next check in 30 seconds..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
}

# Main execution
Write-Host "=== Kite Market Data Service Background Manager ===" -ForegroundColor Green
Write-Host ""

if ($Stop) {
    Stop-Service
    Write-Host "Service stop requested completed." -ForegroundColor Yellow
} elseif ($Status) {
    Show-ServiceStatus
} elseif ($Restart) {
    Write-Log "Restarting service..."
    Stop-Service
    Start-Sleep -Seconds 3
    $result = Start-Service
    if ($result) {
        Write-Host "Service restarted successfully!" -ForegroundColor Green
    } else {
        Write-Host "Failed to restart service!" -ForegroundColor Red
    }
} elseif ($Monitor) {
    Start-Monitoring
} else {
    # Default: Start service
    $result = Start-Service
    if ($result) {
        Write-Host ""
        Write-Host "✅ Service started successfully in background!" -ForegroundColor Green
        Write-Host "   PID: $($result.PID)" -ForegroundColor White
        Write-Host "   Web Interface: http://localhost:5000" -ForegroundColor Cyan
        Write-Host "   Log File: $LogFile" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To check status: .\RunServiceInBackground.ps1 -Status" -ForegroundColor Yellow
        Write-Host "To monitor: .\RunServiceInBackground.ps1 -Monitor" -ForegroundColor Yellow
        Write-Host "To stop: .\RunServiceInBackground.ps1 -Stop" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Failed to start service!" -ForegroundColor Red
        Write-Host "Check the log file for details: $LogFile" -ForegroundColor Yellow
    }
}

Write-Host ""

        Write-Host "✅ Service started successfully in background!" -ForegroundColor Green
        Write-Host "   PID: $($result.PID)" -ForegroundColor White
        Write-Host "   Web Interface: http://localhost:5000" -ForegroundColor Cyan
        Write-Host "   Log File: $LogFile" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To check status: .\RunServiceInBackground.ps1 -Status" -ForegroundColor Yellow
        Write-Host "To monitor: .\RunServiceInBackground.ps1 -Monitor" -ForegroundColor Yellow
        Write-Host "To stop: .\RunServiceInBackground.ps1 -Stop" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Failed to start service!" -ForegroundColor Red
        Write-Host "Check the log file for details: $LogFile" -ForegroundColor Yellow
    }
}

Write-Host ""

        Write-Host "✅ Service started successfully in background!" -ForegroundColor Green
        Write-Host "   PID: $($result.PID)" -ForegroundColor White
        Write-Host "   Web Interface: http://localhost:5000" -ForegroundColor Cyan
        Write-Host "   Log File: $LogFile" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "To check status: .\RunServiceInBackground.ps1 -Status" -ForegroundColor Yellow
        Write-Host "To monitor: .\RunServiceInBackground.ps1 -Monitor" -ForegroundColor Yellow
        Write-Host "To stop: .\RunServiceInBackground.ps1 -Stop" -ForegroundColor Yellow
    } else {
        Write-Host "❌ Failed to start service!" -ForegroundColor Red
        Write-Host "Check the log file for details: $LogFile" -ForegroundColor Yellow
    }
}

Write-Host ""
