-- Verify Database Fixes
-- Run this script after implementing the fixes to verify they're working

USE KiteMarketData;

-- Check 1: Verify expiry data is being stored
PRINT '=== CHECKING EXPIRY DATA STORAGE ===';
SELECT 
    'MarketQuotes with Expiry' as CheckType,
    COUNT(*) as TotalRecords,
    COUNT(Expiry) as RecordsWithExpiry,
    COUNT(*) - COUNT(Expiry) as RecordsWithoutExpiry,
    CASE 
        WHEN COUNT(Expiry) = COUNT(*) THEN '✅ PASSED - All records have expiry data'
        WHEN COUNT(Expiry) > 0 THEN '⚠️ PARTIAL - Some records have expiry data'
        ELSE '❌ FAILED - No expiry data found'
    END as Status
FROM MarketQuotes;

-- Check 2: Verify timestamp format (should be IST)
PRINT '';
PRINT '=== CHECKING TIMESTAMP FORMAT ===';
SELECT 
    'QuoteTimestamp Format Check' as CheckType,
    COUNT(*) as TotalRecords,
    COUNT(CASE WHEN QuoteTimestamp > '1970-01-01' THEN 1 END) as ValidTimestamps,
    COUNT(CASE WHEN QuoteTimestamp <= '1970-01-01' THEN 1 END) as InvalidTimestamps,
    CASE 
        WHEN COUNT(CASE WHEN QuoteTimestamp > '1970-01-01' THEN 1 END) = COUNT(*) THEN '✅ PASSED - All timestamps are valid'
        WHEN COUNT(CASE WHEN QuoteTimestamp > '1970-01-01' THEN 1 END) > 0 THEN '⚠️ PARTIAL - Some timestamps are valid'
        ELSE '❌ FAILED - All timestamps are invalid'
    END as Status
FROM MarketQuotes;

-- Check 3: Verify data linking between Instruments and MarketQuotes
PRINT '';
PRINT '=== CHECKING DATA LINKING ===';
SELECT 
    'Data Linking Check' as CheckType,
    COUNT(*) as TotalMarketQuotes,
    COUNT(CASE WHEN i.InstrumentToken IS NOT NULL THEN 1 END) as LinkedToInstruments,
    COUNT(CASE WHEN i.InstrumentToken IS NULL THEN 1 END) as NotLinkedToInstruments,
    CASE 
        WHEN COUNT(CASE WHEN i.InstrumentToken IS NOT NULL THEN 1 END) = COUNT(*) THEN '✅ PASSED - All quotes linked to instruments'
        WHEN COUNT(CASE WHEN i.InstrumentToken IS NOT NULL THEN 1 END) > 0 THEN '⚠️ PARTIAL - Some quotes linked to instruments'
        ELSE '❌ FAILED - No quotes linked to instruments'
    END as Status
FROM MarketQuotes mq
LEFT JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken;

-- Check 4: Sample data verification
PRINT '';
PRINT '=== SAMPLE DATA VERIFICATION ===';
SELECT TOP 5
    mq.TradingSymbol,
    mq.Expiry,
    mq.QuoteTimestamp,
    mq.LastTradeTime,
    i.Expiry as InstrumentExpiry,
    CASE 
        WHEN mq.Expiry = i.Expiry THEN '✅ MATCHED'
        WHEN mq.Expiry IS NULL OR i.Expiry IS NULL THEN '❌ NULL VALUE'
        ELSE '⚠️ MISMATCH'
    END as ExpiryMatch
FROM MarketQuotes mq
LEFT JOIN Instruments i ON mq.InstrumentToken = i.InstrumentToken
ORDER BY mq.CreatedAt DESC;

-- Check 5: Data quality summary
PRINT '';
PRINT '=== DATA QUALITY SUMMARY ===';
SELECT 
    'Overall Data Quality' as CheckType,
    (SELECT COUNT(*) FROM MarketQuotes) as TotalMarketQuotes,
    (SELECT COUNT(*) FROM Instruments) as TotalInstruments,
    (SELECT COUNT(*) FROM CircuitLimits) as TotalCircuitLimits,
    CASE 
        WHEN (SELECT COUNT(*) FROM MarketQuotes) > 0 
             AND (SELECT COUNT(*) FROM Instruments) > 0 
             AND (SELECT COUNT(Expiry) FROM MarketQuotes) = (SELECT COUNT(*) FROM MarketQuotes)
        THEN '✅ EXCELLENT - All data properly stored with expiry'
        WHEN (SELECT COUNT(*) FROM MarketQuotes) > 0 
             AND (SELECT COUNT(*) FROM Instruments) > 0
        THEN '⚠️ GOOD - Data exists but may have some issues'
        ELSE '❌ POOR - Missing or corrupted data'
    END as OverallStatus;

PRINT '';
PRINT '=== VERIFICATION COMPLETE ===';
PRINT 'If you see ✅ PASSED for all checks, the fixes are working correctly!';
PRINT 'If you see ❌ FAILED, run the "Fix Database and Restart.ps1" script.';
