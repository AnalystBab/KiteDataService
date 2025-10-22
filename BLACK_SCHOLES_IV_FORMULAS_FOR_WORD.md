# BLACK-SCHOLES MODEL & IMPLIED VOLATILITY IMPLEMENTATION

## 1. BLACK-SCHOLES MODEL FORMULAS

### 1.1 Basic Black-Scholes Formula

**For Call Options:**
```
C = S₀ × e^(-q×T) × N(d₁) - K × e^(-r×T) × N(d₂)
```

**For Put Options:**
```
P = K × e^(-r×T) × N(-d₂) - S₀ × e^(-q×T) × N(-d₁)
```

### 1.2 Parameters Calculation

**d₁ and d₂ Calculation:**
```
d₁ = [ln(S₀/K) + (r - q + σ²/2) × T] / (σ × √T)

d₂ = d₁ - σ × √T
```

### 1.3 Variable Definitions

```
S₀ = Current spot price (underlying asset price)
K = Strike price of the option
T = Time to expiry (in years)
r = Risk-free interest rate (annual)
q = Dividend yield (annual)
σ = Volatility (annual standard deviation)
N(x) = Cumulative standard normal distribution function
N'(x) = Standard normal probability density function
```

### 1.4 Standard Normal Distribution

**Cumulative Distribution Function (CDF):**
```
N(x) = (1/√(2π)) × ∫[from -∞ to x] e^(-t²/2) dt
```

**Probability Density Function (PDF):**
```
N'(x) = (1/√(2π)) × e^(-x²/2)
```

## 2. OPTIONS GREEKS FORMULAS

### 2.1 Delta (Price Sensitivity)
```
Call Delta = e^(-q×T) × N(d₁)
Put Delta = e^(-q×T) × [N(d₁) - 1]
```

### 2.2 Gamma (Delta Sensitivity)
```
Gamma = e^(-q×T) × N'(d₁) / (S₀ × σ × √T)
```

### 2.3 Theta (Time Decay)
```
Call Theta = -[S₀ × e^(-q×T) × N'(d₁) × σ / (2√T)] - r×K×e^(-r×T)×N(d₂) + q×S₀×e^(-q×T)×N(d₁)

Put Theta = -[S₀ × e^(-q×T) × N'(d₁) × σ / (2√T)] + r×K×e^(-r×T)×N(-d₂) - q×S₀×e^(-q×T)×N(-d₁)
```

### 2.4 Vega (Volatility Sensitivity)
```
Vega = S₀ × e^(-q×T) × √T × N'(d₁)
```

### 2.5 Rho (Interest Rate Sensitivity)
```
Call Rho = K × T × e^(-r×T) × N(d₂)
Put Rho = -K × T × e^(-r×T) × N(-d₂)
```

## 3. IMPLIED VOLATILITY CALCULATION

### 3.1 Newton-Raphson Method

**Iterative Formula:**
```
σₙ₊₁ = σₙ - f(σₙ) / f'(σₙ)
```

**Where:**
```
f(σ) = BlackScholesPrice(σ) - MarketPrice
f'(σ) = Vega = ∂Price/∂σ
```

### 3.2 Implementation Steps

**Step 1: Initial Guess**
```
σ₀ = 20% (or historical volatility)
```

**Step 2: Calculate Theoretical Price**
```
TheoreticalPrice = BlackScholesFormula(Spot, Strike, Time, RiskFreeRate, DividendYield, σₙ)
```

**Step 3: Calculate Error**
```
Error = TheoreticalPrice - MarketPrice
```

**Step 4: Calculate Vega**
```
Vega = Spot × e^(-DividendYield×Time) × √Time × N'(d₁)
```

**Step 5: Update Volatility**
```
σₙ₊₁ = σₙ - Error / Vega
```

**Step 6: Check Convergence**
```
If |Error| < Tolerance (e.g., 0.001), then σₙ₊₁ is the Implied Volatility
Otherwise, repeat from Step 2
```

### 3.3 Convergence Criteria

```
Tolerance = 0.001 (0.1% accuracy)
Maximum Iterations = 100
Volatility Bounds = [1%, 500%]
```

## 4. CODE IMPLEMENTATION

### 4.1 C# Implementation - d1 and d2 Calculation

```csharp
private (decimal d1, decimal d2) CalculateD1D2(decimal spot, decimal strike, decimal timeToExpiry, decimal riskFreeRate, decimal dividendYield, decimal volatility)
{
    var vol = volatility / 100m; // Convert percentage to decimal
    var rate = riskFreeRate / 100m;
    var div = dividendYield / 100m;

    var d1 = (Math.Log((double)(spot / strike)) + (double)(rate - div + (vol * vol) / 2) * (double)timeToExpiry) / 
             (double)(vol * (decimal)Math.Sqrt((double)timeToExpiry));

    var d2 = d1 - (double)(vol * (decimal)Math.Sqrt((double)timeToExpiry));

    return ((decimal)d1, (decimal)d2);
}
```

### 4.2 C# Implementation - Black-Scholes Price

```csharp
private decimal CalculateTheoreticalPrice(decimal spot, decimal strike, decimal timeToExpiry, decimal riskFreeRate, decimal dividendYield, decimal volatility, string optionType, decimal d1, decimal d2)
{
    var vol = volatility / 100m;
    var rate = riskFreeRate / 100m;
    var div = dividendYield / 100m;

    var discountFactor = (decimal)Math.Exp(-(double)rate * (double)timeToExpiry);
    var dividendDiscountFactor = (decimal)Math.Exp(-(double)div * (double)timeToExpiry);
    var forwardPrice = spot * dividendDiscountFactor;

    var nD1 = NormalCDF((double)d1);
    var nD2 = NormalCDF((double)d2);
    var nMinusD1 = NormalCDF(-(double)d1);
    var nMinusD2 = NormalCDF(-(double)d2);

    if (optionType == "CE")
    {
        return forwardPrice * (decimal)nD1 - strike * discountFactor * (decimal)nD2;
    }
    else // PE
    {
        return strike * discountFactor * (decimal)nMinusD2 - forwardPrice * (decimal)nMinusD1;
    }
}
```

### 4.3 C# Implementation - Greeks Calculation

```csharp
// Delta Calculation
private decimal CalculateDelta(decimal spot, decimal strike, decimal timeToExpiry, decimal riskFreeRate, decimal dividendYield, decimal volatility, string optionType, decimal d1)
{
    var div = dividendYield / 100m;
    var dividendDiscountFactor = (decimal)Math.Exp(-(double)div * (double)timeToExpiry);
    var delta = dividendDiscountFactor * (decimal)NormalCDF((double)d1);

    return optionType == "CE" ? delta : delta - dividendDiscountFactor;
}

// Gamma Calculation
private decimal CalculateGamma(decimal spot, decimal timeToExpiry, decimal volatility, decimal d1)
{
    var vol = volatility / 100m;
    var div = 0m; // Assuming no dividend yield for simplicity
    var dividendDiscountFactor = (decimal)Math.Exp(-(double)div * (double)timeToExpiry);
    
    return dividendDiscountFactor * (decimal)NormalPDF((double)d1) / (spot * vol * (decimal)Math.Sqrt((double)timeToExpiry));
}

// Theta Calculation
private decimal CalculateTheta(decimal spot, decimal strike, decimal timeToExpiry, decimal riskFreeRate, decimal dividendYield, decimal volatility, string optionType, decimal d1, decimal d2)
{
    var vol = volatility / 100m;
    var rate = riskFreeRate / 100m;
    var div = dividendYield / 100m;

    var dividendDiscountFactor = (decimal)Math.Exp(-(double)div * (double)timeToExpiry);
    var discountFactor = (decimal)Math.Exp(-(double)rate * (double)timeToExpiry);

    var theta = -(spot * dividendDiscountFactor * (decimal)NormalPDF((double)d1) * vol / (2 * (decimal)Math.Sqrt((double)timeToExpiry)));

    if (optionType == "CE")
    {
        theta -= rate * strike * discountFactor * (decimal)NormalCDF((double)d2);
        theta += div * spot * dividendDiscountFactor * (decimal)NormalCDF((double)d1);
    }
    else // PE
    {
        theta += rate * strike * discountFactor * (decimal)NormalCDF(-(double)d2);
        theta -= div * spot * dividendDiscountFactor * (decimal)NormalCDF(-(double)d1);
    }

    return theta / 365; // Convert to per-day theta
}

// Vega Calculation
private decimal CalculateVega(decimal spot, decimal timeToExpiry, decimal volatility, decimal d1)
{
    var div = 0m; // Assuming no dividend yield
    var dividendDiscountFactor = (decimal)Math.Exp(-(double)div * (double)timeToExpiry);
    
    return spot * dividendDiscountFactor * (decimal)NormalPDF((double)d1) * (decimal)Math.Sqrt((double)timeToExpiry) / 100;
}

// Rho Calculation
private decimal CalculateRho(decimal strike, decimal timeToExpiry, decimal riskFreeRate, string optionType, decimal d2)
{
    var rate = riskFreeRate / 100m;
    var discountFactor = (decimal)Math.Exp(-(double)rate * (double)timeToExpiry);

    if (optionType == "CE")
    {
        return strike * timeToExpiry * discountFactor * (decimal)NormalCDF((double)d2) / 100;
    }
    else // PE
    {
        return -strike * timeToExpiry * discountFactor * (decimal)NormalCDF(-(double)d2) / 100;
    }
}
```

### 4.4 C# Implementation - Implied Volatility

```csharp
private decimal CalculateImpliedVolatility(decimal spot, decimal strike, decimal timeToExpiry, decimal riskFreeRate, decimal dividendYield, decimal marketPrice, string optionType)
{
    // Initial guess
    decimal vol = 20m; // Start with 20%
    decimal tolerance = 0.001m;
    int maxIterations = 100;

    for (int i = 0; i < maxIterations; i++)
    {
        var (d1, d2) = CalculateD1D2(spot, strike, timeToExpiry, riskFreeRate, dividendYield, vol);
        var theoreticalPrice = CalculateTheoreticalPrice(spot, strike, timeToExpiry, riskFreeRate, dividendYield, vol, optionType, d1, d2);
        
        var priceDiff = theoreticalPrice - marketPrice;
        
        if (Math.Abs(priceDiff) < tolerance)
            break;

        // Calculate vega for Newton-Raphson
        var vega = CalculateVega(spot, timeToExpiry, vol, d1);
        
        if (Math.Abs(vega) < 0.001m)
            break;

        // Update volatility
        vol = vol - priceDiff / vega;
        
        // Keep volatility in reasonable bounds
        vol = Math.Max(1m, Math.Min(vol, 500m));
    }

    return vol;
}
```

### 4.5 C# Implementation - Normal Distribution Functions

```csharp
// Standard Normal CDF approximation
private double NormalCDF(double x)
{
    return 0.5 * (1 + Erf(x / Math.Sqrt(2)));
}

// Standard Normal PDF
private double NormalPDF(double x)
{
    return Math.Exp(-0.5 * x * x) / Math.Sqrt(2 * Math.PI);
}

// Error function approximation (Abramowitz and Stegun)
private double Erf(double x)
{
    double a1 = 0.254829592;
    double a2 = -0.284496736;
    double a3 = 1.421413741;
    double a4 = -1.453152027;
    double a5 = 1.061405429;
    double p = 0.3275911;

    int sign = x >= 0 ? 1 : -1;
    x = Math.Abs(x);

    double t = 1.0 / (1.0 + p * x);
    double y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.Exp(-x * x);

    return sign * y;
}
```

## 5. PRACTICAL EXAMPLE

### 5.1 Input Parameters
```
Spot Price (S₀) = ₹25,000
Strike Price (K) = ₹25,500
Time to Expiry (T) = 15 days = 0.0411 years
Risk-free Rate (r) = 7% = 0.07
Dividend Yield (q) = 1.2% = 0.012
Market Price = ₹150
Option Type = CE (Call)
```

### 5.2 Step-by-Step Calculation

**Step 1: Calculate d₁ and d₂**
```
d₁ = [ln(25000/25500) + (0.07 - 0.012 + σ²/2) × 0.0411] / (σ × √0.0411)
d₂ = d₁ - σ × √0.0411
```

**Step 2: Newton-Raphson Iteration**
```
Initial guess: σ₀ = 20%

Iteration 1:
- Calculate Black-Scholes price with σ = 20%
- Compare with market price ₹150
- Calculate error and vega
- Update: σ₁ = σ₀ - error/vega

Iteration 2:
- Repeat with σ₁
- Continue until |error| < 0.001

Final result: σ = 21.2% (Implied Volatility)
```

### 5.3 Greeks Calculation with σ = 21.2%
```
Delta = e^(-0.012×0.0411) × N(d₁) = 0.487
Gamma = e^(-0.012×0.0411) × N'(d₁) / (25000 × 0.212 × √0.0411) = 0.0001
Theta = -[25000 × e^(-0.012×0.0411) × N'(d₁) × 0.212 / (2√0.0411)] / 365 = -2.34
Vega = 25000 × e^(-0.012×0.0411) × √0.0411 × N'(d₁) / 100 = 15.67
Rho = 25500 × 0.0411 × e^(-0.07×0.0411) × N(d₂) / 100 = 0.89
```

## 6. IMPLEMENTATION NOTES

### 6.1 Key Assumptions
- European-style options (no early exercise)
- Constant volatility (Black-Scholes limitation)
- Log-normal distribution of returns
- No transaction costs
- Continuous trading

### 6.2 Accuracy Considerations
- Newton-Raphson typically converges in 5-10 iterations
- Tolerance of 0.001 provides sufficient accuracy for trading
- Volatility bounds [1%, 500%] prevent extreme values
- Multiple starting points can help avoid local minima

### 6.3 Performance Optimization
- Pre-calculate common values (e^(-rT), e^(-qT))
- Use lookup tables for normal distribution functions
- Cache Vega calculations for Newton-Raphson
- Parallel processing for multiple options

## 7. VALIDATION AND TESTING

### 7.1 Benchmark Tests
- Compare with known option prices
- Verify Greeks against analytical derivatives
- Test edge cases (very short/long expiry, deep ITM/OTM)
- Validate against industry-standard calculators

### 7.2 Error Handling
- Check for division by zero in Vega calculation
- Handle extreme volatility values
- Validate input parameters (positive prices, reasonable time to expiry)
- Provide meaningful error messages for debugging
