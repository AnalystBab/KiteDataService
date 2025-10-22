# 📊 **DATABASE TABLES PURPOSE & EXPLANATION**

## 🎯 **Overview:**
The system uses **2 databases** with **7 main tables** to handle market data collection, circuit limit tracking, and spot data management.

---

## 🗄️ **KiteMarketData Database:**

### **1. 📈 Instruments Table (Master Data)**
- **Purpose**: Master data for all financial instruments
- **Contains**: 7,346 instruments (CE/PE options + INDEX instruments)
- **Key Fields**: 
  - `InstrumentToken`: Unique identifier from Kite API
  - `TradingSymbol`: Symbol name (e.g., "NIFTY25DEC30000CE", "NIFTY")
  - `InstrumentType`: "CE", "PE", or "INDEX"
  - `Exchange`: "NFO", "BFO", "NSE"
  - `Strike`, `Expiry`: Options details
- **Why Keep**: This table is **NOT cleared** because it contains master instrument data
- **Usage**: Used by service to know which instruments to collect data for

### **2. 📊 MarketQuotes Table (Options Data)**
- **Purpose**: Real-time options market data (CE/PE only)
- **Contains**: OHLC, circuit limits, volume, open interest for options
- **Key Fields**:
  - `TradingSymbol`: Options symbols (e.g., "NIFTY25DEC30000CE")
  - `Strike`, `OptionType`, `ExpiryDate`: Options details
  - `OpenPrice`, `HighPrice`, `LowPrice`, `ClosePrice`: OHLC data
  - `LowerCircuitLimit`, `UpperCircuitLimit`: Circuit limits
  - `Volume`, `OpenInterest`: Trading metrics
  - `BusinessDate`: Calculated business date (NEW!)
- **Collection**: Every minute during market hours
- **Separation**: **ONLY options data** - no spot/index data mixed in

### **3. 🎯 SpotData Table (Index Data)**
- **Purpose**: Real-time index/spot data (NIFTY, SENSEX, etc.)
- **Contains**: OHLC data for indices only
- **Key Fields**:
  - `IndexName`: Index name (e.g., "NIFTY", "SENSEX")
  - `OpenPrice`, `HighPrice`, `LowPrice`, `ClosePrice`: OHLC data
  - `LastPrice`: Current price
  - `IsMarketOpen`: Market status flag
  - `TradingDate`, `QuoteTimestamp`: Time information
- **Collection**: Every minute during market hours
- **Separation**: **ONLY index data** - completely separate from options

### **4. 🔄 CircuitLimitChanges Table (Change Tracking)**
- **Purpose**: Tracks when circuit limits change for options
- **Contains**: Before/after values when LC/UC changes occur
- **Key Fields**:
  - `TradingSymbol`: Options symbol
  - `PreviousLC`, `PreviousUC`: Old circuit limit values
  - `NewLC`, `NewUC`: New circuit limit values
  - `ChangeType`: "LC_CHANGE", "UC_CHANGE", "BOTH_CHANGE"
  - `ChangeTimestamp`: IST time when change occurred
- **Trigger**: Only when circuit limits actually change
- **Usage**: Used for Excel export and change analysis

### **5. 📋 CircuitLimitChangeHistory Table (Historical Changes)**
- **Purpose**: Historical record of all circuit limit changes
- **Contains**: Complete history of LC/UC changes with context
- **Key Fields**:
  - `TradingDate`, `TradedTime`: When change occurred
  - `Strike`, `OptionType`, `ExpiryDate`: Instrument details
  - `LowerCircuit`, `UpperCircuit`: New circuit limit values
  - `SpotOpen`, `SpotHigh`, `SpotLow`, `SpotClose`: NIFTY data at change time
  - `ChangeTimestamp`: IST timestamp
- **Usage**: Long-term analysis and reporting

### **6. 📸 DailyMarketSnapshots Table (Daily Snapshots)**
- **Purpose**: Daily snapshots of market data
- **Contains**: End-of-day data for all instruments
- **Key Fields**:
  - `TradingDate`: Date of snapshot
  - `SnapshotType`: "MARKET_OPEN", "MARKET_CLOSE", "POST_MARKET"
  - `SnapshotTime`: When snapshot was taken
  - All OHLC and circuit limit data
- **Usage**: Baseline data for change detection

---

## 🗄️ **CircuitLimitTracking Database:**

### **7. 🔍 CircuitLimitChangeDetails Table (Detailed Tracking)**
- **Purpose**: Detailed circuit limit change tracking with full context
- **Contains**: Comprehensive change records with all related data
- **Key Fields**:
  - `InstrumentToken`, `TradingSymbol`: Instrument identification
  - `PreviousLowerCircuit`, `PreviousUpperCircuit`: Old values
  - `NewLowerCircuit`, `NewUpperCircuit`: New values
  - `ChangeTimestamp`: IST time of change
  - All instrument and market context data
- **Usage**: Detailed analysis and advanced reporting

---

## 🔄 **Data Flow:**

### **1. Service Startup:**
1. **Load Instruments** → Preserve INDEX instruments, reload CE/PE from Kite API
2. **Initialize** → All tables start empty, ready for fresh data

### **2. Every Minute:**
1. **Collect Options Data** → MarketQuotes table (CE/PE only)
2. **Collect Spot Data** → SpotData table (INDEX only)
3. **Detect LC/UC Changes** → CircuitLimitChanges table
4. **Calculate BusinessDate** → Using spot data from SpotData table

### **3. Every 10 Minutes (or when changes detected):**
1. **Excel Export** → Automatic export when LC/UC changes occur
2. **Historical Storage** → CircuitLimitChangeHistory table

---

## ✅ **Key Benefits:**

### **1. Clean Data Separation:**
- **MarketQuotes**: Options data only
- **SpotData**: Index data only
- **No mixing** of different data types

### **2. Accurate Time Tracking:**
- **All timestamps**: IST time consistently
- **Market hours**: Proper detection (9:15 AM - 3:30 PM)
- **Change tracking**: Real-time with exact timestamps

### **3. Automatic Operations:**
- **Spot data collection**: Every minute
- **LC/UC change detection**: Real-time
- **Excel export**: Automatic when changes occur
- **BusinessDate calculation**: Using proper spot data

### **4. Complete Audit Trail:**
- **All changes tracked**: With timestamps
- **Historical data**: Preserved for analysis
- **Context data**: Spot data included with changes

---

## 🎯 **Ready for Service Start:**

**All tables are now empty and ready for fresh data collection. The service will:**
1. **Preserve INDEX instruments** during reload
2. **Collect options data** every minute → MarketQuotes table
3. **Collect spot data** every minute → SpotData table
4. **Track LC/UC changes** in real-time → CircuitLimitChanges table
5. **Export Excel files** automatically when changes occur
6. **Calculate BusinessDate** using proper spot data

**The system is ready for a fresh start with proper data separation and accurate time tracking!** 🚀




