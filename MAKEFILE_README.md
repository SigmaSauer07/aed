# Makefile Usage

The provided `Makefile` streamlines common project tasks. Before running commands ensure that Node.js 18+ is installed.

## Available Targets

- `make install` – installs npm dependencies. If your network blocks scoped packages (e.g. `@nomicfoundation/...`), configure npm to use the public registry: `npm config set @nomicfoundation:registry https://registry.npmjs.org/`.
- `make compile` – compiles the Solidity contracts with Hardhat.
- `make test` – runs the Hardhat test suite.
- `make coverage` – generates Solidity coverage metrics.
- `make metadata` – launches the Express metadata server located in `metadata-server/`.
- `make clean` – removes build caches (`cache/`, `artifacts/`, and `coverage/`).

All commands are idempotent and can be chained (e.g. `make install compile test`).
