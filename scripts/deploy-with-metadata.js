const { ethers, network } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Deploying AED with Enhanced Metadata Support...");
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
    console.log("\n🔄 Deploying AED Implementation with Enhanced Metadata...");
    
    // Deploy AED Implementation
    const AEDImplementation = await ethers.getContractFactory("AEDMinimal");
    const aedImplementation = await AEDImplementation.deploy();
    await aedImplementation.waitForDeployment();
    
    const implementationAddress = await aedImplementation.getAddress();
    console.log("🔧 Implementation deployed:", implementationAddress);
    
    // Deploy proxy
    console.log("📦 Deploying proxy...");
    const AED = await ethers.getContractFactory("AED");
    
    // Encode initialization data
    const initData = aedImplementation.interface.encodeFunctionData(
      "initialize",
      [name, symbol, paymentWallet, initialAdmin]
    );
    
    const aedProxy = await AED.deploy(implementationAddress, initData);
    await aedProxy.waitForDeployment();
    
    const proxyAddress = await aedProxy.getAddress();
    console.log("📍 Proxy deployed:", proxyAddress);
    
    // Connect to the proxy using implementation interface
    const aed = aedImplementation.attach(proxyAddress);

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
    
    console.log(`  Subdomain Enhancement: ${ethers.formatEther(subdomainPrice)} ETH`);

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
        metadataSupport: "Enhanced with SVG images and JSON metadata",
        deploymentVersion: "v2-metadata"
      }
    };

    // Save to multiple formats
    const outputText = `${network.name} - ${timestamp}\nProxy: ${proxyAddress}\nImplementation: ${implementationAddress}\nDeployer: ${deployer.address}\nVersion: v2-metadata\n\n`;
    fs.appendFileSync("./deployedAddress.txt", outputText, "utf8");
    
    const jsonFilename = `./amoy-metadata-deployment.json`;
    fs.writeFileSync(jsonFilename, JSON.stringify(deploymentInfo, null, 2), "utf8");
    
    console.log("\n📝 Deployment logged to:");
    console.log("  Text file: deployedAddress.txt");
    console.log("  JSON file:", jsonFilename);

    console.log("\n🎉 AED deployment with metadata support completed successfully!");
    console.log("\n📖 Next steps:");
    console.log("  1. Test metadata functionality");
    console.log("  2. Mint domains and verify images show up");
    console.log("  3. Verify domain names display properly");

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
