# ⚡ QUICK CHEAT SHEET

## 🎯 **ONE-PAGE REFERENCE**

---

## 👤 **OWNER: BABU | SYSTEM: Kite Market Data Service**

---

## 🔑 **MOST CRITICAL CONCEPT**

### **BusinessDate:**
The **trading day** data belongs to ≠ collection timestamp

```
Example:
Collection: 2025-10-07 08:30 AM → BusinessDate: 2025-10-06
(Market opens 9:15 AM, so 8:30 AM data is from previous day)
```

---

## ⏰ **TIME-BASED LOGIC**

| Time | BusinessDate | Historical API toDate | Spot Data Source |
|------|--------------|----------------------|------------------|
| **Before 9:15 AM** | PREVIOUS day | YESTERDAY | Previous close |
| **9:15 - 3:30 PM** | CURRENT day | YESTERDAY | Today's live |
| **After 3:30 PM** | CURRENT day | **TODAY** ⭐ | Today's close |

⭐ = Recent fix (Oct 8, 2025)

---

## 📊 **DATA SOURCES**

### **Historical API** (`/instruments/historical/{token}/day`)
- **Purpose:** Daily OHLC for indices
- **Storage:** SpotData table
- **DataSource:** "Kite Historical API"

### **GetQuotes API** (`/quote`)
- **Purpose:** Live options data
- **Storage:** MarketQuotes table
- **DataSource:** "Kite GetQuotes API"

---

## 🎯 **BUSINESSDATE CALCULATION**

```
1. Get NIFTY spot from SpotData table
2. Find nearest NIFTY strike in MarketQuotes
3. Get Last Trade Time (LTT) from that strike
4. BusinessDate = LTT.Date

Fallback (if no spot data):
  - Before 9:15 AM → GetPreviousTradingDay()
  - 9:15 - 3:30 PM → Today
  - After 3:30 PM → Today
```

---

## 🗂️ **KEY FILES**

```
Services/
├── BusinessDateCalculationService.cs    ← BusinessDate logic
├── HistoricalSpotDataService.cs         ← Historical fetching (time-aware)
└── TimeBasedCollectionService.cs        ← Real-time collection

Models/
├── SpotData.cs                          ← Index historical data
└── MarketQuote.cs                       ← Options data

Documentation/
├── PROJECT_MASTER_REFERENCE.md          ← Full reference
├── CONTEXT_RECOVERY_GUIDE.md            ← If context lost
├── AFTER_MARKET_HOURS_WORKFLOW.md       ← Detailed workflow
└── BUSINESSDATE_COMPLETE_FLOW.md        ← Visual diagrams
```

---

## 🔢 **INSTRUMENT TOKENS**

```csharp
NIFTY:     256265
SENSEX:    265
BANKNIFTY: 260105
```

---

## 🚨 **RECENT FIX (Oct 8, 2025)**

**File:** `Services/HistoricalSpotDataService.cs` (Lines 86-91)

**Problem:** Historical API always fetched up to YESTERDAY, even at 8 PM

**Fix:**
```csharp
var toDate = currentTime > new TimeSpan(15, 30, 0)
    ? DateTime.Today           // AFTER 3:30 PM
    : DateTime.Today.AddDays(-1); // BEFORE 3:30 PM
```

**Result:** After market close, TODAY's historical data is fetched ✅

---

## ✅ **GOLDEN RULES**

1. **NEVER** hardcode dates
2. **ALWAYS** preserve LTT-based calculation
3. **UNDERSTAND** pre/market/post-market differences
4. **TEST** all time-based logic thoroughly
5. **CHECK** SpotData has recent data before changes

---

## 🛠️ **QUICK COMMANDS**

```powershell
# Build
dotnet build

# Run
dotnet run

# Check spot data
SELECT TOP 5 * FROM SpotData ORDER BY TradingDate DESC;

# Check BusinessDate
SELECT BusinessDate, COUNT(*) FROM MarketQuotes 
WHERE RecordDateTime >= DATEADD(day, -1, GETDATE())
GROUP BY BusinessDate;
```

---

## 🆘 **IF CONTEXT LOST**

**Read in order:**
1. `CONTEXT_RECOVERY_GUIDE.md` (START HERE)
2. `PROJECT_MASTER_REFERENCE.md`
3. `AFTER_MARKET_HOURS_WORKFLOW.md`

---

## 📞 **QUICK TROUBLESHOOTING**

| Problem | Check |
|---------|-------|
| Wrong BusinessDate | Logs → Time → SpotData table → LTT values |
| No historical data | Auth token → API errors → Last TradingDate |
| Duplicates | Multiple instances? → Duplicate prevention logic? |

---

## 💡 **WHAT BABU CARES ABOUT**

1. **BusinessDate accuracy** (MOST IMPORTANT)
2. System can restart anytime
3. Automatic gap-filling
4. No duplicates
5. Clean, reliable data

---

**Last Updated:** 2025-10-08 09:10 AM IST  
**Status:** Production Ready  
**Recent Changes:** Time-aware historical data collection ✅

