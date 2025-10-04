# Alsania Enhanced Domains (AED)

Alsania Enhanced Domains (AED) is an upgradeable ERC-721 naming system with support for subdomains, on-chain metadata, reverse resolution, and paid feature upgrades. The system is designed for deployment on Polygon Amoy (or an Alsania L2 when available) and follows Alsania's sovereign design guidelines.

## Features

- **Upgradeable UUPS proxy** with strict access control for upgrades and administration.
- **Domain lifecycle management**: register top-level domains, enable subdomains, and batch mint native domains.
- **Dynamic pricing**: configurable TLD prices, enhancement fees, and automatic revenue routing to the fee collector.
- **Reverse records**: normalized reverse resolution that updates automatically on transfers.
- **Metadata and SVG rendering**: default IPFS-driven metadata with branded SVG fallbacks and profile/image URIs per domain.
- **Enhancement marketplace**: purchase subdomain enablement or upgrade third-party domains via on-chain feature flags.
- **Front-end client**: HTML/JS interface with wallet connect, dynamic pricing, and enhancement flows.
- **Test coverage**: Hardhat test suite covering registration, payments, upgrades, and reverse resolution.

## Requirements

- Node.js 18+
- npm 9+
- Python 3 (for `solidity-coverage`)
- Access to an RPC endpoint for Polygon Amoy

> **Note:** Installing scoped npm packages (e.g. `@nomiclabs/*` or `@openzeppelin/*`) requires internet access. Some sandbox environments may block these downloads; see the Testing section for details.

## Project Structure

```
contracts/            Solidity source files
contracts/libraries/  App storage, minting, metadata, enhancements, reverse resolution
contracts/core/       Shared domain structs and constants
contracts/test/       Upgradeable mock implementation for tests
frontend/             HTML/JS client (no framework, ethers.js powered)
metadata-server/      Optional metadata service (Node.js)
scripts/              Deployment scripts
Makefile              Developer shortcuts
```

## Setup

1. Clone the repository and install dependencies:

   ```bash
   git clone https://github.com/SigmaSauer07/aed
   cd aed
   make install
   ```

   If your network blocks scoped npm packages you may need to configure an alternative registry or install dependencies manually.

2. Create a `.env` file from the template and populate deployment secrets:

   ```bash
   cp .env.example .env
   # edit .env with your RPC URL, deployer key, admin, and fee collector
   ```

3. Compile the contracts:

   ```bash
   make compile
   ```

## Testing

Run the Hardhat test suite:

```bash
make test
```

If scoped npm packages cannot be installed in your environment you may see `E403 Forbidden` errors from npm. The source code and test suite remain valid; run the commands on a workstation with standard registry access.

Generate coverage:

```bash
make coverage
```

### Resolving npm 403 errors

Some hardened environments block scoped packages such as `@nomiclabs/*`. If `npm install` fails with `E403 Forbidden`:

1. Ensure you are using the public npm registry and not a proxy that strips scoped packages:

   ```bash
   npm config set registry https://registry.npmjs.org/
   npm config set @nomiclabs:registry https://registry.npmjs.org/
   npm config set @nomicfoundation:registry https://registry.npmjs.org/
   ```

2. If your organization enforces authenticated downloads, create an npm access token and configure it:

   ```bash
   npm login --registry=https://registry.npmjs.org/
   npm set //registry.npmjs.org/:_authToken="<YOUR_TOKEN>"
   ```

3. Retry dependency installation or regenerate the lockfile:

   ```bash
   npm install --no-fund --no-audit
   npm install --package-lock-only --ignore-scripts
   ```

Run the commands from a machine with standard internet access if the sandbox remains restricted.

## Deployment

1. Ensure `.env` contains the target RPC endpoint, deployer key, admin, and fee collector.
2. Deploy the proxy + implementation to Polygon Amoy:

   ```bash
   make deploy-amoy
   ```

3. Verify the proxy using `@nomiclabs/hardhat-etherscan` (requires `POLYGONSCAN_API_KEY`).

## Front-end Usage

The public client lives in `frontend/aed-home/`. Serve the directory or open `index.html` directly in a browser:

```bash
# example using a lightweight static server
npx serve frontend/aed-home
```

- Connect a wallet (MetaMask) on Polygon Amoy.
- Pricing data is loaded from the deployed contract. The client stores the proxy address in `localStorage` so you can override it for testing.
- Register free or paid domains, enable subdomains, or upgrade external domains through the UI.

## Upgrades

A lightweight alias contract (`AEDImplementationLite`) inherits the main implementation to maintain backward compatibility for tooling. A test-only `AEDImplementationV2` demonstrates safe upgrades. To perform a production upgrade:

1. Deploy the new implementation contract.
2. Call `upgrades.upgradeProxy` (see `test/AED.test.js` for an example).
3. Confirm state continuity (`ownerOf`, `totalRevenue`, etc.).

## Known Limitations

- npm scope restrictions may prevent dependency installation in hardened sandboxes. Configure an npm token or alternative registry if you encounter `E403` errors.
- Gas reporter requires `REPORT_GAS=true` and a CoinMarketCap API key for fiat prices.

## Useful Commands

Refer to [MAKEFILE_README.md](MAKEFILE_README.md) for a command summary.
