-- Test JSON Support on SQL Server 2022
-- Run this in your SSMS to verify JSON support

-- Create test table with JSON column
CREATE TABLE TestJSONSupport (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    Strike INT,
    OptionType VARCHAR(2),
    LCUCTimeData NVARCHAR(MAX) -- JSON column
);

-- Insert test data
INSERT INTO TestJSONSupport (Strike, OptionType, LCUCTimeData)
VALUES 
(25000, 'CE', '{"0915": {"time": "09:15:00", "lc": 0.05, "uc": 23.40}, "1130": {"time": "11:30:00", "lc": 0.05, "uc": 25.10}}'),
(25000, 'PE', '{"0915": {"time": "09:15:00", "lc": 0.05, "uc": 18.75}, "1130": {"time": "11:30:00", "lc": 0.05, "uc": 20.25}}');

-- Test JSON functions
SELECT 
    Strike,
    OptionType,
    -- Extract specific values using JSON functions
    JSON_VALUE(LCUCTimeData, '$.0915.lc') as LC_0915,
    JSON_VALUE(LCUCTimeData, '$.0915.uc') as UC_0915,
    JSON_VALUE(LCUCTimeData, '$.1130.lc') as LC_1130,
    JSON_VALUE(LCUCTimeData, '$.1130.uc') as UC_1130,
    -- Get all keys
    JSON_KEYS(LCUCTimeData) as TimeKeys
FROM TestJSONSupport;

-- Test filtering with JSON
SELECT Strike, OptionType
FROM TestJSONSupport
WHERE CAST(JSON_VALUE(LCUCTimeData, '$.0915.uc') AS DECIMAL) > 20.00;

-- Clean up test table
DROP TABLE TestJSONSupport;

PRINT 'JSON Support Test Completed Successfully!';
PRINT 'Your SQL Server 2022 fully supports JSON columns and functions.';


