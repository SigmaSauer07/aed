# AED AI Integration Demo

Proof of concept showing how AI agents validate badge ownership and capabilities on-chain.

## What This Demonstrates

1. **Badge Ownership Verification** - AI checks wallet owns the badge NFT
2. **Capability Gating** - AI only responds if badge has required capabilities  
3. **On-Chain Identity** - AI reads badge metadata (model type, capabilities) from contract

## Setup

```bash
cd ai-demo
npm install
npm start
```

Server runs on `http://localhost:3001`

## API Endpoints

### POST /api/chat
AI responds only if badge is valid.

```bash
curl -X POST http://localhost:3001/api/chat \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Hello AI",
    "walletAddress": "0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43",
    "badgeTokenId": "6"
  }'
```

**Success Response:**
```json
{
  "message": "✅ Badge verified! I can now assist you.",
  "badgeInfo": {
    "tokenId": "6",
    "owner": "0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43",
    "modelType": "claude-3.5-sonnet",
    "capabilities": ["ai_communication", "ai_vision"]
  },
  "response": "AI response here..."
}
```

**Failure Response (no badge):**
```json
{
  "error": "Access Denied",
  "reason": "Wallet does not own this badge"
}
```

### POST /api/check-capability
Check if badge has specific capability.

```bash
curl -X POST http://localhost:3001/api/check-capability \
  -H "Content-Type: application/json" \
  -d '{
    "walletAddress": "0x...",
    "badgeTokenId": "6",
    "capability": "ai_vision"
  }'
```

### GET /api/badge/:tokenId
Get badge details.

```bash
curl http://localhost:3001/api/badge/6
```

## How It Works

1. **Client sends request** with wallet address + badge token ID
2. **Server validates** badge ownership on-chain via contract calls:
   - `isAISubdomain(tokenId)` - confirm it's a badge
   - `ownerOf(tokenId)` - verify wallet owns it
   - `hasAICapability(tokenId, capability)` - check required capabilities
3. **AI responds** only if validation passes

## Integration Example

```javascript
// Frontend code
const response = await fetch('http://localhost:3001/api/chat', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    message: userMessage,
    walletAddress: await signer.getAddress(),
    badgeTokenId: selectedBadgeId
  })
});

const data = await response.json();
if (response.ok) {
  // AI verified badge and responded
  console.log(data.response);
} else {
  // Access denied - missing badge or capability
  console.error(data.reason);
}
```

## Key Insight for Investors

**This proves the entire AED value proposition:**
- AI agents can verify on-chain identity
- Capabilities are enforced at access time
- User owns the badge, AI accesses it when connected
- Disconnect wallet = AI loses all access instantly

**Without AED:** AI has no identity, no capabilities, no ownership model  
**With AED:** AI identity is portable, verifiable, and user-controlled

## Next Steps

1. Connect to actual AI models (Claude API, OpenAI, local LLMs)
2. Add wallet signature verification for extra security
3. Build frontend chat UI that integrates this flow
4. Deploy as public demo for investors
