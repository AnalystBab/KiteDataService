using Microsoft.EntityFrameworkCore;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Data
{
    public class CircuitLimitTrackingContext : DbContext
    {
        public CircuitLimitTrackingContext(DbContextOptions<CircuitLimitTrackingContext> options) : base(options)
        {
        }

        public DbSet<CircuitLimitChangeDetails> CircuitLimitChangeDetails { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<CircuitLimitChangeDetails>(entity =>
            {
                entity.ToTable("CircuitLimitChangeDetails");
                
                entity.HasKey(e => e.Id);
                
                entity.Property(e => e.InstrumentToken).IsRequired();
                entity.Property(e => e.TradingSymbol).HasMaxLength(100).IsRequired();
                entity.Property(e => e.Exchange).HasMaxLength(10).IsRequired();
                entity.Property(e => e.Segment).HasMaxLength(20).IsRequired();
                entity.Property(e => e.Strike).HasPrecision(10, 2).IsRequired();
                entity.Property(e => e.OptionType).HasMaxLength(2).IsRequired();
                entity.Property(e => e.ExpiryDate).IsRequired();
                
                entity.Property(e => e.PreviousLowerCircuit).HasPrecision(10, 2).IsRequired();
                entity.Property(e => e.PreviousUpperCircuit).HasPrecision(10, 2).IsRequired();
                entity.Property(e => e.NewLowerCircuit).HasPrecision(10, 2).IsRequired();
                entity.Property(e => e.NewUpperCircuit).HasPrecision(10, 2).IsRequired();
                
                entity.Property(e => e.LowerCircuitChange).HasPrecision(10, 2).IsRequired();
                entity.Property(e => e.UpperCircuitChange).HasPrecision(10, 2).IsRequired();
                entity.Property(e => e.ChangeDirection).HasMaxLength(20).IsRequired();
                
                entity.Property(e => e.OpenPrice).HasPrecision(10, 2);
                entity.Property(e => e.HighPrice).HasPrecision(10, 2);
                entity.Property(e => e.LowPrice).HasPrecision(10, 2);
                entity.Property(e => e.ClosePrice).HasPrecision(10, 2);
                entity.Property(e => e.LastPrice).HasPrecision(10, 2);
                
                entity.Property(e => e.Volume);
                entity.Property(e => e.OpenInterest);
                entity.Property(e => e.AveragePrice).HasPrecision(10, 2);
                entity.Property(e => e.LastTradeTime);
                
                entity.Property(e => e.ChangeTimestamp).IsRequired();
                entity.Property(e => e.QuoteTimestamp).IsRequired();
                entity.Property(e => e.BusinessDate);
                entity.Property(e => e.CreatedAt).IsRequired();
                
                // Create unique constraint to prevent duplicates
                entity.HasIndex(e => new { e.InstrumentToken, e.ChangeTimestamp }).IsUnique();
                
                // Create indexes for performance
                entity.HasIndex(e => new { e.TradingSymbol, e.ChangeTimestamp });
                entity.HasIndex(e => new { e.Exchange, e.ChangeTimestamp });
                entity.HasIndex(e => new { e.ExpiryDate, e.ChangeTimestamp });
                entity.Property(e => e.InsertionSequence);
            });
        }
    }
}
