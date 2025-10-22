# Stop All Monitoring Scripts

Write-Host "Stopping all monitoring scripts..." -ForegroundColor Yellow

# Get all PowerShell processes
$allProcesses = Get-Process powershell -ErrorAction SilentlyContinue

if ($allProcesses) {
    Write-Host "Found $($allProcesses.Count) PowerShell processes" -ForegroundColor Cyan
    
    foreach ($process in $allProcesses) {
        try {
            # Get command line to identify monitoring scripts
            $commandLine = (Get-WmiObject Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
            
            if ($commandLine -like "*LCUC*" -or $commandLine -like "*Monitor*") {
                Write-Host "Stopping monitoring process: PID $($process.Id)" -ForegroundColor Red
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                Write-Host "  Stopped!" -ForegroundColor Green
            }
        } catch {
            # Ignore errors for processes we can't access
        }
    }
    
    Write-Host ""
    Write-Host "Monitoring scripts stopped!" -ForegroundColor Green
} else {
    Write-Host "No PowerShell processes found" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
