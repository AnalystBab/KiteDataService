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
    public class StrategyLabelsController : ControllerBase
    {
        private readonly MarketDataContext _context;
        private readonly ILogger<StrategyLabelsController> _logger;

        public StrategyLabelsController(MarketDataContext context, ILogger<StrategyLabelsController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get all strategy labels for a specific date and index
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<List<StrategyLabelResponse>>> GetLabels(
            [FromQuery] string indexName,
            [FromQuery] DateTime? date = null)
        {
            try
            {
                if (string.IsNullOrEmpty(indexName))
                {
                    return BadRequest(new { error = "IndexName is required" });
                }

                var businessDate = date ?? await _context.StrategyLabels
                    .Where(l => l.IndexName == indexName)
                    .MaxAsync(l => (DateTime?)l.BusinessDate);

                if (!businessDate.HasValue)
                {
                    return Ok(new List<StrategyLabelResponse>());
                }

                var labels = await _context.StrategyLabels
                    .Where(l => l.BusinessDate == businessDate.Value && l.IndexName == indexName)
                    .OrderBy(l => l.LabelName)
                    .Select(l => new StrategyLabelResponse
                    {
                        LabelNumber = 0, // Not available in model
                        LabelName = l.LabelName,
                        LabelValue = l.LabelValue,
                        Formula = l.Formula,
                        Description = l.Description,
                        Category = l.ProcessType, // Using ProcessType as category
                        BusinessDate = l.BusinessDate,
                        IndexName = l.IndexName
                    })
                    .ToListAsync();

                return Ok(labels);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting strategy labels");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        /// <summary>
        /// Get a specific label by name
        /// </summary>
        [HttpGet("{labelName}")]
        public async Task<ActionResult<StrategyLabelResponse>> GetLabelByName(
            string labelName,
            [FromQuery] string indexName,
            [FromQuery] DateTime? date = null)
        {
            try
            {
                if (string.IsNullOrEmpty(indexName))
                {
                    return BadRequest(new { error = "IndexName is required" });
                }

                var businessDate = date ?? await _context.StrategyLabels
                    .Where(l => l.IndexName == indexName)
                    .MaxAsync(l => (DateTime?)l.BusinessDate);

                if (!businessDate.HasValue)
                {
                    return NotFound(new { error = "No data found" });
                }

                var label = await _context.StrategyLabels
                    .Where(l => l.BusinessDate == businessDate.Value 
                        && l.IndexName == indexName 
                        && l.LabelName == labelName)
                    .Select(l => new StrategyLabelResponse
                    {
                        LabelNumber = 0,
                        LabelName = l.LabelName,
                        LabelValue = l.LabelValue,
                        Formula = l.Formula,
                        Description = l.Description,
                        Category = l.ProcessType,
                        BusinessDate = l.BusinessDate,
                        IndexName = l.IndexName
                    })
                    .FirstOrDefaultAsync();

                if (label == null)
                {
                    return NotFound(new { error = $"Label {labelName} not found" });
                }

                return Ok(label);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error getting label {labelName}");
                return StatusCode(500, new { error = ex.Message });
            }
        }
    }
}
