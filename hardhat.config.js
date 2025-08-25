require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
const networks = {
  hardhat: {
    chainId: 1337,
    allowUnlimitedContractSize: true,
  },
};

if (process.env.AMOY_RPC && process.env.PRIVATE_KEY) {
  networks.amoy = {
    url: process.env.AMOY_RPC,
    accounts: [process.env.PRIVATE_KEY],
    chainId: 80002,
  };
}

module.exports = {
  solidity: {
    version: "0.8.30",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true, // Enable IR optimizer to fix stack too deep errors
      evmVersion: "cancun"
    },
  },
  networks,
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY,
  },
};