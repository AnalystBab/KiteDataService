# ⚡ QUICK VERIFICATION GUIDE

## 🎯 **RUN THESE QUERIES AFTER SERVICE STARTS**

---

## ✅ **1. CHECK GLOBALSEQUENCE (MOST CRITICAL)**

```sql
-- Should see continuous increment, NO zeros
SELECT TOP 20
    BusinessDate,
    Strike,
    OptionType,
    InsertionSequence,
    GlobalSequence,
    RecordDateTime
FROM MarketQuotes
WHERE RecordDateTime >= CAST(GETDATE() AS DATE)  -- Today's data
ORDER BY GlobalSequence;

-- ✅ SUCCESS: GlobalSequence = 1, 2, 3, 4, 5, 6...
-- ❌ FAIL: If you see GlobalSequence = 0
```

---

## ✅ **2. CHECK DATABASE EXPORT**

```sql
-- Should have records after Excel files are created
SELECT COUNT(*) AS TotalExports FROM ExcelExportData;

-- ✅ SUCCESS: Count > 0
-- ❌ FAIL: Count = 0 (check logs)
```

---

## ✅ **3. CHECK HISTORICAL ARCHIVAL (After 4:00 PM)**

```sql
-- Should have today's data archived
SELECT 
    TradingDate,
    COUNT(*) AS InstrumentsArchived,
    MAX(ArchivedDate) AS WhenArchived
FROM HistoricalOptionsData
GROUP BY TradingDate
ORDER BY TradingDate DESC;

-- ✅ SUCCESS: See today's date with ~500-1000 instruments
-- ❌ FAIL: Today's date missing (check logs)
```

---

## ✅ **4. VERIFY LAST RECORD CAPTURED**

```sql
-- Compare historical data with MarketQuotes
DECLARE @BusinessDate DATE = (SELECT MAX(TradingDate) FROM HistoricalOptionsData);

SELECT 
    'MarketQuotes LAST' AS Source,
    BusinessDate,
    Strike,
    OptionType,
    GlobalSequence,
    LowerCircuitLimit,
    UpperCircuitLimit,
    RecordDateTime
FROM MarketQuotes
WHERE BusinessDate = @BusinessDate
  AND Strike = 25000
  AND OptionType = 'CE'
  AND GlobalSequence = (
      SELECT MAX(GlobalSequence) 
      FROM MarketQuotes 
      WHERE BusinessDate = @BusinessDate 
        AND Strike = 25000 
        AND OptionType = 'CE'
  )

UNION ALL

SELECT 
    'Historical' AS Source,
    TradingDate AS BusinessDate,
    Strike,
    OptionType,
    NULL AS GlobalSequence,
    LowerCircuitLimit,
    UpperCircuitLimit,
    NULL AS RecordDateTime
FROM HistoricalOptionsData
WHERE TradingDate = @BusinessDate
  AND Strike = 25000
  AND OptionType = 'CE';

-- ✅ SUCCESS: LC/UC values should MATCH between both
-- ❌ FAIL: If values are different
```

---

## 🎊 **ALL GOOD IF:**

✅ GlobalSequence increments (no zeros)
✅ ExcelExportData has records
✅ HistoricalOptionsData has today's data (after 4 PM)
✅ LC/UC values match between MarketQuotes and Historical
✅ No errors in service logs

**Then everything is working perfectly!** 🚀

