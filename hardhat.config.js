require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const {
  PRIVATE_KEY,
  AMOY_RPC,
  POLYGONSCAN_API_KEY,
} = process.env;

const accounts = PRIVATE_KEY ? [PRIVATE_KEY] : [];

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
      url: AMOY_RPC || "https://polygon-amoy-bor.publicnode.com",
      accounts,
      chainId: 80002,
      gasPrice: 50_000_000_000,
      gas: 10_000_000,
    },
  },
  etherscan: {
    apiKey: POLYGONSCAN_API_KEY || "",
  },
};