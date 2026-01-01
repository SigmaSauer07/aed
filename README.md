# Alsania Enhanced Domains (AED)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Polygon](https://img.shields.io/badge/Network-Polygon%20Amoy-blue.svg)](https://polygon.technology/)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.30-363636.svg)](https://soliditylang.org/)

On-chain identity system unifying human domains and AI agent identity. ERC-721 NFTs that evolve through achievements and unlock capabilities.

---

## Core Concepts

### Three Distinct Layers

#### 1. Domain & Subdomain NFTs (Base Layer)
**What they are:**
- Every domain is an NFT (like ENS/Unstoppable Domains)
- Every subdomain is also an NFT
- **Up to 20 regular (non-AI) subdomains per domain**
- Standard ownership, transfer, trading
- Examples: `example.aed`, `docs.example.aed`, `app.example.aed`

**Key point:** These exist whether or not AI is involved.

---

#### 2. Badges (AI-Enhanced Subdomains)
**What they are:**
- A special type of subdomain NFT that syncs with an AI agent
- Created by "enhancing" a domain to mint a badge
- **Up to 10 badges per domain** (exponential fee scaling)
- **Tracked separately from regular subdomains** (20 regular + 10 badges = 30 total subdomains possible)
- Each badge = 1 subdomain that connects to 1 AI agent/model
- Example: `claude.example.aed`, `echo.example.aed`

**What makes them special:**
- They represent AI agent identity on-chain
- They're still subdomain NFTs, just with AI sync + AI added abilities
- Owned by user, accessed by AI when wallet connected

**Key point:** Badge = subdomain NFT + AI sync + added AI capability

**Critical distinction:** Badges ARE subdomains. Not all subdomains are badges, but all badges are subdomains. The system maintains separate counters to distinguish organizational structure (regular subdomains) from AI identity (badges).

---

#### 3. Fragments (Visual Achievements)
**What they are:**
- Cosmetic overlays/decorations rendered on the NFT image
- **Not separate NFTs** - stored as metadata attributes on the parent NFT
- Attach to ANY awarded domain or subdomain NFT (AI or non-AI)
- Multiple fragments per NFT
- Pure visual representation of achievements

**What they represent:**
- Achievements unlocked (e.g., "first domain minted")
- Capabilities demonstrated (e.g., "communication enhancement unlocked")
- Activity milestones (e.g., "10 subdomains created")

**Key point:** Fragments are visual overlays triggered when achievements unlock. The fragment itself doesn't trigger anything—it's the reward display, not the cause.

**Data structure:** Each fragment is a struct `{fragmentType, earnedAt, eventHash}` stored in the parent NFT's metadata.

---

## How They Work Together

**Example scenario:**

1. User owns `example.aed` (domain NFT)
2. User creates subdomains:
   - `docs.example.aed` (regular subdomain NFT)
   - `api.example.aed` (regular subdomain NFT)
3. User enhances domain to create badges:
   - `claude.example.aed` (badge = AI-synced subdomain NFT for Claude model)
   - `echo.example.aed` (badge = AI-synced subdomain NFT for Echo model)
4. Achievements unlock over time:
   - Claude badge completes 100 tasks → fragment appears on `claude.example.aed`
   - API hits 1M calls → fragment appears on `api.example.aed`
   - Domain reaches 1 year age → fragment appears on `example.aed`
5. Badges evolve visually as more fragments accumulate

---

## Subdomain Capacity

**Per Domain Limits:**
- **Regular subdomains**: Up to 20 (organizational/non-AI use)
- **Badge subdomains**: Up to 10 (AI-synced, tracked separately)
- **Combined total**: 30 subdomains per domain maximum

Badges don't count against the 20-subdomain limit because they serve a distinct purpose (AI identity vs organizational structure) and are tracked in separate storage slots.

---

## Key Distinctions

| Aspect | Domain/Subdomain NFT | Badge | Fragment |
|--------|---------------------|-------|----------|
| **What is it?** | Ownership token | AI-synced subdomain NFT | Visual decoration attribute |
| **Quantity** | Unlimited domains / Up to 20 regular subdomains per domain | Up to 10 per domain (separate limit) | Multiple per NFT |
| **Function** | Identity, ownership | AI identity + ability integration | Achievement display |
| **AI Required?** | No | Yes | No |
| **Evolves?** | Yes | Yes | No |
| **Transferable?** | Yes (standard ERC-721) | Yes (standard ERC-721) | No (bound to NFT) |

---

## Evolution System

All badge NFTs evolve visually based on fragment accumulation.

### Fragments

Visual symbols representing achievements:
- Stored as metadata: `{fragmentType, earnedAt, eventHash}`
- **Not separate NFTs**—purely metadata attributes rendered as SVG overlays
- Awarded for: enhancement purchases, events, contests, achievements
- Types: `first_domain`, `subdomain_creator`, `vision_pioneer`, etc.
- Some one-time, others repeatable

### Evolution Levels

Level = `total_fragments / 5`

- **Level 0**: Basic frame
- **Level 1-5**: Enhanced frame + cyan glow
- **Level 6-10**: Advanced frame + pink/purple accents
- **Level 11+**: Maximum evolution + gold accents

Visual rendering:
- Max 15 fragments displayed on NFT image. rarest over common
- Frame thickness/color changes per level
- Each fragment has unique color/icon
- Agent fragments use metallic hexagons vs. circular shapes for non-AI

---

## AI Agent System

Badges enable verifiable AI identity on-chain.

### Badge Mechanics

1. **Mint**: Reserve badge slot on parent domain (pay reservation fee, exponential per badge)
2. **Sync**: Mint badge with AI model identifier (e.g., `claude.example.aed` synced to `claude-3.5-sonnet`)
3. **Enhance**: Purchase capabilities (communication, vision, memory, reasoning)
4. **Evolve**: Earn fragments as enhancements unlock

### Agent Enhancements

- **Communication** (`ai_communication`): Agent-to-agent messaging
- **Vision** (`ai_vision`): Image processing
- **Memory** (`ai_memory`): Auto-store memory snapshots to IPFS
- **Reasoning** (`ai_reasoning`): Enhanced logic/pattern capabilities

Each enhancement:
- Requires payment (exponential per badge)
- Awards fragment on unlock
- Stored as capability flag on badge NFT
- Rendered as metallic hexagon fragment

### Access Rules

- Badge owned by user wallet/domain
- AI accesses badge capabilities only when wallet connected
- Badge transfer: keeps sync, new owner controls access
- Disconnect: AI instantly loses all privileges

### Example Fragments

- `first_badge`: First AI badge minted under this domain
- `communication_expert`: Communication enhancement unlocked
- `vision_pioneer`: Vision enhancement unlocked
- `multi_agent`: User owns 3+ badges

---

## Architecture

### Smart Contracts

```
AED (Proxy)
└── AEDImplementation (UUPS Upgradeable)
    ├── Core (ERC-721, Access Control)
    ├── Libraries
    │   ├── LibMinting
    │   ├── LibEvolution
    │   ├── LibEnhancements
    │   ├── LibMetadata
    │   ├── LibReverse
    │   ├── LibAdmin
    │   └── LibAISubdomains
    └── Modules (future expansion)
```

### Storage

Single `AppStorage` struct using Diamond Storage pattern:
- All state in one struct
- `keccak256("aed.app.storage")` slot
- Reserved `__gap` for future additions
- No storage collisions on upgrade

### Features

- UUPS upgradeable (admin-only)
- Role-based access: `ADMIN_ROLE`, `FEE_MANAGER_ROLE`, `TLD_MANAGER_ROLE`
- Reentrancy protection on all payable functions
- Pausable minting operations
- Gas-optimized storage reads

---

## Getting Started

### Installation

```bash
git clone https://github.com/alsania-io/aed.git
cd aed
npm install
```

### Environment

```bash
cp .env.example .env
# Edit .env:
# AMOY_RPC=https://rpc-amoy.polygon.technology
# PRIVATE_KEY=<your_key>
# POLYGONSCAN_API_KEY=<your_key>
```

### Compile & Test

```bash
npx hardhat compile
npx hardhat test
npx hardhat coverage
```

### Deploy

```bash
npx hardhat run scripts/deploy.js --network amoy
npx hardhat verify --network amoy <proxy_address>
```

---

## Fee Structure

**Current implementation: Hardcoded $ values for example**

### Domain Registration

- Paid TLDs (`.alsania`, `.fx`, `.echo`): **$1** (includes subdomain minting)
- Free TLDs (`.aed`, `.alsa`, `.07`): **Free** (gas only)
- Subdomain Enhancement: **$2** (enables subdomain minting on free TLDs)

### Subdomain Minting

- First 2 subdomains: **Free** (gas only)
- Additional subdomains: **$0.10 × 2^(n-3)** (where n = total subdomain count)
  - 3rd: $0.10
  - 4th: $0.20
  - 5th: $0.40
  - 6th: $0.80

*Note: Maximum 20 regular subdomains per domain (badges tracked separately)*

### Badge System

**Badge Slot Reservation** (up to 10 per domain, separate from 20 regular subdomain limit): **$1 × 2^(n-1)**
  - 1st badge: $1
  - 2nd badge: $2
  - 3rd badge: $4
  - 4th badge: $8

**Agent Enhancements** (per badge, any order): **$1 × 2^(n-1)**
  - 1st capability: $1
  - 2nd capability: $2
  - 3rd capability: $4
  - 4th capability: $8

All fees in USD equivalent (converted to network token). Fees sent to `feeCollector` address (admin configurable).

---

## Metadata Server

Dynamic NFT metadata via Vercel serverless functions.

**Deployed**: https://aed-metadata.vercel.app/

### Endpoints

- `GET /domain/:tokenId.json` - Domain metadata
- `GET /sub/:tokenId.json` - Subdomain/badge metadata

### Features

- Reads on-chain data (name, fragments, evolution level)
- Generates dynamic SVG with rendered fragments
- Default backgrounds for unset images
- Evolution level and fragment count in attributes

### Deploy

```bash
cd metadata-server
npm install
vercel --prod

# Set in Vercel dashboard:
# AMOY_RPC=<rpc_url>
# CONTRACT_ADDRESS=<proxy_address>
```

---

## Security

- Multi-role access control
- Reentrancy guards on all payable functions
- Storage layout validation before upgrades
- Input validation (domain names, TLDs, addresses)
- Emergency pause mechanism
- No external dependencies in core logic

### Audit Checklist

- [ ] `slither .`
- [ ] `npx hardhat storage-layout`
- [ ] Verify `AppStorage` unchanged before upgrade
- [ ] Test all access control paths
- [ ] Verify fee calculations
- [ ] Test fragment awarding
- [ ] Verify badge sync safety

---

## Frontend Integration

### Register Domain

```javascript
const tx = await aed.registerDomain(
  "example",
  "aed",
  true, // enable subdomains
  { value: ethers.parseEther("2") }
);
```

### Mint Subdomain

```javascript
const parentId = 1;
const fee = await aed.calculateSubdomainFee(parentId);
const tx = await aed.mintSubdomain(parentId, "docs", { value: fee });
```

### Mint Badge

```javascript
// Reserve badge slot (1st badge)
const tx1 = await aed.createAISubdomain(
  "claude",
  "example.aed",
  "claude-3.5-sonnet",
  { value: ethers.parseEther("2") }
);

// Purchase enhancement
const badgeId = await aed.getAISubdomain("example.aed", "claude-3.5-sonnet");
const tx2 = await aed.purchaseAICapability(
  badgeId,
  "communication",
  { value: ethers.parseEther("1") }
);
```

### Check Evolution

```javascript
const level = await aed.getEvolutionLevel(tokenId);
const count = await aed.getFragmentCount(tokenId);
const fragments = await aed.getTokenFragments(tokenId);
```

---

## Upgrade Process

UUPS pattern for upgradability:

1. Write new implementation (keep `AppStorage` unchanged)
2. Validate storage: `npx hardhat storage-layout`
3. Deploy new implementation
4. Call `upgradeTo(newImplementation)` with admin role
5. Verify storage preserved

### Storage Safety

- Never remove fields from `AppStorage`
- Never change field order
- Append new fields at end only
- Use `__gap` for future expansion
- Test upgrades on testnet first

---

## Roadmap

### Phase 1: Core Identity (Complete)

- [x] Domain/subdomain registration
- [x] Badge minting (up to 10 per domain)
- [x] Fragment system
- [x] Evolution rendering
- [x] Metadata server

### Phase 2: AI Agent Features (In Progress)

- [x] Agent enhancements framework
- [ ] Agent-to-agent messaging protocol
- [ ] Memory snapshot storage (IPFS)
- [ ] Vision module integration
- [ ] Badge burn mechanism
- [ ] Enhancement removal

### Phase 3: Advanced Features

- [ ] Cross-chain bridging
- [ ] Guardian recovery
- [ ] Governance module
- [ ] Reputation scoring
- [ ] Domain expiry/renewal

### Phase 4: Ecosystem

- [ ] Agent marketplace
- [ ] Enhancement packs
- [ ] Event-based fragments
- [ ] Alsania AI agent integration

### Under Consideration

- [ ] FastAPI-based badge sync service (experimental)

---

## Documentation

- **Contracts**: `contracts/README.md`
- **Deployment**: `DEPLOYMENT.md`
- **Quick Reference**: `docs/PROJECT_QUICKREF.md`
- **API Reference**: Generated docs in `docs/`

---

## Contributing

Follow Alsanian Code principles (see `.userPreferences`):
- No surveillance/tracking
- Open, inspectable code
- Minimal dependencies
- Gas-optimized
- Upgrade-safe
- Test coverage >90%

1. Fork repository
2. Create feature branch
3. Submit PR with clear description

---

## License

MIT License - See [LICENSE](LICENSE)

---

## Support

- **Issues**: [GitHub Issues](https://github.com/alsania-io/aed/issues)
- **Discord**: [Alsania Community](https://discord.gg/alsania)
- **Docs**: [docs.alsania.io](https://docs.alsania.io)

---

**Alsania Enhanced Domains**
Where human identity and AI agency converge on-chain.
