-- Test the automatic Excel export functionality
-- This query shows what data will be exported when LC/UC changes are detected

USE KiteMarketData;
GO

-- =============================================
-- 1. CHECK CURRENT DATA FOR BUSINESS DATE 2025-09-16
-- =============================================

PRINT '=============================================';
PRINT 'AUTOMATIC EXCEL EXPORT TEST';
PRINT '=============================================';

-- Check total records for the business date
SELECT 
    'Total Records' as DataType,
    COUNT(*) as Count
FROM vw_OptionsData 
WHERE BusinessDate = '2025-09-16'

UNION ALL

SELECT 
    'Records with LC/UC Data',
    COUNT(*)
FROM vw_OptionsData 
WHERE BusinessDate = '2025-09-16'
    AND (LC > 0 OR UC > 0);

-- =============================================
-- 2. SAMPLE DATA THAT WILL BE EXPORTED
-- =============================================

PRINT '';
PRINT 'Sample data that will be exported to Excel:';

SELECT TOP 10
    BusinessDate,
    ExpiryDate,
    TickerSymbol,
    StrikePrice,
    OptionType,
    [Open],
    [High],
    [Low],
    [Close],
    LC,
    UC,
    Volume,
    OpenInterest
FROM vw_OptionsData 
WHERE BusinessDate = '2025-09-16'
    AND (LC > 0 OR UC > 0)
ORDER BY ExpiryDate, OptionType, SortStrike;

-- =============================================
-- 3. STRIKE SUMMARY DATA
-- =============================================

PRINT '';
PRINT 'Strike Summary data:';

SELECT TOP 5
    BusinessDate,
    ExpiryDate,
    StrikePrice,
    CallSymbol,
    CallLC,
    CallUC,
    PutSymbol,
    PutLC,
    PutUC
FROM vw_StrikeSummary 
WHERE BusinessDate = '2025-09-16'
ORDER BY StrikePrice;

-- =============================================
-- 4. EXPIRY BREAKDOWN
-- =============================================

PRINT '';
PRINT 'Expiry breakdown:';

SELECT 
    ExpiryDate,
    COUNT(*) as OptionCount,
    COUNT(CASE WHEN OptionType = 'CE' THEN 1 END) as CallCount,
    COUNT(CASE WHEN OptionType = 'PE' THEN 1 END) as PutCount,
    MIN(StrikePrice) as MinStrike,
    MAX(StrikePrice) as MaxStrike
FROM vw_OptionsData 
WHERE BusinessDate = '2025-09-16'
GROUP BY ExpiryDate
ORDER BY ExpiryDate;

PRINT '';
PRINT '=============================================';
PRINT 'AUTOMATIC EXCEL EXPORT WILL CREATE:';
PRINT '1. All Options Data sheet - All 1522 records';
PRINT '2. Strike Summary sheet - Strike-wise summary';
PRINT '3. LC/UC Changes sheet - Change tracking';
PRINT '4. Individual expiry sheets - Expiry-wise data';
PRINT '=============================================';
PRINT 'File will be saved as: OptionsData_20250916.xlsx';
PRINT 'Location: ProjectFolder/Exports/';
PRINT '=============================================';

GO




