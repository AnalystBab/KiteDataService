# 🚀 SERVICE STARTUP STEPS

## 📋 **COMPLETE STARTUP GUIDE**

---

## **STEP 1: GET REQUEST TOKEN FROM KITE** 🔑

### **1.1 Login to Kite Developer Console**
```
URL: https://kite.trade/
```

### **1.2 Generate Request Token**
1. Go to your Kite app settings
2. Click "Generate Session"
3. Login with your Zerodha credentials
4. Copy the `request_token` from the redirect URL

**Example URL after login:**
```
http://127.0.0.1/?request_token=ABC123XYZ789&action=login&status=success
```

**Copy:** `ABC123XYZ789` (the request_token value)

---

## **STEP 2: UPDATE CONFIGURATION** ⚙️

### **2.1 Open appsettings.json**
```powershell
cd C:\Users\babu\Documents\Services\KiteMarketDataService.Worker
notepad appsettings.json
```

### **2.2 Update Request Token**
```json
{
  "KiteConnect": {
    "ApiKey": "kw3ptb0zmocwupmo",
    "ApiSecret": "q6iqhpb3lx2sw9tomkrljb5fmczdx6mv",
    "RequestToken": "PUT_YOUR_REQUEST_TOKEN_HERE",  // ← UPDATE THIS
    "AccessToken": "NqC2Qlr65jZU8JQrvtDUYqZ0XD3xeaMR"
  }
}
```

### **2.3 Save and Close**
- Press `Ctrl+S` to save
- Close Notepad

---

## **STEP 3: VERIFY DATABASE CONNECTION** 💾

### **3.1 Check SQL Server is Running**
```powershell
Get-Service -Name "MSSQLSERVER" | Select-Object Status, DisplayName
```

**Expected Output:**
```
Status  DisplayName
------  -----------
Running SQL Server (MSSQLSERVER)
```

### **3.2 Test Database Connection**
```powershell
sqlcmd -S localhost -Q "SELECT @@VERSION"
```

### **3.3 Verify Tables Exist**
```sql
sqlcmd -S localhost -d KiteMarketData -Q "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME IN ('MarketQuotes', 'StrikeLatestRecords', 'StrategyLabels')"
```

**Expected Output:**
```
TABLE_NAME
----------
MarketQuotes
StrikeLatestRecords
StrategyLabels
```

---

## **STEP 4: BUILD THE SERVICE** 🔨

### **4.1 Navigate to Project Directory**
```powershell
cd C:\Users\babu\Documents\Services\KiteMarketDataService.Worker
```

### **4.2 Build in Release Mode**
```powershell
dotnet build --configuration Release
```

**Expected Output:**
```
Build succeeded.
    0 Warning(s)
    0 Error(s)
```

---

## **STEP 5: RUN THE SERVICE** ▶️

### **5.1 Start the Service**
```powershell
dotnet run --configuration Release
```

### **5.2 Alternative: Run from Build Output**
```powershell
cd bin\Release\net9.0-windows
dotnet KiteMarketDataService.Worker.dll
```

---

## **STEP 6: VERIFY SERVICE STARTUP** ✅

### **6.1 Watch Console Output**
You should see this startup sequence:

```
🎯 [12:55:28] Kite Market Data Service Starting
✓  [12:55:29] Mutex Check........................... ✓
✓  [12:55:29] Log File Setup........................ ✓
✓  [12:55:30] Database Setup........................ ✓
✓  [12:55:31] Request Token & Authentication........ ✓
✓  [12:55:32] Instruments Loading................... ✓
✓  [12:55:33] Historical Spot Data Collection....... ✓
✓  [12:55:34] Business Date Calculation............. ✓
✓  [12:55:35] Circuit Limits Setup.................. ✓
✓  [12:55:36] Service Ready......................... ✓

🚀 Service is ready and collecting data!
✅ Updated latest 3 records for 245 strikes
```

### **6.2 Check Log File**
```powershell
Get-Content .\logs\KiteMarketDataService.log -Tail 20
```

---

## **STEP 7: ACCESS WEB DASHBOARD** 🌐

### **7.1 Open Browser**
```
URL: http://localhost:5000
```

**Auto-redirects to:**
```
http://localhost:5000/AdvancedDashboard.html
```

### **7.2 Verify Dashboard Features**
- ✅ Real-time predictions (NIFTY, SENSEX, BANKNIFTY)
- ✅ Strategy labels (28 labels)
- ✅ Process breakdown (CALL_MINUS, PUT_MINUS, etc.)
- ✅ Live market data
- ✅ Pattern analysis

---

## **STEP 8: VERIFY DATA COLLECTION** 📊

### **8.1 Check Market Quotes**
```sql
sqlcmd -S localhost -d KiteMarketData -Q "SELECT TOP 10 TradingSymbol, Strike, LastPrice, RecordDateTime FROM MarketQuotes ORDER BY RecordDateTime DESC"
```

### **8.2 Check StrikeLatestRecords**
```sql
sqlcmd -S localhost -d KiteMarketData -Q "SELECT COUNT(*) AS TotalRecords, COUNT(DISTINCT CONCAT(TradingSymbol, Strike, OptionType)) AS UniqueStrikes FROM StrikeLatestRecords"
```

**Expected Output:**
```
TotalRecords UniqueStrikes
------------ -------------
735          245
```
*(3 records per strike × 245 strikes = 735 total records)*

### **8.3 Verify Latest Records**
```sql
sqlcmd -S localhost -d KiteMarketData -Q "SELECT TOP 5 TradingSymbol, Strike, OptionType, UpperCircuitLimit, RecordOrder FROM StrikeLatestRecords WHERE RecordOrder = 1 ORDER BY RecordDateTime DESC"
```

---

## **TROUBLESHOOTING** 🔧

### **Issue 1: "Another instance is already running"**
**Solution:**
```powershell
# Find and stop the running process
Get-Process -Name "dotnet" | Stop-Process -Force
```

### **Issue 2: "Access denied" or SSL Certificate Error**
**Solution:** Already fixed in `appsettings.json` with HTTP-only configuration.

### **Issue 3: Database Connection Failed**
**Solution:**
```powershell
# Check connection string in appsettings.json
# Verify SQL Server is running
Get-Service -Name "MSSQLSERVER"
```

### **Issue 4: Invalid Request Token**
**Solution:**
- Request tokens expire after a few minutes
- Generate a new request token from Kite
- Update `appsettings.json` immediately
- Start the service

### **Issue 5: No Data Being Collected**
**Solution:**
- Check if market is open (9:15 AM - 3:30 PM IST)
- Check log file for errors
- Verify instruments are loaded (should see ~245 instruments)

---

## **MONITORING THE SERVICE** 👁️

### **Real-time Log Monitoring**
```powershell
Get-Content .\logs\KiteMarketDataService.log -Wait -Tail 50
```

### **Check Service Status**
```powershell
Get-Process -Name "dotnet" | Where-Object {$_.StartTime -gt (Get-Date).AddMinutes(-10)}
```

### **Database Statistics**
```sql
-- Check data collection progress
SELECT 
    BusinessDate,
    COUNT(*) AS QuotesCount,
    MIN(RecordDateTime) AS FirstRecord,
    MAX(RecordDateTime) AS LastRecord
FROM MarketQuotes
WHERE BusinessDate >= CAST(GETDATE() AS DATE)
GROUP BY BusinessDate
ORDER BY BusinessDate DESC;
```

---

## **STOPPING THE SERVICE** 🛑

### **Method 1: Graceful Shutdown**
Press `Ctrl+C` in the console window

### **Method 2: Force Stop**
```powershell
Get-Process -Name "dotnet" | Stop-Process -Force
```

---

## **QUICK START CHECKLIST** ✅

- [ ] Get request token from Kite
- [ ] Update `appsettings.json` with request token
- [ ] Verify SQL Server is running
- [ ] Verify database tables exist
- [ ] Build service: `dotnet build --configuration Release`
- [ ] Run service: `dotnet run --configuration Release`
- [ ] Verify startup messages in console
- [ ] Open web dashboard: `http://localhost:5000`
- [ ] Check data collection in database
- [ ] Monitor log file for any errors

---

## **IMPORTANT NOTES** ⚠️

1. **Request Token Expires:** Get a fresh token before each service start
2. **Market Hours:** Service collects data differently during pre-market, market hours, and after-hours
3. **Business Date:** Service automatically calculates the correct business date based on NIFTY spot data
4. **Single Instance:** Only one instance can run at a time (protected by Mutex)
5. **Log Archival:** Old log files are automatically moved to `Log_Dump` folder
6. **StrikeLatestRecords:** Automatically maintains only latest 3 records per strike

---

## **NEXT STEPS AFTER STARTUP** 🎯

1. **Monitor Data Collection**
   - Watch console for collection messages
   - Check database for new records every minute

2. **Verify StrikeLatestRecords**
   ```sql
   SELECT * FROM StrikeLatestRecords WHERE RecordOrder = 1;
   ```

3. **Check Strategy Labels**
   ```sql
   SELECT * FROM StrategyLabels ORDER BY BusinessDate DESC;
   ```

4. **Monitor Web Dashboard**
   - Refresh to see latest predictions
   - Check pattern matches
   - View strategy labels

5. **Review Excel Exports** (if enabled)
   ```
   Location: Exports\StrategyAnalysis\
   ```

---

## 🎉 **YOU'RE ALL SET!**

The service is now running and collecting data. The **StrikeLatestRecords** table will automatically maintain the latest 3 records for each strike, giving you fast access to current UC/LC values and change history!

**Happy Trading! 📈**







