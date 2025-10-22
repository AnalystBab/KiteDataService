using System;
using System.ComponentModel.DataAnnotations;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// MarketQuote model matching the cleaned database schema
    /// Contains only essential columns for LC/UC monitoring and OHLC data
    /// Target indices: NIFTY, SENSEX, BANKNIFTY only
    /// </summary>
    public class MarketQuote
    {
        // Primary Key (composite)
        public DateTime BusinessDate { get; set; }
        public string TradingSymbol { get; set; } = string.Empty;
        public int InsertionSequence { get; set; }  // Daily sequence (resets per business date)

        /// <summary>
        /// Global sequence number that increments across ALL business dates until expiry.
        /// Example: For NIFTY 25100 CE (expiry Oct 24):
        ///   Oct 7: GlobalSeq 1, 2, 3
        ///   Oct 8: GlobalSeq 4, 5, 6  (continues from Oct 7)
        ///   Oct 9: GlobalSeq 7, 8     (continues from Oct 8)
        /// Used for tracking complete lifecycle of a contract.
        /// </summary>
        public int GlobalSequence { get; set; }

        // CRITICAL: Instrument Token from Kite API (needed for API integration)
        public long InstrumentToken { get; set; }

        // Option Details
        public decimal Strike { get; set; }
        public string OptionType { get; set; } = string.Empty; // 'CE' or 'PE'
        public DateTime ExpiryDate { get; set; }

        // OHLC Data
        public decimal OpenPrice { get; set; }
        public decimal HighPrice { get; set; }
        public decimal LowPrice { get; set; }
        public decimal ClosePrice { get; set; }
        public decimal LastPrice { get; set; }

        // Circuit Limits (CRITICAL for this project)
        public decimal LowerCircuitLimit { get; set; }
        public decimal UpperCircuitLimit { get; set; }

        // Trade Timing
        public DateTime LastTradeTime { get; set; }
        
        // Record Timing - when LC/UC change was actually detected and recorded
        public DateTime RecordDateTime { get; set; }

        /// <summary>
        /// Get index name from trading symbol (NIFTY, SENSEX, BANKNIFTY only)
        /// </summary>
        public string GetIndexName()
        {
            if (TradingSymbol.Contains("SENSEX"))
                return "SENSEX";
            else if (TradingSymbol.Contains("BANKNIFTY"))
                return "BANKNIFTY";
            else if (TradingSymbol.Contains("NIFTY"))
                return "NIFTY";
            else
                return "UNKNOWN";
        }

        /// <summary>
        /// Check if this is a LC/UC change record (sequence > 1)
        /// </summary>
        public bool IsLCUCChange => InsertionSequence > 1;

        /// <summary>
        /// Get formatted display name
        /// </summary>
        public string DisplayName => $"{TradingSymbol} {Strike} {OptionType}";
    }
}