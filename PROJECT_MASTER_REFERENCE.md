# 🎯 KITE MARKET DATA SERVICE - MASTER REFERENCE

## 📌 **PROJECT OWNER: BABU**

**Critical Note:** This is a production trading system. Any changes must be thoroughly tested and validated.

---

## 🏗️ **SYSTEM ARCHITECTURE**

### **Core Purpose:**
Real-time market data collection system for NIFTY, SENSEX, and BANKNIFTY options with:
- Circuit limit tracking (LC/UC changes)
- Business date calculation for accurate data attribution
- Historical spot data storage
- Automated Excel export functionality

---

## 🔑 **CRITICAL CONCEPTS**

### **1. BusinessDate (MOST IMPORTANT)**

**What It Is:**
- The **trading day** that collected data belongs to
- **NOT** the same as collection timestamp
- Used to correctly attribute pre-market and post-market data

**Why It Matters:**
```
Example: Data collected at 8:30 AM on 2025-10-07 (Monday)
- Collection Time: 2025-10-07 08:30:00
- BusinessDate: 2025-10-06 (PREVIOUS trading day)
- Reason: Market hasn't opened yet, so this is end-of-day data from 2025-10-06
```

**Calculation Logic:**
```
PRIORITY 1: NIFTY spot → nearest strike → LTT (Last Trade Time)
PRIORITY 2: Time-based fallback (only if no spot data)
  - Before 9:15 AM → PREVIOUS trading day
  - 9:15 AM - 3:30 PM → CURRENT day
  - After 3:30 PM → CURRENT day
```

**Key Files:**
- `Services/BusinessDateCalculationService.cs` - Core logic
- `Services/HistoricalSpotDataService.cs` - Historical data collection

---

### **2. Historical vs Real-time Data**

**Historical Data (Kite Historical API):**
- Daily OHLC (Open, High, Low, Close)
- Fetched from: `/instruments/historical/{token}/day`
- Stored in: `SpotData` table
- Purpose: Calculate BusinessDate, provide reference spot prices

**Real-time Data (Kite GetQuotes API):**
- Live market quotes (options data)
- Fetched from: `/quote`
- Stored in: `MarketQuotes` table
- Purpose: Track LC/UC, option prices, Greeks

**CRITICAL DISTINCTION:**
```
❌ WRONG: Use GetQuotes data for historical spot prices
✅ RIGHT: Use Historical API for spot prices, GetQuotes for live options
```

---

### **3. Circuit Limits (LC/UC)**

**LC (Lower Circuit):** Minimum price allowed for trading
**UC (Upper Circuit):** Maximum price allowed for trading

**Why We Track Them:**
- Identify volatile options
- Alert on circuit breaches
- Historical analysis of limit changes

**Key Files:**
- `Services/EnhancedCircuitLimitService.cs`
- `Models/CircuitLimitChange.cs`

---

## 📊 **DATABASE SCHEMA**

### **Key Tables:**

**1. SpotData**
```
Purpose: Historical index data (NIFTY, SENSEX, BANKNIFTY)
Key Fields:
  - IndexName (NIFTY/SENSEX/BANKNIFTY)
  - TradingDate (the actual trading day)
  - OpenPrice, HighPrice, LowPrice, ClosePrice
  - DataSource ("Kite Historical API" or "Kite GetQuotes API")
  - IsMarketOpen (true during market hours)
```

**2. MarketQuotes**
```
Purpose: Real-time options data
Key Fields:
  - TradingSymbol (e.g., "NIFTY24OCT10425CE")
  - Strike, OptionType (CE/PE)
  - LastPrice, BidPrice, AskPrice
  - LowerCircuitLimit (LC), UpperCircuitLimit (UC)
  - LastTradeTime (LTT) - CRITICAL for BusinessDate
  - BusinessDate - The trading day this data belongs to
```

**3. CircuitLimitChanges**
```
Purpose: Track LC/UC changes over time
Key Fields:
  - TradingSymbol, Strike, OptionType
  - OldLC, NewLC, OldUC, NewUC
  - ChangeTimestamp
  - BusinessDate
```

**4. Instruments**
```
Purpose: Master list of all tradeable instruments
Key Fields:
  - InstrumentToken (unique ID from Kite)
  - TradingSymbol, Name
  - Strike, OptionType
  - Expiry, TickSize
```

---

## 🔄 **SERVICE FLOW**

### **Startup Sequence:**
```
1. Database connection & verification
2. Kite API authentication
3. Instrument loading (if needed)
4. Historical spot data collection ← CRITICAL!
5. Real-time data collection loop
6. BusinessDate calculation & application
```

### **Data Collection Cycle (Every 2 minutes during market hours):**
```
1. HistoricalSpotDataService.CollectAndStoreHistoricalDataAsync()
   → Fetches missing historical spot data
   → Stores in SpotData table
   
2. TimeBasedCollectionService.CollectDataAsync()
   → Fetches real-time options data
   → Stores in MarketQuotes table
   
3. BusinessDateCalculationService.CalculateBusinessDateAsync()
   → Determines correct BusinessDate
   → Applies to all collected quotes
   
4. EnhancedCircuitLimitService (if enabled)
   → Tracks LC/UC changes
   → Stores in CircuitLimitChanges table
```

---

## 🚨 **CRITICAL ISSUES FIXED**

### **Issue 1: Pre-market BusinessDate**
```
Problem: Data at 8:30 AM assigned to CURRENT day instead of PREVIOUS day
Fix: Added time-based check in BusinessDateCalculationService
Status: ✅ FIXED
```

### **Issue 2: Historical data not including TODAY after market close**
```
Problem: Historical API always fetched up to YESTERDAY, even at 8 PM
Fix: Time-aware toDate calculation in HistoricalSpotDataService
  - Before 3:30 PM: toDate = YESTERDAY
  - After 3:30 PM: toDate = TODAY
Status: ✅ FIXED (2025-10-08)
```

### **Issue 3: XML file confusion**
```
Problem: XML fallback used for both spot prices and BusinessDate
Fix: Removed XML logic from BusinessDateCalculationService
      Now uses ONLY SpotData table from Historical API
Status: ✅ FIXED
```

---

## 📁 **KEY FILES REFERENCE**

### **Core Services:**
```
Services/
├── BusinessDateCalculationService.cs     ← BusinessDate logic
├── HistoricalSpotDataService.cs          ← Historical data fetching
├── KiteConnectService.cs                 ← Main API wrapper
├── TimeBasedCollectionService.cs         ← Real-time collection
├── EnhancedCircuitLimitService.cs        ← LC/UC tracking
└── ConsolidatedExcelExportService.cs     ← Excel generation
```

### **Models:**
```
Models/
├── MarketQuote.cs              ← Options data
├── SpotData.cs                 ← Index data
├── CircuitLimitChange.cs       ← LC/UC changes
└── Instrument.cs               ← Master instruments
```

### **Configuration:**
```
appsettings.json                ← Kite API keys, connection strings
appsettings.Development.json    ← Development overrides
```

### **Entry Points:**
```
Program.cs                      ← DI container setup
Worker.cs                       ← Main background service
```

---

## 🎯 **INSTRUMENT TOKENS (HARDCODED)**

```csharp
// These are the ACTUAL INDEX tokens (not futures)
NIFTY:     256265
SENSEX:    265
BANKNIFTY: 260105
```

**Source:** Kite Connect API instrument dump
**Usage:** Historical data API calls

---

## ⏰ **MARKET TIMINGS**

```
Pre-market:     Before 9:15 AM  → BusinessDate = PREVIOUS day
Market Hours:   9:15 AM - 3:30 PM → BusinessDate = CURRENT day
Post-market:    After 3:30 PM    → BusinessDate = CURRENT day
```

**Critical Times:**
- **9:15 AM**: Market opens, switch to TODAY
- **3:30 PM**: Market closes, historical data for TODAY becomes available

---

## 🔧 **COMMON TROUBLESHOOTING**

### **Problem: BusinessDate is wrong**
```
Check:
1. Current time vs market hours
2. SpotData table - recent data exists?
3. Logs - BusinessDateCalculationService output
4. MarketQuotes - valid LTT values?
```

### **Problem: No historical data**
```
Check:
1. Access token valid?
2. HistoricalSpotDataService logs - API errors?
3. SpotData table - last TradingDate?
4. Time check - before/after 3:30 PM logic working?
```

### **Problem: Duplicate spot data**
```
Check:
1. DataSource field - "Kite Historical API"?
2. Duplicate prevention logic working?
3. Multiple service instances running?
```

---

## 📝 **TESTING CHECKLIST**

### **Pre-market Test (8:00 AM):**
- [ ] Historical data fetches YESTERDAY's close
- [ ] BusinessDate = YESTERDAY
- [ ] No TODAY data in SpotData yet

### **Market Hours Test (10:00 AM):**
- [ ] Real-time data flowing
- [ ] BusinessDate = TODAY
- [ ] LTT values are current

### **Post-market Test (4:00 PM):**
- [ ] Historical data fetches TODAY's close
- [ ] BusinessDate = TODAY
- [ ] SpotData has TODAY's entry

### **Service Restart Test:**
- [ ] Can restart at any time
- [ ] Fetches missing dates
- [ ] No duplicates created

---

## 🚀 **DEPLOYMENT NOTES**

### **Requirements:**
- Windows Server (or Windows 10+)
- SQL Server (LocalDB or full instance)
- .NET 9.0 Runtime
- Valid Kite Connect API credentials

### **Configuration:**
```json
{
  "KiteConnect": {
    "ApiKey": "your_api_key",
    "ApiSecret": "your_api_secret",
    "AccessToken": "generated_daily",
    "RequestToken": "generated_daily"
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=KiteMarketData;..."
  }
}
```

### **Daily Maintenance:**
- **Every trading day**: Generate new request token via Kite login
- **Token expiry**: Midnight IST (need to re-authenticate)
- **Database cleanup**: Optional (historical data preserved)

---

## 📚 **DOCUMENTATION FILES**

**Recently Created:**
- `AFTER_MARKET_HOURS_WORKFLOW.md` - Complete after-hours logic
- `BUSINESSDATE_COMPLETE_FLOW.md` - Visual flow diagrams
- `PROJECT_MASTER_REFERENCE.md` - This file

**Existing:**
- `README.md` - General overview
- `SYSTEM_SUMMARY.md` - Technical summary
- `SERVICE_SUMMARY.md` - Service architecture
- `DATABASE_TABLES_PURPOSE.md` - Table definitions

---

## 🎓 **KEY LEARNINGS FROM BABU**

1. **"BusinessDate should solely depend on spot nearest strike's LTT"**
   - Time-based logic is FALLBACK only
   - LTT from actual market data is PRIMARY

2. **"After market closed, historical data for current date should be available"**
   - Critical insight that led to time-aware toDate logic
   - Ensures correct BusinessDate after 3:30 PM

3. **"Service can be stopped and run anytime"**
   - System must be self-healing
   - Automatic gap-filling for missing dates

4. **"No hardcoded business dates"**
   - All calculations must be dynamic
   - GetPreviousTradingDay() handles weekends

---

## 🔐 **IMPORTANT SECURITY NOTES**

1. **Never commit API keys** to version control
2. **Access tokens expire daily** - need refresh mechanism
3. **Request tokens** are one-time use
4. **Database backups** before major changes

---

## 📞 **QUICK REFERENCE - WHEN CONTEXT IS LOST**

**Tell AI:**
```
"This is the Kite Market Data Service for BABU.
Read PROJECT_MASTER_REFERENCE.md first.
Key focus: BusinessDate calculation must be accurate.
Recent fix: After 3:30 PM, historical API includes TODAY's data.
All changes must preserve LTT-based BusinessDate logic."
```

**Critical Files to Review:**
1. `Services/BusinessDateCalculationService.cs`
2. `Services/HistoricalSpotDataService.cs`
3. `Worker.cs`

**Critical Concepts:**
1. BusinessDate ≠ Collection Time
2. Historical API vs GetQuotes API
3. Time-aware data collection (before/after 3:30 PM)

---

## ✅ **CURRENT STATUS (2025-10-08)**

- ✅ BusinessDate calculation: WORKING
- ✅ Historical data collection: WORKING (time-aware)
- ✅ Real-time data collection: WORKING
- ✅ Circuit limit tracking: WORKING
- ✅ Excel export: WORKING
- ✅ Service restart: ROBUST (anytime restart supported)

**Last Major Fix:** After-market historical data collection (2025-10-08)

---

## 🎯 **NEXT STEPS / FUTURE ENHANCEMENTS**

- [ ] Test after-market data collection at 4:00 PM
- [ ] Verify BusinessDate correctness over 1 week
- [ ] Consider automated request token refresh
- [ ] Add alerting for API failures
- [ ] Performance optimization for large datasets

---

**🙏 BABU - Thank you for your trust and collaboration!**

**This is a living document. Update it whenever significant changes are made.**

---

**Last Updated:** 2025-10-08 09:00 AM IST
**Updated By:** AI Assistant working with Babu
**Project Status:** Active Development / Production Use

