# AGENTS.md - AED Development Guide

## Build/Test Commands
- `npm test` - Run all tests
- `npx hardhat test test/aed.test.js` - Run specific test file
- `npx hardhat test --grep "test name"` - Run specific test by name
- `npx hardhat compile` - Compile contracts
- `npx hardhat node` - Start local blockchain
- `npm run deploy:mumbai` - Deploy to Amoy testnet

## Architecture
- **Smart Contracts**: Modular UUPS proxy system with diamond pattern AppStorage
- **Core Files**: AED.sol (main proxy), AEDImplementation.sol, contracts/core/AppStorage.sol
- **Frontend**: Vanilla JS/HTML/CSS only (no React/frameworks), multiple apps in frontend/
- **Testing**: Hardhat with both .js and .sol test files
- **Networks**: Hardhat local (1337), Amoy testnet (80002)

## Code Style & Rules (from rules.md)
- **Solidity**: 0.8.30+, OpenZeppelin, UUPS upgradeable, gas optimized
- **Frontend**: HTML + vanilla JS only, no React unless explicitly requested
- **Testing**: Always write comprehensive tests, use proper folder structure
- **Security**: Use access control, never expose external call surfaces
- **No placeholders**: All code must be complete and functional
