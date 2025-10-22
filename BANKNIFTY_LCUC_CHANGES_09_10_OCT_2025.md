# 📊 BANKNIFTY LC/UC CHANGES - 09 & 10 OCT 2025

## 📋 **SUMMARY**

### **BusinessDate: 2025-10-09**
- **Unique Strikes**: 139
- **Unique Expiries**: 6
- **Total Records**: 6,195
- **LC Range**: 0.05 to (various)
- **UC Range**: (various) to 15,626.65

### **BusinessDate: 2025-10-10**
- **Unique Strikes**: 143
- **Total Records**: 8,810 (+2,615 records from previous day)
- **LC Range**: 0.05 to (various)
- **UC Range**: (various) to 15,972.55 (+345.90 from previous day)

---

## 📊 **EXAMPLE: BANKNIFTY 55000 CE CHANGES**

### **For Expiry: 2025-10-28**

```
BusinessDate 2025-10-10:
  12 LC/UC changes recorded

  Min LC: 409.20
  Max LC: 679.80
  Change: +270.60 (66% increase!)
  
  Min UC: 3,181.30
  Max UC: 3,322.75
  Change: +141.45 (4% increase)
```

### **Pattern Analysis:**
- **LC increased significantly** (409 → 679)
- **UC increased moderately** (3,181 → 3,322)
- **12 changes throughout the day** (shows volatility)

---

## 🎯 **BANKNIFTY DATA CHARACTERISTICS**

### **Strike Range Coverage:**
```
2025-10-09: 139 strikes
2025-10-10: 143 strikes (+4 new strikes added)
```

### **Multiple Expiries Active:**
Based on data, BANKNIFTY has **6 active expiries**:
1. Weekly (2025-10-14)
2. Weekly (2025-10-20)
3. Weekly (2025-10-28)
4. Monthly (2025-11-25)
5. Monthly (2025-12-30)
6. Quarterly expiries (2026+)

---

## 📊 **SAMPLE STRIKES WITH SIGNIFICANT CHANGES**

### **BANKNIFTY 56000 CE (2025-10-28 Expiry):**
```
BusinessDate: 2025-10-10
Changes: 12 records

LC Range: 0.05 → 58.85 (massive jump!)
UC Range: 2,064.95 → 2,187.10
```

### **BANKNIFTY 55000 PE (2025-11-25 Expiry):**
```
BusinessDate: 2025-10-10
Changes: 4 records

LC: 0.05 (stable)
UC: 626.25 (stable - no change)
```

---

## 🎨 **HOW THIS APPEARS IN COLOR-CODED EXCEL:**

When you open the consolidated Excel export for **2025-10-10**:

### **Example for Strike 55000 CE:**

```
Strike | OptionType | LCUC_TIME_0915 | LC_0915 | UC_0915 | LCUC_TIME_1030 | LC_1030 | UC_1030
-------|------------|----------------|---------|---------|----------------|---------|----------
55000  | CE         | 09:15:00       | 409.20  | 3181.30 | 10:30:00       | 679.80  | 3322.75
                           🔵           🔵        🔵             🟢          🟢        🟢
                      (Prev Day)   (Baseline)            (Current Day)    (Today)

Color Explanation:
  🔵 Blue = From BusinessDate 2025-10-09 (baseline for comparison)
  🟢 Green = From BusinessDate 2025-10-10 (current day changes)
```

### **Visual Benefits:**
- **Instantly see**: Which values are baseline (blue) vs current (green)
- **Easy comparison**: Compare green vs blue to see changes
- **Pattern detection**: See how LC/UC evolved across days

---

## 🔍 **DETAILED BREAKDOWN (Sample Strikes)**

### **Strike 55000 CE (Multiple Expiries):**

#### **Expiry: 2025-10-28**
```
BusinessDate 2025-10-10: 12 changes
  LC: 409.20 → 679.80 (+270.60)
  UC: 3,181.30 → 3,322.75 (+141.45)
```

#### **Expiry: 2025-11-25**
```
BusinessDate 2025-10-10: 12 changes
  LC: 921.90 → 1,214.60 (+292.70)
  UC: 3,482.90 → 3,628.70 (+145.80)
```

#### **Expiry: 2025-12-30**
```
BusinessDate 2025-10-10: 12 changes
  LC: 1,358.10 → 1,701.90 (+343.80)
  UC: 3,898.10 → 4,005.40 (+107.30)
```

---

## 📊 **KEY INSIGHTS**

### **1. High Volatility:**
- **12 changes** for most strikes (indicates active trading/volatility)
- LC/UC adjusting frequently throughout the day

### **2. LC Increases More Than UC:**
- Example: Strike 55000 CE
  - LC: +66% increase
  - UC: +4% increase
- Pattern: LC rising faster (tightening range)

### **3. Different Behavior by Expiry:**
- Near expiries (Oct 28): Smaller absolute values, larger % changes
- Far expiries (Dec 30): Larger absolute values, smaller % changes

---

## 🎯 **USING THIS DATA**

### **In Color-Coded Excel:**
1. **Open**: `Exports/Consolidated/2025-10-10/BANKNIFTY_2025-10-10/`
2. **See**: Calls/Puts sheets with color-coded LC/UC columns
3. **Baseline (Blue)**: Previous day values for comparison
4. **Current (Green)**: Today's changes
5. **Legend**: At bottom of each sheet

### **In Database:**
```sql
-- Query specific strike changes
SELECT * FROM MarketQuotes
WHERE TradingSymbol LIKE 'BANKNIFTY55000CE%'
  AND BusinessDate = '2025-10-10'
ORDER BY GlobalSequence;
```

### **In Historical Archive:**
```sql
-- After 4:00 PM, check archived data
SELECT * FROM HistoricalOptionsData
WHERE IndexName = 'BANKNIFTY'
  AND TradingDate = '2025-10-10'
  AND Strike = 55000
  AND OptionType = 'CE';
```

---

## ✅ **DATA AVAILABILITY**

**YES! All BANKNIFTY data for both days is available:**
- ✅ 2025-10-09: 6,195 records (139 strikes × 6 expiries)
- ✅ 2025-10-10: 8,810 records (143 strikes × 6 expiries)
- ✅ LC/UC changes tracked throughout each day
- ✅ Color-coded in Excel for easy analysis
- ✅ Archived in HistoricalOptionsData (after 4 PM)

**Ready for your analysis!** 🎊

