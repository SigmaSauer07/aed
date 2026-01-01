# AED Economic Model & Pricing Analysis

## Fee Structure Overview

### Domain Registration
| TLD | Price | Includes |
|-----|-------|----------|
| .alsania, .fx, .echo | 1 MATIC | Subdomain minting enabled |
| .aed, .alsa, .07 | FREE | Gas only |
| Subdomain Enhancement | 2 MATIC | Enable subdomain minting on free TLDs |

### Subdomain Minting (Exponential)
| Subdomain # | Fee Formula | Cost (MATIC) |
|-------------|-------------|--------------|
| 1-2 | FREE | 0 |
| 3 | 0.1 × 2^0 | 0.1 |
| 4 | 0.1 × 2^1 | 0.2 |
| 5 | 0.1 × 2^2 | 0.4 |
| 6 | 0.1 × 2^3 | 0.8 |
| 10 | 0.1 × 2^7 | 12.8 |
| 20 | 0.1 × 2^17 | 13,107.2 |

### Badge Minting (Up to 10 per domain)
| Badge # | Fee Formula | Cost (MATIC) | USD (@ $0.40/MATIC) |
|---------|-------------|--------------|---------------------|
| 1 | 2 × 2^0 | 2 | $0.80 |
| 2 | 2 × 2^1 | 4 | $1.60 |
| 3 | 2 × 2^2 | 8 | $3.20 |
| 4 | 2 × 2^3 | 16 | $6.40 |
| 5 | 2 × 2^4 | 32 | $12.80 |
| 6 | 2 × 2^5 | 64 | $25.60 |
| 7 | 2 × 2^6 | 128 | $51.20 |
| 8 | 2 × 2^7 | 256 | $102.40 |
| 9 | 2 × 2^8 | 512 | $204.80 |
| 10 | 2 × 2^9 | 1024 | $409.60 |

**Total for 10 badges:** 2046 MATIC ($818.40 @ $0.40/MATIC)

### Capability Unlocks (Per Badge)
| Capability # | Fee Formula | Cost (MATIC) | USD (@ $0.40/MATIC) |
|--------------|-------------|--------------|---------------------|
| 1st | 1 × 2^0 | 1 | $0.40 |
| 2nd | 1 × 2^1 | 2 | $0.80 |
| 3rd | 1 × 2^2 | 4 | $1.60 |
| 4th | 1 × 2^3 | 8 | $3.20 |

**Total for all 4 capabilities:** 15 MATIC ($6.00)

---

## User Journey Economics

### Typical User (1 domain, 2 badges)
```
Domain: sigma.aed               FREE
Badge 1: claude.sigma.aed       2 MATIC    ($0.80)
  + Communication               1 MATIC    ($0.40)
  + Vision                      2 MATIC    ($0.80)
Badge 2: gpt4.sigma.aed         4 MATIC    ($1.60)
  + Communication               1 MATIC    ($0.40)
----------------------------------------------
TOTAL:                          10 MATIC   ($4.00)
```

### Power User (1 domain, 5 badges, all capabilities)
```
Domain: company.alsania         1 MATIC    ($0.40)
Badge 1                         2 MATIC    ($0.80)
  + All 4 capabilities          15 MATIC   ($6.00)
Badge 2                         4 MATIC    ($1.60)
  + All 4 capabilities          15 MATIC   ($6.00)
Badge 3                         8 MATIC    ($3.20)
  + All 4 capabilities          15 MATIC   ($6.00)
Badge 4                         16 MATIC   ($6.40)
  + All 4 capabilities          15 MATIC   ($6.00)
Badge 5                         32 MATIC   ($12.80)
  + All 4 capabilities          15 MATIC   ($6.00)
----------------------------------------------
TOTAL:                          138 MATIC  ($55.20)
```

### Enterprise (1 domain, 10 badges, all capabilities)
```
Domain: enterprise.fx           1 MATIC    ($0.40)
10 Badges                       2046 MATIC ($818.40)
40 Capability unlocks (4×10)    150 MATIC  ($60.00)
----------------------------------------------
TOTAL:                          2197 MATIC ($878.80)
```

---

## Revenue Projections

### Conservative (Year 1)
- 5,000 users
- Average: 1 domain + 1 badge + 2 capabilities = 5 MATIC ($2)
- **Total Revenue: 25,000 MATIC = $10,000**

### Moderate (Year 1)
- 20,000 users
- Average: 1 domain + 2 badges + 4 capabilities = 12 MATIC ($4.80)
- **Total Revenue: 240,000 MATIC = $96,000**

### Optimistic (Year 1)
- 50,000 users
- Average: 1 domain + 3 badges + 8 capabilities = 30 MATIC ($12)
- **Total Revenue: 1,500,000 MATIC = $600,000**

### Enterprise Scenario
- 100 enterprise customers @ $878.80 each
- **Additional Revenue: $87,880**

---

## Comparison to Competitors

### ENS
- .eth domain: ~$5-640/year (depends on length, requires renewal)
- Subdomains: FREE (unlimited)
- **No AI features, no capabilities, no evolution**

### Unstoppable Domains
- One-time fee: $5-200 (no renewal)
- Subdomains: Not supported
- **No AI features, no capabilities, no evolution**

### AED Advantages
✅ AI badge system (unique)  
✅ Capability gating (unique)  
✅ Visual evolution (unique)  
✅ Free base TLDs  
✅ Exponential pricing rewards early adoption  
✅ No renewals required  

---

## Pricing Rationale

### Why Exponential Scaling?

**Goal:** Prevent spam while allowing scale

1. **Badge 1-2:** Affordable for regular users ($0.80 - $1.60)
2. **Badge 3-5:** Power users with multiple agents ($3.20 - $12.80)
3. **Badge 6-10:** Enterprises managing agent fleets ($25.60 - $409.60)

**Alternative considered:** Flat fee  
- **Problem:** No spam prevention, no economic value capture from power users
- **Rejected:** Exponential better aligns incentives

### MATIC vs USD Pricing

**Current:** Hardcoded MATIC amounts  
**Problem:** MATIC price volatility affects real costs

| MATIC Price | Badge 1 Cost | Badge 5 Cost |
|-------------|--------------|--------------|
| $0.40 | $0.80 | $12.80 |
| $1.00 | $2.00 | $32.00 |
| $2.00 | $4.00 | $64.00 |

**Solution Options:**

1. **Quarterly manual adjustment** (current plan)
   - Pro: Simple, no oracle dependency
   - Con: Periodic repricing required

2. **Chainlink oracle integration**
   - Pro: Stable USD pricing
   - Con: Oracle dependency, gas overhead, manipulation risk

**Recommendation:** Start with quarterly manual adjustment, migrate to oracle if MATIC volatility becomes problematic.

---

## Break-Even Analysis

### Platform Costs (Year 1)
- Smart contract audits: $30,000
- Metadata server (Vercel): $2,400/year
- RPC costs: $1,200/year
- Development: $120,000 (assume 2 devs × $60k)
- **Total Costs: $153,600**

### Users Needed to Break Even
- Conservative scenario: 15,360 users @ $10 each
- Moderate scenario: 3,200 users @ $48 each
- Optimistic scenario: 1,280 users @ $120 each

**Target:** 10,000 users Year 1 = $48,000 revenue (31% of costs covered)  
Requires additional revenue streams or runway funding.

---

## Additional Revenue Opportunities

1. **Premium TLDs** - Auction system for custom TLDs
2. **Fragment Packs** - Cosmetic achievement bundles ($5-20)
3. **Enhanced Metadata** - Custom SVG generation service
4. **Enterprise Plans** - Bulk badge discounts + SLAs
5. **Agent Marketplace** - Transaction fees (2-5%)
6. **Memory Storage** - IPFS pinning service ($1/GB/month)

---

## Total Addressable Market

### AI Identity Market
- **Size:** $20B by 2030 (projected)
- **Growth:** 35% CAGR
- **Competition:** None (AED is first mover)

### Digital Identity Market
- **Size:** $100B current TAM
- **Growth:** 16% CAGR
- **Players:** ENS ($50M revenue), UD ($30M revenue)

### AED Opportunity
- Capture 1% of AI identity market: **$200M revenue potential**
- Capture 0.1% of digital identity market: **$100M revenue potential**

**Conservative target:** $10M ARR by Year 3

---

## Conclusion

AED's exponential pricing model:
✅ Prevents spam and Sybil attacks  
✅ Allows affordable entry ($0.80 first badge)  
✅ Captures value from power users/enterprises  
✅ Aligns with Web3 norms (ENS, UD use similar models)  
✅ Generates meaningful revenue at scale  

**Key metric:** Customer Lifetime Value (LTV)
- Typical user: $4-10
- Power user: $50-200
- Enterprise: $500-2000

**Next steps:**
1. Deploy mainnet
2. Launch with 1000 beta users
3. Validate pricing via feedback
4. Adjust if needed (quarterly)
