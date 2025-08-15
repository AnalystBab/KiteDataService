# Task 8: Stop Market Data Service
# Purpose: Gracefully stop the service
# Icon: ⚫ Black Circle with "STOP SERVICE" text

Write-Host "⚫ TASK 8: STOPPING MARKET DATA SERVICE" -ForegroundColor Black -BackgroundColor White
Write-Host "================================================" -ForegroundColor Black -BackgroundColor White

Write-Host "🛑 Stopping Kite Market Data Service..." -ForegroundColor Cyan

try {
    # Find dotnet processes running the service
    $ServiceProcesses = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object {
        $_.ProcessName -eq "dotnet" -and 
        $_.MainWindowTitle -like "*KiteMarketDataService*" -or
        $_.CommandLine -like "*KiteMarketDataService*"
    }
    
    if ($ServiceProcesses.Count -eq 0) {
        Write-Host "ℹ️  INFO: No running Kite Market Data Service found" -ForegroundColor Cyan
        Write-Host "💡 The service may already be stopped" -ForegroundColor Yellow
    } else {
        Write-Host "📊 Found $($ServiceProcesses.Count) service process(es)" -ForegroundColor Yellow
        
        foreach ($Process in $ServiceProcesses) {
            Write-Host "🔄 Stopping process ID: $($Process.Id)" -ForegroundColor Yellow
            
            try {
                # Try graceful shutdown first
                $Process.CloseMainWindow()
                
                # Wait for graceful shutdown
                if (!$Process.WaitForExit(5000)) {
                    Write-Host "⚠️  Process not responding to graceful shutdown" -ForegroundColor Yellow
                    Write-Host "🔄 Force stopping process..." -ForegroundColor Red
                    $Process.Kill()
                }
                
                Write-Host "✅ Process $($Process.Id) stopped successfully" -ForegroundColor Green
                
            } catch {
                Write-Host "❌ ERROR: Failed to stop process $($Process.Id)" -ForegroundColor Red
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
    
    # Additional cleanup - check for any remaining dotnet processes
    Write-Host "🧹 Performing cleanup..." -ForegroundColor Yellow
    
    $RemainingProcesses = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object {
        $_.MainWindowTitle -like "*KiteMarketDataService*"
    }
    
    if ($RemainingProcesses.Count -eq 0) {
        Write-Host "✅ Service stopped successfully!" -ForegroundColor Green
        Write-Host "📊 All service processes terminated" -ForegroundColor Green
    } else {
        Write-Host "⚠️  WARNING: $($RemainingProcesses.Count) process(es) still running" -ForegroundColor Yellow
        Write-Host "💡 You may need to manually stop them" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "📋 SERVICE STOP SUMMARY:" -ForegroundColor Yellow
    Write-Host "=========================" -ForegroundColor Yellow
    Write-Host "🛑 Service Status: Stopped" -ForegroundColor Red
    Write-Host "📅 Stop Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
    Write-Host "💡 To restart: Run Task 1 (Start Service)" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ ERROR: Failed to stop service" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔍 You may need to manually stop the service" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 TASK 8 COMPLETED: Service stopped" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
