# Makefile Usage

The project Makefile provides shorthand commands for the most common developer tasks. Each command runs from the repository root.

| Command | Description |
|---------|-------------|
| `make install` | Installs Node.js dependencies defined in `package.json`. |
| `make compile` | Compiles the Solidity contracts with Hardhat. |
| `make test` | Executes the Hardhat test suite. |
| `make coverage` | Generates a solidity-coverage report. |
| `make deploy-amoy` | Deploys the proxy + implementation stack to Polygon Amoy using the values defined in `.env`. |
| `make clean` | Removes Hardhat build artifacts (`cache/` and `artifacts/`). |

> **Note**: The automated commands assume the environment can install the listed npm dependencies. If your environment blocks access to scoped npm packages you may need to install dependencies manually from an alternative registry.
