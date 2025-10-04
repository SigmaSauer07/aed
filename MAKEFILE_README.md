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
