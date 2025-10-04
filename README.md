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
