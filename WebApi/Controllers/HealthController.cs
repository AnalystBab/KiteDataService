using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Data;
using System;
using System.Threading.Tasks;

namespace KiteMarketDataService.Worker.WebApi.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class HealthController : ControllerBase
    {
        private readonly MarketDataContext _context;
        private readonly ILogger<HealthController> _logger;

        public HealthController(MarketDataContext context, ILogger<HealthController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Health check endpoint
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<object>> GetHealth()
        {
            try
            {
                // Test database connection
                var dbConnected = await _context.Database.CanConnectAsync();

                // Get some basic stats
                var labelCount = await _context.StrategyLabels.CountAsync();
                var spotDataCount = await _context.HistoricalSpotData.CountAsync();

                return Ok(new
                {
                    status = "Healthy",
                    timestamp = DateTime.UtcNow,
                    database = dbConnected ? "Connected" : "Disconnected",
                    stats = new
                    {
                        totalLabels = labelCount,
                        totalSpotData = spotDataCount
                    },
                    version = "1.0.0",
                    environment = "Production"
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Health check failed");
                return StatusCode(500, new
                {
                    status = "Unhealthy",
                    timestamp = DateTime.UtcNow,
                    error = ex.Message
                });
            }
        }
    }
}
