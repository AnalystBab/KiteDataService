using System;
using System.Collections.Generic;
using System.Text.Json;

namespace KiteMarketDataService.Worker.Models
{
    /// <summary>
    /// Helper class for serializing/deserializing LC/UC time data
    /// </summary>
    public class LCUCTimeData
    {
        public string Time { get; set; } = string.Empty; // Format: "09:15:00"
        public string RecordDateTime { get; set; } = string.Empty; // Format: "2025-09-23 08:00:00"
        public decimal LowerCircuit { get; set; }
        public decimal UpperCircuit { get; set; }

        public LCUCTimeData() { }

        public LCUCTimeData(string time, string recordDateTime, decimal lc, decimal uc)
        {
            Time = time;
            RecordDateTime = recordDateTime;
            LowerCircuit = lc;
            UpperCircuit = uc;
        }
    }

    /// <summary>
    /// Container for multiple LC/UC time entries
    /// </summary>
    public class LCUCTimeDataCollection : Dictionary<string, LCUCTimeData>
    {
        public LCUCTimeDataCollection() : base() { }

        /// <summary>
        /// Add LC/UC data for a specific time
        /// </summary>
        /// <param name="timeKey">Time key like "0915", "1130", etc.</param>
        /// <param name="time">Actual time string like "09:15:00"</param>
        /// <param name="recordDateTime">Full record datetime like "2025-09-23 08:00:00"</param>
        /// <param name="lc">Lower Circuit value</param>
        /// <param name="uc">Upper Circuit value</param>
        public void AddLCUCData(string timeKey, string time, string recordDateTime, decimal lc, decimal uc)
        {
            this[timeKey] = new LCUCTimeData(time, recordDateTime, lc, uc);
        }

        /// <summary>
        /// Serialize to JSON string
        /// </summary>
        public string ToJson()
        {
            return JsonSerializer.Serialize(this, new JsonSerializerOptions
            {
                WriteIndented = false,
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase
            });
        }

        /// <summary>
        /// Deserialize from JSON string
        /// </summary>
        public static LCUCTimeDataCollection FromJson(string json)
        {
            if (string.IsNullOrEmpty(json))
                return new LCUCTimeDataCollection();

            try
            {
                var data = JsonSerializer.Deserialize<Dictionary<string, LCUCTimeData>>(json, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var collection = new LCUCTimeDataCollection();
                if (data != null)
                {
                    foreach (var kvp in data)
                    {
                        collection[kvp.Key] = kvp.Value;
                    }
                }
                return collection;
            }
            catch (JsonException)
            {
                return new LCUCTimeDataCollection();
            }
        }
    }
}
