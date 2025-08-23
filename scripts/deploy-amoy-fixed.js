const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying FIXED AED to Amoy Testnet...");
  console.log("🔧 Fixes: tokenURI function, proper TLD validation, SVG generation");
  
  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // Step 1: Deploy libraries first
  console.log("\n📚 Step 1: Deploying Libraries...");
  const LibMinting = await ethers.getContractFactory("LibMinting");
  const libMinting = await LibMinting.deploy();
  await libMinting.waitForDeployment();
  console.log("✅ LibMinting deployed to:", await libMinting.getAddress());

  // Step 2: Deploy FIXED AEDCoreImplementation
  console.log("\n🏗️  Step 2: Deploying FIXED AEDCoreImplementation...");
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation");
  
  const coreImplementation = await AEDCoreImplementation.deploy();
  await coreImplementation.waitForDeployment();
  console.log("✅ FIXED AEDCoreImplementation deployed to:", await coreImplementation.getAddress());

  // Step 3: Deploy proxy
  console.log("\n🎭 Step 3: Deploying Proxy...");
  const AED = await ethers.getContractFactory("AED");
  
  // Encode initialization data
  const initData = coreImplementation.interface.encodeFunctionData(
    'initialize',
    [
      "Alsania Enhanced Domains", // name
      "AED",                      // symbol  
      deployer.address,           // payment wallet
      deployer.address            // admin
    ]
  );

  const proxy = await AED.deploy(await coreImplementation.getAddress(), initData);
  await proxy.waitForDeployment();
  console.log("✅ Proxy deployed to:", await proxy.getAddress());

  // Step 4: Connect to proxy using core implementation interface
  const aed = coreImplementation.attach(await proxy.getAddress());

  // Step 5: Verify deployment
  console.log("\n🔍 Step 5: Verifying Deployment...");
  console.log("Name:", await aed.name());
  console.log("Symbol:", await aed.symbol());
  console.log("Next Token ID:", await aed.getNextTokenId());

  console.log("\n🎉 FIXED AED Deployment to Amoy Testnet Completed Successfully!");
  console.log("\n📝 Contract Addresses:");
  console.log("- Proxy (main):", await proxy.getAddress());
  console.log("- Core Implementation:", await coreImplementation.getAddress());
  console.log("- LibMinting:", await libMinting.getAddress());
  
  console.log("\n🔧 FIXES IMPLEMENTED:");
  console.log("✅ tokenURI function added");
  console.log("✅ SVG generation for domain images");
  console.log("✅ Proper TLD validation (Alsania TLDs only)");
  console.log("✅ Base64 encoding for metadata");
  console.log("✅ Dynamic domain name display");
  
  console.log("\n🚀 AED is now live on Amoy testnet with fixes!");
  console.log("✅ Ready for domain minting with proper metadata");
  console.log("✅ Ready for subdomain creation");
  console.log("✅ Ready for testing with images");
  
  // Save addresses to file for later use
  const addresses = {
    proxy: await proxy.getAddress(),
    coreImplementation: await coreImplementation.getAddress(),
    libMinting: await libMinting.getAddress(),
    deployer: deployer.address
  };
  
  console.log("\n💾 Saving addresses to amoy-addresses-fixed.json...");
  const fs = require('fs');
  fs.writeFileSync('amoy-addresses-fixed.json', JSON.stringify(addresses, null, 2));
  
  return addresses;
}

main()
  .then((result) => {
    console.log("\n✅ FIXED AED Amoy Deployment successful!");
    console.log("Use proxy address for interaction:", result.proxy);
    console.log("Addresses saved to: amoy-addresses-fixed.json");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }); 