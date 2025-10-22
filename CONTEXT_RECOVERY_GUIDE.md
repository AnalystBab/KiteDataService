# 🆘 CONTEXT RECOVERY GUIDE

## 🎯 **IF AI CONTEXT IS LOST - READ THIS FIRST**

---

## 👤 **PROJECT OWNER**

**Name:** Babu  
**Project:** Kite Market Data Service (Production Trading System)  
**Critical Requirement:** BusinessDate accuracy is PARAMOUNT

---

## ⚡ **IMMEDIATE ORIENTATION**

### **What This System Does:**
Collects real-time Indian stock market data (NIFTY, SENSEX, BANKNIFTY options) via Kite Connect API and tracks circuit limit changes (LC/UC).

### **Most Critical Component:**
**BusinessDate Calculation** - Determines which trading day collected data belongs to.

---

## 📖 **FIRST STEPS AFTER CONTEXT LOSS**

### **Step 1: Read Core Documentation (5 minutes)**
```
1. PROJECT_MASTER_REFERENCE.md         ← START HERE! Complete overview
2. AFTER_MARKET_HOURS_WORKFLOW.md      ← BusinessDate logic details
3. BUSINESSDATE_COMPLETE_FLOW.md       ← Visual diagrams
```

### **Step 2: Understand The Core Problem We Solved**
```
PROBLEM: 
Data collected at 8:30 AM on Oct 7th was being assigned BusinessDate = Oct 7th
But market opens at 9:15 AM, so this is actually END-OF-DAY data from Oct 6th

SOLUTION:
BusinessDate calculation based on:
  1. NIFTY spot price → nearest strike → Last Trade Time (LTT)
  2. Time-based fallback (pre-market = previous day, market hours = current day)
```

### **Step 3: Review Key Files**
```
Services/BusinessDateCalculationService.cs     ← Core BusinessDate logic
Services/HistoricalSpotDataService.cs          ← Historical data with time-aware fetching
Worker.cs                                      ← Main service orchestration
```

---

## 🔑 **CRITICAL CONCEPTS (MUST UNDERSTAND)**

### **1. BusinessDate vs Collection Time**
```
Collection Time: When data was collected (e.g., 8:30 AM Oct 7)
BusinessDate:    Which trading day it belongs to (e.g., Oct 6)

They are NOT the same during pre-market and post-market hours!
```

### **2. The 3:30 PM Rule (RECENTLY FIXED - Oct 8, 2025)**
```
BEFORE 3:30 PM:
  - Historical API fetches up to YESTERDAY
  - Reason: Today's close not available yet

AFTER 3:30 PM:
  - Historical API fetches up to TODAY
  - Reason: Today's close IS available from Kite

This was the LAST MAJOR FIX Babu identified!
```

### **3. Historical vs Real-time Data**
```
Historical API:
  - Endpoint: /instruments/historical/{token}/day
  - Purpose: Daily OHLC for indices (NIFTY spot prices)
  - Storage: SpotData table

GetQuotes API:
  - Endpoint: /quote
  - Purpose: Live options data
  - Storage: MarketQuotes table

NEVER mix these up!
```

---

## 🚨 **WHAT BABU CARES ABOUT MOST**

### **Priority 1: BusinessDate Accuracy**
```
❌ NEVER introduce logic that hardcodes dates
❌ NEVER break the LTT-based calculation
❌ NEVER ignore the time-based fallback

✅ ALWAYS preserve dynamic calculation
✅ ALWAYS use spot data → nearest strike → LTT
✅ ALWAYS handle pre-market, market, post-market correctly
```

### **Priority 2: System Reliability**
```
✅ Service must handle restart at ANY time
✅ Automatic gap-filling for missing historical dates
✅ Duplicate prevention in SpotData table
✅ Graceful fallback when APIs fail
```

### **Priority 3: Data Integrity**
```
✅ No duplicate spot data entries
✅ Correct DataSource labels ("Kite Historical API" vs "Kite GetQuotes API")
✅ Proper separation of historical vs real-time data
```

---

## 🔍 **COMMON QUESTIONS AFTER CONTEXT LOSS**

### **Q: What is BusinessDate and why does it matter?**
```
A: It's the TRADING DAY that data belongs to, not when it was collected.
   
   Example: LC value collected at 8:30 AM on Monday
            → BusinessDate = PREVIOUS Friday (market was closed over weekend)
            
   Why: Market opens 9:15 AM, so 8:30 AM data is end-of-previous-day
```

### **Q: How is BusinessDate calculated?**
```
A: PRIORITY 1 - Spot-based (PRIMARY):
   1. Get NIFTY spot price from SpotData table
   2. Find nearest NIFTY strike in MarketQuotes
   3. Get LTT (Last Trade Time) from that strike
   4. BusinessDate = LTT.Date
   
   PRIORITY 2 - Time-based (FALLBACK):
   - Before 9:15 AM → PREVIOUS trading day
   - 9:15 AM - 3:30 PM → CURRENT day
   - After 3:30 PM → CURRENT day
```

### **Q: What was the recent fix on Oct 8, 2025?**
```
A: Historical data collection now time-aware:
   
   BEFORE FIX:
   - Always fetched up to YESTERDAY
   - Even at 8 PM, wouldn't have TODAY's data
   
   AFTER FIX:
   - Before 3:30 PM → fetch up to YESTERDAY
   - After 3:30 PM → fetch up to TODAY
   
   File: Services/HistoricalSpotDataService.cs, lines 86-91
```

### **Q: What files should I NEVER modify without understanding?**
```
A: Critical files (read thoroughly before changing):
   1. Services/BusinessDateCalculationService.cs
   2. Services/HistoricalSpotDataService.cs
   3. Worker.cs (main orchestration)
   4. Models/SpotData.cs
   5. Models/MarketQuote.cs
```

---

## 📊 **QUICK REFERENCE - MARKET TIMINGS**

```
┌────────────────────────────────────────────────────────────┐
│ TIME ZONE: IST (Indian Standard Time)                      │
└────────────────────────────────────────────────────────────┘

12:00 AM - 9:15 AM    PRE-MARKET
  ├─ BusinessDate = PREVIOUS trading day
  ├─ Historical API: toDate = YESTERDAY
  └─ Using previous day's close price

9:15 AM - 3:30 PM     MARKET HOURS
  ├─ BusinessDate = CURRENT day
  ├─ Real-time GetQuotes API active
  └─ Using today's live data

3:30 PM - 11:59 PM    POST-MARKET
  ├─ BusinessDate = CURRENT day  ← Key!
  ├─ Historical API: toDate = TODAY  ← Recent fix!
  └─ Using today's close price
```

---

## 🛠️ **TROUBLESHOOTING GUIDE**

### **Issue: BusinessDate seems wrong**
```
Steps:
1. Check logs: BusinessDateCalculationService output
2. Check time: Pre-market? Market hours? Post-market?
3. Check SpotData: Latest NIFTY entry and its TradingDate
4. Check MarketQuotes: Nearest strike has valid LTT?
5. Read: AFTER_MARKET_HOURS_WORKFLOW.md for expected behavior
```

### **Issue: No historical spot data**
```
Steps:
1. Check logs: HistoricalSpotDataService - API errors?
2. Check auth: Access token still valid? (expires daily)
3. Check database: SpotData table - last TradingDate?
4. Check time logic: Lines 86-91 in HistoricalSpotDataService.cs
5. Verify: Instrument tokens correct? (NIFTY=256265, SENSEX=265, BANKNIFTY=260105)
```

### **Issue: Duplicate spot data entries**
```
Steps:
1. Check: Multiple service instances running?
2. Check: Duplicate prevention logic working?
3. Query: SELECT * FROM SpotData WHERE IndexName='NIFTY' ORDER BY TradingDate DESC
4. Verify: DataSource field properly set?
```

---

## 💬 **HOW TO COMMUNICATE WITH BABU**

### **Babu's Communication Style:**
- Direct and to the point
- Highly knowledgeable about market mechanics
- Will quickly identify logical flaws
- Expects system to be robust and self-healing

### **When Explaining Changes:**
```
✅ DO:
- Explain WHAT changed, WHY it matters, HOW it works
- Show before/after examples with real dates/times
- Highlight edge cases handled
- Be precise about time-based logic

❌ DON'T:
- Use vague terms like "it should work now"
- Ignore time zones (always IST)
- Forget about weekends/holidays
- Introduce hardcoded values
```

---

## 🎯 **CONTEXT RECOVERY CHECKLIST**

When starting fresh, verify understanding of:

- [ ] What BusinessDate is and why it matters
- [ ] The difference between historical and real-time data
- [ ] The 3:30 PM rule for historical data fetching
- [ ] How LTT-based calculation works
- [ ] Time-based fallback logic (pre/during/post market)
- [ ] Recent fix: Time-aware toDate in HistoricalSpotDataService
- [ ] Service can restart anytime (self-healing)
- [ ] Instrument tokens: NIFTY=256265, SENSEX=265, BANKNIFTY=260105

---

## 📝 **TEMPLATE FOR NEW AI CONTEXT**

```
You are working with BABU on a production trading system.

SYSTEM: Kite Market Data Service - Real-time options data collection

CRITICAL COMPONENT: BusinessDate calculation
- Determines which trading day collected data belongs to
- NOT the same as collection timestamp
- Based on NIFTY spot → nearest strike → Last Trade Time (LTT)

RECENT FIX (Oct 8, 2025):
- Historical data collection now time-aware
- After 3:30 PM, includes TODAY's data (not just yesterday)
- File: Services/HistoricalSpotDataService.cs

KEY CONCEPTS:
1. BusinessDate ≠ Collection Time
2. Pre-market (before 9:15 AM) uses PREVIOUS day
3. Market hours (9:15-3:30) uses CURRENT day
4. Post-market (after 3:30) uses CURRENT day
5. Historical API vs GetQuotes API (different purposes)

READ FIRST:
- PROJECT_MASTER_REFERENCE.md
- AFTER_MARKET_HOURS_WORKFLOW.md
- BUSINESSDATE_COMPLETE_FLOW.md

NEVER:
- Hardcode dates
- Break LTT-based logic
- Mix historical and real-time data sources
- Ignore time-based fallback
```

---

## 🚀 **QUICK START COMMANDS**

### **Build and Run:**
```powershell
cd "C:\Users\babu\Documents\Services\KiteMarketDataService.Worker"
dotnet build
dotnet run
```

### **Check Database:**
```sql
-- Check latest spot data
SELECT TOP 10 * FROM SpotData ORDER BY TradingDate DESC, QuoteTimestamp DESC;

-- Check BusinessDate distribution
SELECT BusinessDate, COUNT(*) as Count 
FROM MarketQuotes 
WHERE RecordDateTime >= DATEADD(day, -2, GETDATE())
GROUP BY BusinessDate 
ORDER BY BusinessDate DESC;

-- Check for duplicates
SELECT IndexName, TradingDate, COUNT(*) as Count
FROM SpotData
WHERE DataSource = 'Kite Historical API'
GROUP BY IndexName, TradingDate
HAVING COUNT(*) > 1;
```

### **View Logs:**
```powershell
# Real-time logs
dotnet run

# Or check log file (if configured)
Get-Content logs/service.log -Tail 50
```

---

## ✅ **VERIFICATION - DO YOU UNDERSTAND?**

Before making ANY changes, ask yourself:

1. Do I understand what BusinessDate is?
2. Do I understand the 3:30 PM rule?
3. Do I understand historical vs real-time data?
4. Have I read the three core documentation files?
5. Do I understand why this change is needed?
6. Will this change preserve BusinessDate accuracy?
7. Have I considered pre-market, market, and post-market scenarios?

If ANY answer is NO → Read documentation again!

---

## 🙏 **FINAL NOTE**

This is Babu's PRODUCTION TRADING SYSTEM. Data accuracy is critical for his trading decisions.

**When in doubt:**
1. Read the documentation
2. Ask clarifying questions
3. Test thoroughly before implementing
4. Explain your reasoning clearly

**Never:**
- Rush changes
- Make assumptions
- Break existing logic
- Ignore edge cases

---

**Last Updated:** 2025-10-08 09:05 AM IST  
**Purpose:** Context recovery for AI assistant  
**Owner:** Babu  
**System Status:** Production / Active Development

