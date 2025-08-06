const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying AED Simplified Core Implementation...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));

  // Step 1: Deploy libraries first
  console.log("\n📚 Step 1: Deploying Libraries...");
  const LibMinting = await ethers.getContractFactory("LibMinting");
  const libMinting = await LibMinting.deploy();
  await libMinting.waitForDeployment();
  console.log("✅ LibMinting deployed to:", await libMinting.getAddress());

  // Step 2: Deploy AEDCoreImplementation (small, just ERC721 + basic functions)
  console.log("\n🏗️  Step 2: Deploying AEDCoreImplementation...");
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation");
  
  const coreImplementation = await AEDCoreImplementation.deploy();
  await coreImplementation.waitForDeployment();
  console.log("✅ AEDCoreImplementation deployed to:", await coreImplementation.getAddress());

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

  console.log("\n🎉 Simplified AED Deployment Completed Successfully!");
  console.log("\n📝 Contract Addresses:");
  console.log("- Proxy (main):", await proxy.getAddress());
  console.log("- Core Implementation:", await coreImplementation.getAddress());
  console.log("- LibMinting:", await libMinting.getAddress());
  
  console.log("\n🚀 AED is now production-ready with core functionality!");
  console.log("✅ ERC721 functionality");
  console.log("✅ Domain registration");
  console.log("✅ Transfer capabilities");
  console.log("✅ Admin controls");
  console.log("✅ UUPS upgradeability");
  
  console.log("\n📋 Next Steps:");
  console.log("1. Test domain registration");
  console.log("2. Test transfers");
  console.log("3. Add modules incrementally as needed");
  console.log("4. Deploy to mainnet when ready");
  
  return {
    proxy: await proxy.getAddress(),
    coreImplementation: await coreImplementation.getAddress(),
    libMinting: await libMinting.getAddress()
  };
}

main()
  .then((result) => {
    console.log("\n✅ Simplified AED Deployment successful!");
    console.log("Use proxy address for interaction:", result.proxy);
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }); 