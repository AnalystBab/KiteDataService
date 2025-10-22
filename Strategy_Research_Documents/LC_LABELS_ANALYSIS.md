# 🔍 LC LABELS ANALYSIS - Lower Circuit Patterns

## 🎯 **NEW LC-BASED LABELS (28-34)**

---

## **LABEL 28: CALL_BASE_PUT_BASE_LC_DIFFERENCE**

### **Hypothesis:**
```
Similar to Label 24 (UC difference = 318 pattern)
LC difference might predict LOW premium levels!
```

### **Calculation from D0 (9th Oct):**
```
CALL_BASE_STRIKE: 79,600 CE
  LC = 193.10
  UC = 5,133.00

PUT_BASE_STRIKE: 84,700 PE
  LC = 68.10
  UC = 4,815.50

FORMULA: CALL_BASE_LC - PUT_BASE_LC
CALCULATION: 193.10 - 68.10 = 125.00 ⚡

LABEL 28 VALUE: 125.00
```

### **What to Test:**
```
1. Does 125 appear as premium LOW on D1?
2. Do strikes trade near 125 Rs at their lows?
3. Is 125 related to entry points?
```

---

## **LABEL 29: CLOSE_CE_LC_D0**

### **Calculation from D0:**
```
CLOSE_STRIKE: 82,100 CE
Query: SELECT LowerCircuitLimit 
       FROM MarketQuotes 
       WHERE Strike = 82100 AND OptionType = 'CE'

VALUE: Need to check (typically 0.05 for OTM/ATM)
```

---

## **LABEL 30: CLOSE_PE_LC_D0**

### **Calculation from D0:**
```
CLOSE_STRIKE: 82,100 PE
Query: SELECT LowerCircuitLimit 
       FROM MarketQuotes 
       WHERE Strike = 82100 AND OptionType = 'PE'

VALUE: Need to check (typically 0.05 for OTM/ATM)
```

---

## **LABEL 31: LC_MINUS_DISTANCE**

### **Hypothesis:**
```
Similar to CALL_MINUS_TO_CALL_BASE_DISTANCE (579)
But using LC values instead of calculated C- value
```

### **Calculation:**
```
CLOSE_CE_LC: (to be queried)
CALL_BASE_LC: 193.10

FORMULA: CALL_BASE_LC - CLOSE_CE_LC
Purpose: LC-based distance calculation
```

---

## **LABEL 32: TARGET_CE_LC_PREMIUM**

### **Calculation:**
```
Similar to TARGET_CE_PREMIUM (Label 20)
But for LC values

FORMULA: CLOSE_CE_LC + some distance
Purpose: Find LC-based targets
```

---

## **LABEL 33: MIN_PREMIUM_AT_SPOT_LOW**

### **Calculation:**
```
When spot reaches predicted LOW (82,073):
  Which strike is ATM?
  82,000 or 82,100
  
  ATM strike intrinsic = Spot - Strike
  For 82000: 82,073 - 82,000 = 73
  
  Minimum premium = Intrinsic + small time value
  = 73 + time value

Question: What's the time value at spot low?
Can we predict this from D0?
```

---

## **LABEL 34: STRIKE_LOW_PREMIUM_TARGET**

### **For specific strike (e.g., 82000 CE):**
```
D1 Actual: 82000 CE LOW = 500

From D0, which UC matches 500?
Scan: Find strikes where UC ≈ 500

Need to query D0 data...
```

Let me query and find the patterns!

