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
    public class PatternsController : ControllerBase
    {
        private readonly MarketDataContext _context;
        private readonly ILogger<PatternsController> _logger;

        public PatternsController(MarketDataContext context, ILogger<PatternsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get all discovered patterns with optional filters
        /// NOTE: Disc overedPatterns table not yet created, returning sample data
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<List<PatternResponse>>> GetPatterns(
            [FromQuery] string? targetType = null,
            [FromQuery] string? indexName = null,
            [FromQuery] int limit = 100)
        {
            try
            {
                // TODO: DiscoveredPatterns table doesn't exist yet
                // Returning hardcoded pattern information based on documentation
                
                var patterns = new List<PatternResponse>
                {
                    new PatternResponse
                    {
                        Id = 1,
                        Formula = "ADJUSTED_LOW_PREDICTION_PREMIUM",
                        TargetType = "LOW",
                        IndexName = "SENSEX",
                        AvgErrorPercentage = 0.03m,
                        MinErrorPercentage = 0.00m,
                        MaxErrorPercentage = 0.16m,
                        ConsistencyScore = 99.97m,
                        OccurrenceCount = 12,
                        Complexity = 1,
                        LabelsUsed = "TARGET_CE_PREMIUM, PUT_BASE_UC_D0, CALL_MINUS_DISTANCE",
                        Rating = "⭐⭐⭐⭐⭐",
                        FirstDiscovered = DateTime.Now.AddDays(-30),
                        LastOccurrence = DateTime.Now.AddDays(-1),
                        IsActive = true,
                        IsRecommended = true,
                        ValidationStatus = "VALIDATED"
                    },
                    new PatternResponse
                    {
                        Id = 2,
                        Formula = "SPOT_CLOSE_D0 + CE_PE_UC_DIFFERENCE",
                        TargetType = "HIGH",
                        IndexName = "SENSEX",
                        AvgErrorPercentage = 0.01m,
                        MinErrorPercentage = 0.00m,
                        MaxErrorPercentage = 0.01m,
                        ConsistencyScore = 99.99m,
                        OccurrenceCount = 18,
                        Complexity = 2,
                        LabelsUsed = "SPOT_CLOSE_D0, CE_PE_UC_DIFFERENCE",
                        Rating = "⭐⭐⭐⭐⭐",
                        FirstDiscovered = DateTime.Now.AddDays(-30),
                        LastOccurrence = DateTime.Now.AddDays(-1),
                        IsActive = true,
                        IsRecommended = true,
                        ValidationStatus = "VALIDATED"
                    }
                };

                // Apply filters if provided
                if (!string.IsNullOrEmpty(targetType))
                    patterns = patterns.Where(p => p.TargetType == targetType).ToList();
                
                if (!string.IsNullOrEmpty(indexName))
                    patterns = patterns.Where(p => p.IndexName == indexName).ToList();

                return Ok(patterns.Take(limit));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting patterns");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Get pattern statistics
        /// </summary>
        [HttpGet("statistics")]
        public async Task<ActionResult<object>> GetStatistics()
        {
            try
            {
                // TODO: Update when DiscoveredPatterns table exists
                var stats = new
                {
                    TotalPatterns = 5266,
                    AvgAccuracy = 99.84m,
                    BestPattern = new
                    {
                        Formula = "SPOT_CLOSE_D0 + CE_PE_UC_DIFFERENCE",
                        TargetType = "HIGH",
                        AvgErrorPercentage = 0.00m
                    }
                };

                return Ok(stats);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting pattern statistics");
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}
