# 🧪 WEB APP TESTING GUIDE

Complete testing checklist to verify the web app integration works correctly.

---

## 🚀 **QUICK START TEST**

### **Step 1: Build & Run**
```powershell
# Navigate to project folder
cd C:\Users\babu\Documents\Services\KiteMarketDataService.Worker

# Option A: Use launch script (RECOMMENDED)
.\LaunchWebApp.bat

# Option B: Manual run
dotnet build
dotnet run
```

**Expected Output:**
```
🚀 KITE MARKET DATA SERVICE STARTED
📡 Server running on: http://localhost:5000
📊 Dashboard URL: http://localhost:5000
```

### **Step 2: Verify Services Started**
Check console output shows:
- ✅ Worker Service initialized
- ✅ Web API listening on port 5000
- ✅ Database connected

---

## 📋 **API ENDPOINT TESTS**

### **Test 1: Health Check** ✅
```
URL: http://localhost:5000/api/health
Method: GET
```

**Expected Response:**
```json
{
  "status": "Healthy",
  "timestamp": "2025-10-14T...",
  "database": "Connected",
  "stats": {
    "totalLabels": 123,
    "totalPatterns": 5266,
    "totalSpotData": 45
  },
  "version": "1.0.0"
}
```

**✅ PASS if:** status = "Healthy", database = "Connected"  
**❌ FAIL if:** Error 500, database = "Disconnected"

---

### **Test 2: Get Predictions** ✅
```
URL: http://localhost:5000/api/predictions
Method: GET
```

**Expected Response:**
```json
[
  {
    "indexName": "SENSEX",
    "businessDate": "2025-10-13",
    "predictionDate": "2025-10-14",
    "predictedLow": 80400.00,
    "predictedHigh": 82650.00,
    "predictedClose": 82500.00,
    "accuracyLow": 99.97,
    "accuracyHigh": 99.99,
    "accuracyClose": 99.99,
    "lowFormula": "ADJUSTED_LOW_PREDICTION_PREMIUM",
    "highFormula": "SPOT_CLOSE_D0 + CE_PE_UC_DIFFERENCE",
    "closeFormula": "(PUT_BASE_STRIKE + BOUNDARY_LOWER) / 2"
  }
  // ... more indices
]
```

**✅ PASS if:** Returns array with SENSEX, BANKNIFTY, NIFTY predictions  
**❌ FAIL if:** Empty array, hardcoded values, or error

---

### **Test 3: Get Patterns** ✅
```
URL: http://localhost:5000/api/patterns?targetType=LOW&indexName=SENSEX&limit=10
Method: GET
```

**Expected Response:**
```json
[
  {
    "id": 1,
    "formula": "TARGET_CE_PREMIUM",
    "targetType": "LOW",
    "indexName": "SENSEX",
    "avgErrorPercentage": 0.03,
    "consistencyScore": 97.8,
    "occurrenceCount": 12,
    "rating": "⭐⭐⭐⭐⭐",
    "isActive": true
  }
  // ... more patterns
]
```

**✅ PASS if:** Returns patterns from DiscoveredPatterns table  
**❌ FAIL if:** Empty array or hardcoded data

---

### **Test 4: Get Live Market Data** ✅
```
URL: http://localhost:5000/api/livemarket/SENSEX
Method: GET
```

**Expected Response:**
```json
{
  "indexName": "SENSEX",
  "tradingDate": "2025-10-13",
  "openPrice": 82089.00,
  "highPrice": 82250.00,
  "lowPrice": 82000.00,
  "closePrice": 82150.00,
  "changePercent": 0.25,
  "changeValue": 61.00,
  "lastUpdated": "2025-10-14T...",
  "marketStatus": "CLOSED"
}
```

**✅ PASS if:** Returns real data from HistoricalSpotData table  
**❌ FAIL if:** Hardcoded values or error

---

### **Test 5: Get Strategy Labels** ✅
```
URL: http://localhost:5000/api/strategylabels?indexName=SENSEX
Method: GET
```

**Expected Response:**
```json
[
  {
    "labelNumber": 1,
    "labelName": "SPOT_CLOSE_D0",
    "labelValue": 82151.66,
    "formula": "HistoricalSpotData.ClosePrice",
    "description": "SENSEX/NIFTY/BANKNIFTY closing price on prediction day (D0)",
    "category": "BASE_DATA",
    "businessDate": "2025-10-13",
    "indexName": "SENSEX"
  }
  // ... 27 more labels
]
```

**✅ PASS if:** Returns all 28 labels from StrategyLabels table  
**❌ FAIL if:** Less than 28 labels or hardcoded data

---

### **Test 6: Get Process Breakdown** ✅
```
URL: http://localhost:5000/api/processbreakdown?indexName=SENSEX&date=2025-10-13
Method: GET
```

**Expected Response:**
```json
{
  "businessDate": "2025-10-13",
  "indexName": "SENSEX",
  "spotClose": 82151.66,
  "closeStrike": 82100,
  "closeCeUc": 3660.60,
  "closePeUc": 1766.40,
  "callBaseStrike": 82000,
  "putBaseStrike": 82200,
  "callMinus": {
    "processName": "CALL_MINUS (C-)",
    "value": 1234.56,
    "formula": "CALL_BASE_UC_D0 - CLOSE_CE_UC_D0",
    "description": "Difference between Call Base UC and Close Strike CE UC",
    "distance": 100.00
  },
  // ... P-, C+, P+ processes
  "relatedLabels": [ /* all 28 labels */ ]
}
```

**✅ PASS if:** Returns complete breakdown with all processes  
**❌ FAIL if:** Missing processes or hardcoded data

---

## 🌐 **WEB APP INTERFACE TESTS**

### **Test 7: Dashboard Loads** ✅
```
URL: http://localhost:5000
```

**Expected:**
- ✅ Page loads without errors
- ✅ Navigation menu visible
- ✅ Dashboard sections displayed
- ✅ No JavaScript console errors

---

### **Test 8: Predictions Display** ✅
Navigate to D1 Predictions section

**Check:**
- ✅ Shows predictions for SENSEX, BANKNIFTY, NIFTY
- ✅ Values are NOT hardcoded (change when you change dates)
- ✅ Accuracy percentages shown
- ✅ Formulas displayed

---

### **Test 9: Process Breakdown Works** ✅
1. Select index: SENSEX
2. Select date: 2025-10-13 (or latest available)
3. Click "Load Real Data"

**Check:**
- ✅ Loading indicator appears
- ✅ Data loads successfully
- ✅ All 4 processes shown (C-, P-, C+, P+)
- ✅ Values match database (not hardcoded)
- ✅ Related labels displayed

---

### **Test 10: Live Market Updates** ✅
Navigate to Live Market section

**Check:**
- ✅ Shows current market data
- ✅ OHLC values displayed
- ✅ Market status shown (OPEN/CLOSED/PRE_MARKET)
- ✅ Change percentages calculated

---

## 📊 **DATA VERIFICATION TESTS**

### **Test 11: Database Values Match** ✅

Run SQL query:
```sql
SELECT TOP 1 * FROM StrategyLabels 
WHERE IndexName = 'SENSEX' 
ORDER BY BusinessDate DESC;
```

Then check web app predictions:
- ✅ Spot close matches SPOT_CLOSE_D0
- ✅ Predicted low matches ADJUSTED_LOW_PREDICTION_PREMIUM
- ✅ All values are from actual database, not hardcoded

---

### **Test 12: Pattern Data Matches** ✅

Run SQL query:
```sql
SELECT TOP 10 * FROM DiscoveredPatterns 
WHERE TargetType = 'LOW' AND IndexName = 'SENSEX'
ORDER BY AvgErrorPercentage;
```

Then check web app patterns list:
- ✅ Formulas match database
- ✅ Error percentages match
- ✅ Occurrence counts match
- ✅ Rating calculated correctly

---

## 🔍 **SWAGGER API DOCS TEST**

### **Test 13: Swagger UI Works** ✅
```
URL: http://localhost:5000/api-docs
```

**Check:**
- ✅ Swagger UI loads
- ✅ All 6 controllers visible
- ✅ Can test endpoints directly
- ✅ Request/Response schemas shown

**Try Testing:**
1. Expand `GET /api/health`
2. Click "Try it out"
3. Click "Execute"
4. Verify response shows "Healthy"

---

## ⚠️ **COMMON ISSUES & FIXES**

### **Issue 1: Port Already in Use**
**Error:** "Failed to bind to address http://localhost:5000"

**Fix:**
```powershell
# Find process using port 5000
netstat -ano | findstr :5000

# Kill the process
taskkill /PID <process_id> /F

# Or change port in Program.cs:
# webBuilder.UseUrls("http://localhost:5001");
```

---

### **Issue 2: Database Connection Failed**
**Error:** "Database: Disconnected" in health check

**Fix:**
1. Verify SQL Server is running
2. Check connection string in appsettings.json
3. Test database connection:
```powershell
sqlcmd -S localhost -E -Q "SELECT @@VERSION"
```

---

### **Issue 3: No Data Returned**
**Error:** Empty arrays or null responses

**Fix:**
1. Check if StrategyLabels table has data:
```sql
SELECT COUNT(*) FROM StrategyLabels;
SELECT COUNT(*) FROM DiscoveredPatterns;
```

2. If empty, run the Worker service first to collect data:
```powershell
dotnet run
# Wait for at least one cycle
```

---

### **Issue 4: Worker Service Not Starting**
**Error:** Service initialization fails

**Fix:**
1. Check request token in appsettings.json
2. Verify all required services registered
3. Check logs in `logs/KiteMarketDataService.log`

---

## ✅ **TESTING CHECKLIST**

Mark each test as you complete it:

**API Tests:**
- [ ] Test 1: Health Check
- [ ] Test 2: Get Predictions
- [ ] Test 3: Get Patterns
- [ ] Test 4: Get Live Market
- [ ] Test 5: Get Strategy Labels
- [ ] Test 6: Get Process Breakdown

**Web App Tests:**
- [ ] Test 7: Dashboard Loads
- [ ] Test 8: Predictions Display
- [ ] Test 9: Process Breakdown Works
- [ ] Test 10: Live Market Updates

**Verification Tests:**
- [ ] Test 11: Database Values Match
- [ ] Test 12: Pattern Data Matches
- [ ] Test 13: Swagger UI Works

**Final Verification:**
- [ ] Worker service still runs normally
- [ ] Data collection continues
- [ ] No errors in console
- [ ] Web app shows real data (not hardcoded)
- [ ] All features responsive

---

## 🎯 **SUCCESS CRITERIA**

**ALL TESTS MUST PASS:**
- ✅ All API endpoints return 200 OK
- ✅ Data comes from database (not hardcoded)
- ✅ Worker service unaffected
- ✅ Web app fully functional
- ✅ No errors in console/logs

**WHEN ALL GREEN:**
**STATUS: WEB APP INTEGRATION VERIFIED! 🎉**

---

**Last Updated:** October 14, 2025










