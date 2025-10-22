# 📊 CONSOLIDATED EXCEL EXPORT VISUAL EXAMPLE

## **📁 File Structure:**
```
📁 Exports/
  └── 📁 2025-09-22/
      └── 📄 ConsolidatedLCUCData_20250922.xlsx
          ├── 📊 Sheet: "Expiry_23-09-2025"
          ├── 📊 Sheet: "Expiry_30-09-2025"
          └── 📊 Sheet: "Expiry_07-10-2025"
```

## **📋 Sheet: "Expiry_23-09-2025" - Visual Layout:**

| A | B | C | D | E | F | G | H | I | J | K | L | M | N | O | P | Q | R |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **BusinessDate** | **Expiry** | **Strike** | **OptionType** | **OpenPrice** | **HighPrice** | **LowPrice** | **ClosePrice** | **LastPrice** | **LCUC_TIME_0915** | **LC_0915** | **UC_0915** | **LCUC_TIME_1130** | **LC_1130** | **UC_1130** | **LCUC_TIME_1445** | **LC_1445** | **UC_1445** |
| 22-09-2025 | 23-09-2025 | 24700 | CE | 2.35 | 2.90 | 1.70 | 2.85 | 2.10 | 09:15:00 | 0.05 | 23.40 | 11:30:00 | 0.05 | 25.10 | 14:45:00 | 0.05 | 28.50 |
| 22-09-2025 | 23-09-2025 | 24700 | PE | 1.85 | 2.20 | 1.45 | 2.05 | 1.90 | 09:15:00 | 0.05 | 18.75 | 11:30:00 | 0.05 | 20.25 | 14:45:00 | 0.05 | 22.80 |
| 22-09-2025 | 23-09-2025 | 24750 | CE | 2.50 | 3.10 | 1.80 | 2.95 | 2.25 | 09:15:00 | 0.05 | 24.85 | 11:30:00 | 0.05 | 26.55 | 14:45:00 | 0.05 | 30.20 |
| 22-09-2025 | 23-09-2025 | 24750 | PE | 1.95 | 2.35 | 1.55 | 2.15 | 2.00 | 09:15:00 | 0.05 | 19.80 | 11:30:00 | 0.05 | 21.40 | 14:45:00 | 0.05 | 24.15 |
| 22-09-2025 | 23-09-2025 | 24800 | CE | 2.65 | 3.30 | 1.90 | 3.05 | 2.40 | 09:15:00 | 0.05 | 26.30 | 11:30:00 | 0.05 | 28.00 | 14:45:00 | 0.05 | 31.90 |
| 22-09-2025 | 23-09-2025 | 24800 | PE | 2.05 | 2.50 | 1.65 | 2.25 | 2.10 | 09:15:00 | 0.05 | 20.85 | 11:30:00 | 0.05 | 22.55 | 14:45:00 | 0.05 | 25.50 |
| 22-09-2025 | 23-09-2025 | 24850 | CE | 2.80 | 3.50 | 2.00 | 3.15 | 2.55 | 09:15:00 | 0.05 | 27.75 | 11:30:00 | 0.05 | 29.45 | 14:45:00 | 0.05 | 33.60 |
| 22-09-2025 | 23-09-2025 | 24850 | PE | 2.15 | 2.65 | 1.75 | 2.35 | 2.20 | 09:15:00 | 0.05 | 21.90 | 11:30:00 | 0.05 | 23.70 | 14:45:00 | 0.05 | 26.85 |
| 22-09-2025 | 23-09-2025 | 24900 | CE | 2.95 | 3.70 | 2.10 | 3.25 | 2.70 | 09:15:00 | 0.05 | 29.20 | 11:30:00 | 0.05 | 30.90 | 14:45:00 | 0.05 | 35.30 |
| 22-09-2025 | 23-09-2025 | 24900 | PE | 2.25 | 2.80 | 1.85 | 2.45 | 2.30 | 09:15:00 | 0.05 | 22.95 | 11:30:00 | 0.05 | 24.85 | 14:45:00 | 0.05 | 28.20 |
| 22-09-2025 | 23-09-2025 | 24950 | CE | 3.10 | 3.90 | 2.20 | 3.35 | 2.85 | 09:15:00 | 0.05 | 30.65 | 11:30:00 | 0.05 | 32.35 | 14:45:00 | 0.05 | 37.00 |
| 22-09-2025 | 23-09-2025 | 24950 | PE | 2.35 | 2.95 | 1.95 | 2.55 | 2.40 | 09:15:00 | 0.05 | 24.00 | 11:30:00 | 0.05 | 26.00 | 14:45:00 | 0.05 | 29.55 |
| 22-09-2025 | 23-09-2025 | 25000 | CE | 3.25 | 4.10 | 2.30 | 3.45 | 3.00 | 09:15:00 | 0.05 | 32.10 | 11:30:00 | 0.05 | 33.80 | 14:45:00 | 0.05 | 38.70 |

## **🎯 Key Features Explained:**

### **✅ One Row Per Strike:**
- **NIFTY 25000 CE**: One row showing all LC/UC changes throughout the day
- **NIFTY 25000 PE**: Separate row for Put option
- **Multiple strikes**: 24700, 24750, 24800, 24850, 24900, 24950, 25000, etc.

### **✅ Multiple LC/UC Times:**
- **LCUC_TIME_0915**: Shows 09:15:00 (when first LC/UC was recorded)
- **LC_0915**: Lower Circuit at 09:15 AM
- **UC_0915**: Upper Circuit at 09:15 AM
- **LCUC_TIME_1130**: Shows 11:30:00 (when LC/UC changed)
- **LC_1130**: Lower Circuit at 11:30 AM
- **UC_1130**: Upper Circuit at 11:30 AM
- **LCUC_TIME_1445**: Shows 14:45:00 (when LC/UC changed again)
- **LC_1445**: Lower Circuit at 14:45 PM
- **UC_1445**: Upper Circuit at 14:45 PM

### **✅ Proper DateTime Formatting:**
- **BusinessDate**: 22-09-2025 (dd-mm-yyyy format)
- **Expiry**: 23-09-2025 (dd-mm-yyyy format)
- **LCUC_TIME columns**: 09:15:00 (hh:mm:ss format)

### **✅ No TradingSymbol Column:**
- TradingSymbol column is **excluded** as requested
- Only essential data columns are shown

### **✅ Dynamic Time Columns:**
- Columns are created based on **actual data times**
- If LC/UC changed at 09:15, 11:30, 14:45 → 3 time groups
- If LC/UC changed at 09:15, 15:20 → 2 time groups
- **Flexible** based on actual changes

## **📊 Example Data Interpretation:**

**For NIFTY 25000 CE:**
- **09:15 AM**: LC=0.05, UC=32.10 (Initial values)
- **11:30 AM**: LC=0.05, UC=33.80 (UC increased by 1.70)
- **14:45 PM**: LC=0.05, UC=38.70 (UC increased by 4.90 more)

**This shows LC/UC changed 3 times** for NIFTY 25000 CE on 2025-09-22.

## **🎨 Excel Formatting:**
- **Headers**: Bold, Light Blue background
- **Borders**: Thin borders around all cells
- **Auto-fit**: Columns automatically sized
- **Frozen**: Header row frozen for scrolling
- **Colors**: Professional color scheme

## **📁 File Organization:**
- **One file per business date**: ConsolidatedLCUCData_20250922.xlsx
- **Separate sheets per expiry**: Expiry_23-09-2025, Expiry_30-09-2025, etc.
- **Organized folders**: Exports/2025-09-22/
- **Daily export**: Automatic at 6:00 PM IST

This is exactly what your consolidated Excel export will look like! 🎉


