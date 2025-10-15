const { ethers, network } = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("🔄 Upgrading AED Implementation...");
  console.log("Network:", network.name);
  
  // Read deployment address from file
  const deploymentData = require("../amoy-upgradeable-addresses.json");
  const proxyAddress = deploymentData.proxy;
  console.log("📍 Using AED Proxy:", proxyAddress);

  // Get signer
  const [signer] = await ethers.getSigners();
  console.log("👤 Signer:", signer.address);
  console.log("💰 Balance:", ethers.formatEther(await ethers.provider.getBalance(signer.address)), "ETH");

  try {
    console.log("\n🔧 Deploying new implementation...");
    
    // Deploy new implementation
    const AEDMinimal = await ethers.getContractFactory("AEDMinimal");
    const newImplementation = await AEDMinimal.deploy();
    await newImplementation.waitForDeployment();
    
    const newImplementationAddress = await newImplementation.getAddress();
    console.log("📦 New implementation deployed:", newImplementationAddress);
    
    // Connect to existing proxy
    const aed = await ethers.getContractAt("AEDMinimal", proxyAddress);
    
    // Check if we have upgrade permission
    const adminRole = await aed.DEFAULT_ADMIN_ROLE();
    const hasAdminRole = await aed.hasRole(adminRole, signer.address);
    console.log("🔑 Has admin role:", hasAdminRole);
    
    if (!hasAdminRole) {
      throw new Error("❌ Signer does not have admin role for upgrade");
    }
    
    console.log("\n⬆️  Upgrading proxy to new implementation...");
    
    // Perform the upgrade
    const upgradeTx = await aed.upgradeTo(newImplementationAddress);
    const upgradeReceipt = await upgradeTx.wait();
    
    console.log("✅ Upgrade transaction:", upgradeReceipt.hash);
    
    // Verify the upgrade
    const currentImplementation = await ethers.provider.call({
      to: proxyAddress,
      data: "0x5c60da1b" // implementation() selector
    });
    
    const implementationAddress = ethers.getAddress("0x" + currentImplementation.slice(-40));
    console.log("🔍 Current implementation:", implementationAddress);
    console.log("✅ Upgrade successful:", implementationAddress === newImplementationAddress);
    
    // Update deployment info
    const fs = require("fs");
    const updatedDeploymentData = {
      ...deploymentData,
      implementation: newImplementationAddress,
      upgradeTimestamp: new Date().toISOString(),
      upgradeTransactionHash: upgradeReceipt.hash
    };
    
    fs.writeFileSync("./amoy-upgradeable-addresses.json", JSON.stringify(updatedDeploymentData, null, 2));
    console.log("📝 Updated deployment data");
    
    console.log("\n🎉 Implementation upgrade completed successfully!");
    
    return {
      proxy: proxyAddress,
      oldImplementation: deploymentData.implementation,
      newImplementation: newImplementationAddress,
      upgradeHash: upgradeReceipt.hash
    };

  } catch (error) {
    console.error("\n❌ Upgrade failed:", error);
    throw error;
  }
}

if (require.main === module) {
  main().catch((error) => {
    console.error("❌ Upgrade script failed:", error);
    process.exitCode = 1;
  });
}

module.exports = main;
