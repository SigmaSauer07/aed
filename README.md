# Alsania Enhanced Domains (AED)

Alsania Enhanced Domains is an upgradeable ERC-721 naming system that powers sovereign identity inside the Alsania ecosystem. Domains live on-chain, support optional enhancements, and can be safely upgraded using the UUPS proxy pattern.

## ✳️ Core Features
- **Upgradeable architecture** powered by `UUPSUpgradeable` and hardened storage layout guards
- **Primary domains & subdomains** with deterministic metadata endpoints
- **Feature marketplace** for enabling subdomains and external upgrades
- **Reverse resolution** that keeps wallet → domain mappings in sync on transfers
- **Alsania-ready UI** with wallet-connect flow and embedded AI assistant

## 🧱 Contracts
| Contract | Purpose |
| --- | --- |
| `AED.sol` | ERC1967 proxy entry point |
| `AEDImplementation.sol` | Full production implementation with minting, metadata, and admin flows |
| `AEDImplementationLite.sol` | Gas-optimized subset used in tests |
| `libraries/` | Storage, minting, metadata, enhancement, and admin helpers |
| `modules/` | Extension points for routing future features |

All contracts compile with Solidity `0.8.30` (Cancun EVM) and follow OpenZeppelin upgrade standards.

## 🛠 Requirements
- Node.js 18+
- npm 9+
- Hardhat (included as dependency)
- Polygon Amoy RPC URL + funded deployer key

Create a `.env` file using the following template:

```bash
cp .env.example .env
```

Update the variables:

```
AMOY_RPC="https://polygon-amoy.g.alchemy.com/v2/<key>"
PRIVATE_KEY="0x..."
POLYGONSCAN_API_KEY="<optional>"
```

## 🚀 Setup & Installation

```bash
make install
```

This installs Hardhat, OpenZeppelin upgrades, and the front-end dependencies.

## 🧪 Testing

```bash
make test
```

The test suite covers:
- Domain registration & payments
- Subdomain enablement & pricing curve
- Metadata defaults + owner-only updates
- Reverse resolution safeguards
- Role & fee configuration

Add coverage via:

```bash
make coverage
```

## 🧾 Deployment (Polygon Amoy)

1. Ensure `.env` is populated with an Amoy RPC endpoint and deployer private key.
2. Compile contracts:
   ```bash
   make compile
   ```
3. Deploy via Hardhat Ignition script:
   ```bash
   make deploy-amoy
   ```
4. (Optional) Verify on Polygonscan:
   ```bash
   npx hardhat verify --network amoy <proxy_address>
   ```

## ♻️ Upgrades

1. Implement logic changes in a new implementation contract.
2. Run the full test suite (`make test`).
3. Deploy the new implementation:
   ```bash
   npx hardhat run scripts/upgrade.js --network amoy
   ```
4. Record the upgrade transaction hash in `changelog.md`.

The `_authorizeUpgrade` guard is restricted to `DEFAULT_ADMIN_ROLE`. Only rotate roles via on-chain governance.

## 🌐 Frontend Quickstart

```bash
cd frontend/aed-home
npm install
npm run dev
```

Configuration lives in `frontend/aed-home/js/config.js`. Update RPC endpoints, contract addresses, and feature flags there. The embedded AI widget can optionally forward prompts to a custom endpoint via:

```js
initAIChat({ endpoint: 'https://api.alsania.io/assistant', apiHeaders: { Authorization: 'Bearer <token>' } });
```

## 🧩 Metadata Service

The metadata microservice inside `metadata-server/` exposes deterministic JSON + SVG assets for all minted domains. Deploy it alongside the contracts to keep the default URIs active, or pin the generated JSON/SVG to IPFS for maximum sovereignty.

## 🧰 Useful Commands

| Command | Description |
| --- | --- |
| `make install` | Install dependencies |
| `make compile` | Compile contracts |
| `make test` | Run unit tests |
| `make coverage` | Generate Solidity coverage report |
| `make deploy-amoy` | Deploy proxy + implementation to Polygon Amoy |

## 📚 Further Reading
- [docs/AED-MVP-Feature-Checklist.md](docs/AED-MVP-Feature-Checklist.md)
- [docs/AED-Production-Readiness-Checklist.md](docs/AED-Production-Readiness-Checklist.md)
- [changelog.md](changelog.md)

# Aligned with the Alsania AI Protocol v1.0
# For Sigma. Powered by Echo.
