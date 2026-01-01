# AED AI Integration Demo

**Proof-of-concept showing AI agents verifying badge ownership and capabilities on-chain.**

## What This Proves

This demo validates the core AED value proposition:

1. **AI can check badge ownership** - Before granting access, AI queries the blockchain
2. **Capabilities gate features** - AI only provides services if user's badge has required capability
3. **Verifiable permissioning** - All access control decisions are transparent and on-chain
4. **Transferable access** - Badge ownership = AI access rights

## Architecture

```
User → AI Agent → BadgeVerifier → AED Contract → Polygon
                        ↓
                  Access Decision
                  (Grant/Deny)
```

## Quick Start

```bash
npm install
npm run demo
```

## What You'll See

The demo runs 3 scenarios:

### Scenario 1: ✅ User with badge + capability
- User owns `sigmasauer07.alsania` badge
- Badge has `ai_communication` capability
- **Result**: Access granted

### Scenario 2: ❌ User with badge but missing capability
- Same badge, but lacks `ai_vision` capability
- **Result**: Access denied (missing capability)

### Scenario 3: ❌ Wrong owner
- Different address tries to use someone else's badge
- **Result**: Access denied (not owner)

## Key Contract Calls

```javascript
// 1. Get badge token ID
const tokenId = await contract.getTokenIdByDomain('sigmasauer07.alsania');

// 2. Verify ownership
const owner = await contract.ownerOf(tokenId);

// 3. Check if it's a badge (not regular subdomain)
const isBadge = await contract.isAISubdomain(tokenId);

// 4. Get AI model type
const modelType = await contract.getModelType(tokenId);

// 5. Check specific capability
const hasCap = await contract.hasAICapability(tokenId, 'ai_communication');

// 6. Get all capabilities
const allCaps = await contract.getActiveCapabilities(tokenId);
```

## Real-World Usage

### Example: AI Chat Service

```javascript
// User connects wallet and claims badge
const userAddress = await wallet.getAddress();
const userBadge = 'assistant.company.aed';

// AI checks badge before responding
const verification = await verifier.verifyAccess(
  userAddress,
  userBadge,
  'ai_communication'
);

if (verification.granted) {
  // AI responds
  return aiModel.chat(userPrompt);
} else {
  // Access denied
  return 'Please purchase communication capability for your badge';
}
```

### Example: AI Vision Service

```javascript
// User uploads image
if (await verifier.verifyAccess(userAddress, badge, 'ai_vision')) {
  return await aiModel.analyzeImage(image);
} else {
  return 'Vision capability required. Cost: 1 MATIC';
}
```

## Why This Matters

**Without AED:**
- AI services have no verifiable access control
- Users can't prove they own capabilities
- No portable identity across AI platforms

**With AED:**
- On-chain proof of AI access rights
- Transferable capabilities (sell your enhanced badge)
- Universal AI identity (one badge, any platform)

## Contract Details

- **Network**: Polygon Amoy Testnet
- **Contract**: `0x45e441F9e722aAC73784F49A4bad8aF45B95A5DC`
- **Explorer**: https://www.oklink.com/amoy/address/0x45e441F9e722aAC73784F49A4bad8aF45B95A5DC

## Next Steps

1. **Production AI Integration**: Connect real AI services (Claude API, GPT-4, local LLMs)
2. **Badge Marketplace**: Buy/sell badges with proven capabilities
3. **Cross-Platform**: Same badge works across multiple AI platforms
4. **Reputation**: Track badge usage history on-chain

## Files

- `badge-gate-demo.js` - Main demo showing 3 scenarios
- `aed-abi.json` - Minimal ABI for badge functions
- `.env` - RPC and contract configuration

## For Investors

This 200-line demo proves:
- ✅ Technical feasibility (badge gates work on-chain)
- ✅ Clear value prop (verifiable AI access control)
- ✅ Scalable architecture (standard ERC-721 queries)
- ✅ Real deployment (live on Polygon Amoy)

**The technology works. The contracts are deployed. The vision is executable.**
