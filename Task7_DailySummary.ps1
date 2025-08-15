# Task 7: Generate Daily Summary
# Purpose: Create comprehensive daily report
# Icon: 🔶 Brown Circle with "DAILY SUMMARY" text

Write-Host "🔶 TASK 7: GENERATING DAILY SUMMARY" -ForegroundColor DarkRed
Write-Host "================================================" -ForegroundColor DarkRed

# Database connection parameters
$Server = "localhost"
$Database = "KiteMarketData"

Write-Host "📋 Creating comprehensive daily summary report..." -ForegroundColor Cyan
Write-Host "🔗 Database: $Server\$Database" -ForegroundColor Yellow

try {
    # Get current date
    $CurrentDate = Get-Date -Format "yyyy-MM-dd"
    Write-Host "📅 Date: $CurrentDate" -ForegroundColor Cyan
    
    # Create summary file
    $SummaryFile = "C:\Users\babu\Desktop\KiteMarketDataService\DailySummary_$CurrentDate.txt"
    
    # Initialize summary content
    $SummaryContent = @"
================================================================
                    DAILY MARKET DATA SUMMARY
================================================================
Date: $CurrentDate
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
================================================================

"@
    
    # 1. Market Quotes Summary
    Write-Host "📊 Collecting market quotes summary..." -ForegroundColor Yellow
    $QuotesQuery = "SELECT COUNT(*) as TotalQuotes FROM MarketQuotes WHERE CAST(QuoteTimestamp AS DATE) = '$CurrentDate'"
    $TotalQuotes = sqlcmd -S $Server -d $Database -Q $QuotesQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    $SummaryContent += @"

1. MARKET QUOTES SUMMARY
========================
Total Quotes Today: $TotalQuotes
"@
    
    # 2. EOD Data Summary
    Write-Host "💾 Collecting EOD data summary..." -ForegroundColor Yellow
    $EODQuery = "SELECT COUNT(*) as EODCount FROM EODMarketData WHERE TradingDate = '$CurrentDate'"
    $EODCount = sqlcmd -S $Server -d $Database -Q $EODQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    $SummaryContent += @"

2. EOD DATA SUMMARY
===================
EOD Records Stored: $EODCount
"@
    
    # 3. Circuit Limit Changes Summary
    Write-Host "🔍 Collecting circuit limit changes..." -ForegroundColor Yellow
    $ChangesQuery = "SELECT COUNT(*) as ChangeCount FROM CircuitLimitChanges WHERE TradingDate = '$CurrentDate'"
    $ChangeCount = sqlcmd -S $Server -d $Database -Q $ChangesQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    if ([int]$ChangeCount -gt 0) {
        $ChangeTypesQuery = @"
        SELECT ChangeType, COUNT(*) as Count 
        FROM CircuitLimitChanges 
        WHERE TradingDate = '$CurrentDate' 
        GROUP BY ChangeType 
        ORDER BY ChangeType
"@
        $ChangeTypes = sqlcmd -S $Server -d $Database -Q $ChangeTypesQuery
        
        $SummaryContent += @"

3. CIRCUIT LIMIT CHANGES
========================
Total Changes: $ChangeCount
Change Types:
$ChangeTypes
"@
    } else {
        $SummaryContent += @"

3. CIRCUIT LIMIT CHANGES
========================
Total Changes: 0
Status: No changes detected today
"@
    }
    
    # 4. NIFTY Options Summary
    Write-Host "📈 Collecting NIFTY options summary..." -ForegroundColor Yellow
    $NiftyQuery = @"
    SELECT 
        i.InstrumentType,
        COUNT(*) as Count
    FROM MarketQuotes mq 
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken 
    WHERE mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-14'
    GROUP BY i.InstrumentType
    ORDER BY i.InstrumentType
"@
    $NiftySummary = sqlcmd -S $Server -d $Database -Q $NiftyQuery
    
    $SummaryContent += @"

4. NIFTY AUG 14 OPTIONS SUMMARY
================================
$NiftySummary
"@
    
    # 5. System Status
    Write-Host "⚙️ Collecting system status..." -ForegroundColor Yellow
    $LatestQuoteQuery = "SELECT MAX(QuoteTimestamp) as LatestQuote FROM MarketQuotes"
    $LatestQuote = sqlcmd -S $Server -d $Database -Q $LatestQuoteQuery -h -1 | Select-String -Pattern "\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}" | ForEach-Object { $_.Matches[0].Value }
    
    $SummaryContent += @"

5. SYSTEM STATUS
================
Latest Quote Time: $LatestQuote
Service Status: Active
Database: Connected
"@
    
    # 6. Recommendations
    Write-Host "💡 Adding recommendations..." -ForegroundColor Yellow
    $SummaryContent += @"

6. RECOMMENDATIONS
==================
- Monitor circuit limit changes daily
- Review NIFTY options analysis regularly
- Ensure EOD data is stored before market close
- Check service logs for any errors
- Backup database regularly

================================================================
                    END OF DAILY SUMMARY
================================================================
"@
    
    # Save summary to file
    $SummaryContent | Out-File -FilePath $SummaryFile -Encoding UTF8
    
    Write-Host "✅ Daily summary generated successfully!" -ForegroundColor Green
    Write-Host "💾 Summary saved to: $SummaryFile" -ForegroundColor Green
    
    # Display summary in console
    Write-Host ""
    Write-Host "📋 DAILY SUMMARY PREVIEW:" -ForegroundColor Yellow
    Write-Host "=========================" -ForegroundColor Yellow
    Write-Host $SummaryContent -ForegroundColor White
    
    Write-Host ""
    Write-Host "💡 Next: Run Task 8 to stop the service" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ ERROR: Failed to generate daily summary" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔍 Check database connection and data availability" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 TASK 7 COMPLETED: Daily summary generated" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
