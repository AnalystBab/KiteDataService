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
    public class ProcessBreakdownController : ControllerBase
    {
        private readonly MarketDataContext _context;
        private readonly ILogger<ProcessBreakdownController> _logger;

        public ProcessBreakdownController(MarketDataContext context, ILogger<ProcessBreakdownController> logger)
        {
            _context = context;
            _logger = logger;
        }

        /// <summary>
        /// Get complete process breakdown (C-, P-, C+, P+) for a given date and index
        /// </summary>
        [HttpGet]
        public async Task<ActionResult<ProcessBreakdownResponse>> GetProcessBreakdown(
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
                    return NotFound(new { error = $"No data found for {indexName}" });
                }

                // Get all labels for this date/index
                var labels = await _context.StrategyLabels
                    .Where(l => l.BusinessDate == businessDate.Value && l.IndexName == indexName)
                    .ToListAsync();

                if (!labels.Any())
                {
                    return NotFound(new { error = $"No labels found for {indexName} on {businessDate.Value:yyyy-MM-dd}" });
                }

                var response = BuildProcessBreakdown(businessDate.Value, indexName, labels);
                return Ok(response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting process breakdown");
                return StatusCode(500, new { error = ex.Message });
            }
        }

        private ProcessBreakdownResponse BuildProcessBreakdown(
            DateTime businessDate, 
            string indexName, 
            List<KiteMarketDataService.Worker.Models.StrategyLabel> labels)
        {
            // Helper to get label value
            decimal GetValue(string name) => labels.FirstOrDefault(l => l.LabelName == name)?.LabelValue ?? 0;

            return new ProcessBreakdownResponse
            {
                BusinessDate = businessDate,
                IndexName = indexName,
                
                // Base data
                SpotClose = GetValue("SPOT_CLOSE_D0"),
                CloseStrike = (int)GetValue("CLOSE_STRIKE"),
                CloseCeUc = GetValue("CLOSE_CE_UC_D0"),
                ClosePeUc = GetValue("CLOSE_PE_UC_D0"),
                
                // Base strikes
                CallBaseStrike = (int)GetValue("CALL_BASE_STRIKE"),
                PutBaseStrike = (int)GetValue("PUT_BASE_STRIKE"),
                CallBaseLc = GetValue("CALL_BASE_LC_D0"),
                PutBaseLc = GetValue("PUT_BASE_LC_D0"),
                CallBaseUc = GetValue("CALL_BASE_UC_D0"),
                PutBaseUc = GetValue("PUT_BASE_UC_D0"),
                
                // Processes
                CallMinus = new ProcessDetail
                {
                    ProcessName = "CALL_MINUS (C-)",
                    Value = GetValue("CALL_MINUS"),
                    Formula = "CALL_BASE_UC_D0 - CLOSE_CE_UC_D0",
                    Description = "Difference between Call Base UC and Close Strike CE UC",
                    Distance = GetValue("CALL_MINUS_TO_CALL_BASE_DISTANCE"),
                    RelatedLabelNames = new List<string> { "CALL_BASE_STRIKE", "CALL_BASE_UC_D0", "CLOSE_CE_UC_D0" }
                },
                
                PutMinus = new ProcessDetail
                {
                    ProcessName = "PUT_MINUS (P-)",
                    Value = GetValue("PUT_MINUS"),
                    Formula = "PUT_BASE_UC_D0 - CLOSE_PE_UC_D0",
                    Description = "Difference between Put Base UC and Close Strike PE UC",
                    Distance = GetValue("PUT_MINUS_TO_PUT_BASE_DISTANCE"),
                    RelatedLabelNames = new List<string> { "PUT_BASE_STRIKE", "PUT_BASE_UC_D0", "CLOSE_PE_UC_D0" }
                },
                
                CallPlus = new ProcessDetail
                {
                    ProcessName = "CALL_PLUS (C+)",
                    Value = GetValue("CALL_PLUS"),
                    Formula = "CLOSE_CE_UC_D0 - CALL_BASE_LC_D0",
                    Description = "Difference between Close Strike CE UC and Call Base LC",
                    Distance = 0, // Not typically calculated
                    RelatedLabelNames = new List<string> { "CLOSE_CE_UC_D0", "CALL_BASE_LC_D0" }
                },
                
                PutPlus = new ProcessDetail
                {
                    ProcessName = "PUT_PLUS (P+)",
                    Value = GetValue("PUT_PLUS"),
                    Formula = "CLOSE_PE_UC_D0 - PUT_BASE_LC_D0",
                    Description = "Difference between Close Strike PE UC and Put Base LC",
                    Distance = 0, // Not typically calculated
                    RelatedLabelNames = new List<string> { "CLOSE_PE_UC_D0", "PUT_BASE_LC_D0" }
                },
                
                // Related labels
                RelatedLabels = labels
                    .OrderBy(l => l.LabelName)
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
                    .ToList()
            };
        }
    }
}

