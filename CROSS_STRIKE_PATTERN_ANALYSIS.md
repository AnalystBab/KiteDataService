# Cross-Strike Pattern Analysis from User's Calculation Sheet

## Understanding Cross-Strike Matching

Based on the user's calculation sheet images, here's how cross-strike patterns work:

### Pattern 1: PUT MINUS (Highlighted in Yellow)
```
Row 17: 81800 CE - UC: 5336
Row 18: 87100 PE - UC: 5289, LC: 2.65
```

**Cross-Strike Match:**
- 81800 CE UC (5336) ≈ 87100 PE UC (5289)
- Difference: Only 47 points
- **Logic:** Higher strike PE's UC matches lower strike CE's UC

### Pattern 2: CALL PLUS (Highlighted in Yellow)
```
Row 1: 84400, 87100, 1696, 1420
Row 2: 1696, 86096, 1004, 1004
Row 3: 86096, 1004, 692, 416
```

**Cross-Strike Relationships:**
- Base strike (84400) calculations with other strikes
- UC values being compared across different strikes

### Pattern 3: PUT/PE Orange Highlight
```
Row 22: 83700 PE - UC: 568, LC: 0
```

## Key Insights:

1. **Cross-Strike UC Matching:** One strike's UC matches another strike's UC
2. **Strike Distance Matters:** 2600 point difference (81800 vs 87100) but UC values are close
3. **CE-PE Cross Relationships:** CE UC matching PE UC across different strikes
4. **Premium Transfer Logic:** UC values transfer across strikes with logical relationships

## Real Database Example Found:
```
83200 PE UC: 1199.90
85800 PE Low: 1200.00
Difference: 0.10 (Perfect Match!)
```

**This is the pattern you're looking for:**
- One PE strike's UC (83200 PE) = Another PE strike's Low (85800 PE)
- Cross-strike premium transfer/relationship
- 2600 point strike difference but price relationship maintained

## Pattern Discovery Logic Needed:

1. **UC Cross-Matching:** Find where UC of Strike A matches Low of Strike B
2. **Strike Distance Analysis:** Calculate relationships between different strike distances
3. **Premium Transfer Formulas:** Derive why certain strikes have UC relationships
4. **CE-PE Cross Relationships:** Find CE UC matching PE UC patterns

This is MUCH more sophisticated than same-strike patterns!






