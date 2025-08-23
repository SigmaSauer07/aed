const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Deploying UPGRADEABLE AED to Hardhat...");
  console.log("🔧 This is the upgradeable version of our working contract");
  
  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // Deploy the implementation
  console.log("\n🏗️  Deploying AEDSimpleUpgradeable Implementation...");
  const AEDSimpleUpgradeable = await ethers.getContractFactory("AEDSimpleUpgradeable");
  const implementation = await AEDSimpleUpgradeable.deploy();
  await implementation.waitForDeployment();
  const implementationAddress = await implementation.getAddress();
  
  console.log("✅ Implementation deployed to:", implementationAddress);
  
  // Deploy the proxy
  console.log("\n🎭 Deploying Proxy...");
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
  
  console.log("✅ Proxy deployed to:", proxyAddress);
  
  // Connect to proxy using implementation interface
  const aed = implementation.attach(proxyAddress);
  
  // Test basic functionality
  console.log("\n🔍 Testing upgradeable contract...");
  
  try {
    const name = await aed.name();
    const symbol = await aed.symbol();
    const nextTokenId = await aed.nextTokenId();
    
    console.log("✅ Name:", name);
    console.log("✅ Symbol:", symbol);
    console.log("✅ Next Token ID:", nextTokenId.toString());
    
    // Test domain registration
    console.log("\n🔍 Testing domain registration...");
    const tx = await aed.registerDomain("test.alsania", deployer.address, {
      value: ethers.parseEther("1.0")
    });
    await tx.wait();
    console.log("✅ Domain registered successfully");
    
    // Test view functions
    console.log("\n🔍 Testing view functions...");
    const owner = await aed.ownerOf(1);
    const tokenURI = await aed.tokenURI(1);
    const isRegistered = await aed.isRegistered("test.alsania");
    const domainInfo = await aed.getDomainInfo(1);
    
    console.log("✅ Token 1 owner:", owner);
    console.log("✅ Domain registered:", isRegistered);
    console.log("✅ Domain info TLD:", domainInfo.tld);
    console.log("✅ Token URI (first 100 chars):", tokenURI.substring(0, 100) + "...");
    
    // Test user domains
    const userDomains = await aed.getUserDomains(deployer.address);
    console.log("✅ User domains:", userDomains);
    
    console.log("\n🎉 UPGRADEABLE AED is working perfectly!");
    
  } catch (error) {
    console.log("❌ Test failed:", error.message);
  }
  
  // Save addresses
  const addresses = {
    proxy: proxyAddress,
    implementation: implementationAddress,
    deployer: deployer.address
  };
  
  fs.writeFileSync("upgradeable-addresses.json", JSON.stringify(addresses, null, 2));
  console.log("\n💾 Addresses saved to: upgradeable-addresses.json");
  
  console.log("\n✅ UPGRADEABLE AED Deployment successful!");
  console.log("Use proxy address for interaction:", proxyAddress);
  console.log("Implementation address for upgrades:", implementationAddress);
}

main()
  .then(() => {
    console.log("\n🎉 UPGRADEABLE AED Deployment completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ UPGRADEABLE AED Deployment failed:", error);
    process.exit(1);
  }); 