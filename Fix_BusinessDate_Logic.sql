-- Fix BusinessDate Logic - Update all quotes to use correct business date
-- Before market opens, BusinessDate should be previous trading day

-- Check current time and determine correct business date
DECLARE @CurrentTime TIME = CAST(GETDATE() AS TIME);
DECLARE @MarketOpen TIME = '09:15:00';
DECLARE @MarketClose TIME = '15:30:00';
DECLARE @CurrentDate DATE = CAST(GETDATE() AS DATE);
DECLARE @CorrectBusinessDate DATE;

-- Determine correct business date based on current time
IF @CurrentTime < @MarketOpen OR @CurrentTime > @MarketClose
BEGIN
    -- Before market opens or after market closes - use previous trading day
    SET @CorrectBusinessDate = CASE 
        WHEN DATEPART(WEEKDAY, @CurrentDate) = 2 -- Monday
        THEN DATEADD(DAY, -3, @CurrentDate) -- Previous Friday
        WHEN DATEPART(WEEKDAY, @CurrentDate) = 1 -- Sunday  
        THEN DATEADD(DAY, -2, @CurrentDate) -- Previous Friday
        ELSE DATEADD(DAY, -1, @CurrentDate) -- Previous day
    END;
    
    PRINT 'Market is closed - Using previous trading day: ' + CAST(@CorrectBusinessDate AS VARCHAR(10));
END
ELSE
BEGIN
    -- Market is open - use current date
    SET @CorrectBusinessDate = @CurrentDate;
    PRINT 'Market is open - Using current date: ' + CAST(@CorrectBusinessDate AS VARCHAR(10));
END

-- Update all market quotes with correct business date
UPDATE MarketQuotes 
SET BusinessDate = @CorrectBusinessDate
WHERE BusinessDate = @CurrentDate;

PRINT 'Updated ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' quotes with correct BusinessDate: ' + CAST(@CorrectBusinessDate AS VARCHAR(10));

-- Show sample of updated data
SELECT TOP 5 
    BusinessDate,
    TradingSymbol,
    Strike,
    OptionType,
    RecordDateTime
FROM MarketQuotes 
WHERE TradingSymbol LIKE 'SENSEX%'
ORDER BY RecordDateTime DESC;


