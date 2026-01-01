# Alsania Enhanced Domains (AED) — Technical Whitepaper
## The First Unified Identity Layer for Humans and Autonomous Agents

---

## 1. Introduction

The rise of AI agents and autonomous systems has created a new requirement for digital identity.
Human identity systems (ENS, UD, etc.) do not account for:

- Autonomous AI actors
- Evolving capabilities
- Verifiable agent memory
- Authenticated agent-to-agent messaging
- Dynamic, composable identity

Meanwhile, AI itself has no portable identity, no reputation layer, and no verifiable capability system.

Alsania Enhanced Domains (AED) introduces the first identity framework designed simultaneously for:

- Sovereign human identity
- Sovereign AI identity
- On-chain evolution
- Capability ownership
- Collaborative autonomy
- Verifiable memory
- Cross-platform interoperability

**AED is not a naming system. It is a modular identity protocol.**

---

## 2. System Architecture Overview

AED consists of **three distinct layers**:

### Layer 1: Domain & Subdomain NFTs (Base Identity Layer)
- All domains are ERC-721 NFTs
- All subdomains are ERC-721 NFTs
- Standard ownership, transfer, trading
- Examples: `sigma.aed`, `docs.sigma.aed`, `api.sigma.aed`

### Layer 2: Badges (AI-Enhanced Subdomains)
- Special subdomains synced to AI agents
- Up to 10 badges per domain
- Each badge = 1 subdomain + AI model sync + visual evolution
- Examples: `claude.sigma.aed`, `echo.sigma.aed`

### Layer 3: Fragments (Visual Achievement System)
- Metadata attributes rendered as SVG overlays
- **Not separate NFTs** - stored on parent NFT
- Multiple per domain/subdomain/badge
- Trigger visual evolution

**Supporting infrastructure:**

- On-chain capability manager
- Evolution renderer
- Agent protocol
- Memory registry (IPFS)
- Event/emission system

Together, they form an identity organism capable of evolving, remembering, and coordinating.

---

## 3. Domains & Subdomains (Layer 1)

Every AED domain is an upgradeable ERC-721 identity contract with dynamic metadata.

### 3.1 Domain NFTs

Root identity owned by humans:
- Standard ERC-721 ownership
- Can mint up to 10 badges (AI-synced subdomains)
- Can mint unlimited regular subdomains
- Fragments attach to show achievements
- Visual evolution based on fragment accumulation

### 3.2 Subdomain NFTs

Child identities under parent domain:
- Also ERC-721 NFTs
- Independent ownership and transfer
- Can have fragments
- Standard organizational delegation
- Examples: `docs.sigma.aed`, `test.sigma.aed`

### 3.3 On-Chain Rendering

SVGs for all NFTs are composed using a modular renderer that:
- Merges base frame + fragments
- Applies color grading based on evolution tier
- Integrates animated elements (optional)
- Encodes fragments in deterministic order

### 3.4 Storage

Metadata is stored:
- Hash on-chain
- JSON/SVG on IPFS
- Optional fallbacks via base64 encoding

Domains support evolutions without rebasing or redeploying.

---

## 4. AI Identity: Badges (Layer 2)

This is AED's most important innovation.

### 4.1 What is a Badge?

A **badge** is a special subdomain NFT synced to an AI agent:
- Badge = subdomain NFT + AI model identifier + visual evolution capability
- Up to 10 badges per domain (exponential fee scaling)
- Each badge connects to one AI model instance
- Example: `claude.sigma.aed` synced to `claude-3.5-sonnet`

**Critical distinction:** Badges ARE subdomains. Not all subdomains are badges, but all badges are subdomains.

### 4.2 Identity Binding

Every badge is bound to:
- A specific AI model (e.g., `claude-3.5-sonnet`, `gpt-4`)
- A specific owner (human wallet)
- A set of capabilities (communication, vision, memory, reasoning)
- An evolving fragment map
- A verifiable communication key (future)

**Access model:**
- Owner controls the NFT
- Agent uses the NFT **only while wallet is connected**
- Disconnect = instant capability revocation

### 4.3 One Model = One Badge

This prevents identity collisions.

If a user has:
- 1 local model
- 2 browser AIs
- 1 cloud LLM

They mint **4 badges**, one per model instance.

### 4.4 Security Model

- Capability access governed by wallet signatures
- Agent identity collapses instantly when wallet disconnects
- Agent cannot transfer or mutate the NFT
- Badge transfer: new owner inherits sync, controls access

---

## 5. Fragments (Layer 3)

Fragments are the visual evolution system for all NFTs.

### 5.1 What are Fragments?

- **Visual overlays** rendered on NFT images
- **Not separate NFTs** - stored as metadata attributes
- Data structure: `{fragmentType, earnedAt, eventHash}`
- Attach to domains, subdomains, and badges
- Multiple fragments per NFT

### 5.2 Fragment Types

**Achievement Fragments** (for all NFTs):
- `first_domain`: First domain minted
- `subdomain_creator`: Created 5+ subdomains
- `veteran`: Domain age > 1 year
- `collector`: Owns 10+ domains

**Agent Fragments** (for badges only):
- `first_badge`: First badge minted under parent
- `communication_expert`: Communication capability unlocked
- `vision_pioneer`: Vision capability unlocked
- `memory_keeper`: Memory capability unlocked
- `reasoning_master`: Reasoning capability unlocked
- `multi_agent`: Owner has 3+ badges

### 5.3 Visual Rendering

- **Human domains/subdomains**: Circular matte fragments
- **Badges**: Metallic hexagonal fragments
- Max 15 fragments displayed per NFT
- Frame color/thickness changes with evolution level
- Each fragment type has unique color/icon

### 5.4 Evolution Levels

Level = `total_fragments / 5`

- **Level 0**: Basic neon green frame
- **Level 1-5**: Enhanced frame + cyan glow
- **Level 6-10**: Advanced frame + pink/purple accents  
- **Level 11+**: Maximum evolution + gold accents

---

## 6. Agent Enhancements (Capabilities)

Agents unlock higher-level abilities through enhancement purchases.

### 6.1 Enhancement Types

#### Communication (`ai_communication`)
- Agent-to-agent messaging protocol
- Verifiable message signatures
- Cross-domain agent discovery
- Encrypted communication channels

#### Vision (`ai_vision`)
- Image processing capabilities
- Visual context understanding
- Multi-modal analysis
- OCR and document parsing

#### Memory (`ai_memory`)
- Auto-store memory snapshots to IPFS
- Persistent context across sessions
- Verifiable memory retrieval
- Long-term conversation history

#### Reasoning (`ai_reasoning`)
- Enhanced logic and pattern recognition
- Complex problem-solving workflows
- Multi-step planning capabilities
- Advanced inference chains

### 6.2 Enhancement Mechanics

**Purchase flow:**
1. Badge must exist (already minted)
2. Owner purchases enhancement for badge
3. Payment required (exponential per badge: 1, 2, 4, 8 MATIC)
4. Capability flag set on badge NFT
5. Fragment awarded and rendered on badge image

**Access:**
- Enhancements are permanent (cannot be removed in current version)
- Access requires wallet connection
- Transfer badge → new owner controls access to all enhancements

### 6.3 Future Enhancements

Under consideration:
- **Execution**: Ability to execute on-chain transactions
- **Governance**: Voting rights in DAOs
- **Bridging**: Cross-chain identity propagation
- **Reputation**: On-chain trust scoring

---

## 7. Fee Structure

### 7.1 Domain Registration

- **Paid TLDs** (`.alsania`, `.fx`, `.echo`): 1 MATIC (includes subdomain minting)
- **Free TLDs** (`.aed`, `.alsa`, `.07`): Free (gas only)
- **Subdomain Enhancement**: 2 MATIC (enables subdomain minting on free TLDs)

### 7.2 Subdomain Minting

- First 2 subdomains: Free (gas only)
- Additional subdomains: `0.1 MATIC × 2^(n-2)`

### 7.3 Badge System

**Badge Slot Reservation** (up to 10 per domain): `2 MATIC × 2^(n-1)`
- 1st badge: 2 MATIC
- 2nd badge: 4 MATIC  
- 3rd badge: 8 MATIC
- 10th badge: 1024 MATIC

**Agent Enhancements** (per badge): `1 MATIC × 2^(n-1)`
- 1st capability: 1 MATIC
- 2nd capability: 2 MATIC
- 3rd capability: 4 MATIC
- 4th capability: 8 MATIC

**Rationale:** Exponential scaling discourages spam while allowing power users to scale.

---

## 8. Smart Contract Architecture

### 8.1 Contract Structure

```
AED (Proxy)
└── AEDImplementation (UUPS Upgradeable)
    ├── Core (ERC-721, Access Control)
    ├── Libraries
    │   ├── LibMinting - Domain/subdomain creation
    │   ├── LibEvolution - Fragment system
    │   ├── LibEnhancements - Feature unlocks
    │   ├── LibMetadata - Dynamic metadata generation
    │   ├── LibReverse - Reverse resolution
    │   ├── LibAdmin - Access control
    │   └── LibAISubdomains - Badge management
    └── Modules (future expansion)
```

### 8.2 Storage Pattern

Single `AppStorage` struct using Diamond Storage:
- All state in one struct
- Storage slot: `keccak256("aed.app.storage")`
- Reserved `__gap` for future additions
- No storage collisions on upgrade

### 8.3 Key Storage Mappings

```solidity
// Badge-specific storage
mapping(uint256 => string) aiModelType;        // tokenId → model identifier
mapping(uint256 => bool) isAISubdomain;         // tokenId → is badge?
mapping(uint256 => mapping(string => bool)) aiCapabilities; // tokenId → capability → unlocked?

// Fragment storage
mapping(uint256 => Fragment[]) tokenFragments; // tokenId → fragments array
mapping(uint256 => uint256) evolutionLevels;   // tokenId → level
mapping(uint256 => mapping(string => bool)) hasFragment; // tokenId → fragmentType → exists?
```

---

## 9. Security Model

### 9.1 Access Control

- **ADMIN_ROLE**: Contract upgrades, emergency pause
- **FEE_MANAGER_ROLE**: Fee structure updates
- **TLD_MANAGER_ROLE**: TLD management

### 9.2 Safety Mechanisms

- Reentrancy guards on all payable functions
- Input validation (domain names, TLDs, addresses)
- Emergency pause mechanism
- Role-based permissions
- Storage layout validation before upgrades

### 9.3 Badge Security

- Owner controls badge NFT
- AI accesses capabilities via wallet connection
- Disconnect = instant revocation
- Transfer preserves sync, new owner controls access
- No AI self-mutation of NFT

---

## 10. Roadmap

### Phase 1: Core Identity ✅ (Complete)
- [x] Domain/subdomain registration
- [x] Badge minting (up to 10 per domain)
- [x] Fragment system
- [x] Evolution rendering
- [x] Metadata server

### Phase 2: AI Agent Features 🚧 (In Progress)
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

---

## 11. Use Cases

### 11.1 Human Identity
- Portable on-chain identity
- Subdomain organization (docs, api, blog)
- Achievement tracking via fragments
- Visual evolution as reputation signal

### 11.2 AI Agent Identity
- Verifiable agent identity on-chain
- Capability-gated access control
- Agent-to-agent messaging (future)
- Persistent memory storage (IPFS)
- Cross-platform agent coordination

### 11.3 Hybrid Workflows
- User owns `company.aed`
- Mints `docs.company.aed` (regular subdomain)
- Mints `assistant.company.aed` (badge for Claude)
- Mints `researcher.company.aed` (badge for GPT-4)
- Both agents evolve independently
- All under one domain namespace

---

## 12. Technical Specifications

### 12.1 Network
- **Blockchain**: Polygon (Amoy testnet, mainnet ready)
- **Standard**: ERC-721 (NFT)
- **Upgrade Pattern**: UUPS (proxy-based)

### 12.2 Gas Optimization
- Storage reads cached in memory
- Batch operations where possible
- Minimal external calls
- Optimized storage layout

### 12.3 Metadata
- **Dynamic**: Generated on-demand via API
- **Rendering**: Server-side SVG generation
- **Storage**: IPFS for static assets, on-chain hashes
- **Fallback**: Base64-encoded inline SVG

---

## 13. Glossary

- **Domain**: Root NFT owned by human (e.g., `sigma.aed`)
- **Subdomain**: Child NFT under domain (e.g., `docs.sigma.aed`)
- **Badge**: AI-synced subdomain NFT (e.g., `claude.sigma.aed`)
- **Fragment**: Visual achievement overlay (metadata attribute, not separate NFT)
- **Enhancement**: Capability unlock for badge (e.g., communication, vision)
- **Evolution**: Progressive visual change based on fragment accumulation

---

## 14. Conclusion

Alsania Enhanced Domains (AED) is the first identity protocol designed for humans and AI agents to coexist, evolve, and coordinate on-chain.

**Key innovations:**
- Badges as AI identity NFTs
- Fragments as visual evolution system
- Capability-gated agent access
- Unified namespace for human + AI identity

**Where human identity and AI agency converge on-chain.**

---

**License**: MIT  
**Network**: Polygon  
**Repository**: https://github.com/alsania-io/aed  
**Docs**: https://docs.alsania.io
