# Kite Market Strategy Framework

A comprehensive framework for developing, testing, and executing trading strategies using market data from the Kite Market Data Service.

## Architecture

The framework is built with a clean, modular architecture:

```
KiteMarketStrategyFramework/
├── KiteMarketStrategyFramework.Core/          # Core interfaces, models, and base classes
├── KiteMarketStrategyFramework.Strategies/    # Concrete strategy implementations
├── KiteMarketStrategyFramework.Console/       # Console application for testing strategies
└── KiteMarketStrategyFramework.sln            # Solution file
```

## Core Components

### 1. Core Project (`KiteMarketStrategyFramework.Core`)

Contains the foundation of the framework:

- **Interfaces**: `IStrategy`, `IMarketDataProvider`, `IStrategyLogger`
- **Models**: `StrategyResult`, `StrategyContext`, `StrategyMarketData`, etc.
- **Base Classes**: `BaseStrategy` - abstract base for all strategies
- **Services**: `StrategyFactory`, `StrategyExecutionService`
- **Data Access**: `KiteMarketDbContext` for Entity Framework Core

### 2. Strategies Project (`KiteMarketStrategyFramework.Strategies`)

Contains concrete strategy implementations:

- **CircuitLimitPredictionStrategy**: Predicts circuit limit changes based on historical patterns
- **More strategies can be added here...**

### 3. Console Project (`KiteMarketStrategyFramework.Console`)

A console application for:

- Testing strategies
- Executing strategies with different parameters
- Viewing strategy results and performance metrics

## Key Features

### Strategy Framework
- **Extensible**: Easy to add new strategies by implementing `IStrategy`
- **Parameterized**: Strategies can accept configurable parameters
- **Validated**: Built-in parameter validation
- **Logged**: Comprehensive logging for debugging and monitoring
- **Documented**: Each strategy includes detailed documentation

### Market Data Integration
- **Database Integration**: Uses existing `KiteMarketData` database
- **Real-time Data**: Access to live market quotes and circuit limit changes
- **Historical Data**: Access to historical market data for analysis
- **Strategy-Specific Data**: Dedicated `StrategyMarketData` table for optimized strategy execution

### Circuit Limit Analysis
- **Pattern Recognition**: Identifies patterns in circuit limit changes
- **Prediction Engine**: Predicts potential circuit limit changes
- **Deviation Analysis**: Calculates confidence scores based on data accuracy
- **Performance Metrics**: Tracks strategy performance and accuracy

## Getting Started

### Prerequisites
- .NET 9.0 SDK
- SQL Server with `KiteMarketData` database
- Access to Kite Connect API (for live data)

### Installation
1. Clone or download the framework
2. Update connection string in `appsettings.json`
3. Build the solution: `dotnet build`
4. Run the console application: `dotnet run --project KiteMarketStrategyFramework.Console`

### Creating a New Strategy

1. **Create Strategy Class**:
```csharp
public class MyStrategy : BaseStrategy
{
    public MyStrategy()
    {
        StrategyId = "MY001";
        StrategyName = "My Custom Strategy";
        Description = "Description of what this strategy does";
        Version = "1.0.0";
        Category = "Custom Analysis";
        
        Parameters = new Dictionary<string, object>
        {
            { "Param1", 100 },
            { "Param2", "Value" }
        };
    }

    public override async Task<StrategyResult> ExecuteAsync(StrategyContext context)
    {
        // Your strategy logic here
        // Access market data via context.MarketDataProvider
        // Return results via StrategyResult
    }
}
```

2. **Add to Strategies Project**: Place your strategy in the `KiteMarketStrategyFramework.Strategies` project
3. **Build and Test**: The framework will automatically discover and register your strategy

## Database Schema

### StrategyMarketData Table
A simplified, optimized table for strategy execution:

```sql
CREATE TABLE StrategyMarketData (
    Id BIGINT IDENTITY(1,1) PRIMARY KEY NONCLUSTERED,
    TradingSymbol NVARCHAR(100),
    IndexName NVARCHAR(50),
    Strike INT,
    OptionType NVARCHAR(10),
    ExpiryDate DATE,
    MarketRanDate DATE,
    TradingDate DATE,
    CreatedDate DATETIME2,
    LastUpdated DATETIME2,
    OpenPrice DECIMAL(18,2),
    HighPrice DECIMAL(18,2),
    LowPrice DECIMAL(18,2),
    ClosePrice DECIMAL(18,2),
    LastPrice DECIMAL(18,2),
    LowerLimit DECIMAL(18,2),
    UpperLimit DECIMAL(18,2)
)
```

### Key Features
- **MarketRanDate**: Derived from spot open and nearest strike LTT for accurate trading day confirmation
- **Optimized Indexes**: Clustered index on (TradingDate, IndexName, ExpiryDate) for fast queries
- **Filtered Indexes**: Separate indexes for CE/PE options and active instruments

## Usage Examples

### Execute a Strategy
```csharp
var context = new StrategyContext
{
    IndexName = "SENSEX",
    FromDate = DateTime.Today.AddDays(-1),
    ToDate = DateTime.Today,
    ExpiryDate = new DateTime(2025, 8, 26),
    Parameters = new Dictionary<string, object>
    {
        { "DeviationThreshold", 0.10 }
    }
};

var result = await executionService.ExecuteStrategyAsync("CLP001", context);
```

### View Strategy Results
```csharp
if (result.IsSuccess)
{
    Console.WriteLine($"Strategy executed successfully: {result.Message}");
    Console.WriteLine($"Predictions: {result.Predictions?.Count ?? 0}");
    
    foreach (var prediction in result.Predictions)
    {
        Console.WriteLine($"{prediction.Name}: {prediction.Value} (Confidence: {prediction.Confidence:P1})");
    }
}
```

## Configuration

### Connection String
Update the connection string in `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=your-server;Database=KiteMarketData;Trusted_Connection=true;"
  }
}
```

### Strategy Parameters
Each strategy can be configured with custom parameters:

```json
{
  "StrategyParameters": {
    "CLP001": {
      "DeviationThreshold": 0.15,
      "MinStrikeRange": 500,
      "MaxStrikeRange": 3000
    }
  }
}
```

## Performance Considerations

### Database Optimization
- **Clustered Indexes**: Optimized for date-based queries
- **Filtered Indexes**: Separate indexes for different option types
- **Covering Indexes**: Include frequently accessed columns

### Strategy Execution
- **Async Operations**: All database operations are asynchronous
- **Batch Processing**: Strategies can process multiple data points efficiently
- **Memory Management**: Efficient data structures for large datasets

## Extending the Framework

### Adding New Data Sources
1. Implement `IMarketDataProvider` interface
2. Register in dependency injection
3. Update configuration

### Adding New Strategy Types
1. Create new strategy category
2. Implement category-specific base classes
3. Add category-specific models and interfaces

### Adding New Analysis Tools
1. Create analysis service interfaces
2. Implement analysis algorithms
3. Integrate with strategy execution pipeline

## Troubleshooting

### Common Issues
1. **Strategy Not Found**: Ensure strategy is in the correct project and implements `IStrategy`
2. **Database Connection**: Verify connection string and SQL Server access
3. **Missing Dependencies**: Check NuGet package references and project references

### Debugging
- Enable detailed logging in `appsettings.json`
- Use console output for strategy execution details
- Check database queries and data availability

## Contributing

1. Follow the existing code structure and patterns
2. Add comprehensive documentation for new strategies
3. Include parameter validation and error handling
4. Test thoroughly before submitting changes

## License

This framework is designed for educational and research purposes. Always verify strategy results with actual market data and consult with financial advisors before making trading decisions.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review strategy documentation
3. Examine console output and logs
4. Verify database connectivity and data availability 