# Task 6: Analyze NIFTY Options
# Purpose: Get NIFTY options with EOD comparison
# Icon: 🟠 Orange Circle with "ANALYZE NIFTY" text

Write-Host "🟠 TASK 6: ANALYZING NIFTY OPTIONS" -ForegroundColor DarkYellow
Write-Host "================================================" -ForegroundColor DarkYellow

# Database connection parameters
$Server = "localhost"
$Database = "KiteMarketData"

Write-Host "📈 Analyzing NIFTY options with EOD comparison..." -ForegroundColor Cyan
Write-Host "🔗 Database: $Server\$Database" -ForegroundColor Yellow

try {
    # Get current date
    $CurrentDate = Get-Date -Format "yyyy-MM-dd"
    Write-Host "📅 Date: $CurrentDate" -ForegroundColor Cyan
    
    # Check if EOD data exists for today
    $EODQuery = "SELECT COUNT(*) as EODCount FROM EODMarketData WHERE TradingDate = '$CurrentDate'"
    $EODCount = sqlcmd -S $Server -d $Database -Q $EODQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    if ([int]$EODCount -eq 0) {
        Write-Host "⚠️  WARNING: No EOD data found for today" -ForegroundColor Yellow
        Write-Host "💡 Run Task 3 first to store EOD data" -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        exit 0
    }
    
    Write-Host "✅ Found $EODCount EOD records for today" -ForegroundColor Green
    Write-Host ""
    
    # Get NIFTY Aug 14 CALL options count
    $NiftyQuery = @"
    SELECT COUNT(*) as NiftyCount 
    FROM MarketQuotes mq 
    INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken 
    WHERE mq.TradingSymbol LIKE 'NIFTY%' 
    AND CAST(mq.Expiry AS DATE) = '2025-08-14' 
    AND i.InstrumentType = 'CE'
"@
    
    $NiftyCount = sqlcmd -S $Server -d $Database -Q $NiftyQuery -h -1 | Select-String -Pattern "\d+" | ForEach-Object { $_.Matches[0].Value }
    
    Write-Host "📊 NIFTY ANALYSIS SUMMARY:" -ForegroundColor Yellow
    Write-Host "=========================" -ForegroundColor Yellow
    Write-Host "📅 Analysis Date: $CurrentDate" -ForegroundColor Cyan
    Write-Host "📈 NIFTY Aug 14 CALL Options: $NiftyCount" -ForegroundColor Cyan
    Write-Host "💾 EOD Data Available: $EODCount records" -ForegroundColor Cyan
    Write-Host ""
    
    # Run the NIFTY analysis query
    Write-Host "🔍 Executing NIFTY analysis query..." -ForegroundColor Yellow
    
    $AnalysisQuery = @"
    WITH LatestCALLQuotes AS (
        SELECT 
            mq.InstrumentToken,
            mq.TradingSymbol,
            mq.Exchange,
            mq.Expiry,
            mq.OHLC_Open,
            mq.OHLC_High,
            mq.OHLC_Low,
            mq.OHLC_Close,
            mq.LastPrice,
            mq.Volume,
            mq.OpenInterest,
            mq.LowerCircuitLimit,
            mq.UpperCircuitLimit,
            mq.QuoteTimestamp,
            i.Strike,
            i.InstrumentType,
            ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
        FROM MarketQuotes mq
        INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
        WHERE 
            mq.TradingSymbol LIKE 'NIFTY%' 
            AND CAST(mq.Expiry AS DATE) = '2025-08-14'
            AND i.InstrumentType = 'CE'
            AND mq.Expiry IS NOT NULL
    )
    SELECT TOP 20
        lq.Strike AS StrkPric,
        lq.OHLC_Open AS OpnPric,
        lq.OHLC_High AS HghPric,
        lq.OHLC_Low AS LwPric,
        lq.OHLC_Close AS ClsPric,
        lq.LastPrice AS LastPric,
        lq.LowerCircuitLimit AS lowerLimit,
        lq.UpperCircuitLimit AS UpperLimit,
        eod.LowerCircuitLimit as EOD_LC,
        eod.UpperCircuitLimit as EOD_UC,
        eod.OHLC_Close as EOD_Close,
        eod.LastPrice as EOD_LastPrice,
        CASE 
            WHEN eod.LowerCircuitLimit != lq.LowerCircuitLimit THEN 'LC_CHANGED'
            WHEN eod.UpperCircuitLimit != lq.UpperCircuitLimit THEN 'UC_CHANGED'
            ELSE 'NO_CHANGE'
        END as CircuitChange
    FROM LatestCALLQuotes lq
    LEFT JOIN EODMarketData eod ON lq.TradingSymbol = eod.TradingSymbol 
        AND eod.TradingDate = '$CurrentDate'
    WHERE lq.rn = 1
    ORDER BY lq.Strike ASC
"@
    
    $Analysis = sqlcmd -S $Server -d $Database -Q $AnalysisQuery
    Write-Host $Analysis -ForegroundColor White
    
    # Save analysis to file
    $AnalysisFile = "C:\Users\babu\Desktop\KiteMarketDataService\NIFTYAnalysis_$CurrentDate.txt"
    $FullAnalysisQuery = @"
    WITH LatestCALLQuotes AS (
        SELECT 
            mq.InstrumentToken,
            mq.TradingSymbol,
            mq.Exchange,
            mq.Expiry,
            mq.OHLC_Open,
            mq.OHLC_High,
            mq.OHLC_Low,
            mq.OHLC_Close,
            mq.LastPrice,
            mq.Volume,
            mq.OpenInterest,
            mq.LowerCircuitLimit,
            mq.UpperCircuitLimit,
            mq.QuoteTimestamp,
            i.Strike,
            i.InstrumentType,
            ROW_NUMBER() OVER (PARTITION BY mq.TradingSymbol ORDER BY mq.QuoteTimestamp DESC) as rn
        FROM MarketQuotes mq
        INNER JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
        WHERE 
            mq.TradingSymbol LIKE 'NIFTY%' 
            AND CAST(mq.Expiry AS DATE) = '2025-08-14'
            AND i.InstrumentType = 'CE'
            AND mq.Expiry IS NOT NULL
    )
    SELECT 
        lq.Strike AS StrkPric,
        lq.OHLC_Open AS OpnPric,
        lq.OHLC_High AS HghPric,
        lq.OHLC_Low AS LwPric,
        lq.OHLC_Close AS ClsPric,
        lq.LastPrice AS LastPric,
        lq.LowerCircuitLimit AS lowerLimit,
        lq.UpperCircuitLimit AS UpperLimit,
        eod.LowerCircuitLimit as EOD_LC,
        eod.UpperCircuitLimit as EOD_UC,
        eod.OHLC_Close as EOD_Close,
        eod.LastPrice as EOD_LastPrice,
        CASE 
            WHEN eod.LowerCircuitLimit != lq.LowerCircuitLimit THEN 'LC_CHANGED'
            WHEN eod.UpperCircuitLimit != lq.UpperCircuitLimit THEN 'UC_CHANGED'
            ELSE 'NO_CHANGE'
        END as CircuitChange
    FROM LatestCALLQuotes lq
    LEFT JOIN EODMarketData eod ON lq.TradingSymbol = eod.TradingSymbol 
        AND eod.TradingDate = '$CurrentDate'
    WHERE lq.rn = 1
    ORDER BY lq.Strike ASC
"@
    
    sqlcmd -S $Server -d $Database -Q $FullAnalysisQuery -o $AnalysisFile
    
    Write-Host ""
    Write-Host "💾 Full NIFTY analysis saved to: $AnalysisFile" -ForegroundColor Green
    Write-Host "💡 Next: Run Task 7 to generate daily summary" -ForegroundColor Yellow
    
} catch {
    Write-Host "❌ ERROR: Failed to analyze NIFTY options" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "🔍 Check database connection and data availability" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "🎯 TASK 6 COMPLETED: NIFTY analysis finished" -ForegroundColor Green
Write-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
