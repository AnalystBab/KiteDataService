using Microsoft.EntityFrameworkCore;
using KiteMarketDataService.Worker.Models;
using KiteMarketDataService.Worker.Services;

namespace KiteMarketDataService.Worker.Data
{
    public class MarketDataContext : DbContext
    {
        public MarketDataContext(DbContextOptions<MarketDataContext> options) : base(options)
        {
        }

        public DbSet<Instrument> Instruments { get; set; }
        public DbSet<MarketQuote> MarketQuotes { get; set; }
        public DbSet<SpotData> SpotData { get; set; }
        public DbSet<HistoricalSpotData> HistoricalSpotData { get; set; }
        public DbSet<IntradaySpotData> IntradaySpotData { get; set; }
        public DbSet<FullInstrument> FullInstruments { get; set; }
        public DbSet<CircuitLimit> CircuitLimits { get; set; }
        public DbSet<CircuitLimitChangeRecord> CircuitLimitChanges { get; set; }
        public DbSet<IntradayTickData> IntradayTickData { get; set; }
        public DbSet<ExcelExportData> ExcelExportData { get; set; }
        public DbSet<HistoricalOptionsData> HistoricalOptionsData { get; set; }
        public DbSet<AuthConfiguration> AuthConfiguration { get; set; }
        
        // Strategy System Tables
        public DbSet<StrategyLabelCatalog> StrategyLabelsCatalog { get; set; }
        public DbSet<StrategyLabel> StrategyLabels { get; set; }
        public DbSet<StrategyMatch> StrategyMatches { get; set; }
        public DbSet<StrategyPrediction> StrategyPredictions { get; set; }
        public DbSet<StrategyValidation> StrategyValidations { get; set; }
        public DbSet<StrategyPerformance> StrategyPerformances { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            // Configure Instrument entity
            modelBuilder.Entity<Instrument>(entity =>
            {
                entity.HasKey(e => e.InstrumentToken);
                entity.Property(e => e.InstrumentToken).ValueGeneratedNever();
                entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(100);
                entity.Property(e => e.InstrumentType).HasMaxLength(10);
                entity.Property(e => e.Exchange).HasMaxLength(20);
                entity.Property(e => e.Name).HasMaxLength(200);
                
                // Create indexes for efficient queries
                entity.HasIndex(e => e.TradingSymbol);
                entity.HasIndex(e => e.InstrumentType);
                entity.HasIndex(e => e.Exchange);
                entity.HasIndex(e => e.Expiry);
            });

            // Configure MarketQuote entity (Cleaned Schema - Only Essential Columns for NIFTY, SENSEX, BANKNIFTY)
            modelBuilder.Entity<MarketQuote>(entity =>
            {
                // Composite Primary Key
                entity.HasKey(e => new { e.BusinessDate, e.TradingSymbol, e.InsertionSequence });
                
                // Configure string properties
                entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(100);
                entity.Property(e => e.OptionType).IsRequired().HasMaxLength(2);
                
                // Configure InstrumentToken
                entity.Property(e => e.InstrumentToken).IsRequired();
                
                // Configure decimal precision for financial data
                entity.Property(e => e.Strike).HasPrecision(10, 2);
                entity.Property(e => e.OpenPrice).HasPrecision(10, 2);
                entity.Property(e => e.HighPrice).HasPrecision(10, 2);
                entity.Property(e => e.LowPrice).HasPrecision(10, 2);
                entity.Property(e => e.ClosePrice).HasPrecision(10, 2);
                entity.Property(e => e.LastPrice).HasPrecision(10, 2);
                entity.Property(e => e.LowerCircuitLimit).HasPrecision(10, 2);
                entity.Property(e => e.UpperCircuitLimit).HasPrecision(10, 2);
                
                // Configure datetime properties
                entity.Property(e => e.ExpiryDate).HasColumnType("date");
                entity.Property(e => e.BusinessDate).HasColumnType("date");
                entity.Property(e => e.LastTradeTime).HasColumnType("datetime2");
                entity.Property(e => e.RecordDateTime).HasColumnType("datetime2");
                
                // Create indexes for performance
                entity.HasIndex(e => e.BusinessDate);
                entity.HasIndex(e => e.TradingSymbol);
                entity.HasIndex(e => e.InstrumentToken);
                entity.HasIndex(e => e.Strike);
                entity.HasIndex(e => e.OptionType);
                entity.HasIndex(e => e.ExpiryDate);
                entity.HasIndex(e => e.InsertionSequence);
                entity.HasIndex(e => e.RecordDateTime);
                
                // Composite indexes for common queries
                entity.HasIndex(e => new { e.TradingSymbol, e.ExpiryDate, e.Strike, e.OptionType });
                entity.HasIndex(e => new { e.BusinessDate, e.TradingSymbol });
                entity.HasIndex(e => new { e.TradingSymbol, e.BusinessDate, e.RecordDateTime });
                entity.HasIndex(e => new { e.BusinessDate, e.ExpiryDate });
            });

            // Configure SpotData entity
            modelBuilder.Entity<SpotData>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.IndexName).IsRequired().HasMaxLength(50);
                entity.Property(e => e.DataSource).HasMaxLength(50);

                // Configure decimal precision
                entity.Property(e => e.OpenPrice).HasPrecision(10, 2);
                entity.Property(e => e.HighPrice).HasPrecision(10, 2);
                entity.Property(e => e.LowPrice).HasPrecision(10, 2);
                entity.Property(e => e.ClosePrice).HasPrecision(10, 2);
                entity.Property(e => e.LastPrice).HasPrecision(10, 2);
                entity.Property(e => e.Change).HasPrecision(10, 2);
                entity.Property(e => e.ChangePercent).HasPrecision(5, 2);

                // Create indexes for performance
                entity.HasIndex(e => e.TradingDate);
                entity.HasIndex(e => e.IndexName);
                entity.HasIndex(e => e.QuoteTimestamp);
                entity.HasIndex(e => new { e.IndexName, e.TradingDate });

                entity.Property(e => e.TradingDate).IsRequired();
                entity.Property(e => e.QuoteTimestamp).IsRequired();
                entity.Property(e => e.CreatedDate).IsRequired();
            });

            // Configure FullInstrument entity
            modelBuilder.Entity<FullInstrument>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(50);
                entity.Property(e => e.InstrumentType).HasMaxLength(10);
                entity.Property(e => e.Exchange).IsRequired().HasMaxLength(10);
                entity.Property(e => e.Segment).IsRequired().HasMaxLength(20);
                entity.Property(e => e.Name).HasMaxLength(200);
                entity.Property(e => e.IndexName).HasMaxLength(20);

                // Configure decimal precision
                entity.Property(e => e.Strike).HasPrecision(10, 2);
                entity.Property(e => e.TickSize).HasPrecision(10, 2);
                entity.Property(e => e.LastPrice).HasPrecision(10, 2);

                // Create indexes for performance
                entity.HasIndex(e => e.TradingSymbol);
                entity.HasIndex(e => e.InstrumentType);
                entity.HasIndex(e => e.Exchange);
                entity.HasIndex(e => e.IsIndex);
                entity.HasIndex(e => e.IndexName);
                entity.HasIndex(e => new { e.IsIndex, e.IndexName });
            });

            // Configure CircuitLimit entity
            modelBuilder.Entity<CircuitLimit>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(100);
                entity.Property(e => e.OptionType).IsRequired().HasMaxLength(2);
                entity.Property(e => e.Source).IsRequired().HasMaxLength(50);
                
                // Configure decimal precision
                entity.Property(e => e.Strike).HasPrecision(10, 2);
                entity.Property(e => e.LowerCircuitLimit).HasPrecision(10, 2);
                entity.Property(e => e.UpperCircuitLimit).HasPrecision(10, 2);
                
                // Create indexes for performance
                entity.HasIndex(e => e.TradingDate);
                entity.HasIndex(e => e.InstrumentToken);
                entity.HasIndex(e => new { e.TradingDate, e.TradingSymbol });
            });

            // Configure CircuitLimitChangeRecord entity
            modelBuilder.Entity<CircuitLimitChangeRecord>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(100);
                entity.Property(e => e.OptionType).IsRequired().HasMaxLength(2);
                entity.Property(e => e.Exchange).IsRequired().HasMaxLength(20);
                entity.Property(e => e.ChangeType).IsRequired().HasMaxLength(20);
                
                // Configure decimal precision
                entity.Property(e => e.Strike).HasPrecision(10, 2);
                entity.Property(e => e.PreviousLC).HasPrecision(10, 2);
                entity.Property(e => e.PreviousUC).HasPrecision(10, 2);
                entity.Property(e => e.PreviousOpenPrice).HasPrecision(10, 2);
                entity.Property(e => e.PreviousHighPrice).HasPrecision(10, 2);
                entity.Property(e => e.PreviousLowPrice).HasPrecision(10, 2);
                entity.Property(e => e.PreviousClosePrice).HasPrecision(10, 2);
                entity.Property(e => e.PreviousLastPrice).HasPrecision(10, 2);
                entity.Property(e => e.NewLC).HasPrecision(10, 2);
                entity.Property(e => e.NewUC).HasPrecision(10, 2);
                entity.Property(e => e.NewOpenPrice).HasPrecision(10, 2);
                entity.Property(e => e.NewHighPrice).HasPrecision(10, 2);
                entity.Property(e => e.NewLowPrice).HasPrecision(10, 2);
                entity.Property(e => e.NewClosePrice).HasPrecision(10, 2);
                entity.Property(e => e.NewLastPrice).HasPrecision(10, 2);
                entity.Property(e => e.IndexOpenPrice).HasPrecision(10, 2);
                entity.Property(e => e.IndexHighPrice).HasPrecision(10, 2);
                entity.Property(e => e.IndexLowPrice).HasPrecision(10, 2);
                entity.Property(e => e.IndexClosePrice).HasPrecision(10, 2);
                entity.Property(e => e.IndexLastPrice).HasPrecision(10, 2);
                
                // Create indexes for performance
                entity.HasIndex(e => e.TradingDate);
                entity.HasIndex(e => e.ChangeTime);
                entity.HasIndex(e => e.InstrumentToken);
                entity.HasIndex(e => e.ChangeType);
            });




            // Configure IntradayTickData entity
            modelBuilder.Entity<IntradayTickData>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(100);
                entity.Property(e => e.IndexName).IsRequired().HasMaxLength(20);
                entity.Property(e => e.OptionType).IsRequired().HasMaxLength(2);
                entity.Property(e => e.StrikeType).HasMaxLength(10);
                entity.Property(e => e.MarketSentiment).HasMaxLength(20);
                entity.Property(e => e.DataSource).HasMaxLength(20);
                
                // Configure decimal precision for all financial fields
                entity.Property(e => e.Strike).HasPrecision(10, 2);
                entity.Property(e => e.OpenPrice).HasPrecision(10, 2);
                entity.Property(e => e.HighPrice).HasPrecision(10, 2);
                entity.Property(e => e.LowPrice).HasPrecision(10, 2);
                entity.Property(e => e.ClosePrice).HasPrecision(10, 2);
                entity.Property(e => e.LastPrice).HasPrecision(10, 2);
                entity.Property(e => e.LowerCircuitLimit).HasPrecision(10, 2);
                entity.Property(e => e.UpperCircuitLimit).HasPrecision(10, 2);
                entity.Property(e => e.AveragePrice).HasPrecision(10, 2);
                entity.Property(e => e.OpenInterest).HasPrecision(15, 2);
                entity.Property(e => e.OiDayHigh).HasPrecision(15, 2);
                entity.Property(e => e.OiDayLow).HasPrecision(15, 2);
                entity.Property(e => e.NetChange).HasPrecision(10, 2);
                entity.Property(e => e.SpotPrice).HasPrecision(10, 2);
                
                // Greeks precision
                entity.Property(e => e.Delta).HasPrecision(10, 6);
                entity.Property(e => e.Gamma).HasPrecision(10, 8);
                entity.Property(e => e.Theta).HasPrecision(10, 6);
                entity.Property(e => e.Vega).HasPrecision(10, 6);
                entity.Property(e => e.Rho).HasPrecision(10, 6);
                
                // Advanced analytics precision
                entity.Property(e => e.ImpliedVolatility).HasPrecision(8, 2);
                entity.Property(e => e.TheoreticalPrice).HasPrecision(10, 2);
                entity.Property(e => e.PriceDeviation).HasPrecision(10, 2);
                entity.Property(e => e.PriceDeviationPercent).HasPrecision(8, 2);
                entity.Property(e => e.Moneyness).HasPrecision(10, 4);
                entity.Property(e => e.IntrinsicValue).HasPrecision(10, 2);
                entity.Property(e => e.TimeValue).HasPrecision(10, 2);
                entity.Property(e => e.PredictedLow).HasPrecision(10, 2);
                entity.Property(e => e.PredictedHigh).HasPrecision(10, 2);
                entity.Property(e => e.ConfidenceScore).HasPrecision(5, 2);
                entity.Property(e => e.HistoricalVolatility).HasPrecision(8, 2);
                entity.Property(e => e.VolatilitySkew).HasPrecision(8, 2);
                entity.Property(e => e.VolatilityRank).HasPrecision(5, 2);
                entity.Property(e => e.MaximumLoss).HasPrecision(10, 2);
                entity.Property(e => e.MaximumGain).HasPrecision(10, 2);
                entity.Property(e => e.BreakEvenPoint).HasPrecision(10, 2);
                entity.Property(e => e.PutCallRatio).HasPrecision(10, 4);
                entity.Property(e => e.VolumeRatio).HasPrecision(10, 4);
                
                // Create indexes for efficient queries
                entity.HasIndex(e => e.BusinessDate);
                entity.HasIndex(e => e.TickTimestamp);
                entity.HasIndex(e => e.TickTime);
                entity.HasIndex(e => e.InstrumentToken);
                entity.HasIndex(e => e.IndexName);
                entity.HasIndex(e => e.ExpiryDate);
                entity.HasIndex(e => e.Strike);
                entity.HasIndex(e => e.OptionType);
                entity.HasIndex(e => e.StrikeType);
                entity.HasIndex(e => e.IsMarketOpen);
                
                // Composite indexes for time series queries
                entity.HasIndex(e => new { e.BusinessDate, e.TickTimestamp, e.IndexName });
                entity.HasIndex(e => new { e.InstrumentToken, e.TickTimestamp });
                entity.HasIndex(e => new { e.IndexName, e.ExpiryDate, e.Strike, e.OptionType, e.TickTimestamp });
                entity.HasIndex(e => new { e.BusinessDate, e.IndexName, e.StrikeType });
                
                // Unique constraint to prevent duplicate ticks
                entity.HasIndex(e => new { e.InstrumentToken, e.TickTimestamp }).IsUnique();
            });

            // Configure ExcelExportData entity
            modelBuilder.Entity<ExcelExportData>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                
                // Configure required properties
                entity.Property(e => e.OptionType).IsRequired().HasMaxLength(2);
                entity.Property(e => e.ExportType).IsRequired().HasMaxLength(50);
                entity.Property(e => e.FilePath).IsRequired().HasMaxLength(500);
                
                // Configure decimal precision
                entity.Property(e => e.Strike).HasPrecision(10, 2);
                entity.Property(e => e.OpenPrice).HasPrecision(10, 2);
                entity.Property(e => e.HighPrice).HasPrecision(10, 2);
                entity.Property(e => e.LowPrice).HasPrecision(10, 2);
                entity.Property(e => e.ClosePrice).HasPrecision(10, 2);
                entity.Property(e => e.LastPrice).HasPrecision(10, 2);
                
                // Configure JSON columns
                entity.Property(e => e.LCUCTimeData).HasColumnType("nvarchar(max)");
                entity.Property(e => e.AdditionalData).HasColumnType("nvarchar(max)");
                
                // Create indexes for performance
                entity.HasIndex(e => e.BusinessDate);
                entity.HasIndex(e => e.ExpiryDate);
                entity.HasIndex(e => new { e.BusinessDate, e.ExpiryDate });
                entity.HasIndex(e => new { e.BusinessDate, e.ExpiryDate, e.Strike, e.OptionType });
                entity.HasIndex(e => e.ExportDateTime);
                entity.HasIndex(e => e.ExportType);
            });

            // Configure HistoricalOptionsData entity
            modelBuilder.Entity<HistoricalOptionsData>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                
                // Configure required properties
                entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(100);
                entity.Property(e => e.IndexName).IsRequired().HasMaxLength(20);
                entity.Property(e => e.OptionType).IsRequired().HasMaxLength(2);
                entity.Property(e => e.DataSource).IsRequired().HasMaxLength(50);
                entity.Property(e => e.Notes).HasMaxLength(500);
                
                // Configure date columns
                entity.Property(e => e.ExpiryDate).HasColumnType("date");
                entity.Property(e => e.TradingDate).HasColumnType("date");
                
                // Configure decimal precision
                entity.Property(e => e.Strike).HasPrecision(10, 2);
                entity.Property(e => e.OpenPrice).HasPrecision(10, 2);
                entity.Property(e => e.HighPrice).HasPrecision(10, 2);
                entity.Property(e => e.LowPrice).HasPrecision(10, 2);
                entity.Property(e => e.ClosePrice).HasPrecision(10, 2);
                entity.Property(e => e.LastPrice).HasPrecision(10, 2);
                entity.Property(e => e.LowerCircuitLimit).HasPrecision(10, 2);
                entity.Property(e => e.UpperCircuitLimit).HasPrecision(10, 2);
                entity.Property(e => e.OpenInterest).HasPrecision(15, 2);
                
                // Create composite unique index to prevent duplicates
                entity.HasIndex(e => new { e.InstrumentToken, e.TradingDate })
                    .IsUnique()
                    .HasDatabaseName("IX_HistoricalOptionsData_Unique_InstrumentToken_TradingDate");
                
                // Create indexes for efficient querying
                entity.HasIndex(e => e.IndexName).HasDatabaseName("IX_HistoricalOptionsData_IndexName");
                entity.HasIndex(e => e.ExpiryDate).HasDatabaseName("IX_HistoricalOptionsData_ExpiryDate");
                entity.HasIndex(e => e.TradingDate).HasDatabaseName("IX_HistoricalOptionsData_TradingDate");
                entity.HasIndex(e => e.Strike).HasDatabaseName("IX_HistoricalOptionsData_Strike");
                entity.HasIndex(e => e.IsExpired).HasDatabaseName("IX_HistoricalOptionsData_IsExpired");
                entity.HasIndex(e => e.ArchivedDate).HasDatabaseName("IX_HistoricalOptionsData_ArchivedDate");
                entity.HasIndex(e => new { e.IndexName, e.ExpiryDate }).HasDatabaseName("IX_HistoricalOptionsData_IndexName_ExpiryDate");
                entity.HasIndex(e => new { e.IndexName, e.ExpiryDate, e.Strike, e.OptionType }).HasDatabaseName("IX_HistoricalOptionsData_Full");
                entity.HasIndex(e => new { e.TradingDate, e.IndexName }).HasDatabaseName("IX_HistoricalOptionsData_TradingDate_IndexName");
            });

            // Configure StrikeLatestRecords entity - DISABLED
            // modelBuilder.Entity<StrikeLatestRecord>(entity =>
            // {
            //     entity.HasKey(e => e.Id);
            //     entity.Property(e => e.Id).ValueGeneratedOnAdd();
            //     
            //     entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(50);
            //     entity.Property(e => e.OptionType).IsRequired().HasMaxLength(10);
            //     
            //     // Configure decimal precision
            //     entity.Property(e => e.Strike).HasPrecision(10, 2);
            //     entity.Property(e => e.OpenPrice).HasPrecision(10, 2);
            //     entity.Property(e => e.HighPrice).HasPrecision(10, 2);
            //     entity.Property(e => e.LowPrice).HasPrecision(10, 2);
            //     entity.Property(e => e.ClosePrice).HasPrecision(10, 2);
            //     entity.Property(e => e.LastPrice).HasPrecision(10, 2);
            //     entity.Property(e => e.LowerCircuitLimit).HasPrecision(10, 2);
            //     entity.Property(e => e.UpperCircuitLimit).HasPrecision(10, 2);
            //     
            //     // Configure datetime columns
            //     entity.Property(e => e.ExpiryDate).HasColumnType("date");
            //     entity.Property(e => e.BusinessDate).HasColumnType("date");
            //     entity.Property(e => e.RecordDateTime).HasColumnType("datetime2");
            //     entity.Property(e => e.CreatedAt).HasColumnType("datetime2")
            //         .HasDefaultValueSql("GETUTCDATE()");
            //     
            //     // Create unique constraint to ensure only 3 records per strike
            //     entity.HasIndex(e => new { e.TradingSymbol, e.Strike, e.OptionType, e.ExpiryDate, e.RecordOrder })
            //         .IsUnique()
            //         .HasDatabaseName("UK_StrikeLatestRecords_Strike_Type_Expiry_Order");
            //     
            //     // Create indexes for performance
            //     entity.HasIndex(e => new { e.TradingSymbol, e.Strike, e.OptionType, e.ExpiryDate })
            //         .HasDatabaseName("IX_StrikeLatestRecords_Strike_Type_Expiry");
            //     entity.HasIndex(e => e.BusinessDate).HasDatabaseName("IX_StrikeLatestRecords_BusinessDate");
            //     entity.HasIndex(e => e.RecordDateTime).HasDatabaseName("IX_StrikeLatestRecords_RecordDateTime");
            //     entity.HasIndex(e => new { e.TradingSymbol, e.Strike, e.OptionType, e.ExpiryDate, e.RecordOrder })
            //         .HasDatabaseName("IX_StrikeLatestRecords_RecordOrder");
            // });

            // Configure Strategy System Entities
            
            // StrategyLabelCatalog
            modelBuilder.Entity<StrategyLabelCatalog>(entity =>
            {
                entity.HasKey(e => e.LabelNumber);
                entity.Property(e => e.LabelNumber).ValueGeneratedNever();
                entity.Property(e => e.LabelName).IsRequired().HasMaxLength(100);
                entity.HasIndex(e => e.LabelName).IsUnique();
                entity.HasIndex(e => e.LabelCategory);
                entity.HasIndex(e => e.ImportanceLevel);
            });

            // StrategyLabel (reuse existing - already configured from previous code)
            
            // StrategyMatch
            modelBuilder.Entity<StrategyMatch>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.StrategyName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.IndexName).IsRequired().HasMaxLength(20);
                entity.Property(e => e.CalculatedLabelName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.MatchedOptionType).IsRequired().HasMaxLength(2);
                entity.Property(e => e.MatchedFieldType).IsRequired().HasMaxLength(10);
                
                entity.HasIndex(e => e.BusinessDate);
                entity.HasIndex(e => e.MatchQuality);
                entity.HasIndex(e => e.CalculatedLabelName);
                entity.HasIndex(e => new { e.BusinessDate, e.IndexName });
            });

            // StrategyPrediction
            modelBuilder.Entity<StrategyPrediction>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.StrategyName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.IndexName).IsRequired().HasMaxLength(20);
                entity.Property(e => e.PredictionType).IsRequired().HasMaxLength(50);
                
                entity.HasIndex(e => e.PredictionDate);
                entity.HasIndex(e => e.TargetDate);
                entity.HasIndex(e => e.PredictionType);
                entity.HasIndex(e => new { e.PredictionDate, e.TargetDate, e.IndexName });
            });

            // StrategyValidation
            modelBuilder.Entity<StrategyValidation>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.Status).IsRequired().HasMaxLength(20);
                
                entity.HasIndex(e => e.PredictionId);
                entity.HasIndex(e => e.ActualDate);
                entity.HasIndex(e => e.AccuracyPercentage);
                entity.HasIndex(e => e.Status);
            });

            // StrategyPerformance
            modelBuilder.Entity<StrategyPerformance>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.StrategyName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.StrategyStatus).HasMaxLength(20);
                
                entity.HasIndex(e => new { e.StrategyName, e.StrategyVersion });
                entity.HasIndex(e => e.AverageAccuracy);
            });

            // Configure AuthConfiguration entity
            modelBuilder.Entity<AuthConfiguration>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                
                entity.Property(e => e.ApiKey).IsRequired().HasMaxLength(100);
                entity.Property(e => e.ApiSecret).IsRequired().HasMaxLength(200);
                entity.Property(e => e.RequestToken).HasMaxLength(200);
                entity.Property(e => e.AccessToken).HasMaxLength(200);
                entity.Property(e => e.Notes).HasMaxLength(500);
                
                entity.Property(e => e.IsActive).IsRequired();
                entity.Property(e => e.CreatedAt).IsRequired();
                entity.Property(e => e.UpdatedAt).IsRequired();
                
                // Create indexes for performance
                entity.HasIndex(e => e.IsActive);
                entity.HasIndex(e => e.CreatedAt);
                entity.HasIndex(e => e.UpdatedAt);
            });
        }
    }
} 