# 🧠 Alsania Enhanced Domains (AED)

> **Status:** Pre-Launch (Contracts and Frontends Built, Deployment Pending)

## 🧬 Decentralized Identity for Web3 and Beyond

Alsania Enhanced Domains (AED) is a **modular, upgradeable** Web3 domain system built for total identity sovereignty.
Users can mint their own root domains (e.g., `sigmasauer.fx`), unlock enhancements (like subdomains), and even upgrade third-party domains (like ENS/UD) with Alsanian features.

Built lean. Built ethical. Built for the builders.

---

## 🏗️ Smart Contract Architecture

All contracts use the **UUPS proxy pattern** with clean AppStorage and modular architecture.
> ✅ AED.sol is the main UUPS proxy.
> ✅ Every module has its own interface (IAED*.sol)
> ✅ All modules are plug and play style for easy upgrades, maintenance, and testing.
> ✅ Feature flags and enhancement payments are cleanly separated
> ✅ Uses centralized AppStorage.sol with Diamond/Facet-style layout
> ✅ Admin roles and permission gates enforced using LibAdmin, LibValidation, etc

---

## 🌐 Frontend System

Built with **Vanilla JS**, **no framework**, and optimized for low-end hardware.

> Alsanian Profile (`alsanian-pro.html`) is the new identity hub, replacing and expanding on the old `aedprofile.html`.
> Integrates AED, AlsaniaFX, AI, and more — modular and future-ready.

---

## 🌟 MVP Feature List

| Feature                     | Status | Notes |
|-----------------------------|--------|-------|
| 🆓 Free Domains             | ✅  | `.aed`, `.07`, `.alsa` — gas only |
| 💵 $1 Domains               | ✅  | `.alsania`, `.fx`, `.echo` |
| 🧬 Subdomain Minting        | ✅  | Unlockable via $2 enhancement |
| 👤 Profiles (IPFS)          | ✅  | Editable `profileURI`, `imageURI` |
| 🔁 Reverse Resolution       | ✅  | wallet ↔ domain mapping |
| 🎨 SVG tokenURI             | ✅  | Branded on-chain visuals |
| 🛠️ Feature Flags            | ✅  | Plug-in enhancements via `AEDRegistry` |
| 🧠 BYO Domain Upgrades      | ✅  | $5 to link ENS/UD to AED system |
| 🛡️ Role-Based Admin         | ✅  | `AEDAdmin.sol` control panel |
| 🔐 Upgradeable Architecture | ✅  | UUPS proxy pattern |

---

## 💸 Fee System (Configurable)

| Action                | Fee      | Notes |
|------------------------|-----------|-----------------------------|
| Free Domain            | $0        | `.aed`, `.07`, `.alsa` |
| Paid Domain            | $1        | `.alsania`, `.fx`, `.echo` |
| Subdomain Unlock       | $2        | One-time fee per domain |
| Subdomain Minting      | Linear    | First 2 = free, then $0.10 doubling |
| BYO Upgrade            | $5        | Upgrade ENS/UD domains |
| Future Enhancements    | $1+/mo    | Optional features (AI, themes, etc.) |

All revenue currently routes to:
`0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43` (later multisig/dao)


---

## 🔮 Future Roadmap

🧠 Future Modules & Roadmap
Feature	Status
🧠 AI Chatbots tied to domains	Planned
🧪 Domain-based DApps / DAOs	Planned
🧍‍♂️ Guardians & Recovery	Placeholder module (AEDRecovery.sol)
🧠 Governance DAO	Stub ready, needs front/backend
🛍️ AlsaniaFX NFT Marketplace	Actively in progress
🪪 Domain Leasing Models	Not started yet
🧬 Cross-chain ownership	AEDBridge.sol stub exists
📱 Native mobile app	Not started yet

---

## 🧱 Development Principles

- ✅ Gas-efficient
- ✅ Zero vendor lock-in
- ✅ Fully verifiable (IPFS, Explorer, GitHub)
- ✅ Honest monetization
- ✅ Sovereign-first architecture
- ✅ Low resource usage

---

## 🤝 Credits

**🧠 Sigma** — Creator & Architect
**💻 Echo** — Co-architect, Project Manager, Deployment Strategist
**🌐 Alsania** — Sovereign Ecosystem Chain

---

## 🔗 Quick Links

> Coming after deployment:

- 🌍 Live Frontend
- 📄 Docs
- 🧪 Testnet Explorer
- 🧠 GitHub: [github.com/SigmaSauer07/alsania-aed](https://github.com/SigmaSauer07/)

---

This version of AED is more than MVP. It’s creator-grade, modular, sovereign infrastructure — ready for mainnet with only minor polish.

 ---

 aed/
├── AED-MVP-Feature-Checklist.md
├── AED-Production-Readiness-Checklist.md
├── cache/
│   ├── solidity-files-cache.json
│   └── validations.json
├── contracts/
│   ├── AEDImplementation.sol
│   ├── AED.sol
│   ├── core/
│   │   ├── AEDConstants.sol
│   │   ├── AEDCore.sol
│   │   ├── AppStorage.sol
│   │   └── interfaces/
│   │       ├── IAEDCore.sol
│   │       └── IAEDModule.sol
│   ├── interfaces/
│   │   ├── external/
│   │   │   └── IERC721Extended.sol
│   │   └── modules/
│   │       ├── IAEDAdmin.sol
│   │       ├── IAEDBridge.sol
│   │       ├── IAEDEnhancements.sol
│   │       ├── IAEDMetadata.sol
│   │       ├── IAEDMinting.sol
│   │       ├── IAEDRecovery.sol
│   │       ├── IAEDRegistry.sol
│   │       └── IAEDReverse.sol
│   ├── libraries/
│   │   ├── AEDEvents.sol.bak
│   │   ├── LibAdmin.sol
│   │   ├── LibBridge.sol
│   │   ├── LibEnhancements.sol
│   │   ├── LibMetadata.sol
│   │   ├── LibMinting.sol
│   │   ├── LibModuleRegistry.sol
│   │   ├── LibModule.sol
│   │   ├── LibRecovery.sol
│   │   ├── LibRegistry.sol
│   │   ├── LibReverse.sol
│   │   ├── LibRoles.sol
│   │   └── LibValidation.sol
│   └── modules/
│       ├── admin/
│       │   └── AEDAdmin.sol
│       ├── base/
│       │   ├── ModuleBase.sol
│       │   └── ModuleRegistry.sol
│       ├── bridge/
│       │   └── AEDBridge.sol
│       ├── enhancements/
│       │   └── AEDEnhancements.sol
│       ├── future/
│       │   ├── AEDAnalytics.sol
│       │   ├── AEDGovernance.sol
│       │   └── AEDMessaging.sol
│       ├── metadata/
│       │   └── AEDMetadata.sol
│       ├── minting/
│       │   └── AEDMinting.sol
│       ├── recovery/
│       │   └── AEDRecovery.sol
│       ├── registry/
│       │   └── AEDRegistry.sol
│       └── reverse/
│           └── AEDReverse.sol
├── frontend/
│   ├── abi/
│   │   └── aedABI.json
│   ├── aed-admin/
│   │   ├── aed-admin.html
│   │   ├── css/
│   │   │   ├── ad.css
│   │   │   └── style.css
│   │   ├── img/
│   │   │   ├── AEDlogo.png
│   │   │   └── bg.png
│   │   └── js/
│   │       ├── aedABI.json
│   │       └── script.js
│   ├── aed-home/
│   │   ├── aed_home.html
│   │   ├── css/
│   │   │   └── ah.css
│   │   ├── img/
│   │   │   ├── AEDlogo.png
│   │   │   └── bg.png
│   │   └── js/
│   │       ├── aedABI.json
│   │       └── index.js
│   ├── assets/
│   │   └── img/
│   │       ├── domain_background.png
│   │       └── subdomain_background.png
│   └── components/
│       ├── component-loader.js
│       ├── footer.css
│       ├── footer.html
│       ├── header.css
│       ├── header.html
│       └── header.js
├── hardhat.config.js
├── legal/
│   ├── Cookie-Policy.md
│   ├── Legal-Implementation-Guide.md
│   ├── Privacy-Policy.md
│   └── Terms-of-Service.md
├── LICENSE
├── package.json
├── package-lock.json
├── README.md
├── scripts/
│   ├── checkState.js
│   ├── deploy.js
│   ├── mintTest.js
│   └── verify.js
└── test/
    ├── AEDCoreTest.sol
    ├── aed.test.js
    ├── basic.test.js
    ├── ModuleBase_test.sol
    └── modules/
        └── base/
