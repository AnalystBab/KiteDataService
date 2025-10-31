# Service Health Monitor
# Comprehensive monitoring script for Kite Market Data Service

param(
    [string]$ServicePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker",
    [string]$ConnectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true",
    [switch]$Continuous,
    [switch]$Quick,
    [switch]$Detailed
)

$ServiceName = "KiteMarketDataService"
$PidFile = "$ServicePath\service.pid"
$LogFile = "$ServicePath\logs\service_background.log"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Get-ServiceProcessInfo {
    $processId = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($processId) {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -eq "dotnet") {
            return @{
                Running = $true
                PID = $processId
                StartTime = $process.StartTime
                MemoryUsage = [math]::Round($process.WorkingSet64 / 1MB, 2)
                CPU = $process.TotalProcessorTime
                ProcessName = $process.ProcessName
            }
        }
    }
    return @{ Running = $false }
}

function Test-WebAPI {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/api/SystemMonitor/status" -UseBasicParsing -TimeoutSec 5
        return @{
            Available = $true
            StatusCode = $response.StatusCode
            ResponseTime = $response.Headers.'X-Response-Time'
        }
    } catch {
        return @{
            Available = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-DatabaseStatus {
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        # Get table counts
        $command = New-Object System.Data.SqlClient.SqlCommand("
            SELECT 
                'Instruments' as TableName, COUNT(*) as RecordCount FROM Instruments
            UNION ALL
            SELECT 'MarketQuotes' as TableName, COUNT(*) as RecordCount FROM MarketQuotes
            UNION ALL
            SELECT 'CircuitLimits' as TableName, COUNT(*) as RecordCount FROM CircuitLimits
            UNION ALL
            SELECT 'IntradaySpotData' as TableName, COUNT(*) as RecordCount FROM IntradaySpotData
        ", $connection)
        
        $reader = $command.ExecuteReader()
        $tableData = @{}
        
        while ($reader.Read()) {
            $tableData[$reader["TableName"]] = $reader["RecordCount"]
        }
        $reader.Close()
        
        # Get recent activity
        $command = New-Object System.Data.SqlClient.SqlCommand("
            SELECT 
                COUNT(*) as RecentQuotes,
                MAX(RecordDateTime) as LastRecordTime,
                COUNT(DISTINCT TradingSymbol) as ActiveSymbols
            FROM MarketQuotes 
            WHERE RecordDateTime >= DATEADD(minute, -10, GETUTCDATE())
        ", $connection)
        
        $reader = $command.ExecuteReader()
        $recentActivity = @{}
        if ($reader.Read()) {
            $recentActivity["RecentQuotes"] = $reader["RecentQuotes"]
            $recentActivity["LastRecordTime"] = $reader["LastRecordTime"]
            $recentActivity["ActiveSymbols"] = $reader["ActiveSymbols"]
        }
        $reader.Close()
        
        $connection.Close()
        
        return @{
            Tables = $tableData
            RecentActivity = $recentActivity
            Connected = $true
        }
    } catch {
        return @{
            Connected = $false
            Error = $_.Exception.Message
        }
    }
}

function Show-ServiceStatus {
    Clear-Host
    Write-ColorOutput "=== $ServiceName Health Monitor ===" -Color Green
    Write-ColorOutput "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color Gray
    Write-ColorOutput ""
    
    # Service Process Status
    Write-ColorOutput "🔧 SERVICE PROCESS STATUS" -Color Yellow
    $processInfo = Get-ServiceProcessInfo
    if ($processInfo.Running) {
        Write-ColorOutput "✅ Status: RUNNING" -Color Green
        Write-ColorOutput "   PID: $($processInfo.PID)" -Color White
        Write-ColorOutput "   Start Time: $($processInfo.StartTime)" -Color White
        Write-ColorOutput "   Memory Usage: $($processInfo.MemoryUsage) MB" -Color White
        Write-ColorOutput "   CPU Time: $($processInfo.CPU)" -Color White
    } else {
        Write-ColorOutput "❌ Status: NOT RUNNING" -Color Red
    }
    Write-ColorOutput ""
    
    # Web API Status
    Write-ColorOutput "🌐 WEB API STATUS" -Color Yellow
    $webAPI = Test-WebAPI
    if ($webAPI.Available) {
        Write-ColorOutput "✅ Web API: RESPONDING" -Color Green
        Write-ColorOutput "   Status Code: $($webAPI.StatusCode)" -Color White
        Write-ColorOutput "   URL: http://localhost:5000" -Color Cyan
    } else {
        Write-ColorOutput "❌ Web API: NOT RESPONDING" -Color Red
        Write-ColorOutput "   Error: $($webAPI.Error)" -Color Red
    }
    Write-ColorOutput ""
    
    # Database Status
    Write-ColorOutput "🗄️ DATABASE STATUS" -Color Yellow
    $dbStatus = Get-DatabaseStatus
    if ($dbStatus.Connected) {
        Write-ColorOutput "✅ Database: CONNECTED" -Color Green
        
        # Table counts
        Write-ColorOutput "   Table Records:" -Color White
        foreach ($table in $dbStatus.Tables.Keys) {
            $count = $dbStatus.Tables[$table]
            if ($count -gt 0) {
                Write-ColorOutput "     $table`: $count records" -Color Green
            } else {
                Write-ColorOutput "     $table`: $count records" -Color Yellow
            }
        }
        
        # Recent activity
        if ($dbStatus.RecentActivity.RecentQuotes -gt 0) {
            Write-ColorOutput "   Recent Activity (last 10 min):" -Color White
            Write-ColorOutput "     Quotes: $($dbStatus.RecentActivity.RecentQuotes)" -Color Green
            Write-ColorOutput "     Active Symbols: $($dbStatus.RecentActivity.ActiveSymbols)" -Color Green
            Write-ColorOutput "     Last Record: $($dbStatus.RecentActivity.LastRecordTime)" -Color Green
        } else {
            Write-ColorOutput "   Recent Activity: No data in last 10 minutes" -Color Yellow
        }
    } else {
        Write-ColorOutput "❌ Database: CONNECTION FAILED" -Color Red
        Write-ColorOutput "   Error: $($dbStatus.Error)" -Color Red
    }
    Write-ColorOutput ""
    
    # Overall Health Assessment
    Write-ColorOutput "📊 OVERALL HEALTH ASSESSMENT" -Color Yellow
    $healthScore = 0
    $maxScore = 3
    
    if ($processInfo.Running) { $healthScore++ }
    if ($webAPI.Available) { $healthScore++ }
    if ($dbStatus.Connected) { $healthScore++ }
    
    $healthPercentage = [math]::Round(($healthScore / $maxScore) * 100)
    
    if ($healthPercentage -eq 100) {
        Write-ColorOutput "✅ HEALTH: EXCELLENT ($($healthPercentage) percent)" -Color Green
        Write-ColorOutput "   All systems operational" -Color Green
    } elseif ($healthPercentage -ge 66) {
        Write-ColorOutput "⚠️ HEALTH: GOOD ($($healthPercentage) percent)" -Color Yellow
        Write-ColorOutput "   Minor issues detected" -Color Yellow
    } elseif ($healthPercentage -ge 33) {
        Write-ColorOutput "⚠️ HEALTH: POOR ($($healthPercentage) percent)" -Color Yellow
        Write-ColorOutput "   Multiple issues detected" -Color Yellow
    } else {
        Write-ColorOutput "❌ HEALTH: CRITICAL ($($healthPercentage) percent)" -Color Red
        Write-ColorOutput "   Service needs immediate attention" -Color Red
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "📋 QUICK ACTIONS:" -Color Cyan
    Write-ColorOutput "   Start Service: .\RunServiceInBackground.ps1" -Color White
    Write-ColorOutput "   Stop Service: .\RunServiceInBackground.ps1 -Stop" -Color White
    Write-ColorOutput "   Restart Service: .\RunServiceInBackground.ps1 -Restart" -Color White
    Write-ColorOutput "   Web Interface: http://localhost:5000" -Color White
}

function Show-QuickStatus {
    $processInfo = Get-ServiceProcessInfo
    $webAPI = Test-WebAPI
    $dbStatus = Get-DatabaseStatus
    
    $status = "❌"
    $color = "Red"
    
    if ($processInfo.Running -and $webAPI.Available -and $dbStatus.Connected) {
        $status = "✅"
        $color = "Green"
    } elseif ($processInfo.Running -or $webAPI.Available -or $dbStatus.Connected) {
        $status = "⚠️"
        $color = "Yellow"
    }
    
    $runningStatus = if ($processInfo.Running) { "RUNNING" } else { "STOPPED" }
    $apiStatus = if ($webAPI.Available) { "OK" } else { "FAIL" }
    $dbStatusText = if ($dbStatus.Connected) { "OK" } else { "FAIL" }
    
    Write-ColorOutput "$status $ServiceName Status: $runningStatus | API: $apiStatus | DB: $dbStatusText" -Color $color
}

function Show-DetailedStatus {
    Show-ServiceStatus
    
    Write-ColorOutput "📁 LOG FILES:" -Color Yellow
    $logFiles = @(
        "$ServicePath\logs\KiteMarketDataService.log",
        "$ServicePath\logs\service_background.log"
    )
    
    foreach ($logFile in $logFiles) {
        if (Test-Path $logFile) {
            $fileInfo = Get-Item $logFile
            Write-ColorOutput "   $($fileInfo.Name): $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -Color White
            Write-ColorOutput "     Last Modified: $($fileInfo.LastWriteTime)" -Color Gray
        }
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "🔧 SYSTEM RESOURCES:" -Color Yellow
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    Write-ColorOutput "   Total Memory: $totalMemory MB" -Color White
    Write-ColorOutput "   Free Memory: $freeMemory MB" -Color White
    
    $processInfo = Get-ServiceProcessInfo
    if ($processInfo.Running) {
        Write-ColorOutput "   Service Memory: $($processInfo.MemoryUsage) MB" -Color White
    }
}

# Main execution
if ($Quick) {
    Show-QuickStatus
} elseif ($Detailed) {
    Show-DetailedStatus
} elseif ($Continuous) {
    Write-ColorOutput "Starting continuous monitoring..." -Color Green
    Write-ColorOutput "Press Ctrl+C to stop" -Color Yellow
    Write-ColorOutput ""
    
    while ($true) {
        Show-ServiceStatus
        Write-ColorOutput "Next check in 30 seconds..." -Color Gray
        Start-Sleep -Seconds 30
    }
} else {
    Show-ServiceStatus
}

Write-ColorOutput ""




param(
    [string]$ServicePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker",
    [string]$ConnectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true",
    [switch]$Continuous,
    [switch]$Quick,
    [switch]$Detailed
)

$ServiceName = "KiteMarketDataService"
$PidFile = "$ServicePath\service.pid"
$LogFile = "$ServicePath\logs\service_background.log"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Get-ServiceProcessInfo {
    $processId = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($processId) {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -eq "dotnet") {
            return @{
                Running = $true
                PID = $processId
                StartTime = $process.StartTime
                MemoryUsage = [math]::Round($process.WorkingSet64 / 1MB, 2)
                CPU = $process.TotalProcessorTime
                ProcessName = $process.ProcessName
            }
        }
    }
    return @{ Running = $false }
}

function Test-WebAPI {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/api/SystemMonitor/status" -UseBasicParsing -TimeoutSec 5
        return @{
            Available = $true
            StatusCode = $response.StatusCode
            ResponseTime = $response.Headers.'X-Response-Time'
        }
    } catch {
        return @{
            Available = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-DatabaseStatus {
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        # Get table counts
        $command = New-Object System.Data.SqlClient.SqlCommand("
            SELECT 
                'Instruments' as TableName, COUNT(*) as RecordCount FROM Instruments
            UNION ALL
            SELECT 'MarketQuotes' as TableName, COUNT(*) as RecordCount FROM MarketQuotes
            UNION ALL
            SELECT 'CircuitLimits' as TableName, COUNT(*) as RecordCount FROM CircuitLimits
            UNION ALL
            SELECT 'IntradaySpotData' as TableName, COUNT(*) as RecordCount FROM IntradaySpotData
        ", $connection)
        
        $reader = $command.ExecuteReader()
        $tableData = @{}
        
        while ($reader.Read()) {
            $tableData[$reader["TableName"]] = $reader["RecordCount"]
        }
        $reader.Close()
        
        # Get recent activity
        $command = New-Object System.Data.SqlClient.SqlCommand("
            SELECT 
                COUNT(*) as RecentQuotes,
                MAX(RecordDateTime) as LastRecordTime,
                COUNT(DISTINCT TradingSymbol) as ActiveSymbols
            FROM MarketQuotes 
            WHERE RecordDateTime >= DATEADD(minute, -10, GETUTCDATE())
        ", $connection)
        
        $reader = $command.ExecuteReader()
        $recentActivity = @{}
        if ($reader.Read()) {
            $recentActivity["RecentQuotes"] = $reader["RecentQuotes"]
            $recentActivity["LastRecordTime"] = $reader["LastRecordTime"]
            $recentActivity["ActiveSymbols"] = $reader["ActiveSymbols"]
        }
        $reader.Close()
        
        $connection.Close()
        
        return @{
            Tables = $tableData
            RecentActivity = $recentActivity
            Connected = $true
        }
    } catch {
        return @{
            Connected = $false
            Error = $_.Exception.Message
        }
    }
}

function Show-ServiceStatus {
    Clear-Host
    Write-ColorOutput "=== $ServiceName Health Monitor ===" -Color Green
    Write-ColorOutput "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Color Gray
    Write-ColorOutput ""
    
    # Service Process Status
    Write-ColorOutput "🔧 SERVICE PROCESS STATUS" -Color Yellow
    $processInfo = Get-ServiceProcessInfo
    if ($processInfo.Running) {
        Write-ColorOutput "✅ Status: RUNNING" -Color Green
        Write-ColorOutput "   PID: $($processInfo.PID)" -Color White
        Write-ColorOutput "   Start Time: $($processInfo.StartTime)" -Color White
        Write-ColorOutput "   Memory Usage: $($processInfo.MemoryUsage) MB" -Color White
        Write-ColorOutput "   CPU Time: $($processInfo.CPU)" -Color White
    } else {
        Write-ColorOutput "❌ Status: NOT RUNNING" -Color Red
    }
    Write-ColorOutput ""
    
    # Web API Status
    Write-ColorOutput "🌐 WEB API STATUS" -Color Yellow
    $webAPI = Test-WebAPI
    if ($webAPI.Available) {
        Write-ColorOutput "✅ Web API: RESPONDING" -Color Green
        Write-ColorOutput "   Status Code: $($webAPI.StatusCode)" -Color White
        Write-ColorOutput "   URL: http://localhost:5000" -Color Cyan
    } else {
        Write-ColorOutput "❌ Web API: NOT RESPONDING" -Color Red
        Write-ColorOutput "   Error: $($webAPI.Error)" -Color Red
    }
    Write-ColorOutput ""
    
    # Database Status
    Write-ColorOutput "🗄️ DATABASE STATUS" -Color Yellow
    $dbStatus = Get-DatabaseStatus
    if ($dbStatus.Connected) {
        Write-ColorOutput "✅ Database: CONNECTED" -Color Green
        
        # Table counts
        Write-ColorOutput "   Table Records:" -Color White
        foreach ($table in $dbStatus.Tables.Keys) {
            $count = $dbStatus.Tables[$table]
            if ($count -gt 0) {
                Write-ColorOutput "     $table`: $count records" -Color Green
            } else {
                Write-ColorOutput "     $table`: $count records" -Color Yellow
            }
        }
        
        # Recent activity
        if ($dbStatus.RecentActivity.RecentQuotes -gt 0) {
            Write-ColorOutput "   Recent Activity (last 10 min):" -Color White
            Write-ColorOutput "     Quotes: $($dbStatus.RecentActivity.RecentQuotes)" -Color Green
            Write-ColorOutput "     Active Symbols: $($dbStatus.RecentActivity.ActiveSymbols)" -Color Green
            Write-ColorOutput "     Last Record: $($dbStatus.RecentActivity.LastRecordTime)" -Color Green
        } else {
            Write-ColorOutput "   Recent Activity: No data in last 10 minutes" -Color Yellow
        }
    } else {
        Write-ColorOutput "❌ Database: CONNECTION FAILED" -Color Red
        Write-ColorOutput "   Error: $($dbStatus.Error)" -Color Red
    }
    Write-ColorOutput ""
    
    # Overall Health Assessment
    Write-ColorOutput "📊 OVERALL HEALTH ASSESSMENT" -Color Yellow
    $healthScore = 0
    $maxScore = 3
    
    if ($processInfo.Running) { $healthScore++ }
    if ($webAPI.Available) { $healthScore++ }
    if ($dbStatus.Connected) { $healthScore++ }
    
    $healthPercentage = [math]::Round(($healthScore / $maxScore) * 100)
    
    if ($healthPercentage -eq 100) {
        Write-ColorOutput "✅ HEALTH: EXCELLENT ($($healthPercentage) percent)" -Color Green
        Write-ColorOutput "   All systems operational" -Color Green
    } elseif ($healthPercentage -ge 66) {
        Write-ColorOutput "⚠️ HEALTH: GOOD ($($healthPercentage) percent)" -Color Yellow
        Write-ColorOutput "   Minor issues detected" -Color Yellow
    } elseif ($healthPercentage -ge 33) {
        Write-ColorOutput "⚠️ HEALTH: POOR ($($healthPercentage) percent)" -Color Yellow
        Write-ColorOutput "   Multiple issues detected" -Color Yellow
    } else {
        Write-ColorOutput "❌ HEALTH: CRITICAL ($($healthPercentage) percent)" -Color Red
        Write-ColorOutput "   Service needs immediate attention" -Color Red
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "📋 QUICK ACTIONS:" -Color Cyan
    Write-ColorOutput "   Start Service: .\RunServiceInBackground.ps1" -Color White
    Write-ColorOutput "   Stop Service: .\RunServiceInBackground.ps1 -Stop" -Color White
    Write-ColorOutput "   Restart Service: .\RunServiceInBackground.ps1 -Restart" -Color White
    Write-ColorOutput "   Web Interface: http://localhost:5000" -Color White
}

function Show-QuickStatus {
    $processInfo = Get-ServiceProcessInfo
    $webAPI = Test-WebAPI
    $dbStatus = Get-DatabaseStatus
    
    $status = "❌"
    $color = "Red"
    
    if ($processInfo.Running -and $webAPI.Available -and $dbStatus.Connected) {
        $status = "✅"
        $color = "Green"
    } elseif ($processInfo.Running -or $webAPI.Available -or $dbStatus.Connected) {
        $status = "⚠️"
        $color = "Yellow"
    }
    
    $runningStatus = if ($processInfo.Running) { "RUNNING" } else { "STOPPED" }
    $apiStatus = if ($webAPI.Available) { "OK" } else { "FAIL" }
    $dbStatusText = if ($dbStatus.Connected) { "OK" } else { "FAIL" }
    
    Write-ColorOutput "$status $ServiceName Status: $runningStatus | API: $apiStatus | DB: $dbStatusText" -Color $color
}

function Show-DetailedStatus {
    Show-ServiceStatus
    
    Write-ColorOutput "📁 LOG FILES:" -Color Yellow
    $logFiles = @(
        "$ServicePath\logs\KiteMarketDataService.log",
        "$ServicePath\logs\service_background.log"
    )
    
    foreach ($logFile in $logFiles) {
        if (Test-Path $logFile) {
            $fileInfo = Get-Item $logFile
            Write-ColorOutput "   $($fileInfo.Name): $([math]::Round($fileInfo.Length / 1KB, 2)) KB" -Color White
            Write-ColorOutput "     Last Modified: $($fileInfo.LastWriteTime)" -Color Gray
        }
    }
    
    Write-ColorOutput ""
    Write-ColorOutput "🔧 SYSTEM RESOURCES:" -Color Yellow
    $memory = Get-WmiObject -Class Win32_OperatingSystem
    $totalMemory = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)
    Write-ColorOutput "   Total Memory: $totalMemory MB" -Color White
    Write-ColorOutput "   Free Memory: $freeMemory MB" -Color White
    
    $processInfo = Get-ServiceProcessInfo
    if ($processInfo.Running) {
        Write-ColorOutput "   Service Memory: $($processInfo.MemoryUsage) MB" -Color White
    }
}

# Main execution
if ($Quick) {
    Show-QuickStatus
} elseif ($Detailed) {
    Show-DetailedStatus
} elseif ($Continuous) {
    Write-ColorOutput "Starting continuous monitoring..." -Color Green
    Write-ColorOutput "Press Ctrl+C to stop" -Color Yellow
    Write-ColorOutput ""
    
    while ($true) {
        Show-ServiceStatus
        Write-ColorOutput "Next check in 30 seconds..." -Color Gray
        Start-Sleep -Seconds 30
    }
} else {
    Show-ServiceStatus
}

Write-ColorOutput ""
