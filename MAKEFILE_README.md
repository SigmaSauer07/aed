# Makefile Usage

The repository ships with a thin Makefile so repetitive Hardhat commands can be issued with memorable shortcuts.

## Available Targets

| Target | Description |
| --- | --- |
| `make install` | Install all npm dependencies (root project) |
| `make compile` | Compile Solidity contracts using Hardhat |
| `make test` | Run the mocha/Chai test-suite |
| `make coverage` | Generate Solidity coverage via `solidity-coverage` |
| `make deploy-amoy` | Deploy the AED proxy + implementation to Polygon Amoy |
| `make clean` | Remove Hardhat build artifacts and coverage output |

## Tips
- All commands execute from the repository root. If you need front-end tooling, run `npm install` inside the respective `frontend/*` directory.
- Environment variables are loaded from `.env`; copy `.env.example` to get started.
- For CI usage, chain commands, e.g. `make install && make compile && make test`.

# For Sigma. Powered by Echo.
