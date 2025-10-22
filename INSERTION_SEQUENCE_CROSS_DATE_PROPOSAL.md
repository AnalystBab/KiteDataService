# InsertionSequence - Cross-Date Incremental Tracking

## 📋 **CURRENT IMPLEMENTATION (PROBLEM)**

### **Current Primary Key:**
```csharp
PK: (BusinessDate, TradingSymbol, InsertionSequence)
```

### **Current Behavior:**
```
NIFTY 25100 CE (Expiry: 2025-10-24)

BusinessDate    InsertionSequence  LC     UC      ❌ WRONG
2025-10-07      1                  500    700     ← Oct 7: Initial
2025-10-07      2                  480    720     ← Oct 7: Change #1
2025-10-08      1                  460    740     ← Oct 8: RESET TO 1 (WRONG!)
2025-10-08      2                  440    760     ← Oct 8: Change #1
```

**Problem**: `InsertionSequence` resets to 1 every business date!

---

## ✅ **YOUR REQUIREMENT (CORRECT)**

### **Desired Behavior:**
```
NIFTY 25100 CE (Expiry: 2025-10-24)

BusinessDate    InsertionSequence  LC     UC      ✅ CORRECT
2025-10-07      1                  500    700     ← Initial load
2025-10-07      2                  480    720     ← Change #1
2025-10-08      3                  460    740     ← Change #2 (continuous!)
2025-10-09      4                  440    760     ← Change #3
2025-10-10      5                  420    780     ← Change #4
...until expiry (2025-10-24)
```

**Goal**: `InsertionSequence` increments **continuously** across all business dates until instrument expires!

---

## 🔧 **SOLUTION OPTIONS**

### **OPTION 1: Change Primary Key (BEST - But Requires Migration)**

**New Primary Key:**
```csharp
PK: (TradingSymbol, ExpiryDate, InsertionSequence)
```

**Rationale**:
- `TradingSymbol + ExpiryDate` uniquely identifies an instrument contract
- `InsertionSequence` increments across all business dates for that contract
- Once contract expires, sequence stops (natural boundary)

**Required Changes:**
1. Change `MarketQuote` PK from `(BusinessDate, TradingSymbol, InsertionSequence)` to `(TradingSymbol, ExpiryDate, InsertionSequence)`
2. Update `SaveMarketQuotesAsync()` to calculate max sequence **per (TradingSymbol, ExpiryDate)**
3. Add database migration to update PK
4. Update all queries to filter by `TradingSymbol + ExpiryDate` instead of `BusinessDate + TradingSymbol`

**Pros:**
- ✅ Perfect alignment with your requirement
- ✅ Natural expiry boundary
- ✅ Easy to query "all changes for NIFTY 25100 CE Oct expiry"

**Cons:**
- ❌ Requires database migration (can lose data if not careful)
- ❌ Need to update ALL existing queries

---

### **OPTION 2: Add Global Sequence Column (EASIER - No PK Change)**

**Keep Current PK, Add New Column:**
```csharp
PK: (BusinessDate, TradingSymbol, InsertionSequence)  ← Keep as-is
New Column: GlobalSequence (int)  ← Add this
```

**Logic:**
```csharp
// For each strike/expiry combination
var lastGlobalSeq = await context.MarketQuotes
    .Where(q => q.TradingSymbol == symbol && q.ExpiryDate == expiry)
    .MaxAsync(q => (int?)q.GlobalSequence) ?? 0;

newQuote.GlobalSequence = lastGlobalSeq + 1;
newQuote.InsertionSequence = dailySequence; // Keep existing logic
```

**Data Example:**
```
TradingSymbol      BusinessDate  InsertionSeq  GlobalSeq  LC    UC
NIFTY25OCT25100CE  2025-10-07    1             1          500   700
NIFTY25OCT25100CE  2025-10-07    2             2          480   720
NIFTY25OCT25100CE  2025-10-08    1             3          460   740  ← See the difference!
NIFTY25OCT25100CE  2025-10-08    2             4          440   760
```

**Pros:**
- ✅ No PK change required
- ✅ Backward compatible with existing queries
- ✅ Easy to implement
- ✅ Can use `GlobalSequence` for your analysis

**Cons:**
- ❌ Have two sequence columns (might be confusing)
- ❌ Slight redundancy in data

---

### **OPTION 3: Change InsertionSequence Logic Only (RISKY)**

**Keep PK, Change How InsertionSequence is Calculated:**

**Current:**
```csharp
var maxSeq = await context.MarketQuotes
    .Where(q => q.BusinessDate == today && q.TradingSymbol == symbol)
    .MaxAsync(q => (int?)q.InsertionSequence) ?? 0;
```

**Change To:**
```csharp
var maxSeq = await context.MarketQuotes
    .Where(q => q.TradingSymbol == symbol && q.ExpiryDate == expiry)
    .MaxAsync(q => (int?)q.InsertionSequence) ?? 0;
```

**BUT THIS BREAKS THE PK!**
```
PK Violation Example:
BusinessDate    TradingSymbol      InsertionSeq  ❌ DUPLICATE PK!
2025-10-07      NIFTY25OCT25100CE  1
2025-10-07      NIFTY25OCT25100CE  2
2025-10-08      NIFTY25OCT25100CE  3  ← Same symbol, sequence 3
2025-10-08      NIFTY25OCT25100CE  4
2025-10-09      NIFTY25OCT25100CE  3  ← DUPLICATE! (2025-10-09, NIFTY25OCT25100CE, 3) vs (2025-10-08, NIFTY25OCT25100CE, 3)
```

**Verdict:** ❌ **NOT VIABLE** - Will cause PK constraint violations!

---

## 💡 **RECOMMENDED APPROACH: OPTION 2 (Add GlobalSequence)**

This is the safest and most flexible approach:

### **Implementation Steps:**

#### **1. Add Column to Database**
```sql
ALTER TABLE MarketQuotes 
ADD GlobalSequence INT NOT NULL DEFAULT 0;

CREATE INDEX IX_MarketQuotes_TradingSymbol_ExpiryDate_GlobalSequence 
ON MarketQuotes(TradingSymbol, ExpiryDate, GlobalSequence);
```

#### **2. Update Model**
```csharp
public class MarketQuote
{
    // Existing PK
    public DateTime BusinessDate { get; set; }
    public string TradingSymbol { get; set; } = string.Empty;
    public int InsertionSequence { get; set; }  // Daily sequence (keeps existing behavior)

    // NEW: Cross-date sequence
    public int GlobalSequence { get; set; }  // Incremental across all dates until expiry

    // ... other properties
}
```

#### **3. Update Save Logic**
```csharp
// Calculate GlobalSequence per strike/expiry
var existingQuotes = await context.MarketQuotes
    .Where(q => q.TradingSymbol == newQuote.TradingSymbol && 
                q.ExpiryDate == newQuote.ExpiryDate)
    .OrderByDescending(q => q.GlobalSequence)
    .FirstOrDefaultAsync();

var nextGlobalSeq = (existingQuotes?.GlobalSequence ?? 0) + 1;
newQuote.GlobalSequence = nextGlobalSeq;

// InsertionSequence stays as daily counter
newQuote.InsertionSequence = dailyInsertionSeq;
```

#### **4. Update Your Queries**
```sql
-- Get all changes for a strike (cross-date)
SELECT * FROM MarketQuotes 
WHERE TradingSymbol = 'NIFTY25OCT25100CE'
  AND ExpiryDate = '2025-10-24'
ORDER BY GlobalSequence;  -- Use GlobalSequence for chronological order

-- Get latest data for a strike
SELECT * FROM MarketQuotes 
WHERE TradingSymbol = 'NIFTY25OCT25100CE'
  AND ExpiryDate = '2025-10-24'
  AND GlobalSequence = (SELECT MAX(GlobalSequence) 
                        FROM MarketQuotes 
                        WHERE TradingSymbol = 'NIFTY25OCT25100CE' 
                          AND ExpiryDate = '2025-10-24');
```

---

## 📊 **COMPARISON TABLE**

| Feature | InsertionSequence (Daily) | GlobalSequence (Cross-Date) |
|---------|---------------------------|----------------------------|
| **Scope** | Resets per BusinessDate | Continuous until expiry |
| **Use Case** | Daily change tracking | Full lifecycle tracking |
| **Max Value** | Usually 1-10 per day | Can be 100+ over contract life |
| **Query** | Filter by BusinessDate | Filter by TradingSymbol + ExpiryDate |
| **Example** | Seq 1-5 on Oct 7, Seq 1-3 on Oct 8 | Seq 1-8 from Oct 7 to Oct 8 |

---

## ✅ **FINAL RECOMMENDATION**

**Implement OPTION 2**: Add `GlobalSequence` column

**Why?**
1. ✅ Minimal code changes
2. ✅ No PK migration required
3. ✅ Backward compatible
4. ✅ Meets your requirement perfectly
5. ✅ Can be implemented in 1 hour

**Would you like me to implement this solution?**

