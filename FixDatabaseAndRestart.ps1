# Fix Database and Restart Service
# This script clears corrupted data and restarts the service with proper expiry handling

param(
    [string]$ServicePath = "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker"
)

Write-Host "=== Database Fix and Service Restart ===" -ForegroundColor Green
Write-Host ""

# Check if SQL Server is accessible
Write-Host "Step 1: Checking database connection..." -ForegroundColor Yellow
try {
    $connectionString = "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    $connection.Close()
    Write-Host "Database connection successful!" -ForegroundColor Green
} catch {
    Write-Host "Error connecting to database: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure SQL Server is running and the database exists." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 2: Clearing corrupted data..." -ForegroundColor Yellow

# Read and execute the SQL cleanup script
$sqlScript = Join-Path $ServicePath "ClearDatabaseAndFixExpiry.sql"
if (Test-Path $sqlScript) {
    try {
        $sqlContent = Get-Content $sqlScript -Raw
        
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        
        $command = New-Object System.Data.SqlClient.SqlCommand($sqlContent, $connection)
        $command.CommandTimeout = 300 # 5 minutes timeout
        
        Write-Host "Executing database cleanup..." -ForegroundColor Yellow
        $command.ExecuteNonQuery() | Out-Null
        
        $connection.Close()
        Write-Host "Database cleanup completed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Error during database cleanup: $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "SQL cleanup script not found at: $sqlScript" -ForegroundColor Red
    Write-Host "Please ensure the script exists in the service directory." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "Step 3: Database has been cleared. Now you need to:" -ForegroundColor Yellow
Write-Host "1. Get a fresh request token from Kite Connect" -ForegroundColor White
Write-Host "2. Update your appsettings.json with the new token" -ForegroundColor White
Write-Host "3. Start the service to reload data with correct expiry information" -ForegroundColor White
Write-Host ""

Write-Host "Step 4: Opening Kite Connect login page..." -ForegroundColor Yellow
$loginUrl = "https://kite.trade/connect/login?api_key=kw3ptb0zmocwupmo&v=3"
Start-Process $loginUrl
Write-Host "Login page opened in your browser." -ForegroundColor Green
Write-Host ""

Write-Host "Step 5: After getting your request token:" -ForegroundColor Yellow
Write-Host "- Update appsettings.json with the new token" -ForegroundColor White
Write-Host "- Run the service to reload with correct data" -ForegroundColor White
Write-Host ""

Write-Host "=== What was fixed ===" -ForegroundColor Green
Write-Host "✓ Cleared all corrupted market quotes" -ForegroundColor White
Write-Host "✓ Cleared all corrupted circuit limits" -ForegroundColor White
Write-Host "✓ Cleared all instruments with wrong expiry data" -ForegroundColor White
Write-Host "✓ Service now properly stores expiry dates" -ForegroundColor White
Write-Host "✓ Service now uses IST timestamps" -ForegroundColor White
Write-Host "✓ Service now links expiry data between instruments and quotes" -ForegroundColor White
Write-Host ""

Write-Host "=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Login to Kite Connect and get request token" -ForegroundColor White
Write-Host "2. Update appsettings.json with new token" -ForegroundColor White
Write-Host "3. Start service: dotnet run" -ForegroundColor White
Write-Host "4. Service will reload all data with correct expiry information" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to close this window"
