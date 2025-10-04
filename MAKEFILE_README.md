# AED Project Makefile Guide

The included `Makefile` provides shortcuts for common development tasks.

## Prerequisites
* Node.js 18+
* npm with access to a registry or local mirror that can serve the required packages
* For the frontend preview targets, `http-server` is invoked via `npx`.

## Targets
* `make install` – install npm dependencies for the Hardhat workspace.
* `make compile` – compile all Solidity contracts with Hardhat.
* `make test` – run the Hardhat test suite.
* `make frontend-home` – serve the user portal from `frontend/aed-home` on port `5173`.
* `make frontend-admin` – serve the admin console from `frontend/aed-admin` on port `5174`.
* `make clean` – remove build artifacts, coverage output, and `node_modules`.

Each command can be invoked individually, e.g. `make test`. The frontend commands run until interrupted (Ctrl+C). If npm cannot reach the registry, copy a prepared `node_modules` directory into the project root before using the Makefile.
