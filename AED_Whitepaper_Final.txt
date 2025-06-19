# Alsania Enhanced Domains (AED)
## A Sovereign Identity and Naming Protocol

### ✨ Vision and Purpose
Alsania Enhanced Domains (AED) is a fully sovereign, upgradable, and gas-efficient on-chain domain registry protocol, designed to replace and surpass the capabilities of ENS and Unstoppable Domains. It gives users full control over root domains, allows minting of subdomain NFTs, and integrates seamlessly with decentralized storage and cross-chain identity systems.

AED enables custom TLDs, visualized subdomains, metadata profiles, and ownership recovery — all designed under Sigma’s principles of freedom, modularity, and resilience.

---

### 🌐 Core Principles
- **Sovereignty**: Users own root domains and control minting/subdomains.
- **Decentralization**: Data is stored on-chain and pinned via IPFS (Crust preferred).
- **Affordability**: Everything deployable and mintable for under 1 MATIC.
- **Modularity**: Built on UUPS upgradeable contracts, with role-based access control.
- **Cross-Chain Future**: Designed for Polygon, but ready for CCIP/LayerZero bridging.
- **Visual Identity**: Subdomains are minted as SVG NFTs showing full domain name and random visuals.

---

### 🔧 Smart Contract Stack
- **EnhancedDomain.sol**:
  - ERC721Upgradeable with URI storage
  - Role-based access (ADMIN, UPGRADER)
  - Register root domains
  - Mint subdomains with optional linear mint fee
  - Inline SVG rendering for subdomain NFTs
  - Profile + image URI for customization

- **Upgradeable Architecture**:
  - `UUPSUpgradeable` via OpenZeppelin
  - `AccessControl` for security and modular governance
  - `Pausable`, `MerkleProof`, and `ECDSA` for feature support

---

### 🎨 Metadata and Visuals
- **Inline SVGs**: Subdomain NFTs are visually rendered on-chain using `<svg>` with:
  - Neon green text
  - Dark navy background
  - Full domain name centered
- **Metadata Fields**:
  - `name`: full domain (e.g. `n3xt.fx`)
  - `image`: user-uploaded URI or fallback SVG
  - `external_url`: profile or landing page

---

### 🧩 Registry Overlay Model
- AED supports:
  - Native TLDs: `.als`, `.fx`, `.07`, `.alsa`, `.alsania`
  - External domains: Link and enhance existing ENS or other names
- Owners of valid external names can self-register overlays and gain access to AED features

---

### 💸 Subdomain Minting Fee System
- Root owners can set:
  - `mintFee` (starting fee)
  - `feeEnabled` (toggle)
- Fee scales linearly with `subdomainCount`
- Admins can mint freely or set custom caps per domain

---

### 🔒 Recovery, Roles, and Security
- `ADMIN_ROLE`: Set image/profile URIs, pause/unpause
- `UPGRADER_ROLE`: Perform contract upgrades
- Recovery: Optionally link multiple wallets or implement guardian structures

---

### 🧪 Deployment Plan
- ✅ Build and test in Remix
- ✅ Deploy to Polygon Amoy (testnet)
- 🔜 Migrate to Hardhat for upgrade scripts
- 🔜 Pin metadata/images via Crust
- 🔜 Launch frontend: mint, edit, view domains
- 🔜 Bridge logic and overlay registration

---

### 🚀 Roadmap
1. ✅ Contract upgradeability + role logic
2. ✅ Mintable subdomains with SVG
3. 🔜 Crust IPFS setup + uploader
4. 🔜 Frontend UI with domain editor
5. 🔜 Bridge + Overlay system (external domains)
6. 🔜 Launch native `.als`, `.fx`, `.07`, `.alsania`
7. 🔜 Full GitHub repo and audit docs

---

### 📜 License
MIT © 2025 Sigma (Alsania Labs)
