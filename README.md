# Kite Market Data Service

A .NET Worker Service that collects real-time market data from Kite Connect API and stores it in a SQL Server database.

## Prerequisites

- .NET 9.0 or later
- SQL Server (LocalDB, Express, or full version)
- Kite Connect API credentials

## Configuration

1. **Database Connection**: Update the connection string in `appsettings.json`:
   ```json
   "ConnectionStrings": {
     "DefaultConnection": "Server=localhost;Database=KiteMarketData;Trusted_Connection=true;TrustServerCertificate=true;MultipleActiveResultSets=true"
   }
   ```

2. **Kite Connect Settings**: Update your API credentials in `appsettings.json`:
   ```json
   "KiteConnect": {
     "ApiKey": "your_api_key_here",
     "ApiSecret": "your_api_secret_here",
     "RequestToken": "your_request_token_here"
   }
   ```

## Getting Your Request Token

1. Go to [Kite Connect Login](https://kite.trade/connect/login?api_key=your_api_key&v=3)
2. Replace `your_api_key` with your actual API key
3. Login with your Zerodha credentials
4. Copy the request token from the URL after successful login
5. Update the `RequestToken` in `appsettings.json`

## Running the Service

### Development
```bash
dotnet run
```

### Production
```bash
dotnet publish -c Release
dotnet KiteMarketDataService.Worker.dll
```

## Features

- **Real-time Market Data**: Collects quotes every minute
- **Instrument Management**: Automatically updates instrument list daily
- **Circuit Limits Analysis**: Smart circuit limits processing
- **Data Cleanup**: Automatic cleanup of old data (30 days retention)
- **Database Storage**: SQL Server with Entity Framework Core

## Database

The service automatically creates the database and applies migrations on first run. The database includes:

- Market quotes with real-time data
- Instrument information
- Circuit limits data

## Logging

Logs are written to the console and can be configured in `appsettings.json`. The service provides detailed logging for:

- Authentication status
- Data collection progress
- Error handling
- Database operations 