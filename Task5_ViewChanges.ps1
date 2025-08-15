# Task 5: View Change Reports
# Purpose: Display circuit limit changes
# Icon: 🟣 Purple Circle with "VIEW CHANGES" text

Write-Host "🟣 TASK 5: VIEWING CHANGE REPORTS" -ForegroundColor Magenta
Write-Host "================================================" -ForegroundColor Magenta

# Database connection parameters
$Server = "localhost"
$Database = "KiteMarketData"

Write-Host "📊 Generating circuit limit change reports..." -ForegroundColor Cyan
Write-Host "🔗 Database: $Server\$Database" -ForegroundColor Yellow

try {
    # Get current date
    $CurrentDate = Get-Date -Format "yyyy-MM-dd"
    Write-Host "📅 Date: $CurrentDate" -ForegroundColor Cyan
    
    # Check if there are any changes for today
    $ChangesQuery = "SELECT COUNT(*) as ChangeCount FROM CircuitLimitChanges WHERE TradingDate = '$CurrentDate'"
    $ChangeCount = sqlcmd -S $Server -d $Database -Q $ChangesQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    if ([int]$ChangeCount -eq 0) {
        Write-Host "ℹ️  INFO: No circuit limit changes found for today" -ForegroundColor Cyan
        Write-Host "💡 Run Task 4 first to detect changes" -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        exit 0
    }
    
    Write-Host "✅ Found $ChangeCount circuit limit changes" -ForegroundColor Green
    Write-Host ""
    
    # Get summary by change type
    Write-Host "📋 CHANGE SUMMARY BY TYPE:" -ForegroundColor Yellow
    Write-Host "==========================" -ForegroundColor Yellow
    
    $SummaryQuery = @"
    SELECT 
        ChangeType,
        COUNT(*) as Count,
        MIN(ChangeTime) as FirstChange,
        MAX(ChangeTime) as LastChange
    FROM CircuitLimitChanges 
    WHERE TradingDate = '$CurrentDate' 
    GROUP BY ChangeType 
    ORDER BY Count DESC
"@
    
    $Summary = sqlcmd -S $Server -d $Database -Q $SummaryQuery
    Write-Host $Summary -ForegroundColor Cyan
    
    Write-Host ""
    Write-Host "📊 DETAILED CHANGE REPORT:" -ForegroundColor Yellow
    Write-Host "==========================" -ForegroundColor Yellow
    
    # Get detailed changes (top 10)
    $DetailQuery = @"
    SELECT TOP 10
        TradingSymbol,
        Strike,
        InstrumentType,
        ChangeType,
        PreviousLC,
        NewLC,
        PreviousUC,
        NewUC,
        ChangeTime,
        IndexOHLC_Close as NiftyClose
    FROM CircuitLimitChanges 
    WHERE TradingDate = '$CurrentDate' 
    ORDER BY ChangeTime DESC
"@
    
    $Details = sqlcmd -S $Server -d $Database -Q $DetailQuery
    Write-Host $Details -ForegroundColor White
    
    # Save report to file
    $ReportFile = "C:\Users\babu\Desktop\KiteMarketDataService\CircuitLimitChanges_$CurrentDate.txt"
    $FullReportQuery = @"
    SELECT 
        TradingSymbol,
        Strike,
        InstrumentType,
        ChangeType,
        PreviousLC,
        NewLC,
        PreviousUC,
        NewUC,
        ChangeTime,
        IndexOHLC_Close as NiftyClose
    FROM CircuitLimitChanges 
    WHERE TradingDate = '$CurrentDate' 
    ORDER BY ChangeTime DESC
"@
    
    sqlcmd -S $Server -d $Database -Q $FullReportQuery -o $ReportFile
    
    Write-Host ""
    Write-Host "💾 Full report saved to: $ReportFile" -ForegroundColor Green
    Write-Host "💡 Next: Run Task 6 to analyze NIFTY options" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ ERROR: Failed to generate change reports" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔍 Check database connection and data availability" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 TASK 5 COMPLETED: Change reports generated" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
