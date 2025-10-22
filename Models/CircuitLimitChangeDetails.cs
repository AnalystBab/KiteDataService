using System;

namespace KiteMarketDataService.Worker.Models
{
    public class CircuitLimitChangeDetails
    {
        public long Id { get; set; }
        
        // Instrument Identification
        public long InstrumentToken { get; set; }
        public string TradingSymbol { get; set; } = string.Empty;
        public string Exchange { get; set; } = string.Empty;  // NFO, BFO
        public string Segment { get; set; } = string.Empty;   // NFO-OPT, BFO-OPT
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty; // CE, PE
        public DateTime ExpiryDate { get; set; }
        
        // Circuit Limit Values (BEFORE change)
        public decimal PreviousLowerCircuit { get; set; }
        public decimal PreviousUpperCircuit { get; set; }
        
        // Circuit Limit Values (AFTER change)
        public decimal NewLowerCircuit { get; set; }
        public decimal NewUpperCircuit { get; set; }
        
        // Change Details
        public decimal LowerCircuitChange { get; set; }  // New - Previous
        public decimal UpperCircuitChange { get; set; }  // New - Previous
        public string ChangeDirection { get; set; } = string.Empty;      // INCREASED, DECREASED, NO_CHANGE
        
        // OHLC Data at the time of change
        public decimal? OpenPrice { get; set; }
        public decimal? HighPrice { get; set; }
        public decimal? LowPrice { get; set; }
        public decimal? ClosePrice { get; set; }
        public decimal? LastPrice { get; set; }
        
        // Market Data at change time
        public long? Volume { get; set; }
        public long? OpenInterest { get; set; }
        public decimal? AveragePrice { get; set; }
        public DateTime? LastTradeTime { get; set; }  // LTT
        
        // Timestamps
        public DateTime ChangeTimestamp { get; set; }
        public DateTime QuoteTimestamp { get; set; }
        public DateTime? BusinessDate { get; set; }  // Business date from MarketQuotes
        
        // Metadata
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow.AddHours(5.5); // Use IST time by default
        
        /// <summary>
        /// Sequence number for this instrument+expiry combination (1, 2, 3, etc.)
        /// </summary>
        public int? InsertionSequence { get; set; }
    }
}
