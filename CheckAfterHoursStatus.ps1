# Check Service Status After Market Hours
$utcTime = Get-Date
$istTime = $utcTime.AddHours(5.5)

Write-Host "=== AFTER MARKET HOURS SERVICE CHECK ===" -ForegroundColor Green
Write-Host ""
Write-Host "Current UTC Time: $($utcTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "Current IST Time: $($istTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host ""
Write-Host "Market Hours: 09:15 AM - 03:30 PM IST" -ForegroundColor Yellow
Write-Host ""

$marketOpen = [TimeSpan]::new(9, 15, 0)
$marketClose = [TimeSpan]::new(15, 30, 0)
$currentTime = $istTime.TimeOfDay

if ($currentTime -ge $marketOpen -and $currentTime -le $marketClose) {
    Write-Host "Status: MARKET IS OPEN" -ForegroundColor Green
} else {
    Write-Host "Status: MARKET IS CLOSED (After Hours)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SERVICE PROCESS STATUS ===" -ForegroundColor Green

$processes = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "✅ Service Process: RUNNING" -ForegroundColor Green
    foreach ($proc in $processes) {
        $uptime = $utcTime - $proc.StartTime
        Write-Host "  PID: $($proc.Id)" -ForegroundColor White
        Write-Host "  Start Time: $($proc.StartTime)" -ForegroundColor White
        Write-Host "  Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -ForegroundColor White
    }
} else {
    Write-Host "❌ Service Process: NOT RUNNING" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== RECENT DATA COLLECTION (Last 30 minutes) ===" -ForegroundColor Green

$connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"
$recentQuotes = 0
$lastRecord = $null

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            COUNT(*) as RecentQuotes,
            MAX(RecordDateTime) as LastRecordTime,
            COUNT(DISTINCT TradingSymbol) as ActiveSymbols
        FROM MarketQuotes 
        WHERE RecordDateTime >= DATEADD(minute, -30, GETUTCDATE())
          AND BusinessDate = '2025-10-29'
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        $recentQuotes = $reader["RecentQuotes"]
        $lastRecord = $reader["LastRecordTime"]
        $activeSymbols = $reader["ActiveSymbols"]
        
        Write-Host "Recent Quotes (last 30 min): $recentQuotes" -ForegroundColor White
        Write-Host "Active Symbols: $activeSymbols" -ForegroundColor White
        Write-Host "Last Record Time: $lastRecord" -ForegroundColor White
        Write-Host ""
        
        if ($recentQuotes -gt 0) {
            Write-Host "✅ SERVICE IS ACTIVE AND COLLECTING DATA!" -ForegroundColor Green
            Write-Host "Even after market hours, service may collect data (after-hours trading, updates, etc.)" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️ NO RECENT DATA COLLECTION" -ForegroundColor Yellow
            Write-Host "Service may be idle after market hours (normal behavior)" -ForegroundColor Yellow
        }
        
        # Calculate time since last record
        if ($lastRecord -ne [DBNull]::Value) {
            $lastRecordTime = [DateTime]$lastRecord
            $timeSinceLastRecord = $utcTime - $lastRecordTime
            Write-Host "Time since last record: $($timeSinceLastRecord.Hours)h $($timeSinceLastRecord.Minutes)m $($timeSinceLastRecord.Seconds)s" -ForegroundColor Gray
        }
    }
    
    $reader.Close()
    $connection.Close()
    
} catch {
    Write-Host "Database check error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SERVICE STATUS SUMMARY ===" -ForegroundColor Green

$hasProcess = ($processes -ne $null -and $processes.Count -gt 0)
$hasRecentData = ($recentQuotes -gt 0)

if ($hasProcess -and $hasRecentData) {
    Write-Host "✅ Service Status: ACTIVE (Running and collecting data)" -ForegroundColor Green
} elseif ($hasProcess -and -not $hasRecentData) {
    Write-Host "⚠️ Service Status: RUNNING BUT IDLE (Process active but no recent data)" -ForegroundColor Yellow
    Write-Host "This is normal after market hours - service stays running but waits for next market session" -ForegroundColor Cyan
} else {
    Write-Host "❌ Service Status: NOT RUNNING" -ForegroundColor Red
}


$istTime = $utcTime.AddHours(5.5)

Write-Host "=== AFTER MARKET HOURS SERVICE CHECK ===" -ForegroundColor Green
Write-Host ""
Write-Host "Current UTC Time: $($utcTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "Current IST Time: $($istTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host ""
Write-Host "Market Hours: 09:15 AM - 03:30 PM IST" -ForegroundColor Yellow
Write-Host ""

$marketOpen = [TimeSpan]::new(9, 15, 0)
$marketClose = [TimeSpan]::new(15, 30, 0)
$currentTime = $istTime.TimeOfDay

if ($currentTime -ge $marketOpen -and $currentTime -le $marketClose) {
    Write-Host "Status: MARKET IS OPEN" -ForegroundColor Green
} else {
    Write-Host "Status: MARKET IS CLOSED (After Hours)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SERVICE PROCESS STATUS ===" -ForegroundColor Green

$processes = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "✅ Service Process: RUNNING" -ForegroundColor Green
    foreach ($proc in $processes) {
        $uptime = $utcTime - $proc.StartTime
        Write-Host "  PID: $($proc.Id)" -ForegroundColor White
        Write-Host "  Start Time: $($proc.StartTime)" -ForegroundColor White
        Write-Host "  Uptime: $($uptime.Days) days, $($uptime.Hours) hours, $($uptime.Minutes) minutes" -ForegroundColor White
    }
} else {
    Write-Host "❌ Service Process: NOT RUNNING" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== RECENT DATA COLLECTION (Last 30 minutes) ===" -ForegroundColor Green

$connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"
$recentQuotes = 0
$lastRecord = $null

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            COUNT(*) as RecentQuotes,
            MAX(RecordDateTime) as LastRecordTime,
            COUNT(DISTINCT TradingSymbol) as ActiveSymbols
        FROM MarketQuotes 
        WHERE RecordDateTime >= DATEADD(minute, -30, GETUTCDATE())
          AND BusinessDate = '2025-10-29'
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        $recentQuotes = $reader["RecentQuotes"]
        $lastRecord = $reader["LastRecordTime"]
        $activeSymbols = $reader["ActiveSymbols"]
        
        Write-Host "Recent Quotes (last 30 min): $recentQuotes" -ForegroundColor White
        Write-Host "Active Symbols: $activeSymbols" -ForegroundColor White
        Write-Host "Last Record Time: $lastRecord" -ForegroundColor White
        Write-Host ""
        
        if ($recentQuotes -gt 0) {
            Write-Host "✅ SERVICE IS ACTIVE AND COLLECTING DATA!" -ForegroundColor Green
            Write-Host "Even after market hours, service may collect data (after-hours trading, updates, etc.)" -ForegroundColor Cyan
        } else {
            Write-Host "⚠️ NO RECENT DATA COLLECTION" -ForegroundColor Yellow
            Write-Host "Service may be idle after market hours (normal behavior)" -ForegroundColor Yellow
        }
        
        # Calculate time since last record
        if ($lastRecord -ne [DBNull]::Value) {
            $lastRecordTime = [DateTime]$lastRecord
            $timeSinceLastRecord = $utcTime - $lastRecordTime
            Write-Host "Time since last record: $($timeSinceLastRecord.Hours)h $($timeSinceLastRecord.Minutes)m $($timeSinceLastRecord.Seconds)s" -ForegroundColor Gray
        }
    }
    
    $reader.Close()
    $connection.Close()
    
} catch {
    Write-Host "Database check error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== SERVICE STATUS SUMMARY ===" -ForegroundColor Green

$hasProcess = ($processes -ne $null -and $processes.Count -gt 0)
$hasRecentData = ($recentQuotes -gt 0)

if ($hasProcess -and $hasRecentData) {
    Write-Host "✅ Service Status: ACTIVE (Running and collecting data)" -ForegroundColor Green
} elseif ($hasProcess -and -not $hasRecentData) {
    Write-Host "⚠️ Service Status: RUNNING BUT IDLE (Process active but no recent data)" -ForegroundColor Yellow
    Write-Host "This is normal after market hours - service stays running but waits for next market session" -ForegroundColor Cyan
} else {
    Write-Host "❌ Service Status: NOT RUNNING" -ForegroundColor Red
}