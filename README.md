# Alsania Enhanced Domains (AED)

Alsania Enhanced Domains is an upgradeable ERC-721 naming protocol that mints sovereign domain NFTs with programmable enhancements, reverse resolution, and dynamic metadata. The system is designed for deployment on Polygon Amoy (or the Alsania mainnet when available) and exposes both a user-facing portal and an operations console.

## Repository Layout

```
contracts/           Solidity sources (UUPS upgradeable)
frontend/aed-home/   Public dApp for registering and enhancing domains
frontend/aed-admin/  Admin console for fee routing, pricing, and roles
scripts/             Deployment scripts
test/                Hardhat tests covering core flows
Makefile             Helper commands for development
```

## Requirements

* Node.js 18+
* npm (with access to an offline mirror or a registry that allows direct package downloads)
* Optional: `http-server` (invoked via `npx`) for local frontend previews

## Environment Variables

Copy `.env.example` to `.env` and populate the following keys before deploying or running scripts:

```
AMOY_RPC=           # Polygon Amoy RPC endpoint
PRIVATE_KEY=        # Deployer private key (0x-prefixed)
POLYGONSCAN_API_KEY=# Polygonscan API key for verification
ALSANIA_ADMIN=      # Default admin wallet
ALSANIA_WALLET=     # Initial fee collector
```

## Installation & Compilation

```bash
make install       # npm install (uses only unscoped dependencies)
make compile       # hardhat compile
```

> **Offline friendly:** all Solidity dependencies are vendored inside `contracts/external/oz`. If npm access is still blocked entirely, copy a pre-installed `node_modules` directory that contains Hardhat 2.25.0, ethers 6.x, chai 4.x, and mocha 10.x into the project root before running the make targets.

## Testing

```bash
make test
```

The test suite covers:
* Proxy deployment and initialization
* Domain registration flows (free and paid TLDs)
* Subdomain minting and tiered pricing
* Metadata updates and reverse resolution
* Feature purchases, revenue accounting, and BYO upgrades
* Admin-only fee updates, TLD management, and role gating
* Pause / unpause controls and upgrade safety via UUPS

> **Note:** If npm access is completely disabled, provision dependencies offline (see the Installation section) and run the tests again. The repository's Hardhat configuration does not depend on any scoped npm packages.

## Frontend Development

Serve the stateless frontends with the provided Make targets:

```bash
make frontend-home   # Serves http://localhost:5173
make frontend-admin  # Serves http://localhost:5174
```

Both frontends load their configuration from `js/config.js`. Update `CONTRACT_ADDRESS`, `NETWORK`, and `RPC_URL` when deploying to a new chain. Branding follows Alsania's neon green (`#39ff14`) and navy (`#0a2472`) palette.

### User Portal (`frontend/aed-home`)
* Wallet connect via MetaMask (v5 ethers provider)
* Real-time pricing fetched from the contract (`getTLDPrice`, `getFeaturePrice`)
* Registration and enhancement flows with transparent totals and refund handling

### Admin Console (`frontend/aed-admin`)
* Network snapshot (total supply, revenue, fee collector, pause status)
* Update fee recipient, configure TLD pricing/activation
* Manage feature pricing and add new enhancement flags
* Grant/revoke core roles (admin, fee manager, TLD manager, bridge manager)
* Pause/unpause the protocol

## Deployment

A deployment script is provided at `scripts/deploy.js`. It deploys the implementation and the lightweight `AED` proxy wrapper without relying on the Hardhat upgrades plugin. Ensure `.env` is populated, then execute:

```bash
npx hardhat run scripts/deploy.js --network amoy
```

The script logs proxy and implementation addresses to `deployedAddress.txt`.

## Upgrade Guidance

* The contract inherits `UUPSUpgradeable`; only `DEFAULT_ADMIN_ROLE` can authorize upgrades.
* Storage layout is anchored by `AppStorage` with a reserved gap.
* Always bump the `version()` string when deploying a new implementation and extend the test suite with regression cases.

## Security Notes

* All admin operations are gated by role checks (`ADMIN_ROLE`, `FEE_MANAGER_ROLE`, `TLD_MANAGER_ROLE`, `BRIDGE_MANAGER_ROLE`).
* Payment flows use pull-style `call` transfers with reentrancy guards.
* Domain metadata defaults to on-chain SVG/JSON (no mutable HTTP endpoints).
* Reverse resolution automatically clears on transfer.

## License

MIT © Alsania Sovereign Systems
