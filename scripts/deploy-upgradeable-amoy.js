const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Deploying UPGRADEABLE AED to Amoy Testnet...");
  console.log("🔧 This is the upgradeable version of our working contract");
  
  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // Deploy the implementation
  console.log("\n🏗️  Deploying AEDSimpleUpgradeable Implementation to Amoy...");
  const AEDSimpleUpgradeable = await ethers.getContractFactory("AEDSimpleUpgradeable");
  const implementation = await AEDSimpleUpgradeable.deploy();
  await implementation.waitForDeployment();
  const implementationAddress = await implementation.getAddress();
  
  console.log("✅ Implementation deployed to Amoy:", implementationAddress);
  
  // Deploy the proxy
  console.log("\n🎭 Deploying Proxy to Amoy...");
  const AED = await ethers.getContractFactory("AED");
  
  // Encode initialization data
  const initData = implementation.interface.encodeFunctionData(
    'initialize',
    [
      "Alsania Enhanced Domains", // name
      "AED",                      // symbol
      deployer.address,           // fee collector
      deployer.address            // admin
    ]
  );

  const proxy = await AED.deploy(implementationAddress, initData);
  await proxy.waitForDeployment();
  const proxyAddress = await proxy.getAddress();
  
  console.log("✅ Proxy deployed to Amoy:", proxyAddress);
  
  // Connect to proxy using implementation interface
  const aed = implementation.attach(proxyAddress);
  
  // Test basic functionality
  console.log("\n🔍 Testing upgradeable contract on Amoy...");
  
  try {
    const name = await aed.name();
    const symbol = await aed.symbol();
    const nextTokenId = await aed.nextTokenId();
    
    console.log("✅ Name:", name);
    console.log("✅ Symbol:", symbol);
    console.log("✅ Next Token ID:", nextTokenId.toString());
    
    console.log("\n🎉 UPGRADEABLE AED is working on Amoy!");
    
  } catch (error) {
    console.log("❌ Test failed:", error.message);
  }
  
  // Save addresses
  const addresses = {
    proxy: proxyAddress,
    implementation: implementationAddress,
    deployer: deployer.address,
    network: "amoy"
  };
  
  fs.writeFileSync("amoy-upgradeable-addresses.json", JSON.stringify(addresses, null, 2));
  console.log("\n💾 Addresses saved to: amoy-upgradeable-addresses.json");
  
  console.log("\n✅ UPGRADEABLE AED Amoy Deployment successful!");
  console.log("Use proxy address for interaction:", proxyAddress);
  console.log("Implementation address for upgrades:", implementationAddress);
  console.log("\n🚀 Ready to mint domains with upgradeable contract!");
}

main()
  .then(() => {
    console.log("\n🎉 UPGRADEABLE AED Amoy Deployment completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ UPGRADEABLE AED Amoy Deployment failed:", error);
    process.exit(1);
  }); 