# Alsania Sovereign Domain System

A decentralized domain and identity registry for the next generation of on-chain users. Fully modular, gas-optimized, and bridgable.

## 🌐 Features

- ERC721-based top-level domains (.fx, .als, .07, etc)
- Subdomain leasing and controller roles
- Cross-chain bridging via Merkle proof receipts
- Off-chain resolvers (EIP-3668 + CCIP-read)
- NFT or image avatar linking (UD/ENS-style)
- Multi-wallet ownership support
- On-chain revenue sharing via CREATE2 PaymentSplitters
- Full recovery system via Merkle root guardians

## 🔧 Built With

- Solidity 0.8.23
- OpenZeppelin Contracts (Upgradeable)
- Hardhat or Foundry (your choice)
- IPFS / NFT.Storage
- Biconomy (meta-transactions)
- LayerZero or CCIP (cross-chain messaging)

## 🚀 Quickstart

```bash
git clone https://github.com/YOUR_USERNAME/alsania-domains.git
cd alsania-domains

# Install dependencies
npm install

# Compile and test (Hardhat)
npx hardhat compile
npx hardhat test
