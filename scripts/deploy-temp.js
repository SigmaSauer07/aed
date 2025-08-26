const { ethers, upgrades, network } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Starting AED Temporary Deployment...");
  console.log("Network:", network.name);
  
  // Get the first signer as both admin and fee collector
  const [deployer] = await ethers.getSigners();
  
  const initialAdmin = deployer.address;
  const paymentWallet = deployer.address;
  const name = "Alsania Enhanced Domains";
  const symbol = "AED";

  console.log("📋 Configuration:");
  console.log("  Deployer:", deployer.address);
  console.log("  Admin:", initialAdmin);
  console.log("  Payment Wallet:", paymentWallet);
  console.log("  Name:", name);
  console.log("  Symbol:", symbol);
  console.log("  Balance:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");

  try {
    console.log("\n🔄 Deploying AED Implementation...");
    
    // Deploy AED Implementation using UUPS upgrades
    const AEDImplementation = await ethers.getContractFactory("AEDImplementationLite");
    
    console.log("📦 Deploying proxy with implementation...");
    const aed = await upgrades.deployProxy(
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

    console.log("\n✅ Deployment Successful!");
    console.log("📍 Proxy Address:", proxyAddress);
    console.log("🔧 Implementation Address:", implementationAddress);
    
    // Verify initial configuration
    console.log("\n🔍 Verifying deployment...");
    const deployedName = await aed.name();
    const deployedSymbol = await aed.symbol();
    const feeCollector = await aed.getFeeCollector();
    const isAdminSet = await aed.hasRole(await aed.ADMIN_ROLE(), initialAdmin);
    
    console.log("  Name:", deployedName);
    console.log("  Symbol:", deployedSymbol);
    console.log("  Fee Collector:", feeCollector);
    console.log("  Admin Set:", isAdminSet);
    
    // Test TLD configuration
    console.log("\n🌐 Verifying TLD Configuration...");
    const freeTlds = ["aed", "alsa", "07"];
    const paidTlds = ["alsania", "fx", "echo"];
    
    for (const tld of freeTlds) {
      const isActive = await aed.isTLDActive(tld);
      console.log(`  ${tld}: ${isActive ? "✅" : "❌"} (Free TLD)`);
    }
    
    for (const tld of paidTlds) {
      const isActive = await aed.isTLDActive(tld);
      console.log(`  ${tld}: ${isActive ? "✅" : "❌"} (Paid TLD)`);
    }
    
    // Test feature pricing
    console.log("\n💰 Verifying Feature Pricing...");
    const subdomainPrice = await aed.getFeaturePrice("subdomain");
    const byoPrice = await aed.getFeaturePrice("byo");
    
    console.log(`  Subdomain Enhancement: ${ethers.formatEther(subdomainPrice)} ETH`);
    console.log(`  BYO Upgrade: ${ethers.formatEther(byoPrice)} ETH`);

    // Save deployment information
    const timestamp = new Date().toISOString();
    const deploymentInfo = {
      network: network.name,
      chainId: network.config.chainId,
      timestamp: timestamp,
      proxy: proxyAddress,
      implementation: implementationAddress,
      admin: initialAdmin,
      feeCollector: paymentWallet,
      deployer: deployer.address,
      name: name,
      symbol: symbol,
      freeTlds: freeTlds,
      paidTlds: paidTlds,
      features: {
        subdomainPrice: ethers.formatEther(subdomainPrice),
        byoPrice: ethers.formatEther(byoPrice)
      }
    };

    // Save to multiple formats
    const outputText = `${network.name} - ${timestamp}\nProxy: ${proxyAddress}\nImplementation: ${implementationAddress}\nDeployer: ${deployer.address}\n\n`;
    fs.appendFileSync("./deployedAddress.txt", outputText, "utf8");
    
    const jsonFilename = `./amoy-upgradeable-addresses.json`;
    fs.writeFileSync(jsonFilename, JSON.stringify(deploymentInfo, null, 2), "utf8");
    
    console.log("\n📝 Deployment logged to:");
    console.log("  Text file: deployedAddress.txt");
    console.log("  JSON file:", jsonFilename);

    console.log("\n🎉 AED deployment completed successfully!");
    console.log("\n📖 Next steps:");
    console.log("  1. Run domain minting tests");
    console.log("  2. Verify contract on block explorer");
    console.log("  3. Update frontend configuration");

    return {
      proxy: proxyAddress,
      implementation: implementationAddress,
      contract: aed
    };

  } catch (error) {
    console.error("\n❌ Deployment failed:", error);
    throw error;
  }
}

// Execute if called directly
if (require.main === module) {
  main().catch((error) => {
    console.error("❌ Deployment script failed:", error);
    process.exitCode = 1;
  });
}

module.exports = main;
