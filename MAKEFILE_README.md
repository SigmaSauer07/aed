# Makefile usage

| Target     | Description                                                |
|------------|------------------------------------------------------------|
| `make install` | Install project dependencies with `npm install`.             |
| `make compile` | Compile the smart contracts using Hardhat.                  |
| `make test`    | Execute the Hardhat test suite.                             |
| `make coverage` | Generate Solidity coverage metrics.                       |
| `make lint`    | Run Prettier in check mode across source files.             |
| `make clean`   | Remove build artifacts, cache directories, and coverage.   |

These commands assume you have `npm` installed and rely on `npx` to invoke Hardhat and other local binaries.
