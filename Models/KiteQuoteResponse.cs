using System;
using System.Collections.Generic;
using Newtonsoft.Json;

namespace KiteMarketDataService.Worker.Models
{
    public class KiteQuoteResponse
    {
        [JsonProperty("status")]
        public string? Status { get; set; }

        [JsonProperty("data")]
        public Dictionary<string, QuoteData>? Data { get; set; }
    }

    public class QuoteData
    {
        [JsonProperty("instrument_token")]
        public long InstrumentToken { get; set; }

        [JsonProperty("timestamp")]
        public string? Timestamp { get; set; }

        [JsonProperty("last_trade_time")]
        public string? LastTradeTime { get; set; }

        [JsonProperty("last_price")]
        public decimal LastPrice { get; set; }

        [JsonProperty("last_quantity")]
        public long LastQuantity { get; set; }

        [JsonProperty("buy_quantity")]
        public long BuyQuantity { get; set; }

        [JsonProperty("sell_quantity")]
        public long SellQuantity { get; set; }

        [JsonProperty("volume")]
        public long Volume { get; set; }

        [JsonProperty("average_price")]
        public decimal AveragePrice { get; set; }

        [JsonProperty("oi")]
        public decimal OpenInterest { get; set; }

        [JsonProperty("oi_day_high")]
        public decimal OiDayHigh { get; set; }

        [JsonProperty("oi_day_low")]
        public decimal OiDayLow { get; set; }

        [JsonProperty("net_change")]
        public decimal NetChange { get; set; }

        [JsonProperty("lower_circuit_limit")]
        public decimal LowerCircuitLimit { get; set; }

        [JsonProperty("upper_circuit_limit")]
        public decimal UpperCircuitLimit { get; set; }

        [JsonProperty("ohlc")]
        public OHLCData? OHLC { get; set; }

        [JsonProperty("depth")]
        public MarketDepth? Depth { get; set; }
    }

    public class OHLCData
    {
        [JsonProperty("open")]
        public decimal Open { get; set; }

        [JsonProperty("high")]
        public decimal High { get; set; }

        [JsonProperty("low")]
        public decimal Low { get; set; }

        [JsonProperty("close")]
        public decimal Close { get; set; }
    }

    public class MarketDepth
    {
        [JsonProperty("buy")]
        public List<DepthItem>? Buy { get; set; }

        [JsonProperty("sell")]
        public List<DepthItem>? Sell { get; set; }
    }

    public class DepthItem
    {
        [JsonProperty("price")]
        public decimal Price { get; set; }

        [JsonProperty("quantity")]
        public long Quantity { get; set; }

        [JsonProperty("orders")]
        public long Orders { get; set; }
    }
} 