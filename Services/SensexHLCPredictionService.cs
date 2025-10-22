using System;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using KiteMarketDataService.Worker.Data;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    /// <summary>
    /// Service to predict SENSEX High, Low, Close using option circuit limit data
    /// Based on PUT_MINUS, PUT_PLUS, and CALL_PLUS processes
    /// </summary>
    public class SensexHLCPredictionService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<SensexHLCPredictionService> _logger;

        public SensexHLCPredictionService(
            IServiceScopeFactory scopeFactory,
            ILogger<SensexHLCPredictionService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        /// <summary>
        /// Predict SENSEX HLC for next trading day using previous day's option data
        /// </summary>
        public async Task<SensexHLCPrediction> PredictHLCAync(DateTime businessDate)
        {
            try
            {
                using var scope = _scopeFactory.CreateScope();
                var context = scope.ServiceProvider.GetRequiredService<MarketDataContext>();

                // Get SENSEX close price for the business date
                var spotData = await context.HistoricalSpotData
                    .Where(s => s.IndexName == "SENSEX" && s.TradingDate.Date == businessDate.Date)
                    .OrderByDescending(s => s.LastUpdated)
                    .FirstOrDefaultAsync();

                if (spotData == null)
                {
                    _logger.LogWarning($"No SENSEX spot data found for {businessDate:yyyy-MM-dd}");
                    return null;
                }

                var sensexClose = spotData.ClosePrice;
                var referenceStrike = Math.Round(sensexClose / 100) * 100; // Round to nearest 100

                _logger.LogInformation($"SENSEX Close: {sensexClose:F2}, Reference Strike: {referenceStrike:F0}");

                // Get option circuit limits for reference strike
                var optionData = await context.MarketQuotes
                    .Where(q => q.TradingSymbol.Contains("SENSEX") && 
                               q.Strike == referenceStrike && 
                               q.BusinessDate == businessDate &&
                               q.ExpiryDate > businessDate)
                    .OrderBy(q => q.ExpiryDate)
                    .ThenBy(q => q.OptionType)
                    .ToListAsync();

                if (!optionData.Any())
                {
                    _logger.LogWarning($"No option data found for SENSEX {referenceStrike:F0} on {businessDate:yyyy-MM-dd}");
                    return null;
                }

                // Get CE and PE UC values
                var ceOption = optionData.FirstOrDefault(q => q.OptionType == "CE");
                var peOption = optionData.FirstOrDefault(q => q.OptionType == "PE");

                if (ceOption == null || peOption == null)
                {
                    _logger.LogWarning($"Missing CE or PE data for SENSEX {referenceStrike:F0}");
                    return null;
                }

                // Calculate base strikes
                var baseStrikes = await CalculateBaseStrikesAsync(context, businessDate, sensexClose);

                // Apply prediction formulas
                var prediction = CalculateHLCPrediction(
                    referenceStrike,
                    ceOption.UpperCircuitLimit,
                    peOption.UpperCircuitLimit,
                    baseStrikes.CallBaseStrike,
                    baseStrikes.PutBaseStrike
                );

                prediction.BusinessDate = businessDate;
                prediction.ReferenceStrike = referenceStrike;
                prediction.SensexClose = sensexClose;

                _logger.LogInformation($"SENSEX HLC Prediction for {businessDate.AddDays(1):yyyy-MM-dd}: Low={prediction.PredictedLow:F0}, High={prediction.PredictedHigh:F0}, Close={prediction.PredictedClose:F0}");

                return prediction;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error predicting SENSEX HLC");
                return null;
            }
        }

        /// <summary>
        /// Calculate base strikes (CALL_BASE_STRIKE and PUT_BASE_STRIKE)
        /// </summary>
        private async Task<BaseStrikes> CalculateBaseStrikesAsync(MarketDataContext context, DateTime businessDate, decimal sensexClose)
        {
            // Get strikes with LC > 0.05 around SENSEX close
            var strikes = await context.MarketQuotes
                .Where(q => q.TradingSymbol.Contains("SENSEX") && 
                           q.BusinessDate == businessDate &&
                           q.LowerCircuitLimit > 0.05m)
                .Select(q => q.Strike)
                .Distinct()
                .OrderBy(s => s)
                .ToListAsync();

            // Find CALL_BASE_STRIKE (first strike below SENSEX close with LC > 0.05)
            var callBaseStrike = strikes
                .Where(s => s < sensexClose)
                .OrderByDescending(s => s)
                .FirstOrDefault();

            // Find PUT_BASE_STRIKE (first strike above SENSEX close with LC > 0.05)
            var putBaseStrike = strikes
                .Where(s => s > sensexClose)
                .OrderBy(s => s)
                .FirstOrDefault();

            return new BaseStrikes
            {
                CallBaseStrike = callBaseStrike,
                PutBaseStrike = putBaseStrike
            };
        }

        /// <summary>
        /// Apply the three-process formula system to predict HLC
        /// </summary>
        public SensexHLCPrediction CalculateHLCPrediction(
            decimal strike, 
            decimal ceUC, 
            decimal peUC, 
            decimal callBaseStrike, 
            decimal putBaseStrike)
        {
            // PUT MINUS PROCESS (Support Calculation)
            var putMinusValue = strike - peUC;
            var distanceFromCallBase = putMinusValue - callBaseStrike;
            var derivedPremium = peUC - distanceFromCallBase;
            var targetSupport = strike - derivedPremium;

            // PUT PLUS PROCESS (Resistance Calculation)
            var putPlusValue = strike + peUC;
            var distanceFromPutBase = putBaseStrike - putPlusValue;
            var derivedResistancePremium = ceUC - distanceFromPutBase;
            var targetResistance = strike + derivedResistancePremium;

            // CALL PLUS PROCESS (Alternative Resistance)
            var callPlusValue = strike + ceUC;
            var callDistanceFromPutBase = putBaseStrike - callPlusValue;
            var callDerivedPremium = peUC - callDistanceFromPutBase;
            var callTargetResistance = strike + callDerivedPremium;

            // Calculate predicted close (average of predicted high and low)
            var predictedClose = (putMinusValue + callPlusValue) / 2;

            return new SensexHLCPrediction
            {
                PredictedLow = putMinusValue,           // Primary support
                PredictedHigh = callPlusValue,          // Primary resistance
                PredictedClose = predictedClose,        // Range midpoint
                TargetSupport = targetSupport,          // Refined support
                TargetResistance = targetResistance,    // Refined resistance
                CallTargetResistance = callTargetResistance, // Alternative resistance
                
                // Process values
                PutMinusValue = putMinusValue,
                PutPlusValue = putPlusValue,
                CallPlusValue = callPlusValue,
                
                // Input values
                Strike = strike,
                CeUC = ceUC,
                PeUC = peUC,
                CallBaseStrike = callBaseStrike,
                PutBaseStrike = putBaseStrike
            };
        }
    }

    /// <summary>
    /// Model for SENSEX HLC prediction results
    /// </summary>
    public class SensexHLCPrediction
    {
        public DateTime BusinessDate { get; set; }
        public decimal ReferenceStrike { get; set; }
        public decimal SensexClose { get; set; }
        
        // Primary predictions
        public decimal PredictedLow { get; set; }
        public decimal PredictedHigh { get; set; }
        public decimal PredictedClose { get; set; }
        
        // Refined levels
        public decimal TargetSupport { get; set; }
        public decimal TargetResistance { get; set; }
        public decimal CallTargetResistance { get; set; }
        
        // Process values
        public decimal PutMinusValue { get; set; }
        public decimal PutPlusValue { get; set; }
        public decimal CallPlusValue { get; set; }
        
        // Input values
        public decimal Strike { get; set; }
        public decimal CeUC { get; set; }
        public decimal PeUC { get; set; }
        public decimal CallBaseStrike { get; set; }
        public decimal PutBaseStrike { get; set; }
    }

    /// <summary>
    /// Model for base strikes
    /// </summary>
    public class BaseStrikes
    {
        public decimal CallBaseStrike { get; set; }
        public decimal PutBaseStrike { get; set; }
    }
}

