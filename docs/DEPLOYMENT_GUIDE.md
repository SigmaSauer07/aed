# 🚀 AED Deployment & Setup Guide

## 📋 Prerequisites Checklist

### Development Environment
- [ ] Node.js 18+ installed
- [ ] npm 9+ or yarn installed
- [ ] Git configured with proper credentials
- [ ] MetaMask wallet installed
- [ ] Polygon Amoy testnet added to MetaMask

### Required Accounts & Keys
- [ ] Polygon Amoy testnet MATIC tokens
- [ ] Polygonscan API key (for contract verification)
- [ ] GitHub account with alsania-io org access

## 🛠️ Development Setup

### 1. Clone and Install
```bash
# Clone the repository
git clone https://github.com/alsania-io/aed.git
cd aed

# Install dependencies
make install
# or
npm install
```

### 2. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Configure your .env file:
cat > .env << EOF
# Network Configuration
AMOY_RPC=https://rpc-amoy.polygon.technology
POLYGONSCAN_API_KEY=your_polygonscan_api_key_here

# Deployment Keys (NEVER commit these)
PRIVATE_KEY=your_deployment_private_key_here
ALSANIA_ADMIN=0xYourAdminAddressHere
ALSANIA_WALLET=0xYourFeeWalletAddressHere

# Contract Addresses (filled after deployment)
PROXY_ADDRESS=
IMPLEMENTATION_ADDRESS=
EOF
```

### 3. Test Environment Setup
```bash
# Compile contracts
make compile

# Run tests
make test

# Generate coverage report
make coverage
```

## 🏗️ Smart Contract Deployment

### Step 1: Compile Contracts
```bash
# Clean previous builds
make clean

# Compile all contracts
make compile

# Verify storage layout
npx hardhat storage-layout
```

### Step 2: Deploy to Polygon Amoy
```bash
# Deploy contracts
npx hardhat run scripts/deploy.js --network amoy

# Expected output:
# ✅ Proxy deployed to: 0x...
# ✅ Implementation deployed to: 0x...
# ✅ Contract verified on Polygonscan
```

### Step 3: Verify Deployment
```bash
# Check deployment status
npx hardhat run scripts/checkState.js --network amoy

# Verify contract functions
npx hardhat run scripts/check-contract-functions.js --network amoy
```

### Step 4: Configure Frontend
Update `frontend/aed-home/js/config.js`:
```javascript
export const config = {
  CONTRACT_ADDRESS: "0xYourDeployedProxyAddress",
  RPC_URL: "https://rpc-amoy.polygon.technology",
  CHAIN_ID: 80002,
  NETWORK_NAME: "Polygon Amoy"
};
```

## 🌐 Frontend Deployment

### Local Development
```bash
# Start local server for testing
npx http-server frontend/aed-home -p 3000

# Or use any static file server
cd frontend/aed-home
python -m http.server 3000
```

### Production Deployment Options

#### Option 1: Vercel
```bash
# Install Vercel CLI
npm i -g vercel

# Deploy frontend
cd frontend/aed-home
vercel

# Follow prompts to deploy
```

#### Option 2: Netlify
```bash
# Install Netlify CLI
npm i -g netlify-cli

# Build and deploy
cd frontend/aed-home
netlify deploy --prod --dir .
```

#### Option 3: GitHub Pages
```bash
# Add to package.json scripts:
# "deploy": "npx gh-pages -d ."

# Deploy to GitHub Pages
npm run deploy
```

## 📊 Metadata Server Setup

### Development Setup
```bash
# Configure environment
export RPC_URL="https://rpc-amoy.polygon.technology"
export CONTRACT_ADDRESS="0xYourDeployedContractAddress"
export PORT=3001

# Start metadata server
node metadata-server/metadata-server.js
```

### Production Deployment

#### Option 1: Railway
```bash
# Install Railway CLI
npm i -g @railway/cli

# Login and deploy
railway login
railway init
railway up
```

#### Option 2: Vercel Functions
Create `api/metadata.js`:
```javascript
export default async function handler(req, res) {
  // Implement metadata server logic
  res.json({ /* metadata */ });
}
```

#### Option 3: Dedicated Server
```bash
# Use PM2 for process management
npm i -g pm2

# Start metadata server
pm2 start metadata-server/metadata-server.js --name aed-metadata
pm2 save
pm2 startup
```

## 🧪 Testing Procedures

### Smart Contract Testing
```bash
# Run all tests
make test

# Run specific test file
npx hardhat test test/AED.test.js

# Generate coverage report
make coverage

# Run gas usage analysis
npx hardhat test --reporter=eth-gas-reporter
```

### Frontend Testing
```bash
# Manual testing checklist:
# 1. Wallet connection
# 2. Network switching to Polygon Amoy
# 3. Domain registration
# 4. Enhancement purchases
# 5. Primary domain setting
# 6. Error handling

# Automated testing with Playwright
npm i -D @playwright/test
npx playwright test
```

### Integration Testing
```bash
# Test full deployment pipeline
# 1. Deploy contracts
# 2. Update frontend config
# 3. Test all contract interactions
# 4. Verify metadata endpoints
# 5. Test upgrade procedures
```

## 🔄 Upgrade Procedures

### Smart Contract Upgrades
```bash
# 1. Implement new version
# 2. Run storage layout check
npx hardhat storage-layout

# 3. Deploy new implementation
npx hardhat run scripts/upgrade-implementation.js --network amoy

# 4. Verify upgrade
npx hardhat run scripts/verify-upgrade.js --network amoy
```

### Frontend Updates
```bash
# Update contract addresses
# Test locally
# Deploy to production
```

## 🔧 Troubleshooting

### Common Issues

#### Node.js Dependencies
```bash
# If npm install fails with 403 errors:
npm config set @nomicfoundation:registry https://registry.npmjs.org/
npm install

# If using yarn:
yarn config set @nomicfoundation:registry https://registry.npmjs.org/
yarn install
```

#### Contract Deployment Issues
```bash
# If deployment fails:
# 1. Check RPC connection
curl -X POST https://rpc-amoy.polygon.technology -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# 2. Verify private key has MATIC
npx hardhat run scripts/check-balance.js --network amoy

# 3. Check gas prices
npx hardhat run scripts/check-gas.js --network amoy
```

#### Frontend Connection Issues
```javascript
// Check these in browser console:
console.log('Contract address:', config.CONTRACT_ADDRESS);
console.log('Network ID:', await window.ethereum.request({method: 'eth_chainId'}));
console.log('Account:', await window.ethereum.request({method: 'eth_accounts'}));
```

#### Metadata Server Issues
```bash
# Test metadata endpoints
curl http://localhost:3001/domain/1.json
curl http://localhost:3001/sub/1.json

# Check server logs
pm2 logs aed-metadata
```

## 📈 Monitoring & Maintenance

### Contract Monitoring
```bash
# Check contract events
npx hardhat run scripts/monitor-events.js --network amoy

# Track domain registrations
npx hardhat run scripts/track-registrations.js --network amoy
```

### Performance Monitoring
- Monitor gas usage in transactions
- Track domain registration rate
- Monitor enhancement purchases
- Watch for contract upgrade needs

### Security Monitoring
- Monitor admin role assignments
- Track large transactions
- Check for suspicious patterns
- Regular security audits

## 🎯 Production Readiness Checklist

### Security
- [ ] All contracts verified on Polygonscan
- [ ] Admin roles properly configured
- [ ] No exposed private keys
- [ ] Access control properly set
- [ ] Emergency pause functionality tested

### Performance
- [ ] Gas optimization completed
- [ ] Frontend optimized for production
- [ ] CDN configured for assets
- [ ] Metadata server scaling tested

### Monitoring
- [ ] Error tracking implemented
- [ ] Performance monitoring active
- [ ] Security alerts configured
- [ ] Backup procedures in place

## 📞 Support & Resources

- **Technical Issues**: Open GitHub issue
- **Security Concerns**: Email security@alsania.io
- **Deployment Help**: Check GitHub Wiki
- **Community**: Join Alsania Discord

---

**🔐 Never share private keys or commit .env files!**