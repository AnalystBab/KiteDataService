-- Fix GlobalSequence column to remove default value
-- This allows the application code to set the value correctly

-- Remove the default constraint
IF EXISTS (SELECT * FROM sys.default_constraints 
           WHERE parent_object_id = OBJECT_ID('MarketQuotes') 
           AND col_name(parent_object_id, parent_column_id) = 'GlobalSequence')
BEGIN
    DECLARE @ConstraintName nvarchar(200)
    SELECT @ConstraintName = name 
    FROM sys.default_constraints 
    WHERE parent_object_id = OBJECT_ID('MarketQuotes') 
    AND col_name(parent_object_id, parent_column_id) = 'GlobalSequence'
    
    EXEC('ALTER TABLE MarketQuotes DROP CONSTRAINT ' + @ConstraintName)
    PRINT '✅ Removed default constraint from GlobalSequence column'
END
ELSE
BEGIN
    PRINT '⚠️ No default constraint found on GlobalSequence'
END
GO

-- Verify the change
SELECT 
    COLUMN_NAME, 
    COLUMN_DEFAULT, 
    IS_NULLABLE, 
    DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'MarketQuotes' 
  AND COLUMN_NAME = 'GlobalSequence';
GO

PRINT '✅ GlobalSequence column fixed - application code will now set values correctly';

