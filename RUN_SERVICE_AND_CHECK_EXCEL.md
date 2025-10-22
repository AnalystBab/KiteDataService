# 🚀 RUN SERVICE AND CHECK EXCEL - QUICK GUIDE

## ✅ **CONFIGURATION CONFIRMED**

```json
"StrategyExport": {
    "ExportDate": "2025-10-09",
    "Indices": ["SENSEX", "BANKNIFTY", "NIFTY"],
    "ExportFolder": "Exports\\StrategyAnalysis",
    "EnableExport": true
}
```

**Status: ✅ Ready to export!**

---

## 🚀 **HOW TO RUN**

### **Option 1: Run Service (Recommended)**

```bash
cd C:\Users\babu\Documents\Services\KiteMarketDataService.Worker
dotnet run
```

### **Option 2: Run from Existing Batch File**

```bash
.\run-service.bat
```

---

## 📊 **WHAT WILL HAPPEN**

### **Service Startup Sequence:**

1. ✅ Service starts and checks for existing instances
2. ✅ Authenticates with Kite API (using saved token)
3. ✅ Loads instruments
4. ✅ Collects historical spot data
5. **🎯 STRATEGY EXPORT RUNS HERE!** ⬅️ Your Excel files generated!
6. ✅ Continues with time-based data collection
7. ✅ Processes LC/UC changes
8. ✅ Main service loop begins

### **Look for These Messages:**

```
🎯 [HH:mm:ss] Running STRATEGY ANALYSIS EXPORT...
📊 Processing SENSEX for 2025-10-09
📊 Processing BANKNIFTY for 2025-10-09
📊 Processing NIFTY for 2025-10-09
✅ [HH:mm:ss] STRATEGY ANALYSIS EXPORT completed!
```

---

## 📁 **WHERE TO FIND EXCEL FILES**

### **Default Location:**

```
C:\Users\babu\Documents\Services\KiteMarketDataService.Worker\
  └── Exports\
      └── StrategyAnalysis\
          └── 2025-10-09\
              └── Expiry_2025-10-16\  (or other expiries)
                  ├── SENSEX_Strategy_Analysis_20251009.xlsx
                  ├── BANKNIFTY_Strategy_Analysis_20251009.xlsx
                  └── NIFTY_Strategy_Analysis_20251009.xlsx
```

### **Quick Path:**

```
.\Exports\StrategyAnalysis\2025-10-09\
```

---

## 🔍 **WHAT TO CHECK IN EXCEL FILES**

### **1. Open SENSEX File First:**

```
SENSEX_Strategy_Analysis_20251009.xlsx
```

### **2. Check Summary Sheet (Sheet 1):**

Look for these key values:

```
SPOT_CLOSE_D0: 82,172.10
CLOSE_STRIKE: 82,100
CALL_BASE_STRIKE: 79,600 ✅ (should be this, not 78,700)
PUT_BASE_STRIKE: 83,800 ✅
CALL_MINUS_VALUE: 80,179.15
CALL_MINUS_TO_CALL_BASE_DISTANCE: 579.15
TARGET_CE_PREMIUM: (value)
TARGET_PE_PREMIUM: (value)
DYNAMIC_HIGH_BOUNDARY: (value)
```

### **3. Check All Labels Sheet (Sheet 2):**

Verify:
- ✅ 27 labels present
- ✅ Formulas shown
- ✅ Color coding (yellow for importance ≥ 5)

### **4. Check C- Call Minus Sheet (Sheet 3):**

Verify:
- ✅ Shows C- calculation
- ✅ Distance: 579.15 (should be close to D1 range 581.18)
- ✅ Shows "99.65% accuracy"

### **5. Check Base Strike Selection Sheet (Sheet 10):**

Verify:
- ✅ Shows "First strike < CLOSE with LC > 0.05"
- ✅ CALL_BASE_STRIKE = 79,600
- ✅ Documents MAX InsertionSequence logic

### **6. Check Raw Data Sheet (Sheet 12):**

Verify:
- ✅ Shows 79600 with LC = 193.10 (green)
- ✅ Shows 79800 with LC = 0.05 (not green - excluded!)
- ✅ Shows InsertionSequence = 7 for most strikes

---

## ✅ **VALIDATION CHECKLIST**

### **For SENSEX Report:**

```
□ File exists: SENSEX_Strategy_Analysis_20251009.xlsx
□ Has 12 sheets
□ Summary sheet shows correct values
□ CALL_BASE_STRIKE = 79,600 (not 78,700)
□ Distance = 579.15 (predicts 581.18 range with 99.65% accuracy)
□ All Labels sheet has 27 labels
□ C- sheet shows 99.65% accuracy note
□ Base Strike Selection sheet documents standard method
□ Raw Data sheet shows final LC/UC values
```

### **Expected Results:**

| Index | Call Base Strike | Distance | D1 Actual Range | Accuracy |
|-------|-----------------|----------|----------------|----------|
| SENSEX | 79,600 | 579.15 | 581.18 | 99.65% ✅ |
| BANKNIFTY | (TBD) | (TBD) | (TBD) | (TBD) |
| NIFTY | (TBD) | (TBD) | (TBD) | (TBD) |

---

## 🚨 **IF EXPORT FAILS**

### **Check Console for Errors:**

Look for:
```
⚠️ Strategy export failed (non-critical): [error message]
```

### **Common Issues:**

1. **No data for date:**
   - Check HistoricalSpotData has 2025-10-09
   - Check MarketQuotes has 2025-10-09 data

2. **No expiry found:**
   - Check MarketQuotes has ExpiryDate data
   - Verify expiry is on or after 2025-10-09

3. **No base strikes found:**
   - Check strikes have LC > 0.05
   - Verify InsertionSequence data exists

### **Manual Check:**

```bash
sqlcmd -S localhost -d KiteMarketData -Q "SELECT COUNT(*) FROM HistoricalSpotData WHERE TradingDate = '2025-10-09'"
sqlcmd -S localhost -d KiteMarketData -Q "SELECT COUNT(*) FROM MarketQuotes WHERE BusinessDate = '2025-10-09'"
```

---

## 📊 **AFTER CHECKING EXCEL FILES**

### **Things to Verify:**

1. ✅ **All 12 sheets present and populated**
2. ✅ **Base strikes use STANDARD METHOD (LC > 0.05)**
3. ✅ **Distance calculations are accurate**
4. ✅ **Formulas are documented**
5. ✅ **Color coding works correctly**
6. ✅ **Raw data shows final values**

### **What to Look For:**

**✅ CORRECT:**
- CALL_BASE_STRIKE = 79,600 (LC = 193.10)
- Distance = 579.15
- Method = "First strike < CLOSE where LC > 0.05"

**❌ WRONG (Should NOT see):**
- CALL_BASE_STRIKE = 78,700 (UC SUM method)
- Distance = 1,479.15
- Any mention of alternative methods

---

## 🎯 **SUCCESS CRITERIA**

### **Excel File Generated Successfully If:**

```
✅ File size: 100-500 KB (reasonable size)
✅ 12 sheets present
✅ Summary shows key metrics
✅ All Labels shows 27 labels with formulas
✅ C- sheet shows 99.65% accuracy
✅ Base Strike Selection documents standard process
✅ Raw Data shows final LC/UC values
✅ No errors in formulas or calculations
```

---

## 📖 **FOR REFERENCE**

### **After Running, Check:**

1. **Console Output:**
   - Look for success messages
   - Note any warnings

2. **Excel Files:**
   - Open all 3 files (SENSEX, BANKNIFTY, NIFTY)
   - Verify structure and data

3. **Documentation:**
   - Refer to `STRATEGY_EXCEL_EXPORT_GUIDE.md`
   - Check `EXCEL_EXPORT_METHODS_CONFIRMATION.md`

---

## 🎯 **READY TO RUN!**

**Everything is configured and ready!**

Just run:
```bash
dotnet run
```

Wait for:
```
🎯 Running STRATEGY ANALYSIS EXPORT...
✅ STRATEGY ANALYSIS EXPORT completed!
```

Then check:
```
.\Exports\StrategyAnalysis\2025-10-09\
```

**Your comprehensive 12-sheet Excel reports await! 🎯📊✅**


