using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.WebApi.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class LiveMarketController : ControllerBase
    {
        private readonly MarketDataContext _context;
        private readonly ILogger<LiveMarketController> _logger;

        public LiveMarketController(MarketDataContext context, ILogger<LiveMarketController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get live market data for all indices
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<List<LiveMarketResponse>>> GetLiveMarket()
        {
            try
            {
                // Get latest trading date with spot data
                var latestDate = await _context.HistoricalSpotData
                    .MaxAsync(s => (DateTime?)s.TradingDate);

                if (!latestDate.HasValue)
                {
                    return Ok(new List<LiveMarketResponse>());
                }

                var spotData = await _context.HistoricalSpotData
                    .Where(s => s.TradingDate == latestDate.Value)
                    .Select(s => new LiveMarketResponse
                    {
                        IndexName = s.IndexName,
                        TradingDate = s.TradingDate,
                        OpenPrice = s.OpenPrice,
                        HighPrice = s.HighPrice,
                        LowPrice = s.LowPrice,
                        ClosePrice = s.ClosePrice,
                        ChangePercent = s.OpenPrice > 0 ? ((s.ClosePrice - s.OpenPrice) / s.OpenPrice * 100) : 0,
                        ChangeValue = s.ClosePrice - s.OpenPrice,
                        LastUpdated = DateTime.UtcNow,
                        MarketStatus = DetermineMarketStatus()
                    })
                    .ToListAsync();

                return Ok(spotData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting live market data");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Get live market data for a specific index
        /// </summary>
        [HttpGet("{indexName}")]
        public async Task<ActionResult<LiveMarketResponse>> GetLiveMarketForIndex(string indexName)
        {
            try
            {
                var latestDate = await _context.HistoricalSpotData
                    .Where(s => s.IndexName == indexName)
                    .MaxAsync(s => (DateTime?)s.TradingDate);

                if (!latestDate.HasValue)
                {
                    return NotFound(new { error = $"No data found for {indexName}" });
                }

                var spotData = await _context.HistoricalSpotData
                    .Where(s => s.TradingDate == latestDate.Value && s.IndexName == indexName)
                    .Select(s => new LiveMarketResponse
                    {
                        IndexName = s.IndexName,
                        TradingDate = s.TradingDate,
                        OpenPrice = s.OpenPrice,
                        HighPrice = s.HighPrice,
                        LowPrice = s.LowPrice,
                        ClosePrice = s.ClosePrice,
                        ChangePercent = s.OpenPrice > 0 ? ((s.ClosePrice - s.OpenPrice) / s.OpenPrice * 100) : 0,
                        ChangeValue = s.ClosePrice - s.OpenPrice,
                        LastUpdated = DateTime.UtcNow,
                        MarketStatus = DetermineMarketStatus()
                    })
                    .FirstOrDefaultAsync();

                if (spotData == null)
                {
                    return NotFound(new { error = $"No data found for {indexName}" });
                }

                return Ok(spotData);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting live market data for {indexName}");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        private string DetermineMarketStatus()
        {
            var istNow = DateTime.UtcNow.AddHours(5.5);
            var timeOfDay = istNow.TimeOfDay;
            var marketOpen = new TimeSpan(9, 15, 0);
            var marketClose = new TimeSpan(15, 30, 0);

            if (timeOfDay >= marketOpen && timeOfDay <= marketClose)
            {
                return "OPEN";
            }
            else if (timeOfDay < marketOpen)
            {
                return "PRE_MARKET";
            }
            else
            {
                return "CLOSED";
            }
        }
    }
}











