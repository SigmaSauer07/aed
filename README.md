
# Alsania Enhanced Domains (AED)

Production‑ready, modular, upgradeable smart‑contract system for on‑chain domains & subdomains.

## Modules
* `AEDCore` – storage, roles, counters
* `AEDMinting` – domain & sub‑domain mint / renewal
* `AEDBridge` – Merkle proof cross‑chain bridge receipts
* `AEDRecovery` – guardian‑based social recovery
* `AEDMetadata` – on‑chain SVG + adjustable royalties

## Quick Start

```bash
npm install
cp .env.example .env   # add PRIVATE_KEY
npx hardhat test
npx hardhat run scripts/deploy.js --network mumbai
```

## License
MIT
