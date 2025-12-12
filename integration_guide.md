# AED Evolution & AI System Integration Guide

## Files Created

### Core Libraries
1. **LibBadges.sol** - Badge & evolution system
2. **LibAISubdomains.sol** - AI subdomain management & capabilities
3. **LibMetadata.sol** (UPDATED) - Now includes badge/evolution rendering
4. **LibMinting.sol** (UPDATED) - Awards badges automatically

### Core Storage
5. **AppStorage.sol** (UPDATED) - Added badge/evolution storage

### Module
6. **AEDAI.sol** - New module for AI functionality

---

## Integration Steps

### Step 1: Replace Files
```bash
# Replace these in your contracts/ directory:
cp LibBadges.sol contracts/libraries/
cp LibAISubdomains.sol contracts/libraries/
cp LibMetadata.sol contracts/libraries/  # REPLACE existing
cp LibMinting.sol contracts/libraries/    # REPLACE existing
cp AppStorage.sol contracts/core/         # REPLACE existing
cp AEDAI.sol contracts/modules/ai/        # NEW directory
```

### Step 2: Update Imports in AEDImplementation.sol

Add these imports:
```solidity
import "./libraries/LibBadges.sol";
import "./libraries/LibAISubdomains.sol";
```

### Step 3: Deploy New Module

Deploy `AEDAI.sol` as a separate contract, then add it to your existing system via your module registry.

### Step 4: Update Metadata Server (Optional)

Your existing metadata server should automatically work since the evolution data is in the on-chain tokenURI. But you can add specific routes if needed:

```javascript
// In metadata-server.js, add evolution data to response:
const evolutionLevel = await contract.getEvolutionLevel(tokenId);
const badges = await contract.getTokenBadges(tokenId);
```

---

## How It Works

### Evolution System
- Domains start at Level 0
- Each badge awards evolution points (decorative = 1 point, capability = 2 points)
- Frame color and thickness change based on level:
  - Level 0: Neon green (#39FF14)
  - Level 1-4: Cyan (#00F6FF)
  - Level 5-9: Pink (#FF2E92)
  - Level 10-14: Purple (#9D4EDD)
  - Level 15+: Gold (#FFD700)

### Badge Types

**Decorative Badges** (auto-awarded):
- `first_subdomain` - Create your first subdomain
- `subdomain_veteran` - Create 5 subdomains
- `subdomain_master` - Create 10 subdomains

**AI Capability Badges** (purchased):
- `ai_vision` - 0.2 ETH - Unlocks vision processing
- `ai_communication` - 0.15 ETH - Enables agent-to-agent messaging
- `ai_memory` - 0.25 ETH - Memory expansion
- `ai_reasoning` - 0.3 ETH - Enhanced reasoning

### AI Subdomains

Users can create AI subdomains like:
- `echo.sigma.alsania` (GPT-4)
- `aegis.sigma.alsania` (DeepSeek)
- `claude.sigma.alsania` (Claude)

**Restrictions**:
- One AI subdomain per model type per parent
- Must purchase separately from regular subdomains (0.5 ETH base price)
- Stays in user's wallet (non-transferable/soulbound concept via ownership)

---

## Usage Examples

### Create AI Subdomain
```solidity
// User calls on AEDAI module:
aedAI.createAISubdomain{value: 0.5 ether}(
    "echo",           // label
    "sigma.alsania",  // parent domain
    "gpt-4"          // model type
);
```

### Purchase AI Capability
```solidity
// User purchases vision for their AI subdomain:
uint256 echoTokenId = aedAI.getAISubdomain("sigma.alsania", "gpt-4");
aedAI.purchaseAICapability{value: 0.2 ether}(
    echoTokenId,
    "vision"
);
```

### Award Custom Badge (Admin)
```solidity
// Admin awards custom badge:
aedAI.awardBadge(
    tokenId,
    "community_champion",
    abi.encodePacked("Awarded for community contributions"),
    false  // not a capability badge
);
```

---

## What Changes in Your Frontend

### Display Evolution Level
```javascript
const level = await contract.getEvolutionLevel(tokenId);
// Show level badge in UI
```

### Show Badges
```javascript
const badges = await contract.getTokenBadges(tokenId);
badges.forEach(badge => {
  console.log(`${badge.badgeType} - Awarded: ${new Date(badge.awardedAt * 1000)}`);
});
```

### Check AI Capabilities
```javascript
const hasVision = await aedAI.hasAICapability(tokenId, "vision");
// Enable/disable vision features in UI based on this
```

---

## Testing Checklist

- [ ] Deploy updated AppStorage
- [ ] Deploy LibBadges
- [ ] Deploy LibAISubdomains
- [ ] Deploy updated LibMetadata
- [ ] Deploy updated LibMinting
- [ ] Deploy AEDAI module
- [ ] Register AEDAI in your module registry
- [ ] Test domain registration (should work as before)
- [ ] Test subdomain creation (should auto-award badges)
- [ ] Test AI subdomain creation
- [ ] Test AI capability purchase
- [ ] Check tokenURI renders with badges/evolution
- [ ] Verify one AI sub per model restriction works

---

## Gas Estimates

- Create AI subdomain: ~250k gas
- Purchase capability: ~180k gas
- Auto badge award (on subdomain create): +~80k gas
- Evolution SVG rendering: ~120k gas

---

## Next Steps

After integration, you can:
1. Add more badge types (custom achievements, events, milestones)
2. Create agent-to-agent messaging using the communication capability
3. Build a badge marketplace
4. Add evolution-based unlocks (Level 10 = free subdomain, etc.)
5. Implement memory storage tied to the memory capability badge

---

## Need Help?

Check if badges are rendering:
```solidity
// Get badge SVG for visual confirmation
string memory svg = LibBadges.getBadgeSVG(tokenId);
```

Verify evolution level calculation:
```solidity
// Should increase with each badge
uint256 level = LibBadges.getEvolutionLevel(tokenId);
```
