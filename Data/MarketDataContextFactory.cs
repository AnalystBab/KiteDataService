using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace KiteMarketDataService.Worker.Data
{
    public class MarketDataContextFactory : IDesignTimeDbContextFactory<MarketDataContext>
    {
        public MarketDataContext CreateDbContext(string[] args)
        {
            var optionsBuilder = new DbContextOptionsBuilder<MarketDataContext>();
            optionsBuilder.UseSqlServer("Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true");

            return new MarketDataContext(optionsBuilder.Options);
        }
    }
} 