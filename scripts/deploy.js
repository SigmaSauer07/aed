const { ethers, upgrades, network } = require("hardhat");
const fs = require("fs");
require("dotenv").config();

async function main() {
  const AED = await ethers.getContractFactory("AED");

  // Load from .env file
  const initialAdmin = process.env.ALSANIA_ADMIN;
  const paymentWallet = process.env.ALSANIA_WALLET;

  if (!initialAdmin || !paymentWallet) {
    throw new Error("🚨 Missing ALSANIA_ADMIN or ALSANIA_WALLET in .env");
  }

  const aed = await upgrades.deployProxy(
    AED,
    [initialAdmin, paymentWallet], // initializer arguments
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

  const timestamp = new Date().toISOString();
  const networkName = network.name;

  const output = `${networkName} - ${timestamp}\nProxy: ${proxyAddress}\nImplementation: ${implementationAddress}\n\n`;
  fs.appendFileSync("./deployedAddress.txt", output, "utf8");

  console.log("✅ AED deployed to:", proxyAddress);
  console.log("📦 Implementation address:", implementationAddress);
  console.log("📝 Logged to deployedAddress.txt");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
