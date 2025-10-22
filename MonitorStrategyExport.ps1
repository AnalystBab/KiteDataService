# Monitor Strategy Export Progress

Write-Host "🎯 MONITORING STRATEGY EXPORT PROGRESS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check database labels
Write-Host "📊 DATABASE STATUS:" -ForegroundColor Yellow
sqlcmd -S localhost -d KiteMarketData -Q "SELECT IndexName, COUNT(*) AS Labels, MAX(CreatedAt) AS LastUpdate FROM StrategyLabels WHERE BusinessDate = '2025-10-09' GROUP BY IndexName ORDER BY IndexName" -W
Write-Host ""

# Check Excel files
Write-Host "📁 EXCEL FILES STATUS:" -ForegroundColor Yellow
if (Test-Path "Exports\StrategyAnalysis\2025-10-09") {
    Write-Host "✅ StrategyAnalysis folder exists" -ForegroundColor Green
    $files = Get-ChildItem "Exports\StrategyAnalysis\2025-10-09" -Recurse -Filter "*.xlsx"
    if ($files) {
        Write-Host "   Found $($files.Count) Excel file(s):" -ForegroundColor Green
        $files | ForEach-Object {
            Write-Host "   - $($_.Name)" -ForegroundColor White
            Write-Host "     Path: $($_.DirectoryName)" -ForegroundColor Gray
            Write-Host "     Size: $([math]::Round($_.Length/1KB, 2)) KB" -ForegroundColor Gray
            Write-Host "     Created: $($_.CreationTime)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "   ⚠️  No Excel files found yet" -ForegroundColor Yellow
    }
} else {
    Write-Host "   ⚠️  StrategyAnalysis folder not created yet" -ForegroundColor Yellow
    Write-Host "   Service may still be starting..." -ForegroundColor Gray
}
Write-Host ""

# Check service log
Write-Host "📝 SERVICE LOG (Last 20 lines with 'Strategy'):" -ForegroundColor Yellow
if (Test-Path "bin\Debug\net8.0\logs\KiteMarketDataService.log") {
    Get-Content "bin\Debug\net8.0\logs\KiteMarketDataService.log" | Select-String -Pattern "Strategy|Processing.*for|calculated|Excel|Error.*Strategy" -CaseSensitive:$false | Select-Object -Last 20 | ForEach-Object {
        if ($_.Line -match "Error|Failed") {
            Write-Host "   ❌ $($_.Line)" -ForegroundColor Red
        } elseif ($_.Line -match "✅|completed") {
            Write-Host "   ✅ $($_.Line)" -ForegroundColor Green
        } else {
            Write-Host "   $($_.Line)" -ForegroundColor White
        }
    }
} else {
    Write-Host "   ⚠️  Log file not found - service may not have started yet" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Re-run this script to check progress" -ForegroundColor Gray

