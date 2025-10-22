# 🧪 DATA COLLECTION TESTING INSTRUCTIONS

## ✅ **PREPARATION COMPLETE**

### **What We Did:**
1. ✅ **Database Located:** `KiteMarketData` on `localhost` SQL Server
2. ✅ **Backup Created:** `DatabaseBackups\KiteMarketData_Backup_20251008_080103.bak` (3.2 GB)
3. ✅ **All Tables Cleared:** Ready for fresh data collection test

### **Previous Data (now backed up):**
- Instruments: 6,287 rows
- SpotData: 21 rows
- MarketQuotes: 90,802 rows  
- CircuitLimitChanges: 469,778 rows
- IntradayTickData: 2,341,851 rows

---

## 🚀 **TESTING STEPS FOR BABU**

### **STEP 1: Start the Service**
```powershell
cd C:\Users\babu\Documents\Services\KiteMarketDataService.Worker
dotnet run
```

**Watch for:**
- ✅ Authentication successful
- ✅ Instruments loading
- ✅ Historical spot data collection
- ✅ Time-based data collection starts
- ✅ No errors in console

### **STEP 2: Let It Run for One Complete Cycle**
**Wait for:**
- First data collection cycle to complete (about 2-3 minutes)
- You should see:
  ```
  🔄 Collecting HISTORICAL SPOT DATA...
  ✅ HISTORICAL SPOT DATA collection completed!
  
  🔄 Starting TIME-BASED DATA COLLECTION...
  ✅ TIME-BASED DATA COLLECTION completed!
  
  🔄 Processing LC/UC CHANGES...
  ```

### **STEP 3: Stop the Service**
```
Press Ctrl+C to stop
```

### **STEP 4: Run Verification Queries**
```powershell
# Run the verification script
sqlcmd -S "localhost" -d "KiteMarketData" -i "VerifyDataCollection_AfterTest.sql" -o "TestResults.txt"

# View results
notepad TestResults.txt
```

---

## 🔍 **WHAT TO CHECK IN RESULTS**

### **1️⃣ Table Row Counts**
```
Expected:
- Instruments: > 0 (should have NIFTY/SENSEX/BANKNIFTY options)
- SpotData: > 0 (should have historical OHLC data)
- MarketQuotes: > 0 (should have collected options data)
- CircuitLimitChanges: Could be 0 (only if LC/UC changed)
- IntradayTickData: > 0 (minute snapshots)
```

### **2️⃣ SpotData Check (CRITICAL)**
```
Check:
✅ IndexName: NIFTY, SENSEX, BANKNIFTY present
✅ TradingDate: Should have proper dates
✅ DataSource: Should show "Kite Historical API" for historical data
✅ OpenPrice, ClosePrice, LastPrice: All should have values > 0

TIME-AWARE CHECK (YOUR FIX):
- If run BEFORE 3:30 PM: TradingDate should be YESTERDAY or earlier
- If run AFTER 3:30 PM: TradingDate should include TODAY
```

### **3️⃣ BusinessDate Check (MOST CRITICAL)**
```
This is the MAIN test!

Check:
✅ Pre-market data (before 9:15 AM):
   - RecordDateTime: e.g., 2025-10-08 08:30:00
   - BusinessDate: Should be 2025-10-07 (PREVIOUS day)
   - Status: Should show "✅ CORRECT (Previous day)"

✅ Market hours data (9:15 AM - 3:30 PM):
   - RecordDateTime: e.g., 2025-10-08 10:30:00
   - BusinessDate: Should be 2025-10-08 (CURRENT day)
   - Status: Should show "✅ CORRECT (Current day)"

✅ Post-market data (after 3:30 PM):
   - RecordDateTime: e.g., 2025-10-08 16:00:00
   - BusinessDate: Should be 2025-10-08 (CURRENT day)
   - Status: Should show "✅ CORRECT (Current day)"

❌ If you see "❌ WRONG" or "❌ NEEDS REVIEW":
   → BusinessDate calculation has issues
   → We need to fix it
```

### **4️⃣ Sample Market Quotes**
```
Check:
✅ TradingSymbol: Should show NIFTY/SENSEX/BANKNIFTY options
✅ Strike, OptionType (CE/PE): Should be populated
✅ LastPrice: Should have values
✅ LC (LowerCircuitLimit): Should have values > 0
✅ UC (UpperCircuitLimit): Should have values > 0
✅ LastTradeTime: Should NOT be NULL or 1/1/0001
✅ BusinessDate: Should match the period (pre-market = previous day, etc.)
```

### **5️⃣ LC/UC Values (YOUR FOCUS)**
```
Check:
✅ LowerCircuitLimit (LC): Should have proper values
✅ UpperCircuitLimit (UC): Should have proper values
✅ LC_UC_Range: Should show the range between LC and UC

Example good data:
TradingSymbol: NIFTY24OCT25000CE
Strike: 25000
LastPrice: 118.50
LC: 50.00
UC: 150.00
LC_UC_Range: 100.00

This is what NSE adjusts daily! 🎯
```

### **6️⃣ Duplicate Check**
```
Expected:
Should show NO RESULTS (no duplicates)

❌ If duplicates found:
   → Something is wrong with duplicate prevention logic
   → We need to fix it
```

### **7️⃣ Circuit Limit Changes**
```
Check:
- If service ran for only 1 cycle: Probably 0 changes (normal)
- If ran for multiple cycles: Should show LC/UC changes if they occurred

Example:
TradingSymbol: NIFTY24OCT25000CE
OldLC: 50.00 → NewLC: 45.00
OldUC: 150.00 → NewUC: 155.00
ChangedAt: 2025-10-08 10:32:15
BusinessDate: 2025-10-08

This is what you're tracking! 🎯
```

---

## 📋 **VERIFICATION CHECKLIST**

### **Data Collection Accuracy:**
- [ ] SpotData has historical data with correct dates
- [ ] SpotData has "Kite Historical API" as DataSource
- [ ] After 3:30 PM, SpotData includes TODAY's data (YOUR FIX)
- [ ] No duplicate entries in SpotData

### **BusinessDate Accuracy (CRITICAL):**
- [ ] Pre-market data (before 9:15 AM) → BusinessDate = PREVIOUS day
- [ ] Market hours data (9:15-3:30) → BusinessDate = CURRENT day
- [ ] Post-market data (after 3:30) → BusinessDate = CURRENT day
- [ ] All checks show "✅ CORRECT" status

### **Market Quotes Quality:**
- [ ] All instruments from Instruments table are collected
- [ ] All strikes have LC and UC values
- [ ] LastTradeTime is valid (not NULL/MinValue)
- [ ] All fields populated (Bid, Ask, Last, OI)

### **LC/UC Tracking (YOUR USE CASE):**
- [ ] LC (LowerCircuitLimit) values present
- [ ] UC (UpperCircuitLimit) values present
- [ ] If changes detected, CircuitLimitChanges table populated
- [ ] Changes have correct BusinessDate

---

## 🚨 **EXPECTED ISSUES TO WATCH FOR**

### **Issue 1: Authentication Failure**
```
Symptom: Service stops with "Authentication failed"
Cause: RequestToken expired (expires daily)
Solution: Get fresh RequestToken from Kite login, update appsettings.json
```

### **Issue 2: No Historical Spot Data**
```
Symptom: SpotData table is empty after collection
Cause: Historical API call failed
Check: Service logs for API errors
```

### **Issue 3: Wrong BusinessDate**
```
Symptom: BusinessDate doesn't match expected values
Cause: Logic issue in BusinessDateCalculationService
Action: Share the BusinessDate Check results from query #5
```

### **Issue 4: Missing Options**
```
Symptom: Only few options collected, not all strikes
Cause: Instruments not loaded properly or API rate limiting
Check: Instruments table row count
```

---

## 📊 **QUICK VERIFICATION COMMANDS**

### **Check Row Counts:**
```sql
USE KiteMarketData;
SELECT 'Instruments' AS [Table], COUNT(*) AS [Rows] FROM Instruments
UNION ALL SELECT 'SpotData', COUNT(*) FROM SpotData
UNION ALL SELECT 'MarketQuotes', COUNT(*) FROM MarketQuotes
UNION ALL SELECT 'CircuitLimitChanges', COUNT(*) FROM CircuitLimitChanges;
```

### **Check Latest BusinessDate:**
```sql
SELECT TOP 10
    BusinessDate,
    FORMAT(RecordDateTime, 'yyyy-MM-dd HH:mm:ss') AS CollectedAt,
    TradingSymbol,
    Strike,
    LastPrice,
    LowerCircuitLimit AS LC,
    UpperCircuitLimit AS UC
FROM MarketQuotes
ORDER BY RecordDateTime DESC;
```

### **Check Spot Data:**
```sql
SELECT 
    IndexName,
    TradingDate,
    ClosePrice,
    DataSource
FROM SpotData
ORDER BY TradingDate DESC, IndexName;
```

---

## 🎯 **DECISION POINTS**

### **If All Checks Pass ✅:**
```
Data collection is VERY VERY CORRECT! 
→ Proceed to next steps:
   - Labeling system
   - LC/UC change analysis
   - Trading opportunity identification
```

### **If BusinessDate is Wrong ❌:**
```
STOP - Fix BusinessDate logic first!
→ Share the query results
→ I'll help debug and fix
→ Re-test after fix
```

### **If Duplicates Found ❌:**
```
STOP - Fix duplicate prevention
→ Share duplicate check results
→ Fix logic
→ Clear DB and re-test
```

### **If LC/UC Values Missing ❌:**
```
STOP - Data collection incomplete
→ Check if Kite API is returning LC/UC
→ Verify field mapping
→ Fix and re-test
```

---

## 💬 **AFTER TESTING**

**Tell me:**
1. ✅ Did service start successfully?
2. ✅ Did it complete one full cycle?
3. ✅ What do the verification results show?
4. ❌ Any errors in console or logs?
5. ❌ Any "❌ WRONG" status in BusinessDate check?

**Share:**
- Screenshot or copy-paste of verification results
- Any errors from console
- Specific issues you noticed

**Then we decide:**
- If all ✅ → Move to next phase (labeling, analysis)
- If any ❌ → Fix issues first, then re-test

---

## 📁 **FILES READY FOR YOU**

1. **VerifyDataCollection_AfterTest.sql** - Comprehensive verification queries
2. **ClearDatabaseForTest.sql** - If you need to clear and re-test
3. **Backup file** - Safe backup before test (3.2 GB)

---

**🎯 Remember: Data collection must be VERY VERY CORRECT before moving forward!**

**I'm ready to help analyze results and fix any issues!** 💪

