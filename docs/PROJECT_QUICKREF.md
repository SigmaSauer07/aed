# AED Project Quick Reference

## 📁 Project Structure
```
aed/
├── 📄 README.md                     # Main project documentation
├── 📄 LICENSE                       # MIT License
├── 📄 .gitignore                   # Git ignore rules
├── 📄 package.json                 # Node.js dependencies
├── 📄 hardhat.config.js            # Hardhat configuration
├── 📄 Makefile                     # Common build commands
├── 📄 .env.example                 # Environment template
│
├── 📁 contracts/                   # Smart Contracts
│   ├── 📄 AED.sol                 # Proxy contract
│   ├── 📁 core/                   # Core implementation
│   ├── 📁 modules/                # Feature modules
│   ├── 📁 libraries/              # Utility libraries
│   └── 📁 interfaces/             # Contract interfaces
│
├── 📁 frontend/                    # Web Applications
│   ├── 📁 aed-home/              # Public domain portal
│   └── 📁 aed-admin/             # Admin dashboard
│
├── 📁 metadata-server/             # NFT Metadata API
│   ├── 📄 metadata-server.js     # Express server
│   └── 📄 package.json           # Server dependencies
│
├── 📁 scripts/                     # Deployment Scripts
│   ├── 📄 deploy.js              # Main deployment
│   ├── 📄 upgrade-implementation.js # Contract upgrades
│   └── 📄 generate-abi.js        # ABI generation
│
├── 📁 test/                        # Test Suite
│   ├── 📄 AED.test.js            # Main contract tests
│   └── 📄 deployment.test.js     # Deployment tests
│
├── 📁 docs/                        # Documentation
│   ├── 📄 REPOSITORY_CREATION_GUIDE.md
│   ├── 📄 DEPLOYMENT_GUIDE.md
│   └── 📄 PROJECT_QUICKREF.md    # This file
│
└── 📁 deprecated/                 # Archived files
    ├── 📁 development/            # Development artifacts
    ├── 📁 assets/                 # Old assets
    └── 📁 logs/                   # Log files
```

## 🚀 Quick Commands

### Development
```bash
make install    # Install dependencies
make compile    # Compile contracts
make test       # Run tests
make clean      # Clean build artifacts
```

### Deployment
```bash
# Deploy to Polygon Amoy
npx hardhat run scripts/deploy.js --network amoy

# Upgrade implementation
npx hardhat run scripts/upgrade-implementation.js --network amoy

# Generate ABI
node scripts/generate-abi.js
```

### Frontend
```bash
# Start local server
npx http-server frontend/aed-home -p 3000

# Deploy to Vercel
vercel --prod frontend/aed-home
```

## 🔗 Important Links

- **Repository**: https://github.com/alsania-io/aed
- **Polygon Amoy RPC**: https://rpc-amoy.polygon.technology
- **Polygonscan**: https://amoy.polygonscan.com
- **MetaMask**: https://metamask.io

## 📝 Environment Setup

Copy `.env.example` to `.env` and configure:
```bash
AMOY_RPC=https://rpc-amoy.polygon.technology
PRIVATE_KEY=your_private_key
POLYGONSCAN_API_KEY=your_api_key
ALSANIA_ADMIN=0xYourAddress
ALSANIA_WALLET=0xYourWallet
```

## 🧪 Testing

```bash
# Run all tests
npx hardhat test

# Generate coverage
npx hardhat coverage

# Check contract functions
npx hardhat run scripts/check-contract-functions.js --network amoy
```

## 🔧 Configuration

### Contract Settings
- Network: Polygon Amoy (Chain ID: 80002)
- Gas Limit: Adjust in `hardhat.config.js`
- Proxy: UUPS upgradeable pattern

### Frontend Config
Update `frontend/aed-home/js/config.js`:
```javascript
export const config = {
  CONTRACT_ADDRESS: "0x...",
  RPC_URL: "https://rpc-amoy.polygon.technology",
  CHAIN_ID: 80002
};
```

## 🚨 Security Notes

- Never commit `.env` files
- Keep private keys secure
- Verify contracts on Polygonscan
- Test upgrades on testnet first
- Use role-based access control

## 🆘 Troubleshooting

### Installation Issues
```bash
# Fix npm registry issues
npm config set @nomicfoundation:registry https://registry.npmjs.org/
npm install
```

### Deployment Issues
```bash
# Check RPC connection
curl -X POST https://rpc-amoy.polygon.technology -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# Check account balance
npx hardhat run scripts/check-balance.js --network amoy
```

## 📈 Next Steps

1. **Create GitHub Repository**: Follow `docs/REPOSITORY_CREATION_GUIDE.md`
2. **Configure Environment**: Set up `.env` with all required keys
3. **Deploy Contracts**: Run deployment scripts to Polygon Amoy
4. **Update Frontend**: Configure contract addresses in frontend
5. **Test Everything**: Verify all functionality works
6. **Deploy Frontend**: Use Vercel, Netlify, or GitHub Pages
7. **Set Up Monitoring**: Configure alerts and tracking

---

**For detailed instructions, see:**
- 📚 `README.md` - Complete project overview
- 🚀 `docs/DEPLOYMENT_GUIDE.md` - Step-by-step deployment
- 📋 `docs/REPOSITORY_CREATION_GUIDE.md` - Repository setup

Built with ❤️ for digital sovereignty by Alsania