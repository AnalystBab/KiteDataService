# 📋 EVERYTHING THE SERVICE DOES - COMPLETE LIST

## 🚀 **PART A: INITIALIZATION (One-Time at Startup)**

---

### **1. Mutex Check**
- Ensures only one instance runs
- Attempts to stop existing instance if found
- Exits if can't acquire mutex

### **2. Log File Setup**
- Clears old log file
- Prepares fresh logging for current session

### **3. Database Setup**
- Creates database if doesn't exist
- Creates all tables if don't exist
- Verifies database connection

**Tables Created:**
- MarketQuotes
- Instruments
- HistoricalSpotData
- IntradaySpotData
- StrikeLatestRecords ⭐
- StrategyLabels
- StrategyMatches
- StrategyPredictions
- StrategyValidations
- StrategyPerformances
- ExcelExportData
- HistoricalOptionsData
- CircuitLimits
- CircuitLimitChanges
- IntradayTickData

### **4. Request Token & Authentication**
- Reads request token from appsettings.json
- Calls Kite Connect API to get access token
- Stores access token for subsequent API calls
- Validates authentication

### **5. Instruments Loading**
- Fetches ALL instruments from Kite API (~50,000+)
- Filters to only CE/PE options
- Removes non-index options (only NIFTY, SENSEX, BANKNIFTY)
- Saves NEW instruments only (no duplicates)
- Total tracked: ~7,171 instruments

### **6. Historical Spot Data Collection**
- Fetches NIFTY historical OHLC data
- Fetches SENSEX historical OHLC data
- Fetches BANKNIFTY historical OHLC data
- Stores in HistoricalSpotData table
- Used for business date calculation

### **7. Business Date Calculation**
- Uses NIFTY spot data + nearest strike LTT
- Calculates correct business date
- Falls back to HistoricalSpotData TradingDate if needed
- Returns business date for the session

### **8. Circuit Limits Setup**
- Gets LAST record for each strike (by RecordDateTime)
- Stores LC/UC values as baseline in memory
- Ready to detect LC/UC changes
- Baseline for ~7,171 instruments

### **9. Service Ready**
- Displays ready banner
- Shows calculated business date
- Enters continuous data collection loop

---

## 🔄 **PART B: CONTINUOUS OPERATIONS (In Main Loop)**

**Loop runs every 1-3 minutes (based on market hours)**

---

### **LOOP PROCESS 1: Update Instruments (Periodic)**

**Frequency:** Every 30 minutes (market hours) OR Every 6 hours (after-market)

**Actions:**
1. Recalculate business date
2. Fetch ALL instruments from Kite API
3. Compare with existing instruments in database
4. Save NEW instruments only
5. Update instrument count

**Purpose:** Capture new strikes added by exchange during the day

---

### **LOOP PROCESS 2: Collect Historical Spot Data**

**Frequency:** Every loop iteration

**Actions:**
1. Check last available date in HistoricalSpotData
2. Calculate date range (last date + 1 to today/yesterday)
3. If before 3:30 PM → Only fetch up to yesterday
4. If after 3:30 PM → Include today's data
5. Call Kite Historical API (if new data needed)
6. Store in HistoricalSpotData table
7. Skip if already have data (duplicate prevention)

**Purpose:** 
- Keep historical data updated
- Capture today's data after market close
- Used for business date calculation

---

### **LOOP PROCESS 3: Time-Based Data Collection** ⭐ **MAIN**

**Frequency:** Every loop iteration

**What it does internally:**
```
Based on market hours:
- Pre-market (6-9:15 AM): Collect every 3 minutes
- Market hours (9:15 AM-3:30 PM): Collect every 1 minute
- After-market (3:30 PM-6 AM): Collect every 1 hour
```

**Actions:**
1. Get all 7,171 option instruments from database
2. Call Kite Quotes API for all instruments
3. Recalculate business date
4. Assign BusinessDate to each quote
5. Check for duplicates (compare LC/UC with last record)
6. If duplicate → Skip
7. If different → Calculate InsertionSequence
8. Calculate GlobalSequence
9. Save to MarketQuotes table
10. **✅ Update StrikeLatestRecords table** ⭐
11. Update EnhancedCircuitLimitService baseline
12. Log summary by underlying

**Sub-processes:**
- Verify all strikes have data
- Fetch missing data individually (if bulk fetch missed some)
- Create fallback quotes for missing strikes
- Track data collection metrics

---

### **LOOP PROCESS 4: Process LC/UC Changes**

**Frequency:** Every loop iteration

**Actions:**
1. Compare current LC/UC with baseline
2. Detect changes
3. Log LC/UC change alerts
4. Update baseline dictionary with new values
5. Track change history
6. Prepare for consolidated export

---

### **LOOP PROCESS 5: Store Intraday Tick Data**

**Frequency:** Every loop iteration

**Actions:**
1. Get current market data from MarketQuotes
2. Calculate additional metrics:
   - Greeks (Delta, Gamma, Theta, Vega, Rho)
   - Implied Volatility
   - Moneyness
   - Intrinsic Value, Time Value
   - Volume ratios
   - Put-Call ratios
3. Store in IntradayTickData table
4. For tick-by-tick analysis

---

### **LOOP PROCESS 6: Export Daily Initial Data**

**Frequency:** Every loop iteration

**Actions:**
1. Get current business date
2. Query MarketQuotes for current business date
3. Export NIFTY data to Excel
4. Export SENSEX data to Excel
5. Export BANKNIFTY data to Excel
6. Save to: Exports/DailyData/YYYY-MM-DD/
7. Files updated every loop (overwrites)

**Files Created:**
- NIFTY_Initial_Data_YYYY-MM-DD.xlsx
- SENSEX_Initial_Data_YYYY-MM-DD.xlsx
- BANKNIFTY_Initial_Data_YYYY-MM-DD.xlsx

---

### **LOOP PROCESS 7: Check LC/UC Changes & Consolidated Export**

**Frequency:** Only when LC/UC changes detected

**Actions:**
1. Check if LC/UC changed since last export
2. If YES:
   - Create consolidated Excel export
   - Include all strikes with changes
   - Show before/after values
   - Add change timestamps
   - Save to: Exports/Consolidated/YYYY-MM-DD/
3. If NO:
   - Skip export
   - Continue to next process

**File Created (when changes occur):**
- Consolidated_Market_Data_YYYY-MM-DD_HHmmss.xlsx

---

### **LOOP PROCESS 8: Cleanup Old Data (Once Per Day)**

**Frequency:** Once per day at 2:00 AM

**Actions:**
1. Delete MarketQuotes data older than 30 days
2. Clean up old records
3. Optimize database performance

---

### **LOOP PROCESS 9: Archive Daily Options Data (Once Per Day)**

**Frequency:** Once per day at 4:00 PM (after market close)

**Actions:**
1. Get all instruments from current business date
2. Get LAST record for each instrument (final LC/UC values)
3. Save to HistoricalOptionsData table
4. Preserves EOD data before Kite API discontinues it
5. Creates historical archive

**Purpose:** Long-term data storage for backtesting and analysis

---

### **LOOP PROCESS 10: Wait for Next Cycle**

**Actions:**
1. Calculate next interval:
   - Pre-market: 3 minutes
   - Market hours: 1 minute
   - After-market: 1 hour
2. Sleep (Task.Delay)
3. Wake up and repeat from Process 1

---

## 🎯 **BACKGROUND PROCESSES (Running Separately)**

### **Advanced Pattern Discovery Engine**

**Runs as:** Separate background service (HostedService)

**Frequency:** Every 6 hours (configurable)

**Actions:**
1. Analyzes historical data (last 30 days)
2. Discovers new patterns
3. Validates existing patterns
4. Updates pattern reliability scores
5. Creates recommendations
6. Saves to StrategyMatches table

**Configuration:**
```json
"PatternDiscovery": {
    "EnableAutoDiscovery": true,
    "DiscoveryIntervalHours": 6,
    "AnalyzePastDays": 30,
    "MinOccurrencesForRecommendation": 5
}
```

---

## 📊 **SPECIAL OPERATIONS (One-Time or Conditional)**

### **1. Strategy Analysis Export (Startup)**

**When:** Once at startup (during initialization)

**Condition:** EnableExport = true in config

**Actions:**
1. Backfill strategy labels for historical dates
2. Calculate all 28 strategy labels
3. Export to Excel (3 files, one per index)
4. Save to: Exports/StrategyAnalysis/YYYY-MM-DD/

**Strategy Labels Calculated:**
- Label #1-7: CALL_MINUS variations
- Label #8-14: PUT_MINUS variations
- Label #15-21: CALL_PLUS, PUT_PLUS variations
- Label #22: Universal Low Prediction ⭐
- Label #23-28: Additional patterns

---

### **2. Excel File Protection (Startup)**

**When:** During initialization

**Actions:**
1. Ensures Export directories exist
2. Protects existing Excel files from overwrite
3. Creates backup folders if needed
4. Logs Excel file status

---

## 📁 **ALL DATABASES/TABLES MAINTAINED:**

### **Primary Data Tables:**
1. **MarketQuotes** - All market quotes (7,171 instruments × multiple records per day)
2. **StrikeLatestRecords** ⭐ - Latest 3 records per strike
3. **Instruments** - All instruments metadata
4. **HistoricalSpotData** - NIFTY/SENSEX/BANKNIFTY OHLC
5. **IntradayTickData** - Tick-by-tick data with Greeks

### **Circuit Limit Tables:**
6. **CircuitLimits** - Circuit limit data
7. **CircuitLimitChanges** - LC/UC change history

### **Strategy Tables:**
8. **StrategyLabels** - 28 strategy label calculations
9. **StrategyMatches** - Pattern matches
10. **StrategyPredictions** - Market predictions
11. **StrategyValidations** - Prediction accuracy
12. **StrategyPerformances** - Strategy performance metrics
13. **StrategyLabelsCatalog** - Label definitions

### **Export & Archive Tables:**
14. **ExcelExportData** - Excel export metadata
15. **HistoricalOptionsData** - EOD options data archive

---

## 🔄 **ALL API CALLS MADE:**

### **Kite Connect API:**
1. **Authentication:** POST /session/token
2. **Instruments:** GET /instruments
3. **Market Quotes:** GET /quote (for 7,171 instruments)
4. **Historical Data:** GET /instruments/historical/{token}/day

**Frequency:**
- Authentication: Once at startup
- Instruments: Every 30 min / 6 hours
- Market Quotes: Every 1-3 minutes
- Historical Data: Once per day (after 3:30 PM)

---

## 📊 **ALL EXCEL FILES CREATED:**

### **Strategy Analysis (Startup):**
```
Exports/StrategyAnalysis/YYYY-MM-DD/
  ├─ Strategy_Analysis_NIFTY_YYYY-MM-DD.xlsx
  ├─ Strategy_Analysis_SENSEX_YYYY-MM-DD.xlsx
  └─ Strategy_Analysis_BANKNIFTY_YYYY-MM-DD.xlsx
```

### **Daily Initial Data (Every 1-3 min):**
```
Exports/DailyData/YYYY-MM-DD/
  ├─ NIFTY_Initial_Data_YYYY-MM-DD.xlsx
  ├─ SENSEX_Initial_Data_YYYY-MM-DD.xlsx
  └─ BANKNIFTY_Initial_Data_YYYY-MM-DD.xlsx
```

### **Consolidated (On LC/UC changes):**
```
Exports/Consolidated/YYYY-MM-DD/
  └─ Consolidated_Market_Data_YYYY-MM-DD_HHmmss.xlsx
```

---

## 🌐 **WEB DASHBOARD (Real-Time):**

**URL:** http://localhost:5000

**API Endpoints:**
- `/api/predictions` - Market predictions
- `/api/patterns` - Discovered patterns
- `/api/livemarket` - Live market data
- `/api/strategylabels` - Strategy labels
- `/api/processbreakdown` - Process breakdown
- `/api/health` - Service health check

**Dashboard Features:**
- Real-time predictions (NIFTY, SENSEX, BANKNIFTY)
- Strategy labels (28 labels)
- Process breakdown (CALL_MINUS, PUT_MINUS, etc.)
- Live market data
- Pattern analysis
- Auto-refresh every 30 seconds

---

## 📝 **ALL LOG FILES CREATED:**

### **Main Log:**
```
logs/KiteMarketDataService.log
- All operations logged here
- Cleared on each service start
- Detailed error messages
- Debug information
```

### **Future Enhancement (Mentioned in Docs):**
```
Log_Dump/
  └─ KiteMarketDataService_YYYY-MM-DD_HHmmss.log
  (Archived old logs - not implemented yet)
```

---

## 🎯 **DATA COLLECTION SUMMARY:**

### **Every Loop (1-3 minutes):**
✅ **7,171 instruments** quotes collected  
✅ **LC/UC** changes detected  
✅ **StrikeLatestRecords** updated (latest 3 per strike) ⭐  
✅ **Intraday tick data** stored  
✅ **Excel files** exported  

### **Daily:**
✅ **Historical spot data** captured (after 3:30 PM)  
✅ **Options data archived** (4:00 PM)  
✅ **Old data cleaned** (2:00 AM)  

### **Periodic:**
✅ **Instruments** updated (30 min / 6 hours)  
✅ **Patterns discovered** (every 6 hours)  

---

## 🧮 **CALCULATIONS PERFORMED:**

### **1. Business Date Calculation**
- Uses NIFTY spot + nearest strike LTT
- Handles pre-market, market hours, after-market
- Automatic weekend/holiday handling

### **2. Strategy Label Calculations (28 labels)**
- CALL_MINUS (7 variations)
- PUT_MINUS (7 variations)
- CALL_PLUS, PUT_PLUS (7 variations)
- Universal Low Prediction (Label #22)
- Additional patterns (6 labels)

### **3. Circuit Limit Change Detection**
- Compares current LC/UC with baseline
- Tracks changes throughout the day
- Updates baseline when changes occur

### **4. InsertionSequence Calculation**
- Daily sequence (resets per business date)
- Tracks changes per day
- Seq 1, 2, 3... for each business date

### **5. GlobalSequence Calculation**
- Continuous sequence across all dates
- Never resets until expiry
- Complete lifecycle tracking

### **6. Greeks & Analytics (IntradayTickData)**
- Delta, Gamma, Theta, Vega, Rho
- Implied Volatility
- Theoretical Price
- Moneyness
- Intrinsic Value, Time Value
- Put-Call Ratio
- Volume Ratio

### **7. Pattern Discovery**
- Premium HLC patterns
- Trend analysis
- Support/Resistance levels
- Pattern reliability scoring

### **8. Market Predictions**
- Low prediction (Label #22 formula)
- High prediction (pattern-based)
- Close prediction (multiple strategies)
- Confidence scores

---

## 🔧 **MONITORING & MAINTENANCE:**

### **1. Error Handling**
- Try-catch blocks for all operations
- Graceful degradation (continues on errors)
- 5-minute retry delay on fatal errors
- Detailed error logging

### **2. Data Validation**
- Duplicate detection and prevention
- Missing data verification
- Data quality checks
- Automatic correction attempts

### **3. Performance Optimization**
- In-memory baseline storage
- Efficient database queries
- Indexed tables for fast lookups
- Batch processing where possible

### **4. Resource Management**
- Database connection pooling
- Proper disposal of resources
- Memory management
- API rate limiting awareness

---

## 🎯 **SPECIAL FEATURES:**

### **1. StrikeLatestRecords Table** ⭐
- Maintains only latest 3 records per strike
- Updated every loop
- Fast access to recent LC/UC values
- Automatic cleanup (deletes oldest when 4th comes)

### **2. Time-Based Collection**
- Different intervals based on market hours
- Pre-market: 3 minutes
- Market hours: 1 minute
- After-market: 1 hour

### **3. Dynamic Instrument Updates**
- More frequent during market hours (30 min)
- Less frequent after market (6 hours)
- Captures new strikes automatically

### **4. Automatic Archival**
- Daily options data archived at 4 PM
- Preserves EOD data
- Historical analysis capability

### **5. Smart Duplicate Prevention**
- Only saves when LC/UC changes
- Reduces database bloat
- Efficient storage

---

## 📊 **DATA VOLUMES:**

**Per Day (Market Hours):**
- Market Quotes collected: ~7,171 instruments × 6 hours × 60 min = ~2.5 million quotes
- Saved to database: Only when LC/UC changes (~1-2% = ~25k-50k records)
- StrikeLatestRecords: Always 7,171 × 3 = ~21,500 records (fixed)
- IntradayTickData: ~7,171 × 6 hours × 60 min = ~2.5 million ticks

**Per Day (Full 24 hours):**
- Total operations: Hundreds of thousands
- API calls: ~500-1000 per day
- Excel exports: ~1500 files per day (updated)
- Database transactions: ~50k-100k per day

---

## 🎉 **COMPLETE FEATURE LIST:**

✅ **Data Collection:**
- Market quotes (7,171 instruments)
- Historical spot data (NIFTY, SENSEX, BANKNIFTY)
- Intraday tick data
- Circuit limits tracking

✅ **Analysis:**
- 28 strategy labels
- Pattern discovery
- Market predictions
- Change detection

✅ **Storage:**
- 15 database tables
- Latest 3 records per strike ⭐
- Historical archival
- Automatic cleanup

✅ **Exports:**
- Strategy analysis Excel
- Daily initial data Excel
- Consolidated Excel (on changes)
- Real-time web dashboard

✅ **Monitoring:**
- Detailed logging
- Error handling
- Data validation
- Performance tracking

✅ **Automation:**
- Time-based collection
- Automatic exports
- Daily archival
- Self-healing (retries on errors)

---

**The service is a COMPLETE market data collection, analysis, and monitoring system!** 🚀

**Full documentation:** `EVERYTHING_THE_SERVICE_DOES.md` 📝







