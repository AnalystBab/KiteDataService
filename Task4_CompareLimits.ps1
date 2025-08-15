# Task 4: Compare Circuit Limits
# Purpose: Detect changes in LC/UC values
# Icon: 🔵 Blue Circle with "COMPARE LIMITS" text

Write-Host "🔵 TASK 4: COMPARING CIRCUIT LIMITS" -ForegroundColor Blue
Write-Host "================================================" -ForegroundColor Blue

# Database connection parameters
$Server = "localhost"
$Database = "KiteMarketData"

Write-Host "🔍 Detecting circuit limit changes..." -ForegroundColor Cyan
Write-Host "🔗 Database: $Server\$Database" -ForegroundColor Yellow

try {
    # Get current date
    $CurrentDate = Get-Date -Format "yyyy-MM-dd"
    Write-Host "📅 Date: $CurrentDate" -ForegroundColor Cyan
    
    # Check if we have EOD data for yesterday
    $Yesterday = (Get-Date).AddDays(-1).ToString("yyyy-MM-dd")
    $YesterdayEODQuery = "SELECT COUNT(*) as YesterdayCount FROM EODMarketData WHERE TradingDate = '$Yesterday'"
    $YesterdayCount = sqlcmd -S $Server -d $Database -Q $YesterdayEODQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    if ([int]$YesterdayCount -eq 0) {
        Write-Host "⚠️  WARNING: No EOD data found for yesterday ($Yesterday)" -ForegroundColor Yellow
        Write-Host "📋 You need EOD data from yesterday to compare changes" -ForegroundColor Yellow
        Write-Host "💡 Run Task 3 first to store today's EOD data" -ForegroundColor Yellow
        Write-Host "🔄 Then run this task tomorrow to compare changes" -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        exit 0
    }
    
    Write-Host "✅ Found $YesterdayCount EOD records from yesterday" -ForegroundColor Green
    Write-Host "⏳ Executing circuit limit comparison..." -ForegroundColor Yellow
    
    # Execute the DetectCircuitLimitChanges procedure
    $CompareQuery = "EXEC DetectCircuitLimitChanges"
    $Result = sqlcmd -S $Server -d $Database -Q $CompareQuery
    
    # Check the result
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Circuit limit comparison completed!" -ForegroundColor Green
        
        # Get the count of changes detected
        $ChangesQuery = "SELECT COUNT(*) as ChangeCount FROM CircuitLimitChanges WHERE TradingDate = '$CurrentDate'"
        $ChangeCount = sqlcmd -S $Server -d $Database -Q $ChangesQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
        
        # Get breakdown by change type
        $ChangeTypesQuery = @"
        SELECT ChangeType, COUNT(*) as Count 
        FROM CircuitLimitChanges 
        WHERE TradingDate = '$CurrentDate' 
        GROUP BY ChangeType 
        ORDER BY ChangeType
"@
        $ChangeTypes = sqlcmd -S $Server -d $Database -Q $ChangeTypesQuery
        
        Write-Host ""
        Write-Host "📊 CIRCUIT LIMIT CHANGES SUMMARY:" -ForegroundColor Yellow
        Write-Host "=================================" -ForegroundColor Yellow
        Write-Host "📅 Date: $CurrentDate" -ForegroundColor Cyan
        Write-Host "📈 Total Changes: $ChangeCount" -ForegroundColor Cyan
        Write-Host "📋 Change Types:" -ForegroundColor Cyan
        
        if ([int]$ChangeCount -gt 0) {
            Write-Host "✅ Changes detected! Run Task 5 to view detailed reports" -ForegroundColor Green
        } else {
            Write-Host "✅ No circuit limit changes detected today" -ForegroundColor Green
        }
        
        Write-Host "💡 Next: Run Task 5 to view change reports" -ForegroundColor Yellow
        
    } else {
        Write-Host "❌ ERROR: Failed to compare circuit limits" -ForegroundColor Red
        Write-Host "Check database connection and stored procedure" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ ERROR: Failed to execute circuit limit comparison" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔍 Check database connection and stored procedure status" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 TASK 4 COMPLETED: Circuit limit comparison finished" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
