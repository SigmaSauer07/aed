# USD Pricing Implementation - Summary

## Problem
Contracts were using hardcoded MATIC values (e.g., `1 ether`, `2 ether`) when they should have been using USD-pegged pricing. At current MATIC prices (~$0.45), this meant:
- Badge fee was $0.90 instead of $2.00
- TLD fees were $0.45 instead of $1.00
- All prices were off by ~50-80%

## Solution
Implemented Chainlink oracle integration for real-time USD-to-MATIC conversion:

### 1. New LibPricing Library
**Location:** `contracts/libraries/LibPricing.sol`

**Features:**
- Uses Chainlink MATIC/USD price feed (Polygon Amoy testnet)
- 5-minute price caching to save gas
- Fallback price mechanism ($0.45 default) if oracle fails
- Sanity checks (price must be $0.10-$10.00 range)
- Admin can manually set fallback price

**Key Functions:**
```solidity
usdToMatic(uint256 usdCents) → uint256 maticAmount
getCachedPrice() → uint256 priceInCents
setFallbackPrice(uint256 priceInCents) → void
```

### 2. Updated Constants
**File:** `contracts/core/AEDConstants.sol`

**Added:**
```solidity
uint256 public constant MAX_BADGES = 10;                      // NEW: 10 badge limit

// All prices in USD cents (100 = $1.00)
uint256 public constant BASE_BADGE_FEE_CENTS = 100;           // $1.00
uint256 public constant BASE_CAPABILITY_FEE_CENTS = 100;      // $1.00
uint256 public constant BASE_SUBDOMAIN_FEE_CENTS = 10;        // $0.10
uint256 public constant SUBDOMAIN_ENHANCEMENT_FEE_CENTS = 200; // $2.00
uint256 public constant PAID_TLD_FEE_CENTS = 100;             // $1.00
uint256 public constant BYO_DOMAIN_FEE_CENTS = 500;           // $5.00
```

### 3. Updated LibAISubdomains
**Changes:**
- Removed hardcoded `BASE_BADGE_FEE = 2 ether`
- Added **10-badge limit enforcement** (CRITICAL FIX)
- `calculateAISubdomainFee()` now returns MATIC amount after USD conversion
- `calculateCapabilityFee()` now returns MATIC amount after USD conversion
- Both functions are now `internal` (not `internal view`) since they call pricing oracle

**Badge Limit Check:**
```solidity
uint256 badgeCount = _countBadgesUnderParent(s, parentDomain);
require(badgeCount < AEDConstants(address(this)).MAX_BADGES(), "Max badges reached");
```

### 4. Updated LibMinting
**Changes:**
- `calculateSubdomainFee()` now uses USD pricing with formula: `$0.10 × 2^(n-3)`
- Removed hardcoded `baseFee = 0.1 ether` logic
- Converts USD to MATIC using `LibPricing.usdToMatic()`
- Function signature changed to `internal` (not `internal view`)

### 5. Updated LibEnhancements
**Changes:**
- `purchaseFeature()` converts USD cents to MATIC before charging
- `upgradeExternalDomain()` converts BYO price ($5.00) to MATIC
- All enhancement prices stored in USD cents, converted at payment time

### 6. Updated AEDImplementation
**Changes:**
- Added import for `LibPricing`
- `_calculateDomainCost()` converts USD to MATIC
- Changed from `internal view` to `internal` (non-view)
- Initialization sets prices in USD cents (not ether)

**New Admin Functions:**
```solidity
function setMaticPriceFallback(uint256 priceInCents) external onlyAdmin
function getMaticPrice() external view returns (uint256)
```

### 7. Fixed AppStorage Syntax
**File:** `contracts/core/AppStorage.sol`

Added missing semicolons:
```solidity
mapping(uint256 => string) aiModelType;
mapping(uint256 => bool) isAISubdomain;
mapping(uint256 => bool) badgeTransferLocked;
mapping(uint256 => mapping(string => bool)) aiCapabilities;
```

## Price Conversion Examples

At current MATIC price of $0.45:

| Feature | USD Price | MATIC Amount |
|---------|-----------|--------------|
| 1st Badge | $1.00 | ~2.22 MATIC |
| 2nd Badge | $2.00 | ~4.44 MATIC |
| 3rd Badge | $4.00 | ~8.89 MATIC |
| TLD (paid) | $1.00 | ~2.22 MATIC |
| 3rd Subdomain | $0.10 | ~0.22 MATIC |
| 4th Subdomain | $0.20 | ~0.44 MATIC |
| Subdomain Enhancement | $2.00 | ~4.44 MATIC |

## Chainlink Integration

**Oracle Address (Polygon Amoy):** `0x001382149eBa3441043c1c66972b4772963f5D43`

**Price Feed:**
- Returns MATIC/USD price with 8 decimals
- Example: `45000000` = $0.45
- Converted to cents: `45000000 / 1e6 = 45 cents`

**Caching:**
- Price cached for 5 minutes
- Reduces gas costs for sequential operations
- Auto-refreshes when cache expires

**Fallback:**
- If oracle fails or returns invalid price, uses $0.45 default
- Admin can update fallback via `setMaticPriceFallback()`
- Valid range: $0.10 - $10.00 per MATIC

## Breaking Changes

### For Frontend:
1. **View functions changed to state-modifying:**
   - `calculateSubdomainFee(uint256)` - now non-view
   - `calculateAISubdomainFee(uint256)` - now non-view
   - `calculateCapabilityFee(uint256)` - now non-view
   - `_calculateDomainCost(string, bool)` - now non-view

   **Impact:** These functions now update price cache state. Frontend should handle this (most web3 libraries do automatically).

2. **All admin-set prices must be in USD cents:**
   - `configureTLD(tld, active, 100)` = $1.00
   - `setFeaturePrice("subdomain", 200)` = $2.00
   - NOT in MATIC/ether anymore

### For Tests:
- Update all price assertions to expect MATIC amounts, not USD
- Mock Chainlink oracle or use fallback price for predictable tests
- Account for price oracle calls in gas estimates

## Migration Guide

### Redeploying:
1. Deploy new implementation with all changes
2. Initialize with admin address
3. Oracle will use fallback price ($0.45) initially
4. Price cache fills automatically on first payment
5. Monitor `PriceUpdated` events for oracle health

### If Upgrading Existing Deployment:
⚠️ **CRITICAL:** This is a major storage layout change. You CANNOT upgrade existing proxy.
Must redeploy entire system (proxy + implementation).

## Testing Checklist

- [ ] Badge limit enforced (10 max per domain)
- [ ] Subdomain limit still works (20 max per domain)
- [ ] Price oracle returns valid MATIC amounts
- [ ] Fallback price works when oracle unavailable
- [ ] Cache reduces gas on sequential calls
- [ ] Admin can set fallback price
- [ ] First badge costs ~$1.00 worth of MATIC
- [ ] Exponential pricing works correctly
- [ ] Regular subdomains use correct formula
- [ ] Free TLDs still free
- [ ] Paid TLDs charge ~$1.00 worth of MATIC

## Gas Impact

**Before:** Fixed MATIC values, minimal computation
**After:** Oracle calls + conversion math

**Estimated Gas Increase:**
- First call in 5min window: +50k gas (oracle fetch)
- Cached calls: +5k gas (conversion math only)
- Batch operations benefit from cache

**Optimization:** Cache duration set to 5min balances freshness vs gas costs.

## Security Considerations

1. **Oracle Dependency:** System relies on Chainlink. Fallback provides safety net.
2. **Price Manipulation:** Chainlink feeds are decentralized and manipulation-resistant.
3. **Sanity Checks:** Prices must be $0.10-$10.00 range to prevent exploits.
4. **Admin Powers:** Admin can set fallback but NOT bypass oracle entirely.
5. **Integer Overflow:** Using Solidity 0.8.30 with built-in overflow protection.

## Future Improvements

1. **Multi-token payments:** Accept USDC/USDT for stable pricing
2. **Dynamic cache duration:** Adjust based on price volatility
3. **Multiple oracle sources:** Average across Chainlink, Band, etc.
4. **Price limits:** Set max MATIC amount per transaction regardless of USD price

---

**Status:** ✅ All fixes implemented
**Ready for:** Testing on Polygon Amoy testnet
**Breaking:** Yes - requires full redeployment
