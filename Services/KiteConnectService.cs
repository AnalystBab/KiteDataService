using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using KiteMarketDataService.Worker.Models;

namespace KiteMarketDataService.Worker.Services
{
    public class KiteConnectService
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<KiteConnectService> _logger;
        private readonly IConfiguration _configuration;
        private readonly KiteAuthService _authService;
        private string? _accessToken;

        public KiteConnectService(
            ILogger<KiteConnectService> logger, 
            HttpClient httpClient, 
            IConfiguration configuration,
            KiteAuthService authService)
        {
            _logger = logger;
            _httpClient = httpClient;
            _configuration = configuration;
            _authService = authService;
            
            _httpClient.BaseAddress = new Uri("https://api.kite.trade/");
            _httpClient.DefaultRequestHeaders.Add("X-Kite-Version", "3");
        }

        public async Task<bool> AuthenticateAsync()
        {
            try
            {
                var requestToken = _configuration["KiteConnect:RequestToken"];
                var accessToken = _configuration["KiteConnect:AccessToken"];

                // Allow non-interactive auth via environment variable as a quick path
                // Supports both standard config binding (KiteConnect__RequestToken) and plain env var (KITE_REQUEST_TOKEN)
                if (string.IsNullOrEmpty(requestToken))
                {
                    var envToken = Environment.GetEnvironmentVariable("KITE_REQUEST_TOKEN");
                    if (!string.IsNullOrWhiteSpace(envToken))
                    {
                        requestToken = envToken;
                    }
                }

                if (!string.IsNullOrEmpty(accessToken))
                {
                    _accessToken = accessToken;
                    _logger.LogInformation("Using existing access token");
                    return true;
                }

                if (!string.IsNullOrEmpty(requestToken))
                {
                    return await AuthenticateWithRequestTokenAsync(requestToken);
                }

                _logger.LogWarning("No access token or request token available");
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to authenticate");
                return false;
            }
        }

        public async Task<bool> AuthenticateWithRequestTokenAsync(string requestToken)
        {
            try
            {
                _logger.LogInformation("Authenticating with request token...");
                
                var accessToken = await _authService.ExchangeRequestTokenForAccessTokenAsync(requestToken);
                
                if (!string.IsNullOrEmpty(accessToken))
                {
                    _accessToken = accessToken;
                    _logger.LogInformation("Successfully authenticated with request token");
                    return true;
                }
                
                _logger.LogError("Failed to exchange request token for access token");
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to authenticate with request token");
                return false;
            }
        }

        public async Task<List<string>> GetOptionInstrumentsAsync()
        {
            try
            {
                var instruments = new List<string>();
                
                // Common index option symbols for NSE with specific strikes
                var indices = new[] { "NIFTY", "BANKNIFTY", "FINNIFTY", "MIDCPNIFTY" };
                
                foreach (var index in indices)
                {
                    // Add CE (Call) and PE (Put) options with common strikes
                    // For NIFTY - around current market levels
                    if (index == "NIFTY")
                    {
                        instruments.Add($"NFO:{index}24DEC24000CE");
                        instruments.Add($"NFO:{index}24DEC24000PE");
                        instruments.Add($"NFO:{index}24DEC24100CE");
                        instruments.Add($"NFO:{index}24DEC24100PE");
                        instruments.Add($"NFO:{index}24DEC24200CE");
                        instruments.Add($"NFO:{index}24DEC24200PE");
                    }
                    // For BANKNIFTY - around current market levels
                    else if (index == "BANKNIFTY")
                    {
                        instruments.Add($"NFO:{index}24DEC52000CE");
                        instruments.Add($"NFO:{index}24DEC52000PE");
                        instruments.Add($"NFO:{index}24DEC52100CE");
                        instruments.Add($"NFO:{index}24DEC52100PE");
                        instruments.Add($"NFO:{index}24DEC52200CE");
                        instruments.Add($"NFO:{index}24DEC52200PE");
                    }
                    // For FINNIFTY
                    else if (index == "FINNIFTY")
                    {
                        instruments.Add($"NFO:{index}24DEC20000CE");
                        instruments.Add($"NFO:{index}24DEC20000PE");
                        instruments.Add($"NFO:{index}24DEC20100CE");
                        instruments.Add($"NFO:{index}24DEC20100PE");
                    }
                    // For MIDCPNIFTY
                    else if (index == "MIDCPNIFTY")
                    {
                        instruments.Add($"NFO:{index}24DEC12000CE");
                        instruments.Add($"NFO:{index}24DEC12000PE");
                        instruments.Add($"NFO:{index}24DEC12100CE");
                        instruments.Add($"NFO:{index}24DEC12100PE");
                    }
                }
                
                _logger.LogInformation($"Generated {instruments.Count} option instruments for data collection");
                return instruments;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get option instruments");
                return new List<string>();
            }
        }

        public async Task<KiteQuoteResponse?> GetMarketQuotesAsync(List<string> instruments)
        {
            try
            {
                _logger.LogInformation("=== KITE CONNECT API: GET MARKET QUOTES ===");
                
                if (string.IsNullOrEmpty(_accessToken))
                {
                    _logger.LogError("Access token not available. Please authenticate first.");
                    return null;
                }

                if (!instruments.Any())
                {
                    _logger.LogWarning("No instruments provided for quotes");
                    return null;
                }

                // Use the instrument tokens passed from the Worker
                var instrumentTokens = instruments.ToList(); // Process all instruments
                
                _logger.LogInformation($"Total instrument tokens to process: {instrumentTokens.Count}");
                _logger.LogInformation($"Sample tokens: {string.Join(", ", instrumentTokens.Take(5))}...");

                // Kite Connect allows max 500 instruments per request
                var batches = instrumentTokens.Select((x, i) => new { Index = i, Value = x })
                                       .GroupBy(x => x.Index / 500)
                                       .Select(g => g.Select(x => x.Value).ToList())
                                       .ToList();

                _logger.LogInformation($"Created {batches.Count} batches (max 500 instruments per batch)");

                var allQuotes = new Dictionary<string, QuoteData>();
                var batchNumber = 0;

                foreach (var batch in batches)
                {
                    batchNumber++;
                    _logger.LogInformation($"=== PROCESSING BATCH {batchNumber}/{batches.Count} ===");
                    _logger.LogInformation($"Batch size: {batch.Count} instruments");
                    _logger.LogInformation($"Sample batch tokens: {string.Join(", ", batch.Take(5))}...");
                    
                    var queryParams = string.Join("&", batch.Select(i => $"i={Uri.EscapeDataString(i)}"));
                    var url = $"quote?{queryParams}";
                    
                    _logger.LogInformation($"API URL length: {url.Length} characters");
                    _logger.LogInformation($"Sample URL: {url.Substring(0, Math.Min(100, url.Length))}...");

                    _httpClient.DefaultRequestHeaders.Remove("Authorization");
                    _httpClient.DefaultRequestHeaders.Add("Authorization", $"token {_configuration["KiteConnect:ApiKey"]}:{_accessToken}");

                    _logger.LogInformation($"Making API request for batch {batchNumber}...");
                    var startTime = DateTime.UtcNow;

                    var response = await _httpClient.GetAsync(url);
                    var endTime = DateTime.UtcNow;
                    var duration = endTime - startTime;
                    
                    _logger.LogInformation($"API response received in {duration.TotalMilliseconds:F0}ms");
                    _logger.LogInformation($"Response status: {response.StatusCode}");
                    _logger.LogInformation($"Response headers: {string.Join(", ", response.Headers.Select(h => $"{h.Key}={string.Join(";", h.Value)}"))}");
                    
                    if (response.IsSuccessStatusCode)
                    {
                        var content = await response.Content.ReadAsStringAsync();
                        _logger.LogInformation($"Response content length: {content.Length} characters");
                        
                        // Log first 500 characters of response for debugging
                        var previewContent = content.Length > 500 ? content.Substring(0, 500) + "..." : content;
                        _logger.LogInformation($"Response preview: {previewContent}");
                        
                        var quoteResponse = JsonConvert.DeserializeObject<KiteQuoteResponse>(content);
                        
                        if (quoteResponse?.Data != null)
                        {
                            _logger.LogInformation($"Batch {batchNumber} response status: {quoteResponse.Status}");
                            _logger.LogInformation($"Batch {batchNumber} quotes received: {quoteResponse.Data.Count}");
                            
                            // Log which instruments in this batch got quotes
                            var batchTokens = batch.ToHashSet();
                            var receivedTokens = quoteResponse.Data.Keys.ToHashSet();
                            var missingInBatch = batchTokens.Except(receivedTokens).ToList();
                            
                            if (missingInBatch.Any())
                            {
                                _logger.LogWarning($"Batch {batchNumber} missing quotes for {missingInBatch.Count} instruments:");
                                foreach (var missing in missingInBatch.Take(5))
                                {
                                    _logger.LogWarning($"  Missing token: {missing}");
                                }
                                if (missingInBatch.Count > 5)
                                {
                                    _logger.LogWarning($"  ... and {missingInBatch.Count - 5} more missing in this batch");
                                }
                            }
                            
                            foreach (var quote in quoteResponse.Data)
                            {
                                allQuotes[quote.Key] = quote.Value;
                            }
                            _logger.LogInformation($"Batch {batchNumber} processed successfully. Total quotes so far: {allQuotes.Count}");
                        }
                        else
                        {
                            _logger.LogWarning($"Batch {batchNumber} response has no data. Full response: {content}");
                        }
                    }
                    else
                    {
                        var errorContent = await response.Content.ReadAsStringAsync();
                        _logger.LogError($"Batch {batchNumber} failed. Status: {response.StatusCode}, Content: {errorContent}");
                    }

                    // Add delay between batches to avoid rate limiting
                    _logger.LogInformation($"Waiting 1 second before next batch...");
                    await Task.Delay(1000);
                }

                _logger.LogInformation($"=== API CALLS COMPLETED ===");
                _logger.LogInformation($"Total quotes collected: {allQuotes.Count}");
                _logger.LogInformation($"Success rate: {(double)allQuotes.Count / instrumentTokens.Count * 100:F1}%");

                return new KiteQuoteResponse
                {
                    Status = "success",
                    Data = allQuotes
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get market quotes");
                return null;
            }
        }

        public async Task<List<Instrument>> GetInstrumentsListAsync()
        {
            try
            {
                if (string.IsNullOrEmpty(_accessToken))
                {
                    _logger.LogError("Access token not available. Please authenticate first.");
                    return new List<Instrument>();
                }

                _httpClient.DefaultRequestHeaders.Remove("Authorization");
                _httpClient.DefaultRequestHeaders.Add("Authorization", $"token {_configuration["KiteConnect:ApiKey"]}:{_accessToken}");

                _logger.LogInformation("Fetching instruments from Kite Connect API...");
                var response = await _httpClient.GetAsync("instruments");
                
                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    _logger.LogInformation($"Received instruments response: {content.Length} characters");
                    
                    // Log first few lines to see the format
                    var lines = content.Split('\n');
                    if (lines.Length > 0)
                    {
                        _logger.LogInformation($"First line (header): {lines[0]}");
                        if (lines.Length > 1)
                        {
                            _logger.LogInformation($"Second line (sample): {lines[1]}");
                        }
                    }
                    
                    var instruments = ParseInstrumentsCsv(content);
                    _logger.LogInformation($"Parsed {instruments.Count} total instruments");
                    
                    // Also fetch BSE instruments specifically for SENSEX
                    _logger.LogInformation("Fetching BSE instruments specifically for SENSEX...");
                    var bseResponse = await _httpClient.GetAsync("instruments/BSE");
                    if (bseResponse.IsSuccessStatusCode)
                    {
                        var bseContent = await bseResponse.Content.ReadAsStringAsync();
                        var bseInstruments = ParseInstrumentsCsv(bseContent);
                        _logger.LogInformation($"Parsed {bseInstruments.Count} BSE instruments");
                        
                        // Add BSE instruments to the main list
                        instruments.AddRange(bseInstruments);
                        _logger.LogInformation($"Total instruments after adding BSE: {instruments.Count}");
                    }
                    else
                    {
                        _logger.LogWarning("Failed to fetch BSE instruments");
                    }
                    
                    // Log segment distribution
                    var segmentGroups = instruments.GroupBy(i => i.Segment).Select(g => new { Segment = g.Key, Count = g.Count() }).ToList();
                    foreach (var group in segmentGroups.Take(10))
                    {
                        _logger.LogInformation($"Segment {group.Segment}: {group.Count} instruments");
                    }
                    
                    // Log all SENSEX instruments to debug
                    var sensexInstruments = instruments.Where(i => i.TradingSymbol.Contains("SENSEX")).ToList();
                    _logger.LogInformation($"Found {sensexInstruments.Count} SENSEX instruments:");
                    foreach (var sensex in sensexInstruments.Take(10))
                    {
                        _logger.LogInformation($"SENSEX: {sensex.TradingSymbol} - Token: {sensex.InstrumentToken} - Type: {sensex.InstrumentType} - Segment: {sensex.Segment}");
                    }
                    
                    // Also check for any instruments that might be SENSEX-related (different naming)
                    var possibleSensex = instruments.Where(i => 
                        i.TradingSymbol.Contains("SENSEX") || 
                        i.TradingSymbol.Contains("SEN") ||
                        i.TradingSymbol.Contains("BSE")).ToList();
                    _logger.LogInformation($"Found {possibleSensex.Count} possible SENSEX-related instruments:");
                    foreach (var sensex in possibleSensex.Take(10))
                    {
                        _logger.LogInformation($"Possible SENSEX: {sensex.TradingSymbol} - Token: {sensex.InstrumentToken} - Type: {sensex.InstrumentType} - Segment: {sensex.Segment}");
                    }
                    
                    // Log all instruments with "SENSEX" in any field
                    var allSensexRelated = instruments.Where(i => 
                        i.TradingSymbol.Contains("SENSEX") || 
                        i.Name.Contains("SENSEX") ||
                        i.Segment.Contains("SENSEX")).ToList();
                    _logger.LogInformation($"Found {allSensexRelated.Count} total SENSEX-related instruments (any field):");
                    foreach (var sensex in allSensexRelated.Take(10))
                    {
                        _logger.LogInformation($"Total SENSEX: {sensex.TradingSymbol} - Name: {sensex.Name} - Segment: {sensex.Segment} - Type: {sensex.InstrumentType}");
                    }
                    
                    // Log all instruments to see what's available
                    _logger.LogInformation("All available instruments (first 20):");
                    foreach (var instrument in instruments.Take(20))
                    {
                        _logger.LogInformation($"All: {instrument.TradingSymbol} - Name: {instrument.Name} - Segment: {instrument.Segment} - Type: {instrument.InstrumentType}");
                    }
                    
                    // Log all unique instrument names to see patterns
                    var uniqueNames = instruments.Select(i => i.Name).Distinct().Take(20).ToList();
                    _logger.LogInformation($"Sample unique instrument names: {string.Join(", ", uniqueNames)}");
                    
                    // Log all unique trading symbols to see patterns
                    var uniqueSymbols = instruments.Select(i => i.TradingSymbol).Distinct().Take(20).ToList();
                    _logger.LogInformation($"Sample unique trading symbols: {string.Join(", ", uniqueSymbols)}");
                    
                    // Strictly include ONLY index option contracts for major indices
                    var allowedPrefixes = new[] { "NIFTY", "BANKNIFTY", "FINNIFTY", "MIDCPNIFTY", "SENSEX" };
                    var optionInstruments = instruments
                        .Where(i =>
                            (i.InstrumentType == "CE" || i.InstrumentType == "PE") &&
                            allowedPrefixes.Any(p => i.TradingSymbol.StartsWith(p)) &&
                            // Exclude NIFTYNXT family explicitly
                            !i.TradingSymbol.StartsWith("NIFTYNXT"))
                        .ToList();

                    _logger.LogInformation($"Found {optionInstruments.Count} index option instruments (CE/PE) for allowed indices only");
                    
                    if (optionInstruments.Any())
                    {
                        // Group by underlying symbol to show variety (excluding NIFTYNXT50)
                        var symbols = optionInstruments.Select(i => i.TradingSymbol.Split('2')[0]).Distinct().Take(10).ToList();
                        _logger.LogInformation($"Sample underlying symbols (excluding NIFTYNXT50): {string.Join(", ", symbols)}");
                        
                        // Show sample instruments with real tokens
                        var samples = optionInstruments.Take(5).ToList();
                        foreach (var sample in samples)
                        {
                            _logger.LogInformation($"Sample: {sample.TradingSymbol} - Token: {sample.InstrumentToken} - Type: {sample.InstrumentType} - Strike: {sample.Strike} - Segment: {sample.Segment}");
                        }
                        
                        // Log count by index type
                        var indexCounts = optionInstruments
                            .GroupBy(i => i.TradingSymbol.StartsWith("NIFTY") && !i.TradingSymbol.StartsWith("NIFTYNXT") ? "NIFTY" :
                                             i.TradingSymbol.StartsWith("BANKNIFTY") ? "BANKNIFTY" :
                                             i.TradingSymbol.StartsWith("FINNIFTY") ? "FINNIFTY" :
                                             i.TradingSymbol.StartsWith("MIDCPNIFTY") ? "MIDCPNIFTY" :
                                             i.TradingSymbol.StartsWith("SENSEX") ? "SENSEX" : "OTHER")
                            .Select(g => new { Index = g.Key, Count = g.Count() })
                            .OrderByDescending(x => x.Count)
                            .ToList();
                        
                        _logger.LogInformation("Index distribution:");
                        foreach (var indexCount in indexCounts)
                        {
                            _logger.LogInformation($"  {indexCount.Index}: {indexCount.Count} instruments");
                        }
                    }
                    
                    return optionInstruments;
                }
                else
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogError($"Failed to get instruments. Status: {response.StatusCode}, Content: {errorContent}");
                    return new List<Instrument>();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get instruments list");
                return new List<Instrument>();
            }
        }

        private List<Instrument> ParseInstrumentsCsv(string csvContent)
        {
            var instruments = new List<Instrument>();
            var lines = csvContent.Split('\n', StringSplitOptions.RemoveEmptyEntries);
            
            _logger.LogInformation($"Parsing {lines.Length} lines from CSV");
            
            // Skip header line
            for (int i = 1; i < lines.Length; i++)
            {
                try
                {
                    var line = lines[i].Trim();
                    if (string.IsNullOrEmpty(line)) continue;
                    
                    var fields = line.Split(',');
                    _logger.LogDebug($"Line {i}: {fields.Length} fields - {line}");
                    
                    // Check if we have enough fields (minimum 12)
                    if (fields.Length >= 12)
                    {
                        var instrument = new Instrument
                        {
                            InstrumentToken = long.TryParse(fields[0], out var token) ? token : 0,
                            ExchangeToken = long.TryParse(fields[1], out var exToken) ? exToken : 0,
                            TradingSymbol = fields[2]?.Trim('"') ?? "",
                            Name = fields[3]?.Trim('"') ?? "",
                            LastPrice = decimal.TryParse(fields[4], out var price) ? price : 0,
                            Expiry = ParseExpiryDate(fields[5]),
                            Strike = decimal.TryParse(fields[6], out var strike) ? strike : 0,
                            TickSize = decimal.TryParse(fields[7], out var tickSize) ? tickSize : 0,
                            LotSize = int.TryParse(fields[8], out var lotSize) ? lotSize : 0,
                            InstrumentType = fields[9]?.Trim('"') ?? "",
                            Segment = fields[10]?.Trim('"') ?? "",
                            Exchange = fields[11]?.Trim('"') ?? ""
                        };
                        
                        // Only add if we have a valid instrument token
                        if (instrument.InstrumentToken > 0)
                        {
                            instruments.Add(instrument);
                        }
                    }
                    else
                    {
                        _logger.LogWarning($"Line {i} has insufficient fields: {fields.Length} (expected >=12)");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, $"Error parsing line {i}: {lines[i]}");
                }
            }
            
            _logger.LogInformation($"Successfully parsed {instruments.Count} instruments from CSV");
            return instruments;
        }

        private DateTime? ParseExpiryDate(string? expiryString)
        {
            if (string.IsNullOrWhiteSpace(expiryString))
                return null;

            try
            {
                // Try different date formats commonly used by Kite
                var formats = new[]
                {
                    "yyyy-MM-dd",
                    "dd-MM-yyyy",
                    "MM-dd-yyyy",
                    "yyyy/MM/dd",
                    "dd/MM/yyyy",
                    "MM/dd/yyyy"
                };

                foreach (var format in formats)
                {
                    if (DateTime.TryParseExact(expiryString.Trim('"'), format, null, System.Globalization.DateTimeStyles.None, out var parsedDate))
                    {
                        // Ensure the date is in IST (add 5:30 hours)
                        var istDate = parsedDate.AddHours(5).AddMinutes(30);
                        return istDate;
                    }
                }

                // Fallback to standard parsing
                if (DateTime.TryParse(expiryString.Trim('"'), out var fallbackDate))
                {
                    var istDate = fallbackDate.AddHours(5).AddMinutes(30);
                    return istDate;
                }

                _logger.LogWarning($"Could not parse expiry date: {expiryString}");
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Error parsing expiry date: {expiryString}");
                return null;
            }
        }
    }
} 