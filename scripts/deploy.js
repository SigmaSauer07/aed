const { ethers, upgrades, network } = require("hardhat");
const fs = require("fs");
require("dotenv").config();

async function main() {
  const AEDImplementation = await ethers.getContractFactory("AEDImplementation");

  // Load from .env
  const initialAdmin = process.env.ALSANIA_ADMIN;
  const paymentWallet = process.env.ALSANIA_WALLET;
  const name = "Alsania Enhanced Domains";
  const symbol = "AED";

  if (!initialAdmin || !paymentWallet) {
    throw new Error("🚨 Missing ALSANIA_ADMIN or ALSANIA_WALLET in .env");
  }

  console.log("🚀 Deploying AED with optimized UUPS structure...");

  const aed = await upgrades.deployProxy(
    AED,
    [
      "Alsania Enhanced Domains", // ERC721 name
      "AED",                       // ERC721 symbol
      paymentWallet,               // fee collector
      initialAdmin                 // admin
    ],
    AEDImplementation,
    [name, symbol, paymentWallet, initialAdmin],
    {
      initializer: "initialize",
      kind: "uups",
      timeout: 300000,
      pollingInterval: 5000,
    }
  );

  await aed.waitForDeployment();

  const proxyAddress = await aed.getAddress();
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(proxyAddress);

  // Log deployment info
  const timestamp = new Date().toISOString();
  const networkName = network.name;
  const output = `${networkName} - ${timestamp}\nProxy: ${proxyAddress}\nImplementation: ${implementationAddress}\n\n`;
  fs.appendFileSync("./deployedAddress.txt", output, "utf8");

  console.log("✅ AED deployed to:", proxyAddress);
  console.log("📦 Implementation address:", implementationAddress);
  console.log("🏗️  Architecture: Optimized UUPS with AppStorage");
  console.log("📝 Logged to deployedAddress.txt");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
