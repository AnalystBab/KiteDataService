using Microsoft.EntityFrameworkCore;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Data
{
    public class MarketDataContext : DbContext
    {
        public MarketDataContext(DbContextOptions<MarketDataContext> options) : base(options)
        {
        }

        public DbSet<Instrument> Instruments { get; set; }
        public DbSet<MarketQuote> MarketQuotes { get; set; }
        public DbSet<CircuitLimit> CircuitLimits { get; set; }
        public DbSet<CircuitLimitChangeRecord> CircuitLimitChanges { get; set; }
        public DbSet<DailyMarketSnapshot> DailyMarketSnapshots { get; set; }

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

            // Configure MarketQuote entity
            modelBuilder.Entity<MarketQuote>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(100);
                entity.Property(e => e.Exchange).IsRequired().HasMaxLength(20);
                entity.Property(e => e.OptionType).IsRequired().HasMaxLength(2);
                
                // Configure decimal precision
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
                
                // Market depth precision
                entity.Property(e => e.BuyPrice1).HasPrecision(10, 2);
                entity.Property(e => e.BuyPrice2).HasPrecision(10, 2);
                entity.Property(e => e.BuyPrice3).HasPrecision(10, 2);
                entity.Property(e => e.BuyPrice4).HasPrecision(10, 2);
                entity.Property(e => e.BuyPrice5).HasPrecision(10, 2);
                entity.Property(e => e.SellPrice1).HasPrecision(10, 2);
                entity.Property(e => e.SellPrice2).HasPrecision(10, 2);
                entity.Property(e => e.SellPrice3).HasPrecision(10, 2);
                entity.Property(e => e.SellPrice4).HasPrecision(10, 2);
                entity.Property(e => e.SellPrice5).HasPrecision(10, 2);
                
                // Create indexes for performance
                entity.HasIndex(e => e.TradingDate);
                entity.HasIndex(e => e.InstrumentToken);
                entity.HasIndex(e => e.QuoteTimestamp);
                entity.HasIndex(e => e.TradingSymbol);
                entity.HasIndex(e => e.Strike);
                entity.HasIndex(e => e.OptionType);
                entity.HasIndex(e => e.ExpiryDate);
                entity.HasIndex(e => new { e.TradingDate, e.TradingSymbol, e.QuoteTimestamp });
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

            // Configure DailyMarketSnapshot entity
            modelBuilder.Entity<DailyMarketSnapshot>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Id).ValueGeneratedOnAdd();
                entity.Property(e => e.TradingSymbol).IsRequired().HasMaxLength(100);
                entity.Property(e => e.OptionType).IsRequired().HasMaxLength(2);
                entity.Property(e => e.Exchange).IsRequired().HasMaxLength(20);
                entity.Property(e => e.SnapshotType).IsRequired().HasMaxLength(20);
                
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
                entity.Property(e => e.NetChange).HasPrecision(10, 2);
                
                // Create indexes for performance
                entity.HasIndex(e => e.TradingDate);
                entity.HasIndex(e => e.SnapshotTime);
                entity.HasIndex(e => e.InstrumentToken);
                entity.HasIndex(e => e.SnapshotType);
            });
        }
    }
} 