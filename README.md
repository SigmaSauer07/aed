# Alsania Enhanced Domains (AED)

Alsania Enhanced Domains (AED) is an upgradeable ERC-721 domain registry that supports subdomains, dynamic metadata, SVG image rendering, and paid feature upgrades. Contracts are designed for UUPS upgradeability, align with Alsania's branding, and target the Polygon Amoy testnet.

## Features

- **Upgradeable architecture** – UUPS proxies with storage layout guard rails.
- **Rich domain data** – On-chain structs track profile URIs, image URIs, and feature flags.
- **Dynamic metadata** – Automatic profile/image defaults with inline SVG fallbacks.
- **Feature marketplace** – Purchase add-ons (subdomains, metadata, reverse, bridging) with transparent pricing.
- **Reverse resolution** – Primary domain assignment with automatic updates on transfer.
- **Batch operations** – Batch registration with precise fee handling.
- **Frontend** – Lightweight HTML/JS dashboard with live pricing sourced from the contract.

## Repository Structure

```
contracts/           Solidity sources (upgradeable implementation + libraries)
frontend/aed-home/   Static landing page + wallet actions
scripts/             Hardhat deployment scripts
test/                Hardhat tests (JavaScript + Foundry-style helpers)
```

## Requirements

- Node.js 18+
- npm 9+
- Polygon Amoy RPC endpoint (`AMOY_RPC`)
- Deployment private key with testnet funds (`PRIVATE_KEY`)
- Polygonscan API key for verification (`POLYGONSCAN_API_KEY`)

Copy `.env.example` to `.env` and edit the values before deploying.
Alsania Enhanced Domains is an upgradeable ERC-721 based domain naming system. Domains live as NFTs and support on-chain metadata, subdomains, enhancement add-ons, and reverse resolution. This repository ships the full smart-contract suite, a lightweight admin/home frontend, and a metadata server ready for deployment on Polygon Amoy (testnet) or the upcoming Alsania chain.

## Contents

- `contracts/` – UUPS upgradeable AED implementation, libraries, and supporting modules.
- `frontend/` – Static HTML/JS admin and public dApps styled for Alsania branding.
- `metadata-server/` – Express server that exposes NFT metadata endpoints.
- `scripts/` – Hardhat helpers for deployment, upgrades, and ABI generation.
- `test/` – Hardhat test suite covering minting, roles, fees, upgrades, and metadata.

## Prerequisites

- Node.js 18+
- npm 9+ (or Yarn 4+ via Corepack)
- Git

> **Note:** Some environments block scoped npm packages (e.g. `@nomicfoundation/*`). If you encounter HTTP 403 errors run `npm config set @nomicfoundation:registry https://registry.npmjs.org/` before installing dependencies.

## Installation

```bash
make install
```

## Smart Contract Tasks

| Command              | Description |
|---------------------|-------------|
| `make compile`       | Compile contracts and export storage layout to `build/storage-layout.txt` |
| `make test`          | Run the Hardhat test suite |
| `make coverage`      | Generate a solidity-coverage report |
| `make clean`         | Remove build artifacts |

All commands can be executed directly via `npx hardhat ...` if preferred.

## Testing

```bash
npx hardhat test
# or
make test
```

The suite covers:

- Domain + subdomain registration
- Metadata defaults
- Feature purchasing (including zero-cost metadata)
- Reverse resolution updates on transfer
- Batch operations and payment refunds
- Contract metadata (`contractURI`) and pricing helpers

## Frontend

`frontend/aed-home/` is a static site served with any HTTP server (or `npx http-server`). Key features:

- Wallet connection (MetaMask) with automatic network switching to Polygon Amoy.
- Live pricing fetched from the AED contract; falls back to configuration constants if RPC unavailable.
- Domain registration and enhancement flows with precise fee estimation.

Configuration lives in `frontend/aed-home/js/config.js`. Update the contract address, RPC endpoint, or fallback pricing before deploying.

## Deployment

1. Configure `.env` with RPC, private key, and Polygonscan API key.
2. Compile contracts: `make compile`
3. Deploy via Hardhat (example):

```bash
npx hardhat run scripts/deploy.js --network amoy
```

4. Verify the implementation with `npx hardhat verify --network amoy <implementation-address>`.

## Upgrade Process

1. Implement upgrades in a new contract (respecting storage layout).
2. Run `npx hardhat storage-layout` to confirm compatibility.
3. Deploy the new implementation.
4. Execute `upgradeTo` via Hardhat upgrades or governor tooling.

## Security Notes

- Administrative actions use `AccessControl` roles (`ADMIN_ROLE`, `FEE_MANAGER_ROLE`, `TLD_MANAGER_ROLE`).
- Feature prices and TLD fees are guarded by roles and surfaced via read functions for auditability.
- Default metadata URIs point to Alsania-hosted endpoints while retaining on-chain SVG fallbacks.
- The test suite enforces refund behaviour and zero-payment checks for free features.

## Support

For issues or feature requests, open an issue on the repository or reach out through the Alsania community channels.
npm install
```

The root `Makefile` mirrors the common commands:

```bash
make install      # npm install
make compile      # npx hardhat compile
make test         # npx hardhat test
make metadata     # node metadata-server/metadata-server.js
```

## Testing

Run the full test suite:

```bash
npx hardhat test
```

The tests deploy the upgradeable proxy, exercise registration flows, validate fee routing, and confirm upgrade safety via a mock V2 implementation.

Generate coverage reports:

```bash
npx hardhat coverage
```

## Deployment

1. Set environment variables (or fill `.env`):
   - `ALSANIA_ADMIN` – address that receives default admin roles.
   - `ALSANIA_WALLET` – fee collector wallet.
   - `AMOY_RPC` – Polygon Amoy RPC endpoint.
   - `PRIVATE_KEY` – deployment key (never commit secrets).
2. Compile contracts: `npx hardhat compile`.
3. Deploy: `npx hardhat run scripts/deploy.js --network amoy`.
4. Verify (optional): configure `POLYGONSCAN_API_KEY` and run `npx hardhat verify --network amoy <proxy>`.

## Upgrade Process

The AED proxy uses the UUPS pattern. To upgrade:

1. Implement the new logic contract (e.g. `AEDImplementationV2` inheriting from `AEDImplementation`).
2. Deploy upgrades: `npx hardhat run scripts/upgrade-implementation.js --network amoy`.
3. Execute `grantRole(DEFAULT_ADMIN_ROLE, <upgrader>)` if necessary before calling the upgrade script.

## Frontend

- `frontend/aed-home/` – public minting portal. Configuration lives in `frontend/config.js` (contract address, network chain ID, RPC URL). The page connects via Ethers v6 and calls `estimateDomainPrice` to display real-time pricing.
- `frontend/aed-admin/` – admin dashboard for roles, TLD configuration, fee tuning, and metadata updates. The dashboard reuses the shared ABI and leverages the same config file.

Both frontends are static assets and can be hosted on any CDN/static host.

## Metadata Server

`metadata-server/metadata-server.js` exposes two endpoints:

- `GET /domain/:tokenId.json`
- `GET /sub/:tokenId.json`

The server reads on-chain data via the configured RPC and contract address. Configure environment variables before running:

```
export RPC_URL="https://rpc-amoy.polygon.technology"
export CONTRACT_ADDRESS="0x6452DCd7Bbee694223D743f09FF07c717Eeb34DF"
node metadata-server/metadata-server.js
```

## Configuration

- Contract/network constants for the frontends live in `frontend/config.js`.
- Default fee and enhancement pricing is stored in contract storage and adjustable through the admin dashboard.
- SVG metadata colors follow Alsania branding (`#39FF14` neon green, `#0A2472` navy).

## Security Considerations

- Access control is enforced via `AccessControlUpgradeable` roles (`ADMIN_ROLE`, `FEE_MANAGER_ROLE`, `TLD_MANAGER_ROLE`).
- All payable entry-points are protected by `ReentrancyGuardUpgradeable` and use safe `call` payouts.
- Storage layout uses a single `AppStorage` struct to maintain upgrade safety. New mappings are appended before the reserved gap.

## Troubleshooting

- **403 during npm install** – run `npm config set @nomicfoundation:registry https://registry.npmjs.org/` or use an alternate network with registry access.
- **ABI mismatch on frontend** – regenerate from contracts via `npx hardhat compile` followed by `node scripts/generate-abi.js` (once dependencies are installed).
- **Metadata previews stale** – restart the metadata server or clear local storage for the admin UI.

## License

This project is released under the MIT License. See `LICENSE` for details.
