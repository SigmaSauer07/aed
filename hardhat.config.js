require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.30",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
      viaIR: true, // Enable IR optimizer to fix stack too deep errors
      evmVersion: "cancun"
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    amoy: {
      url: process.env.AMOY_RPC,
      accounts: [process.env.PRIVATE_KEY_TEST],
      chainId: 80002,
      gasPrice: 50000000000, // 50 gwei
      gas: 10000000, // 10M gas limit
    },
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY,
  },
};