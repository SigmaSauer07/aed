# 🧠 Alsania Enhanced Domains (AED)

**AED** is the official on-chain domain system of the [Alsania](https://alsania.xyz) ecosystem. It provides sovereign, NFT-based domain ownership with programmable enhancements, subdomain minting, reverse resolution, customizable profiles, and native Web3 integrations.

Built to run lean, modular, and verifiable — AED is creator-first infrastructure on the Alsania chain (Polygon CDK).

---

## 🔩 Features

| Feature                        | Description |
|-------------------------------|-------------|
| 🆓 Free Domain Minting         | `.alsania`, `.aed`, `.fx`, `.07`, `.alsa` root domains are free to mint (gas-only) |
| 🪪 NFT Ownership                | Each domain is a transferable ERC721 NFT |
| 🎨 On-chain SVG Metadata       | Domains & subdomains rendered as styled, branded NFTs |
| 🔁 Reverse Resolution          | Auto links domain → wallet |
| 👤 Profile Support             | Add IPFS avatar, links, bio, connected NFTs |
| 🧬 Subdomain Minting (opt-in)  | Users can mint subdomains under their domain (like `vault.sigmasauer.fx`) |
| 💰 Monetization Controls       | Flat $2 unlock for subdomain minting per domain |
| 🧠 BYO Domain Support          | Link 3rd-party domains (e.g., ENS) for upgrades and subdomain control |
| 💎 Feature Enhancements (plug-and-play) | Upgrade domains with new abilities over time |
| 🧾 Recovery + Guardian Logic   | Domains support future recovery mechanisms |
| 🌐 Explorer + GitHub Pages Frontend | Fully on-chain, verifiable system |

---

## 🛠️ Smart Contract Architecture

### 🔗 `AED.sol` (Main Proxy Contract)
- Upgradeable (UUPS)
- Aggregates all AED modules
- Controls feature purchases, fees, and enhancement flags

### 📚 Modules

| Contract | Purpose |
|---------|---------|
| `AEDCore.sol`     | Base storage, access control, and init logic |
| `AEDMinting.sol`  | Free domain + subdomain minting (ERC721) |
| `AEDMetadata.sol` | On-chain SVG logic for tokenURI |
| `AEDReverse.sol`  | Reverse record (domain → wallet) |
| `AEDBridge.sol`   | Bridging logic (future upgrade path) |
| `AEDRecovery.sol` | Recovery/guardian slot system (future) |
| `AEDRegistry.sol` | BYO domain linking + feature flag logic |

---

## 💻 Frontend Architecture

| Page | Purpose |
|------|---------|
| `client.html` | Public domain minting UI |
| `aedprofile.html` | Profile & subdomain management |
| `admin.html` | Admin dashboard |
| `enhanced.html` | BYO domain enhancement UI |

- Wallet connection: MetaMask (ethers.js)
- Deployed frontend via GitHub Pages
- Config stored in `config.js`, ABIs in `js/aedABI.json`

---

## 💸 Monetization Logic

| Type | Description |
|------|-------------|
| Subdomain Unlock | One-time $2 (MATIC or ALSA) to enable subdomain minting on a domain |
| Subdomain Fee    | Linear pricing: 1st is free, 2nd is $0.10, then doubles (max 20) |
| BYO Upgrade Fee  | $5 one-time to add subdomain support to 3rd-party domains |
| Future Enhancements | $1/month or one-time add-ons via `purchaseFeature()` |

---

## 🚀 Deployment Info

| Network | Polygon Amoy (Testnet) |
|---------|------------------------|
| Proxy Address | `0x3Bf795D47f7B32f36cbB1222805b0E0c5EF066f1` |
| Fee Collector | `0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43` |

---

## 🛡️ Development Principles

- ✅ Free to deploy, free to use (gas only)
- ✅ Works on low-end hardware
- ✅ No vendor lock-in
- ✅ Modular upgrades, clean ABIs
- ✅ Honest monetization (no surprise fees)

---

## 🤝 Credits

Built with ❤️ by [Sigma](https://github.com/SigmaSauer07)  
Ecosystem: [Alsania](https://alsania.xyz)  
Chain: Polygon CDK (Aelion Testnet → Mainnet)

---

## 🧩 Coming Soon

- 🛍️ AlsaniaFX NFT Marketplace
- 🧠 AI Chatbot Avatars tied to domain NFTs
- 🧪 Domain-based apps, storefronts, DAOs
