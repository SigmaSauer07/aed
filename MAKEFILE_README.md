# Makefile Usage

The project Makefile provides a thin wrapper around the Hardhat tasks required to work with Alsania Enhanced Domains.

## Prerequisites

* Node.js 18+
* npm
* A configured `.env` file (see `.env.example`)

## Available Commands

| Command | Description |
|---------|-------------|
| `make install` | Install npm dependencies. |
| `make compile` | Compile smart contracts and export the storage layout to `build/storage-layout.txt`. |
| `make test` | Run the Hardhat test suite. |
| `make coverage` | Generate a Solidity coverage report. |
| `make clean` | Remove build artifacts (`artifacts/`, `cache/`, `coverage/`, `build/`). |

## Notes

* `make compile` automatically ensures the `build/` directory exists before writing the storage layout.
* All commands run locally; pass `--network <network>` directly to Hardhat if you need to target a live network.
The provided `Makefile` streamlines common project tasks. Before running commands ensure that Node.js 18+ is installed.

## Available Targets

- `make install` – installs npm dependencies. If your network blocks scoped packages (e.g. `@nomicfoundation/...`), configure npm to use the public registry: `npm config set @nomicfoundation:registry https://registry.npmjs.org/`.
- `make compile` – compiles the Solidity contracts with Hardhat.
- `make test` – runs the Hardhat test suite.
- `make coverage` – generates Solidity coverage metrics.
- `make metadata` – launches the Express metadata server located in `metadata-server/`.
- `make clean` – removes build caches (`cache/`, `artifacts/`, and `coverage/`).

All commands are idempotent and can be chained (e.g. `make install compile test`).
