using System;
using System.ComponentModel.DataAnnotations;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Intraday tick data for all options instruments
    /// Stores OHLC, LC/UC, Greeks, and market data every minute
    /// </summary>
    public class IntradayTickData
    {
        [Key]
        public long Id { get; set; }
        
        // Trading Information
        public DateTime BusinessDate { get; set; }
        public DateTime TickTimestamp { get; set; } // Every minute timestamp
        public TimeSpan TickTime { get; set; } // Time component (09:15:00, 09:16:00, etc.)
        
        // Instrument Information
        public long InstrumentToken { get; set; }
        public string TradingSymbol { get; set; } = string.Empty;
        public string IndexName { get; set; } = string.Empty; // NIFTY, SENSEX, BANKNIFTY
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty; // CE, PE
        public DateTime ExpiryDate { get; set; }
        
        // OHLC Data (from Kite API)
        public decimal OpenPrice { get; set; }
        public decimal HighPrice { get; set; }
        public decimal LowPrice { get; set; }
        public decimal ClosePrice { get; set; }
        public decimal LastPrice { get; set; }
        
        // Circuit Limits (from Kite API)
        public decimal LowerCircuitLimit { get; set; }
        public decimal UpperCircuitLimit { get; set; }
        
        // Volume and Trading Data (from Kite API)
        public long Volume { get; set; }
        public long LastQuantity { get; set; }
        public long BuyQuantity { get; set; }
        public long SellQuantity { get; set; }
        public decimal AveragePrice { get; set; }
        
        // Open Interest (from Kite API)
        public decimal OpenInterest { get; set; }
        public decimal OiDayHigh { get; set; }
        public decimal OiDayLow { get; set; }
        public decimal NetChange { get; set; }
        
        // Spot Price (underlying index)
        public decimal SpotPrice { get; set; } // Current index price
        
        // Options Greeks (calculated)
        public decimal Delta { get; set; }
        public decimal Gamma { get; set; }
        public decimal Theta { get; set; }
        public decimal Vega { get; set; }
        public decimal Rho { get; set; }
        
        // Advanced Analytics (calculated)
        public decimal ImpliedVolatility { get; set; }
        public decimal TheoreticalPrice { get; set; }
        public decimal PriceDeviation { get; set; }
        public decimal PriceDeviationPercent { get; set; }
        public decimal Moneyness { get; set; }
        public string StrikeType { get; set; } = string.Empty; // ITM, ATM, OTM
        public decimal IntrinsicValue { get; set; }
        public decimal TimeValue { get; set; }
        
        // Prediction Analytics (calculated)
        public decimal PredictedLow { get; set; }
        public decimal PredictedHigh { get; set; }
        public decimal ConfidenceScore { get; set; }
        
        // Volatility Analysis (calculated)
        public decimal HistoricalVolatility { get; set; }
        public decimal VolatilitySkew { get; set; }
        public decimal VolatilityRank { get; set; }
        
        // Risk Metrics (calculated)
        public decimal MaximumLoss { get; set; }
        public decimal MaximumGain { get; set; }
        public decimal BreakEvenPoint { get; set; }
        
        // Market Sentiment (calculated)
        public decimal PutCallRatio { get; set; }
        public decimal VolumeRatio { get; set; }
        public string MarketSentiment { get; set; } = string.Empty; // BULLISH, BEARISH, NEUTRAL
        
        // Data Quality Flags
        public bool HasValidData { get; set; } = true;
        public bool IsMarketOpen { get; set; } = true;
        public string DataSource { get; set; } = "KITE_API"; // KITE_API, CALCULATED, INTERPOLATED
        
        // Metadata
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}


