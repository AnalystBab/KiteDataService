using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Services;
using KiteMarketDataService.Worker.Data;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MarketDataController : ControllerBase
    {
        private readonly ILogger<MarketDataController> _logger;
        private readonly KiteConnectService _kiteService;
        private readonly MarketDataContext _context;

        public MarketDataController(
            ILogger<MarketDataController> logger,
            KiteConnectService kiteService,
            MarketDataContext context)
        {
            _logger = logger;
            _kiteService = kiteService;
            _context = context;
        }

        [HttpGet("GetSpotPrices")]
        public async Task<IActionResult> GetSpotPrices()
        {
            try
            {
                _logger.LogInformation("📊 [API] Fetching spot prices for market indices");

                // Get latest spot data from database
                var spotData = await _context.HistoricalSpotData
                    .Where(s => s.TradingDate == DateTime.Today)
                    .OrderByDescending(s => s.LastUpdated)
                    .Take(3)
                    .ToListAsync();

                var result = new
                {
                    sensex = spotData.FirstOrDefault(s => s.IndexName.Contains("SENSEX")) ?? GetDefaultSpotData("SENSEX"),
                    banknifty = spotData.FirstOrDefault(s => s.IndexName.Contains("BANKNIFTY")) ?? GetDefaultSpotData("BANKNIFTY"),
                    nifty = spotData.FirstOrDefault(s => s.IndexName.Contains("NIFTY") && !s.IndexName.Contains("BANK")) ?? GetDefaultSpotData("NIFTY"),
                    timestamp = DateTime.Now,
                    source = "Database"
                };

                _logger.LogInformation("✅ [API] Spot prices retrieved successfully");
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [API] Error fetching spot prices: {Error}", ex.Message);
                return StatusCode(500, new { error = "Failed to fetch spot prices", message = ex.Message });
            }
        }

        [HttpGet("GetMarketStatus")]
        public async Task<IActionResult> GetMarketStatus()
        {
            try
            {
                var now = DateTime.Now;
                var istTime = TimeZoneInfo.ConvertTimeFromUtc(now.ToUniversalTime(), TimeZoneInfo.FindSystemTimeZoneById("India Standard Time"));
                
                var marketOpen = istTime.Hour >= 9 && istTime.Hour < 15;
                var marketClosed = istTime.Hour < 9 || istTime.Hour >= 15;

                var result = new
                {
                    isMarketOpen = marketOpen,
                    isMarketClosed = marketClosed,
                    currentTime = istTime,
                    nextMarketOpen = GetNextMarketOpen(istTime),
                    lastUpdate = DateTime.Now
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [API] Error getting market status: {Error}", ex.Message);
                return StatusCode(500, new { error = "Failed to get market status", message = ex.Message });
            }
        }

        [HttpGet("GetLatestQuotes")]
        public async Task<IActionResult> GetLatestQuotes()
        {
            try
            {
                _logger.LogInformation("📊 [API] Fetching latest market quotes");

                // Get latest quotes from database
                var latestQuotes = await _context.MarketQuotes
                    .Where(q => q.BusinessDate == DateTime.Today)
                    .OrderByDescending(q => q.RecordDateTime)
                    .Take(100)
                    .Select(q => new
                    {
                        q.TradingSymbol,
                        q.LastPrice,
                        q.HighPrice,
                        q.LowPrice,
                        q.OpenPrice,
                        q.ClosePrice,
                        q.RecordDateTime
                    })
                    .ToListAsync();

                var result = new
                    {
                        quotes = latestQuotes,
                        count = latestQuotes.Count,
                        timestamp = DateTime.Now
                    };

                _logger.LogInformation("✅ [API] Latest quotes retrieved: {Count} records", latestQuotes.Count);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [API] Error fetching latest quotes: {Error}", ex.Message);
                return StatusCode(500, new { error = "Failed to fetch latest quotes", message = ex.Message });
            }
        }

        private object GetDefaultSpotData(string indexName)
        {
            // Return default values when no data is available
            return new
            {
                IndexName = indexName,
                ClosePrice = 0.0m,
                LastUpdated = DateTime.Now,
                TradingDate = DateTime.Today
            };
        }

        private DateTime GetNextMarketOpen(DateTime currentTime)
        {
            var nextOpen = currentTime.Date.AddHours(9).AddMinutes(15);
            if (currentTime >= nextOpen)
            {
                nextOpen = nextOpen.AddDays(1);
            }
            return nextOpen;
        }

        [HttpGet("lc-uc-status")]
        public async Task<IActionResult> GetLCUCStatus()
        {
            try
            {
                _logger.LogInformation("📊 [API] Checking LC/UC data collection status");

                // Check today's data for LC/UC values
                var todayData = await _context.MarketQuotes
                    .Where(q => q.BusinessDate == DateTime.Today)
                    .ToListAsync();

                var withLCUC = todayData.Count(q => q.LowerCircuitLimit > 0 || q.UpperCircuitLimit > 0);
                var withoutLCUC = todayData.Count(q => q.LowerCircuitLimit == 0 && q.UpperCircuitLimit == 0);
                var totalRecords = todayData.Count;

                // Get timestamp of most recent record with LC/UC
                var lastRecordWithLCUC = todayData
                    .Where(q => q.LowerCircuitLimit > 0 || q.UpperCircuitLimit > 0)
                    .OrderByDescending(q => q.RecordDateTime)
                    .FirstOrDefault();

                var result = new
                {
                    success = true,
                    hasLCUC = withLCUC > 0,
                    totalRecords = totalRecords,
                    recordsWithLCUC = withLCUC,
                    recordsWithoutLCUC = withoutLCUC,
                    lastTimestamp = lastRecordWithLCUC?.RecordDateTime.ToString("yyyy-MM-dd HH:mm:ss") ?? "None",
                    percentage = totalRecords > 0 ? (double)withLCUC / totalRecords * 100 : 0,
                    message = withLCUC > 0 
                        ? $"LC/UC data being collected ({withLCUC} records)"
                        : "No LC/UC data found for today",
                    timestamp = DateTime.Now
                };

                _logger.LogInformation("✅ [API] LC/UC status: {Status} - {Details}", 
                    result.hasLCUC ? "Active" : "Inactive", 
                    result.message);

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [API] Error checking LC/UC status: {Error}", ex.Message);
                return StatusCode(500, new { 
                    success = false, 
                    hasLCUC = false, 
                    error = "Failed to check LC/UC status", 
                    message = ex.Message 
                });
            }
        }
    }
}



using System;
using System.Threading.Tasks;
using KiteMarketDataService.Worker.Services;
using KiteMarketDataService.Worker.Data;
using Microsoft.EntityFrameworkCore;
using System.Linq;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class MarketDataController : ControllerBase
    {
        private readonly ILogger<MarketDataController> _logger;
        private readonly KiteConnectService _kiteService;
        private readonly MarketDataContext _context;

        public MarketDataController(
            ILogger<MarketDataController> logger,
            KiteConnectService kiteService,
            MarketDataContext context)
        {
            _logger = logger;
            _kiteService = kiteService;
            _context = context;
        }

        [HttpGet("GetSpotPrices")]
        public async Task<IActionResult> GetSpotPrices()
        {
            try
            {
                _logger.LogInformation("📊 [API] Fetching spot prices for market indices");

                // Get latest spot data from database
                var spotData = await _context.HistoricalSpotData
                    .Where(s => s.TradingDate == DateTime.Today)
                    .OrderByDescending(s => s.LastUpdated)
                    .Take(3)
                    .ToListAsync();

                var result = new
                {
                    sensex = spotData.FirstOrDefault(s => s.IndexName.Contains("SENSEX")) ?? GetDefaultSpotData("SENSEX"),
                    banknifty = spotData.FirstOrDefault(s => s.IndexName.Contains("BANKNIFTY")) ?? GetDefaultSpotData("BANKNIFTY"),
                    nifty = spotData.FirstOrDefault(s => s.IndexName.Contains("NIFTY") && !s.IndexName.Contains("BANK")) ?? GetDefaultSpotData("NIFTY"),
                    timestamp = DateTime.Now,
                    source = "Database"
                };

                _logger.LogInformation("✅ [API] Spot prices retrieved successfully");
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [API] Error fetching spot prices: {Error}", ex.Message);
                return StatusCode(500, new { error = "Failed to fetch spot prices", message = ex.Message });
            }
        }

        [HttpGet("GetMarketStatus")]
        public async Task<IActionResult> GetMarketStatus()
        {
            try
            {
                var now = DateTime.Now;
                var istTime = TimeZoneInfo.ConvertTimeFromUtc(now.ToUniversalTime(), TimeZoneInfo.FindSystemTimeZoneById("India Standard Time"));
                
                var marketOpen = istTime.Hour >= 9 && istTime.Hour < 15;
                var marketClosed = istTime.Hour < 9 || istTime.Hour >= 15;

                var result = new
                {
                    isMarketOpen = marketOpen,
                    isMarketClosed = marketClosed,
                    currentTime = istTime,
                    nextMarketOpen = GetNextMarketOpen(istTime),
                    lastUpdate = DateTime.Now
                };

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [API] Error getting market status: {Error}", ex.Message);
                return StatusCode(500, new { error = "Failed to get market status", message = ex.Message });
            }
        }

        [HttpGet("GetLatestQuotes")]
        public async Task<IActionResult> GetLatestQuotes()
        {
            try
            {
                _logger.LogInformation("📊 [API] Fetching latest market quotes");

                // Get latest quotes from database
                var latestQuotes = await _context.MarketQuotes
                    .Where(q => q.BusinessDate == DateTime.Today)
                    .OrderByDescending(q => q.RecordDateTime)
                    .Take(100)
                    .Select(q => new
                    {
                        q.TradingSymbol,
                        q.LastPrice,
                        q.HighPrice,
                        q.LowPrice,
                        q.OpenPrice,
                        q.ClosePrice,
                        q.RecordDateTime
                    })
                    .ToListAsync();

                var result = new
                    {
                        quotes = latestQuotes,
                        count = latestQuotes.Count,
                        timestamp = DateTime.Now
                    };

                _logger.LogInformation("✅ [API] Latest quotes retrieved: {Count} records", latestQuotes.Count);
                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [API] Error fetching latest quotes: {Error}", ex.Message);
                return StatusCode(500, new { error = "Failed to fetch latest quotes", message = ex.Message });
            }
        }

        private object GetDefaultSpotData(string indexName)
        {
            // Return default values when no data is available
            return new
            {
                IndexName = indexName,
                ClosePrice = 0.0m,
                LastUpdated = DateTime.Now,
                TradingDate = DateTime.Today
            };
        }

        private DateTime GetNextMarketOpen(DateTime currentTime)
        {
            var nextOpen = currentTime.Date.AddHours(9).AddMinutes(15);
            if (currentTime >= nextOpen)
            {
                nextOpen = nextOpen.AddDays(1);
            }
            return nextOpen;
        }

        [HttpGet("lc-uc-status")]
        public async Task<IActionResult> GetLCUCStatus()
        {
            try
            {
                _logger.LogInformation("📊 [API] Checking LC/UC data collection status");

                // Check today's data for LC/UC values
                var todayData = await _context.MarketQuotes
                    .Where(q => q.BusinessDate == DateTime.Today)
                    .ToListAsync();

                var withLCUC = todayData.Count(q => q.LowerCircuitLimit > 0 || q.UpperCircuitLimit > 0);
                var withoutLCUC = todayData.Count(q => q.LowerCircuitLimit == 0 && q.UpperCircuitLimit == 0);
                var totalRecords = todayData.Count;

                // Get timestamp of most recent record with LC/UC
                var lastRecordWithLCUC = todayData
                    .Where(q => q.LowerCircuitLimit > 0 || q.UpperCircuitLimit > 0)
                    .OrderByDescending(q => q.RecordDateTime)
                    .FirstOrDefault();

                var result = new
                {
                    success = true,
                    hasLCUC = withLCUC > 0,
                    totalRecords = totalRecords,
                    recordsWithLCUC = withLCUC,
                    recordsWithoutLCUC = withoutLCUC,
                    lastTimestamp = lastRecordWithLCUC?.RecordDateTime.ToString("yyyy-MM-dd HH:mm:ss") ?? "None",
                    percentage = totalRecords > 0 ? (double)withLCUC / totalRecords * 100 : 0,
                    message = withLCUC > 0 
                        ? $"LC/UC data being collected ({withLCUC} records)"
                        : "No LC/UC data found for today",
                    timestamp = DateTime.Now
                };

                _logger.LogInformation("✅ [API] LC/UC status: {Status} - {Details}", 
                    result.hasLCUC ? "Active" : "Inactive", 
                    result.message);

                return Ok(result);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ [API] Error checking LC/UC status: {Error}", ex.Message);
                return StatusCode(500, new { 
                    success = false, 
                    hasLCUC = false, 
                    error = "Failed to check LC/UC status", 
                    message = ex.Message 
                });
            }
        }
    }
}
