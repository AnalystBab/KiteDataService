# Quick Reference Guide - Key Features

## 📊 **TWO SEQUENCE NUMBERS EXPLAINED**

### **InsertionSequence (Daily)**
- **Resets**: Every business date
- **Scope**: Per business date
- **Use**: Daily change tracking
- **Example**: Oct 7 (1,2,3) → Oct 8 (1,2) → Oct 9 (1,2,3)

### **GlobalSequence (Lifecycle)**
- **Resets**: Never (until expiry)
- **Scope**: Entire contract life
- **Use**: Historical analysis
- **Example**: Oct 7 (1,2,3) → Oct 8 (4,5) → Oct 9 (6,7,8)

---

## 🔍 **QUICK QUERIES**

### **Get Latest Data for Strike**
```sql
-- Using GlobalSequence (BEST for latest data)
SELECT TOP 1 * FROM MarketQuotes
WHERE TradingSymbol = 'NIFTY25OCT25100CE'
ORDER BY GlobalSequence DESC;
```

### **Get All Changes for Strike**
```sql
-- Full lifecycle
SELECT * FROM MarketQuotes
WHERE TradingSymbol = 'NIFTY25OCT25100CE'
  AND ExpiryDate = '2025-10-24'
ORDER BY GlobalSequence;
```

### **Get Today's Changes Only**
```sql
-- Daily changes
SELECT * FROM MarketQuotes
WHERE BusinessDate = '2025-10-07'
  AND TradingSymbol = 'NIFTY25OCT25100CE'
ORDER BY InsertionSequence;
```

### **Count Total Changes**
```sql
-- How many times did LC/UC change?
SELECT 
    TradingSymbol,
    MAX(GlobalSequence) AS TotalChanges
FROM MarketQuotes
WHERE TradingSymbol = 'NIFTY25OCT25100CE'
GROUP BY TradingSymbol;
```

---

## 🔧 **DAILY TASKS**

### **Before Market (8:00 AM)**
1. ✅ Update `ManualSpotData.xml` with yesterday's NIFTY close
2. ✅ Start service (auto-loads instruments)

### **During Market**
- ✅ Service automatically collects data
- ✅ New instruments added automatically
- ✅ LC/UC changes tracked

### **After Market**
- ✅ Check Excel exports in `Exports/` folder
- ✅ Verify data completeness

---

## 📁 **KEY FILES**

| File | Purpose |
|------|---------|
| `ManualSpotData.xml` | NIFTY spot data (update daily) |
| `Instruments` table | All instruments (with LoadDate) |
| `MarketQuotes` table | OHLC + LC/UC data (with GlobalSequence) |
| `Exports/DailyInitialData/` | Daily Excel exports |

---

## ⚡ **COMMON SCENARIOS**

### **Service Restart (Same Day)**
- ✅ Uses existing instruments (no duplicates)
- ✅ Continues data collection
- ✅ GlobalSequence continues from last value

### **New Trading Day**
- ✅ Loads fresh instruments from API
- ✅ Sets LoadDate = today
- ✅ GlobalSequence continues from previous day

### **New Strike Added Mid-Day**
- ✅ Detected on next instrument refresh (24h)
- ✅ Added to database automatically
- ✅ GlobalSequence starts at 1 for new strike

---

## 🎯 **REMEMBER**

- ✅ **NIFTY**: Manual XML (you control)
- ✅ **SENSEX/BANKNIFTY**: Kite API (automatic)
- ✅ **InsertionSequence**: Daily tracking
- ✅ **GlobalSequence**: Full lifecycle
- ✅ **LoadDate**: Tracks instrument availability date
- ✅ **No TRUNCATE**: All data preserved forever

---

## 📞 **TROUBLESHOOTING**

### **"Instruments not loading"**
- Check: Is today a new business date?
- Solution: Service auto-loads once per business date

### **"Duplicate instruments"**
- Check: LoadDate in Instruments table
- Solution: Should have only one set per LoadDate

### **"Wrong NIFTY close price"**
- Check: ManualSpotData.xml file
- Solution: Update with correct close from your platform

### **"Missing GlobalSequence"**
- Check: Is data from before implementation?
- Solution: Old data has GlobalSeq = 0 (expected)

---

**For detailed documentation, see:**
- `SESSION_SUMMARY_COMPLETE.md`
- `GLOBALSEQUENCE_IMPLEMENTATION_COMPLETE.md`
- `INSTRUMENT_LOAD_DATE_TRACKING.md`

