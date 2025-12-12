# Alsania Enhanced Domains (AED) 🚀

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Polygon](https://img.shields.io/badge/Network-Polygon%20Amoy-blue.svg)](https://polygon.technology/)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.30-363636.svg)](https://soliditylang.org/)

Alsania Enhanced Domains (AED) is an upgradeable ERC-721 domain registry built for sovereignty, featuring subdomains, dynamic metadata, SVG image rendering, and paid feature upgrades. Designed for UUPS upgradeability and aligned with Alsania's neon green/navy branding.

## ✨ Key Features

- 🔄 **Upgradeable Architecture** – UUPS proxies with storage layout protection
- 🎨 **Rich Domain Data** – On-chain profile URIs, image URIs, and feature flags
- 📊 **Dynamic Metadata** – Automatic defaults with inline SVG fallbacks
- 💰 **Feature Marketplace** – Transparent pricing for subdomains, metadata, reverse, bridging
- 🔄 **Reverse Resolution** – Primary domain assignment with automatic updates
- ⚡ **Batch Operations** – Efficient batch registration with precise fee handling
- 🌐 **Frontend Dashboard** – Lightweight HTML/JS with live pricing integration

## 🏗️ Project Architecture

```
📁 contracts/           Solidity smart contracts (UUPS upgradeable)
📁 frontend/aed-home/   Public domain registration portal
📁 frontend/aed-admin/  Administrative dashboard
📁 metadata-server/     NFT metadata API server
📁 scripts/            Hardhat deployment & utility scripts
📁 test/               Comprehensive test suite
```

## 🛠️ Quick Start

### Prerequisites
- Node.js 18+
- npm 9+
- Polygon Amoy testnet access
- MetaMask wallet

### Installation
```bash
# Clone the repository
git clone https://github.com/alsania-io/aed.git
cd aed

# Install dependencies
make install
# or
npm install
```

### Environment Setup
```bash
# Copy and configure environment variables
cp .env.example .env

# Edit .env with your configuration:
# AMOY_RPC=https://rpc-amoy.polygon.technology
# PRIVATE_KEY=your_private_key_here
# POLYGONSCAN_API_KEY=your_api_key
```

### Development Commands
```bash
make compile      # Compile contracts
make test         # Run test suite
make coverage     # Generate coverage report
make clean        # Clean build artifacts
```

## 🧪 Testing

Run the comprehensive test suite:
```bash
npx hardhat test
```

The test suite covers:
- Domain & subdomain registration flows
- Metadata generation and SVG rendering
- Feature purchasing and fee calculations
- Reverse resolution updates
- Batch operations and payment handling
- Contract upgrade safety

## 🚀 Deployment

### Smart Contract Deployment
```bash
# Compile contracts
npx hardhat compile

# Deploy to Polygon Amoy
npx hardhat run scripts/deploy.js --network amoy

# Verify on Polygonscan
npx hardhat verify --network amoy <contract-address>
```

### Frontend Deployment
```bash
# Serve frontend locally
npx http-server frontend/aed-home

# Or deploy to any static hosting service
```

### Metadata Server
```bash
# Configure environment
export RPC_URL="https://rpc-amoy.polygon.technology"
export CONTRACT_ADDRESS="your_deployed_contract_address"

# Start metadata server
node metadata-server/metadata-server.js
```

## 🔧 Configuration

### Contract Settings
- Network: Polygon Amoy Testnet
- Contract: UUPS Upgradeable ERC-721
- Admin Roles: `ADMIN_ROLE`, `FEE_MANAGER_ROLE`, `TLD_MANAGER_ROLE`

### Frontend Configuration
Update `frontend/aed-home/js/config.js`:
```javascript
export const config = {
  CONTRACT_ADDRESS: "your_contract_address",
  RPC_URL: "https://rpc-amoy.polygon.technology",
  CHAIN_ID: 80002, // Polygon Amoy
  NETWORK_NAME: "Polygon Amoy"
};
```

## 🛡️ Security Features

- **Access Control**: Role-based permissions using OpenZeppelin's `AccessControlUpgradeable`
- **Reentrancy Protection**: All payable functions protected with `ReentrancyGuardUpgradeable`
- **Upgrade Safety**: Single `AppStorage` struct with reserved storage gap
- **Input Validation**: Comprehensive parameter checking and bounds validation

## 🔄 Upgrades

The AED system uses UUPS (Universal Upgradeable Proxy Standard) for upgrades:

1. **Implement**: Create new contract version respecting storage layout
2. **Validate**: Run `npx hardhat storage-layout` to confirm compatibility
3. **Deploy**: Use the upgrade script: `npx hardhat run scripts/upgrade-implementation.js --network amoy`
4. **Execute**: Call `upgradeTo()` with appropriate admin permissions

## 📚 API Reference

### Core Functions
- `registerDomain(string memory name, address owner)` - Register new domain
- `purchaseEnhancement(uint256 tokenId, EnhancementType enhancement)` - Buy features
- `setPrimaryDomain(uint256 tokenId)` - Set primary domain
- `estimateDomainPrice(string memory name)` - Get registration cost

### Metadata Endpoints
- `GET /domain/:tokenId.json` - Domain metadata
- `GET /sub/:tokenId.json` - Subdomain metadata

## 🎨 Design System

AED follows Alsania's design principles:
- **Primary Color**: `#39FF14` (Neon Green)
- **Secondary Color**: `#0A2472` (Navy)
- **Typography**: Clean, modern fonts
- **UI**: Minimalist, sovereignty-focused design

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues**: [GitHub Issues](https://github.com/alsania-io/aed/issues)
- **Documentation**: [Project Wiki](https://github.com/alsania-io/aed/wiki)
- **Community**: [Alsania Discord](https://discord.gg/alsania)

---

**Built with ❤️ for digital sovereignty by the Alsania team**
