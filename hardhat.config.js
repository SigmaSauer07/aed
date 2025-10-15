require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require("solidity-coverage");

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
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 80002,
      gasPrice: 50000000000, // 50 gwei
      gas: 10000000, // 10M gas limit
    },
  },
  etherscan: {
    apiKey: {
      polygonAmoy: process.env.POLYGONSCAN_API_KEY || "",
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS === "true",
    currency: "USD",
    coinmarketcap: process.env.COINMARKETCAP_API_KEY || undefined,
    showTimeSpent: true,
  },
  mocha: {
    timeout: 120000,
  },
};