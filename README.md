# Alsania Enhanced Domains (AED)

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
