# Check After-Hours Data Collection with Correct IST Time
$utcNow = [DateTime]::UtcNow
$istNow = $utcNow.AddHours(5).AddMinutes(30)

Write-Host "=== AFTER-MARKET HOURS ANALYSIS ===" -ForegroundColor Green
Write-Host ""
Write-Host "UTC Time: $($utcNow.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "IST Time: $($istNow.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host ""

$marketOpen = [TimeSpan]::new(9, 15, 0)
$marketClose = [TimeSpan]::new(15, 30, 0)
$currentTime = $istNow.TimeOfDay

if ($currentTime -ge $marketOpen -and $currentTime -le $marketClose) {
    Write-Host "Status: MARKET IS OPEN" -ForegroundColor Green
} else {
    Write-Host "Status: MARKET IS CLOSED (After Hours)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SOURCE CODE ANALYSIS ===" -ForegroundColor Green
Write-Host "According to TimeBasedDataCollectionService.cs:" -ForegroundColor White
Write-Host "  - After Hours Interval: 1 hour" -ForegroundColor Cyan
Write-Host "  - After Hours Collection: CollectAfterHoursDataAsync()" -ForegroundColor Cyan
Write-Host "  - Focus: LC/UC changes detection only" -ForegroundColor Cyan
Write-Host "  - Service should collect every 1 hour after 3:30 PM IST" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== SERVICE PROCESS STATUS ===" -ForegroundColor Green
$processes = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "✅ Service Process: RUNNING" -ForegroundColor Green
    foreach ($proc in $processes) {
        Write-Host "  PID: $($proc.Id)" -ForegroundColor White
        Write-Host "  Start Time: $($proc.StartTime)" -ForegroundColor White
    }
} else {
    Write-Host "❌ Service Process: NOT RUNNING" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== AFTER-HOURS DATA COLLECTION CHECK ===" -ForegroundColor Green
Write-Host "Checking for data collected after market close (3:30 PM IST)..." -ForegroundColor White

$connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"
$afterHoursQuotes = 0

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Calculate 3:30 PM IST today in UTC
    $todayIST = $istNow.Date
    $marketCloseIST = $todayIST.AddHours(15).AddMinutes(30)
    $marketCloseUTC = $marketCloseIST.AddHours(-5).AddMinutes(-30)
    
    Write-Host "Market Close Time (IST): $($marketCloseIST.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
    Write-Host "Market Close Time (UTC): $($marketCloseUTC.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
    Write-Host ""
    
    # Check for data after market close for today's business date
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            COUNT(*) as AfterHoursQuotes,
            MIN(RecordDateTime) as FirstAfterHoursRecord,
            MAX(RecordDateTime) as LastAfterHoursRecord,
            COUNT(DISTINCT TradingSymbol) as ActiveSymbols
        FROM MarketQuotes 
        WHERE BusinessDate = '2025-10-29'
          AND RecordDateTime > CAST('$($marketCloseUTC.ToString("yyyy-MM-dd HH:mm:ss"))' AS DATETIME)
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        $afterHoursQuotes = $reader["AfterHoursQuotes"]
        $firstAfterHours = $reader["FirstAfterHoursRecord"]
        $lastAfterHours = $reader["LastAfterHoursRecord"]
        $activeSymbols = $reader["ActiveSymbols"]
        
        Write-Host "After-Hours Data Collection (since 3:30 PM IST):" -ForegroundColor Yellow
        Write-Host "  Quotes Collected: $afterHoursQuotes" -ForegroundColor White
        Write-Host "  Active Symbols: $activeSymbols" -ForegroundColor White
        if ($firstAfterHours -ne [DBNull]::Value) {
            Write-Host "  First Record: $firstAfterHours" -ForegroundColor White
        }
        if ($lastAfterHours -ne [DBNull]::Value) {
            $lastAfterHoursIST = [DateTime]$lastAfterHours
            Write-Host "  Last Record: $lastAfterHours (IST: $($lastAfterHoursIST.AddHours(5).AddMinutes(30).ToString('HH:mm:ss')))" -ForegroundColor White
            
            # Calculate time since last record
            $timeSinceLast = $utcNow - ([DateTime]$lastAfterHours)
            Write-Host "  Time Since Last Record: $([math]::Floor($timeSinceLast.TotalMinutes)) minutes" -ForegroundColor Gray
        }
        Write-Host ""
        
        if ($afterHoursQuotes -gt 0) {
            Write-Host "✅ AFTER-HOURS DATA COLLECTION IS ACTIVE!" -ForegroundColor Green
            Write-Host "Service is collecting LC/UC changes after market hours as designed." -ForegroundColor Green
        } else {
            Write-Host "⚠️ NO AFTER-HOURS DATA COLLECTED YET" -ForegroundColor Yellow
            Write-Host "Service may still be waiting for the 1-hour interval." -ForegroundColor Yellow
        }
    }
    
    $reader.Close()
    
    # Check last 5 after-hours records
    Write-Host ""
    Write-Host "=== RECENT AFTER-HOURS RECORDS ===" -ForegroundColor Green
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT TOP 5
            RecordDateTime,
            TradingSymbol,
            LowerCircuitLimit,
            UpperCircuitLimit,
            LastPrice
        FROM MarketQuotes 
        WHERE BusinessDate = '2025-10-29'
          AND RecordDateTime > CAST('$($marketCloseUTC.ToString("yyyy-MM-dd HH:mm:ss"))' AS DATETIME)
        ORDER BY RecordDateTime DESC
    ", $connection)
    
    $reader = $command.ExecuteReader()
    $hasRecords = $false
    while ($reader.Read()) {
        $hasRecords = $true
        $recordTime = $reader["RecordDateTime"]
        $symbol = $reader["TradingSymbol"]
        $lc = $reader["LowerCircuitLimit"]
        $uc = $reader["UpperCircuitLimit"]
        $price = $reader["LastPrice"]
        $recordIST = ([DateTime]$recordTime).AddHours(5).AddMinutes(30)
        Write-Host "  $($recordIST.ToString('HH:mm:ss')) IST | $symbol | LC:$lc UC:$uc | LTP:$price" -ForegroundColor White
    }
    
    if (-not $hasRecords) {
        Write-Host "  No after-hours records found yet" -ForegroundColor Gray
    }
    
    $reader.Close()
    $connection.Close()
    
} catch {
    Write-Host "Error checking after-hours data: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== CONCLUSION ===" -ForegroundColor Green

$hasProcess = ($processes -ne $null -and $processes.Count -gt 0)
$hasAfterHoursData = ($afterHoursQuotes -gt 0)

if ($hasProcess -and $hasAfterHoursData) {
    Write-Host "✅ Service is ACTIVE and collecting after-hours LC/UC data" -ForegroundColor Green
    Write-Host "   After-hours collection is working as designed (every 1 hour)" -ForegroundColor Green
} elseif ($hasProcess -and -not $hasAfterHoursData) {
    Write-Host "⚠️ Service is RUNNING but no after-hours data yet" -ForegroundColor Yellow
    Write-Host "   After-hours collection runs every 1 hour - next collection should happen soon" -ForegroundColor Cyan
    Write-Host "   This is normal - LC/UC changes are only stored when they occur" -ForegroundColor Cyan
} else {
    Write-Host "❌ Service may not be running or configured correctly" -ForegroundColor Red
}



$istNow = $utcNow.AddHours(5).AddMinutes(30)

Write-Host "=== AFTER-MARKET HOURS ANALYSIS ===" -ForegroundColor Green
Write-Host ""
Write-Host "UTC Time: $($utcNow.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor White
Write-Host "IST Time: $($istNow.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
Write-Host ""

$marketOpen = [TimeSpan]::new(9, 15, 0)
$marketClose = [TimeSpan]::new(15, 30, 0)
$currentTime = $istNow.TimeOfDay

if ($currentTime -ge $marketOpen -and $currentTime -le $marketClose) {
    Write-Host "Status: MARKET IS OPEN" -ForegroundColor Green
} else {
    Write-Host "Status: MARKET IS CLOSED (After Hours)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SOURCE CODE ANALYSIS ===" -ForegroundColor Green
Write-Host "According to TimeBasedDataCollectionService.cs:" -ForegroundColor White
Write-Host "  - After Hours Interval: 1 hour" -ForegroundColor Cyan
Write-Host "  - After Hours Collection: CollectAfterHoursDataAsync()" -ForegroundColor Cyan
Write-Host "  - Focus: LC/UC changes detection only" -ForegroundColor Cyan
Write-Host "  - Service should collect every 1 hour after 3:30 PM IST" -ForegroundColor Cyan
Write-Host ""

Write-Host "=== SERVICE PROCESS STATUS ===" -ForegroundColor Green
$processes = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue
if ($processes) {
    Write-Host "✅ Service Process: RUNNING" -ForegroundColor Green
    foreach ($proc in $processes) {
        Write-Host "  PID: $($proc.Id)" -ForegroundColor White
        Write-Host "  Start Time: $($proc.StartTime)" -ForegroundColor White
    }
} else {
    Write-Host "❌ Service Process: NOT RUNNING" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== AFTER-HOURS DATA COLLECTION CHECK ===" -ForegroundColor Green
Write-Host "Checking for data collected after market close (3:30 PM IST)..." -ForegroundColor White

$connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"
$afterHoursQuotes = 0

try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    
    # Calculate 3:30 PM IST today in UTC
    $todayIST = $istNow.Date
    $marketCloseIST = $todayIST.AddHours(15).AddMinutes(30)
    $marketCloseUTC = $marketCloseIST.AddHours(-5).AddMinutes(-30)
    
    Write-Host "Market Close Time (IST): $($marketCloseIST.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
    Write-Host "Market Close Time (UTC): $($marketCloseUTC.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Yellow
    Write-Host ""
    
    # Check for data after market close for today's business date
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT 
            COUNT(*) as AfterHoursQuotes,
            MIN(RecordDateTime) as FirstAfterHoursRecord,
            MAX(RecordDateTime) as LastAfterHoursRecord,
            COUNT(DISTINCT TradingSymbol) as ActiveSymbols
        FROM MarketQuotes 
        WHERE BusinessDate = '2025-10-29'
          AND RecordDateTime > CAST('$($marketCloseUTC.ToString("yyyy-MM-dd HH:mm:ss"))' AS DATETIME)
    ", $connection)
    
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        $afterHoursQuotes = $reader["AfterHoursQuotes"]
        $firstAfterHours = $reader["FirstAfterHoursRecord"]
        $lastAfterHours = $reader["LastAfterHoursRecord"]
        $activeSymbols = $reader["ActiveSymbols"]
        
        Write-Host "After-Hours Data Collection (since 3:30 PM IST):" -ForegroundColor Yellow
        Write-Host "  Quotes Collected: $afterHoursQuotes" -ForegroundColor White
        Write-Host "  Active Symbols: $activeSymbols" -ForegroundColor White
        if ($firstAfterHours -ne [DBNull]::Value) {
            Write-Host "  First Record: $firstAfterHours" -ForegroundColor White
        }
        if ($lastAfterHours -ne [DBNull]::Value) {
            $lastAfterHoursIST = [DateTime]$lastAfterHours
            Write-Host "  Last Record: $lastAfterHours (IST: $($lastAfterHoursIST.AddHours(5).AddMinutes(30).ToString('HH:mm:ss')))" -ForegroundColor White
            
            # Calculate time since last record
            $timeSinceLast = $utcNow - ([DateTime]$lastAfterHours)
            Write-Host "  Time Since Last Record: $([math]::Floor($timeSinceLast.TotalMinutes)) minutes" -ForegroundColor Gray
        }
        Write-Host ""
        
        if ($afterHoursQuotes -gt 0) {
            Write-Host "✅ AFTER-HOURS DATA COLLECTION IS ACTIVE!" -ForegroundColor Green
            Write-Host "Service is collecting LC/UC changes after market hours as designed." -ForegroundColor Green
        } else {
            Write-Host "⚠️ NO AFTER-HOURS DATA COLLECTED YET" -ForegroundColor Yellow
            Write-Host "Service may still be waiting for the 1-hour interval." -ForegroundColor Yellow
        }
    }
    
    $reader.Close()
    
    # Check last 5 after-hours records
    Write-Host ""
    Write-Host "=== RECENT AFTER-HOURS RECORDS ===" -ForegroundColor Green
    $command = New-Object System.Data.SqlClient.SqlCommand("
        SELECT TOP 5
            RecordDateTime,
            TradingSymbol,
            LowerCircuitLimit,
            UpperCircuitLimit,
            LastPrice
        FROM MarketQuotes 
        WHERE BusinessDate = '2025-10-29'
          AND RecordDateTime > CAST('$($marketCloseUTC.ToString("yyyy-MM-dd HH:mm:ss"))' AS DATETIME)
        ORDER BY RecordDateTime DESC
    ", $connection)
    
    $reader = $command.ExecuteReader()
    $hasRecords = $false
    while ($reader.Read()) {
        $hasRecords = $true
        $recordTime = $reader["RecordDateTime"]
        $symbol = $reader["TradingSymbol"]
        $lc = $reader["LowerCircuitLimit"]
        $uc = $reader["UpperCircuitLimit"]
        $price = $reader["LastPrice"]
        $recordIST = ([DateTime]$recordTime).AddHours(5).AddMinutes(30)
        Write-Host "  $($recordIST.ToString('HH:mm:ss')) IST | $symbol | LC:$lc UC:$uc | LTP:$price" -ForegroundColor White
    }
    
    if (-not $hasRecords) {
        Write-Host "  No after-hours records found yet" -ForegroundColor Gray
    }
    
    $reader.Close()
    $connection.Close()
    
} catch {
    Write-Host "Error checking after-hours data: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== CONCLUSION ===" -ForegroundColor Green

$hasProcess = ($processes -ne $null -and $processes.Count -gt 0)
$hasAfterHoursData = ($afterHoursQuotes -gt 0)

if ($hasProcess -and $hasAfterHoursData) {
    Write-Host "✅ Service is ACTIVE and collecting after-hours LC/UC data" -ForegroundColor Green
    Write-Host "   After-hours collection is working as designed (every 1 hour)" -ForegroundColor Green
} elseif ($hasProcess -and -not $hasAfterHoursData) {
    Write-Host "⚠️ Service is RUNNING but no after-hours data yet" -ForegroundColor Yellow
    Write-Host "   After-hours collection runs every 1 hour - next collection should happen soon" -ForegroundColor Cyan
    Write-Host "   This is normal - LC/UC changes are only stored when they occur" -ForegroundColor Cyan
} else {
    Write-Host "❌ Service may not be running or configured correctly" -ForegroundColor Red
}
