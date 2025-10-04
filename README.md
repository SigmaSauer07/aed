# Alsania Enhanced Domains (AED)

Alsania Enhanced Domains is an upgradeable ERC-721 naming system that supports subdomains, on-chain metadata, enhancement modules, and fee routing. The contracts follow the UUPS upgrade pattern and expose helper view methods for the web client to remain fully synchronized with on-chain pricing.

## Prerequisites

- Node.js 18+
- npm 9+
- A recent version of Hardhat (installed via `npm install`)

## Project setup

1. Install dependencies

   ```bash
   make install
   ```

2. Copy `.env.example` (if present) to `.env` and populate the following variables when deploying:

   ```ini
   PRIVATE_KEY=<deployer private key>
   AMOY_RPC=<Polygon Amoy RPC URL>
   POLYGONSCAN_API_KEY=<optional Polygonscan key>
   ```

3. Compile the contracts

   ```bash
   make compile
   ```

4. Run the full test suite (including upgrade tests and feature flows)

   ```bash
   make test
   ```

5. Generate coverage reports (optional)

   ```bash
   make coverage
   ```

`make lint` and `make clean` are also available for formatting checks and removing build artifacts. See `MAKEFILE_README.md` for a summary of each target.

## Deployment

The default Hardhat network configuration targets Polygon Amoy. Update your `.env` with a funded deployer key, then run:

```bash
npx hardhat run scripts/deploy.js --network amoy
```

After deploying a proxy, the project can be upgraded using Hardhat Upgrades. Example (also covered by tests):

```bash
const AEDImplementation = await ethers.getContractFactory("AEDImplementationV2Mock");
await upgrades.upgradeProxy(existingProxyAddress, AEDImplementation);
```

## Frontend configuration

The static frontend lives in `frontend/aed-home`. Configuration for the contract address, chain ID, and RPC endpoint is stored in `frontend/config/config.js`:

```javascript
window.AED_CONFIG = {
  networkName: "polygon-amoy",
  chainId: "0x13882",
  rpcUrl: "https://polygon-amoy-bor.publicnode.com",
  contractAddress: "0x6452DCd7Bbee694223D743f09FF07c717Eeb34DF",
};
```

Update `contractAddress` after deployment. The frontend automatically:

- Connects to the configured network (prompts to switch if necessary)
- Retrieves TLD and feature pricing directly from the contract
- Displays accurate totals for registrations and enhancements

To run the static site locally, serve the `frontend/aed-home` directory with any HTTP server (e.g. `npx http-server frontend/aed-home`).

## Key features

- Upgradeable ERC-721 proxy with explicit storage layout and future gaps
- Dynamic pricing and feature catalog managed via `LibEnhancements`
- Default on-chain profile metadata and themed SVG placeholders
- Role-based admin controls for fees, TLDs, and fee collection
- Comprehensive test suite covering minting, metadata, upgrades, transfers, and payments

## Additional notes

- Contract payments use `AddressUpgradeable.sendValue` and are protected by `ReentrancyGuardUpgradeable`.
- All user-facing strings (TLDs, feature names) are normalized for case-insensitive behavior.
- A mock upgrade implementation (`AEDImplementationV2Mock`) is included for testing upgrade flows.
