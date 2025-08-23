---
description: Repository Information Overview
alwaysApply: true
---

# Alsania Enhanced Domains (AED) Information

## Summary
Alsania Enhanced Domains (AED) is a modular, upgradeable Web3 domain system built for identity sovereignty. It allows users to mint root domains, unlock enhancements like subdomains, and upgrade third-party domains with Alsanian features. The project uses a UUPS proxy pattern with clean AppStorage and modular architecture.

## Structure
- **contracts/**: Solidity smart contracts with modular architecture
- **frontend/**: Vanilla JS frontend components and pages
- **scripts/**: Deployment and interaction scripts
- **test/**: Contract test files
- **legal/**: Legal documentation and policies
- **assets/**: Image assets for domain backgrounds

## Language & Runtime
**Language**: Solidity, JavaScript
**Solidity Version**: 0.8.30
**EVM Version**: Cancun
**Build System**: Hardhat
**Package Manager**: npm

## Dependencies
**Main Dependencies**:
- @openzeppelin/contracts: ^5.3.0
- @nomicfoundation/hardhat-verify: ^2.0.14

**Development Dependencies**:
- hardhat: ^2.25.0
- @openzeppelin/contracts-upgradeable: ^5.3.0
- @openzeppelin/hardhat-upgrades: ^3.9.0
- @nomicfoundation/hardhat-toolbox: ^6.0.0
- ethers: ^6.15.0
- dotenv: ^17.2.0

## Build & Installation
```bash
# Install dependencies
npm install

# Run tests
npm test

# Deploy to Amoy testnet
npm run deploy:mumbai
```

## Smart Contract Architecture
The project uses a UUPS proxy pattern with modular architecture:
- **AED.sol**: Main proxy contract
- **AEDImplementation.sol**: Implementation contract
- **core/**: Core contract functionality
- **modules/**: Pluggable modules for different features
- **libraries/**: Shared functionality across modules

Key modules include:
- Admin module for role-based access control
- Minting module for domain registration
- Metadata module for domain information
- Registry module for feature management
- Reverse resolution module for wallet-to-domain mapping

## Frontend
The frontend is built with Vanilla JavaScript without frameworks:
- **AEDHome/**: Main landing page and domain registration
- **AEDAdmin/**: Admin dashboard for contract management
- **components/**: Reusable UI components
- **ai-components/**: AI integration components

## Testing
**Framework**: Hardhat test
**Test Location**: test/
**Naming Convention**: *.test.js for JS tests, *Test.sol for Solidity tests
**Run Command**:
```bash
npx hardhat test
```