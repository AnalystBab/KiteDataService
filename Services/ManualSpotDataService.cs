using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service to read manual spot data from XML file when database spot data is not available
    /// </summary>
    public class ManualSpotDataService
    {
        private readonly ILogger<ManualSpotDataService> _logger;
        private readonly string _xmlFilePath;

        public ManualSpotDataService(ILogger<ManualSpotDataService> logger)
        {
            _logger = logger;
            _xmlFilePath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "ManualSpotData.xml");
        }

        /// <summary>
        /// Get NIFTY spot data from XML file
        /// </summary>
        public Task<MarketQuote?> GetNiftySpotDataFromXmlAsync()
        {
            try
            {
                if (!File.Exists(_xmlFilePath))
                {
                    _logger.LogWarning($"Manual spot data XML file not found: {_xmlFilePath}");
                    return null;
                }

                var xmlDoc = XDocument.Load(_xmlFilePath);
                var niftyData = xmlDoc.Descendants("NIFTY").FirstOrDefault();

                if (niftyData == null)
                {
                    _logger.LogWarning("NIFTY data not found in XML file");
                    return null;
                }

                var spotData = new MarketQuote
                {
                    TradingSymbol = niftyData.Element("IndexName")?.Value ?? "NIFTY",
                    OpenPrice = decimal.Parse(niftyData.Element("OpenPrice")?.Value ?? "0"),
                    HighPrice = decimal.Parse(niftyData.Element("HighPrice")?.Value ?? "0"),
                    LowPrice = decimal.Parse(niftyData.Element("LowPrice")?.Value ?? "0"),
                    ClosePrice = decimal.Parse(niftyData.Element("ClosePrice")?.Value ?? "0"),
                    LastPrice = decimal.Parse(niftyData.Element("LastPrice")?.Value ?? "0"),
                    RecordDateTime = DateTime.Parse(niftyData.Element("QuoteTimestamp")?.Value ?? DateTime.Now.ToString())
                };

                _logger.LogInformation($"✅ Loaded NIFTY spot data from XML: Open={spotData.OpenPrice}, Close={spotData.ClosePrice}, LTT={spotData.RecordDateTime:yyyy-MM-dd HH:mm:ss}");
                return Task.FromResult<MarketQuote?>(spotData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to read NIFTY spot data from XML file");
                return Task.FromResult<MarketQuote?>(null);
            }
        }

        /// <summary>
        /// Get all spot data from XML file
        /// </summary>
        public Task<List<SpotData>> GetAllSpotDataFromXmlAsync()
        {
            var spotDataList = new List<SpotData>();

            try
            {
                if (!File.Exists(_xmlFilePath))
                {
                    _logger.LogWarning($"Manual spot data XML file not found: {_xmlFilePath}");
                    return Task.FromResult(spotDataList);
                }

                var xmlDoc = XDocument.Load(_xmlFilePath);
                var indices = xmlDoc.Descendants().Where(x => x.Name.LocalName != "SpotDataConfiguration");

                foreach (var indexData in indices)
                {
                    var spotData = new SpotData
                    {
                        IndexName = indexData.Element("IndexName")?.Value ?? "",
                        TradingDate = DateTime.Parse(indexData.Element("TradingDate")?.Value ?? DateTime.Now.ToString()).Date,
                        QuoteTimestamp = DateTime.Parse(indexData.Element("QuoteTimestamp")?.Value ?? DateTime.Now.ToString()),
                        OpenPrice = decimal.Parse(indexData.Element("OpenPrice")?.Value ?? "0"),
                        HighPrice = decimal.Parse(indexData.Element("HighPrice")?.Value ?? "0"),
                        LowPrice = decimal.Parse(indexData.Element("LowPrice")?.Value ?? "0"),
                        ClosePrice = decimal.Parse(indexData.Element("ClosePrice")?.Value ?? "0"),
                        LastPrice = decimal.Parse(indexData.Element("LastPrice")?.Value ?? "0")
                    };

                    spotDataList.Add(spotData);
                }

                _logger.LogInformation($"✅ Loaded {spotDataList.Count} spot data entries from XML file");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to read spot data from XML file");
            }

            return Task.FromResult(spotDataList);
        }

        /// <summary>
        /// Check if XML file exists and is valid
        /// </summary>
        public bool IsXmlFileAvailable()
        {
            return File.Exists(_xmlFilePath);
        }

        /// <summary>
        /// Get the path to the XML file
        /// </summary>
        public string GetXmlFilePath()
        {
            return _xmlFilePath;
        }
    }
}
