using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Xml.Linq;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service to read manual NIFTY spot data from XML file when database spot data is not available
    /// </summary>
    public class ManualNiftySpotDataService
    {
        private readonly ILogger<ManualNiftySpotDataService> _logger;
        private readonly string _xmlFilePath;

        public ManualNiftySpotDataService(ILogger<ManualNiftySpotDataService> logger)
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
                    _logger.LogWarning($"Manual NIFTY spot data XML file not found: {_xmlFilePath}");
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

        /// <summary>
        /// Get NIFTY spot data from XML file as SpotData model (for database updates)
        /// </summary>
        public Task<SpotData?> GetNiftySpotDataAsSpotDataAsync()
        {
            try
            {
                if (!File.Exists(_xmlFilePath))
                {
                    _logger.LogWarning($"Manual NIFTY spot data XML file not found: {_xmlFilePath}");
                    return Task.FromResult<SpotData?>(null);
                }

                var xmlDoc = XDocument.Load(_xmlFilePath);
                var niftyData = xmlDoc.Descendants("NIFTY").FirstOrDefault();

                if (niftyData == null)
                {
                    _logger.LogWarning("NIFTY data not found in XML file");
                    return Task.FromResult<SpotData?>(null);
                }

                var tradingDateStr = niftyData.Element("TradingDate")?.Value;
                var quoteTimestampStr = niftyData.Element("QuoteTimestamp")?.Value;
                var isMarketOpenStr = niftyData.Element("IsMarketOpen")?.Value;

                var spotData = new SpotData
                {
                    IndexName = niftyData.Element("IndexName")?.Value ?? "NIFTY",
                    TradingDate = DateTime.Parse(tradingDateStr ?? DateTime.Now.ToString("yyyy-MM-dd")),
                    OpenPrice = decimal.Parse(niftyData.Element("OpenPrice")?.Value ?? "0"),
                    HighPrice = decimal.Parse(niftyData.Element("HighPrice")?.Value ?? "0"),
                    LowPrice = decimal.Parse(niftyData.Element("LowPrice")?.Value ?? "0"),
                    ClosePrice = decimal.Parse(niftyData.Element("ClosePrice")?.Value ?? "0"),
                    LastPrice = decimal.Parse(niftyData.Element("LastPrice")?.Value ?? "0"),
                    QuoteTimestamp = DateTime.Parse(quoteTimestampStr ?? DateTime.Now.ToString()),
                    IsMarketOpen = bool.Parse(isMarketOpenStr ?? "false"),
                    DataSource = "XML File (Manual)"
                };

                _logger.LogInformation($"✅ Loaded NIFTY spot data from XML: Date={spotData.TradingDate:yyyy-MM-dd}, Open={spotData.OpenPrice}, Close={spotData.ClosePrice}");
                return Task.FromResult<SpotData?>(spotData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to read NIFTY spot data from XML file");
                return Task.FromResult<SpotData?>(null);
            }
        }

        /// <summary>
        /// Get business date from XML file
        /// </summary>
        public Task<DateTime?> GetBusinessDateFromXmlAsync()
        {
            try
            {
                if (!File.Exists(_xmlFilePath))
                {
                    return null;
                }

                var xmlDoc = XDocument.Load(_xmlFilePath);
                var niftyData = xmlDoc.Descendants("NIFTY").FirstOrDefault();

                if (niftyData == null)
                {
                    return null;
                }

                var businessDateStr = niftyData.Element("BusinessDate")?.Value;
                if (DateTime.TryParse(businessDateStr, out var businessDate))
                {
                    _logger.LogInformation($"✅ Loaded business date from XML: {businessDate:yyyy-MM-dd}");
                    return Task.FromResult<DateTime?>(businessDate);
                }

                return Task.FromResult<DateTime?>(null);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get business date from XML file");
                return Task.FromResult<DateTime?>(null);
            }
        }
    }
}
