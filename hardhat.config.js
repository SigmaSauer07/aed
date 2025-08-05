require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.30",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "cancun",
    },
  },
  networks: {
    amoy: {
      url: process.env.AMOY_RPC || "https://rpc-mumbai.maticvigil.com",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      timeout: 120000,
    },
  },
etherscan: {
  apiKey: {
    polygonAmoy: "YOUR_POLYGONSCAN_API_KEY"
  },
  customChains: [
    {
      network: "polygonAmoy",
      chainId: 80002,
      urls: {
        apiURL: "https://amoy.polygonscan.com/api",
        browserURL: "https://amoy.polygonscan.com"
      }
    }
  ]
}
}