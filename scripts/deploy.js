const fs = require("fs");
const hre = require("hardhat");
const { ethers } = require("ethers");
require("dotenv").config();

async function main() {
  const name = "Alsania Enhanced Domains";
  const symbol = "AED";
  const admin = process.env.ALSANIA_ADMIN;
  const paymentWallet = process.env.ALSANIA_WALLET;

  if (!admin || !paymentWallet) {
    throw new Error("Missing ALSANIA_ADMIN or ALSANIA_WALLET in environment");
  }

  const provider = new ethers.JsonRpcProvider(hre.network.config.url || "http://127.0.0.1:8545");
  const deployer = await provider.getSigner(0);
  const deployerAddress = await deployer.getAddress();

  console.log(`🚀 Deploying AED from ${deployerAddress}`);

  const implArtifact = await hre.artifacts.readArtifact("AEDImplementation");
  const implFactory = new ethers.ContractFactory(implArtifact.abi, implArtifact.bytecode, deployer);
  const implementation = await implFactory.deploy();
  await implementation.waitForDeployment();
  const implementationAddress = await implementation.getAddress();

  const initData = implementation.interface.encodeFunctionData("initialize", [
    name,
    symbol,
    paymentWallet,
    admin,
  ]);

  const proxyArtifact = await hre.artifacts.readArtifact("AED");
  const proxyFactory = new ethers.ContractFactory(proxyArtifact.abi, proxyArtifact.bytecode, deployer);
  const proxy = await proxyFactory.deploy(implementationAddress, initData);
  await proxy.waitForDeployment();
  const proxyAddress = await proxy.getAddress();

  console.log("✅ Proxy deployed at:", proxyAddress);
  console.log("🏗  Implementation deployed at:", implementationAddress);

  const timestamp = new Date().toISOString();
  const networkName = hre.network.name;
  const output = `${networkName} - ${timestamp}\nDeployer: ${deployerAddress}\nProxy: ${proxyAddress}\nImplementation: ${implementationAddress}\n\n`;
  fs.appendFileSync("./deployedAddress.txt", output, "utf8");
}

main().catch((error) => {
  console.error("❌ Deployment failed:", error);
  process.exitCode = 1;
});
