-- Create ExcelExportData table for storing Excel export data in database
-- This allows querying LC/UC changes via SQL without opening Excel files

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExcelExportData')
BEGIN
    CREATE TABLE [dbo].[ExcelExportData](
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [BusinessDate] [datetime2](7) NOT NULL,
        [ExpiryDate] [datetime2](7) NOT NULL,
        [Strike] [int] NOT NULL,
        [OptionType] [nvarchar](2) NOT NULL,
        [OpenPrice] [decimal](10, 2) NOT NULL,
        [HighPrice] [decimal](10, 2) NOT NULL,
        [LowPrice] [decimal](10, 2) NOT NULL,
        [ClosePrice] [decimal](10, 2) NOT NULL,
        [LastPrice] [decimal](10, 2) NOT NULL,
        [LCUCTimeData] [nvarchar](max) NOT NULL,  -- JSON: {"0915": {"time": "09:15:00", "lc": 0.05, "uc": 23.40}, ...}
        [AdditionalData] [nvarchar](max) NOT NULL,  -- JSON for future dynamic columns
        [ExportDateTime] [datetime2](7) NOT NULL,
        [ExportType] [nvarchar](50) NOT NULL,  -- "ConsolidatedLCUC" or "DailyInitial"
        [FilePath] [nvarchar](500) NOT NULL,
        [CreatedAt] [datetime2](7) NOT NULL DEFAULT (GETDATE()),
        
        CONSTRAINT [PK_ExcelExportData] PRIMARY KEY CLUSTERED ([Id] ASC)
    );

    -- Create indexes for efficient querying
    CREATE NONCLUSTERED INDEX [IX_ExcelExportData_BusinessDate] ON [dbo].[ExcelExportData]([BusinessDate] ASC);
    CREATE NONCLUSTERED INDEX [IX_ExcelExportData_ExpiryDate] ON [dbo].[ExcelExportData]([ExpiryDate] ASC);
    CREATE NONCLUSTERED INDEX [IX_ExcelExportData_BusinessDate_ExpiryDate] ON [dbo].[ExcelExportData]([BusinessDate] ASC, [ExpiryDate] ASC);
    CREATE NONCLUSTERED INDEX [IX_ExcelExportData_BusinessDate_ExpiryDate_Strike_OptionType] ON [dbo].[ExcelExportData]([BusinessDate] ASC, [ExpiryDate] ASC, [Strike] ASC, [OptionType] ASC);
    CREATE NONCLUSTERED INDEX [IX_ExcelExportData_ExportDateTime] ON [dbo].[ExcelExportData]([ExportDateTime] ASC);
    CREATE NONCLUSTERED INDEX [IX_ExcelExportData_ExportType] ON [dbo].[ExcelExportData]([ExportType] ASC);

    PRINT '✅ ExcelExportData table created successfully!';
END
ELSE
BEGIN
    PRINT '⚠️ ExcelExportData table already exists.';
END
GO

