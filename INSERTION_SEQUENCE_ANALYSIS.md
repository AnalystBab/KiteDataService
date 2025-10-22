# InsertionSequence Analysis - Why Some Strikes Have Sequence 2 and Others Don't

## 🎯 **Answer to Your Question:**

### **❓ Why does 85000 strike only have InsertionSequence = 1?**

**Answer**: Because the 85000 strike options did NOT have LC/UC changes that triggered InsertionSequence = 2.

## 📊 **Complete Analysis:**

### **✅ Strikes WITH InsertionSequence = 2 (LC/UC Changes):**
```
75000, 76000, 77000, 77500, 78200, 78300, 78400, 78500, 78600, 
78700, 78800, 78900, 79000, 79100, 79200, 79300, 79400, 79500, 
79600, 79700, 90000
```
**Total**: 21 strikes with LC/UC changes

### **❌ Strikes WITHOUT InsertionSequence = 2 (No LC/UC Changes):**
```
24450-91500 (all other strikes including 85000)
```
**Total**: 246 strikes with NO LC/UC changes

## 🔍 **Why This Happens:**

### **InsertionSequence Logic:**
1. **InsertionSequence = 1**: Initial data capture
2. **InsertionSequence = 2**: LC/UC values changed, new data inserted

### **For 85000 Strike:**
- **SENSEX2591885000PE**: LC = 31.55, UC = 5368.35 (InsertionSequence = 1)
- **SENSEX2591885000CE**: LC = 0.05, UC = 20.05 (InsertionSequence = 1)
- **No changes detected**: LC/UC values remained stable
- **Result**: Only InsertionSequence = 1 exists

### **For 78200 Strike (Example with changes):**
- **SENSEX2591878200PE**: 
  - InsertionSequence = 1: LC = 0.10, UC = 20.05
  - InsertionSequence = 2: LC = 0.05, UC = 20.05 (LC changed from 0.10 to 0.05)
- **Result**: Both InsertionSequence 1 and 2 exist

## 📈 **Change Pattern Analysis:**

### **LC/UC Changes Only Affected Specific Strikes:**
- **Range**: 75000-79700 and 90000
- **Pattern**: Mostly lower strikes (75000-79700)
- **High strikes**: Only 90000 had changes
- **Missing**: 85000 and other high strikes had NO changes

### **Possible Reasons:**
1. **Market Activity**: Only certain strikes had active trading
2. **LC/UC Updates**: Exchange only updated circuit limits for specific strikes
3. **Data Timing**: Changes occurred only for certain strike ranges
4. **Trading Volume**: Higher volume strikes got LC/UC updates

## 🎯 **Your Specific Case (85000 Strike):**

### **Data Summary:**
```
SENSEX2591885000PE (85000 PE):
- InsertionSequence: 1 only
- LC: 31.55 (stable)
- UC: 5368.35 (stable)
- No changes detected

SENSEX2591885000CE (85000 CE):
- InsertionSequence: 1 only  
- LC: 0.05 (stable)
- UC: 20.05 (stable)
- No changes detected
```

### **Why No InsertionSequence = 2:**
- **LC/UC values remained constant** throughout the day
- **No circuit limit changes** occurred for 85000 strike
- **Market conditions** didn't trigger updates for this strike
- **Exchange rules** may not have required updates for this strike

## ✅ **Conclusion:**

**InsertionSequence = 2 exists ONLY when LC/UC values actually change.**

- **85000 strike**: No LC/UC changes → Only InsertionSequence = 1
- **78200 strike**: LC/UC changed → Both InsertionSequence 1 and 2
- **21 strikes**: Had LC/UC changes → Multiple insertion sequences
- **246 strikes**: No LC/UC changes → Single insertion sequence

**The system is working correctly - it only creates InsertionSequence = 2 when actual LC/UC changes are detected!**

---

**Status**: ✅ **ANALYSIS COMPLETE**
**Result**: 85000 strike had no LC/UC changes, so only InsertionSequence = 1 exists
**System**: Working correctly - only creates InsertionSequence = 2 when changes occur




