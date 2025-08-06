const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying AED Modular UUPS System...");
  
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
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation", {
    libraries: {
      "contracts/libraries/LibMinting.sol:LibMinting": await libMinting.getAddress()
    }
  });
  
  const coreImplementation = await AEDCoreImplementation.deploy();
  await coreImplementation.waitForDeployment();
  console.log("✅ AEDCoreImplementation deployed to:", await coreImplementation.getAddress());

  // Step 3: Deploy individual module contracts
  console.log("\n🔧 Step 3: Deploying Individual Modules...");
  
  // Deploy Admin Module
  console.log("📋 Deploying AEDAdminModule...");
  const AEDAdminModule = await ethers.getContractFactory("AEDAdminModule");
  const adminModule = await AEDAdminModule.deploy();
  await adminModule.waitForDeployment();
  console.log("✅ AEDAdminModule deployed to:", await adminModule.getAddress());

  // Deploy Minting Module
  console.log("🪙 Deploying AEDMintingModule...");
  const AEDMintingModule = await ethers.getContractFactory("AEDMintingModule", {
    libraries: {
      "contracts/libraries/LibMinting.sol:LibMinting": await libMinting.getAddress()
    }
  });
  const mintingModule = await AEDMintingModule.deploy();
  await mintingModule.waitForDeployment();
  console.log("✅ AEDMintingModule deployed to:", await mintingModule.getAddress());

  // Deploy Metadata Module
  console.log("📄 Deploying AEDMetadataModule...");
  const AEDMetadataModule = await ethers.getContractFactory("AEDMetadataModule");
  const metadataModule = await AEDMetadataModule.deploy();
  await metadataModule.waitForDeployment();
  console.log("✅ AEDMetadataModule deployed to:", await metadataModule.getAddress());

  // Deploy Registry Module
  console.log("📝 Deploying AEDRegistryModule...");
  const AEDRegistryModule = await ethers.getContractFactory("AEDRegistryModule");
  const registryModule = await AEDRegistryModule.deploy();
  await registryModule.waitForDeployment();
  console.log("✅ AEDRegistryModule deployed to:", await registryModule.getAddress());

  // Deploy Reverse Module
  console.log("🔄 Deploying AEDReverseModule...");
  const AEDReverseModule = await ethers.getContractFactory("AEDReverseModule");
  const reverseModule = await AEDReverseModule.deploy();
  await reverseModule.waitForDeployment();
  console.log("✅ AEDReverseModule deployed to:", await reverseModule.getAddress());

  // Deploy Enhancements Module
  console.log("⚡ Deploying AEDEnhancementsModule...");
  const AEDEnhancementsModule = await ethers.getContractFactory("AEDEnhancementsModule");
  const enhancementsModule = await AEDEnhancementsModule.deploy();
  await enhancementsModule.waitForDeployment();
  console.log("✅ AEDEnhancementsModule deployed to:", await enhancementsModule.getAddress());

  // Deploy Recovery Module
  console.log("🛡️  Deploying AEDRecoveryModule...");
  const AEDRecoveryModule = await ethers.getContractFactory("AEDRecoveryModule");
  const recoveryModule = await AEDRecoveryModule.deploy();
  await recoveryModule.waitForDeployment();
  console.log("✅ AEDRecoveryModule deployed to:", await recoveryModule.getAddress());

  // Deploy Bridge Module
  console.log("🌉 Deploying AEDBridgeModule...");
  const AEDBridgeModule = await ethers.getContractFactory("AEDBridgeModule");
  const bridgeModule = await AEDBridgeModule.deploy();
  await bridgeModule.waitForDeployment();
  console.log("✅ AEDBridgeModule deployed to:", await bridgeModule.getAddress());

  // Step 4: Deploy Module Registry
  console.log("\n📋 Step 4: Deploying Module Registry...");
  const ModuleRegistry = await ethers.getContractFactory("ModuleRegistry");
  const moduleRegistry = await ModuleRegistry.deploy();
  await moduleRegistry.waitForDeployment();
  console.log("✅ ModuleRegistry deployed to:", await moduleRegistry.getAddress());

  // Step 5: Deploy Proxy Router
  console.log("\n🎭 Step 5: Deploying Proxy Router...");
  const ProxyRouter = await ethers.getContractFactory("ProxyRouter");
  const proxyRouter = await ProxyRouter.deploy(
    await coreImplementation.getAddress(),
    await moduleRegistry.getAddress()
  );
  await proxyRouter.waitForDeployment();
  console.log("✅ ProxyRouter deployed to:", await proxyRouter.getAddress());

  // Step 6: Register modules in Module Registry
  console.log("\n🔗 Step 6: Registering Modules...");
  
  const modules = [
    { name: "Admin", address: await adminModule.getAddress(), id: ethers.keccak256(ethers.toUtf8Bytes("AEDAdmin")) },
    { name: "Minting", address: await mintingModule.getAddress(), id: ethers.keccak256(ethers.toUtf8Bytes("AEDMinting")) },
    { name: "Metadata", address: await metadataModule.getAddress(), id: ethers.keccak256(ethers.toUtf8Bytes("AEDMetadata")) },
    { name: "Registry", address: await registryModule.getAddress(), id: ethers.keccak256(ethers.toUtf8Bytes("AEDRegistry")) },
    { name: "Reverse", address: await reverseModule.getAddress(), id: ethers.keccak256(ethers.toUtf8Bytes("AEDReverse")) },
    { name: "Enhancements", address: await enhancementsModule.getAddress(), id: ethers.keccak256(ethers.toUtf8Bytes("AEDEnhancements")) },
    { name: "Recovery", address: await recoveryModule.getAddress(), id: ethers.keccak256(ethers.toUtf8Bytes("AEDRecovery")) },
    { name: "Bridge", address: await bridgeModule.getAddress(), id: ethers.keccak256(ethers.toUtf8Bytes("AEDBridge")) }
  ];

  for (const module of modules) {
    await moduleRegistry.registerModule(module.id, module.address, module.name);
    console.log(`✅ Registered ${module.name} module`);
  }

  // Step 7: Initialize the system
  console.log("\n🚀 Step 7: Initializing System...");
  
  // Connect to proxy router using core implementation interface
  const aed = coreImplementation.attach(await proxyRouter.getAddress());
  
  // Initialize the core contract
  const initData = coreImplementation.interface.encodeFunctionData(
    'initialize',
    [
      "Alsania Enhanced Domains", // name
      "AED",                      // symbol  
      deployer.address,           // payment wallet
      deployer.address            // admin
    ]
  );
  
  await proxyRouter.initialize(initData);
  console.log("✅ System initialized successfully!");

  // Step 8: Verify deployment
  console.log("\n🔍 Step 8: Verifying Deployment...");
  console.log("Name:", await aed.name());
  console.log("Symbol:", await aed.symbol());
  console.log("Next Token ID:", await aed.getNextTokenId());

  console.log("\n🎉 Modular UUPS Deployment Completed Successfully!");
  console.log("\n📝 Contract Addresses:");
  console.log("- Proxy Router (main):", await proxyRouter.getAddress());
  console.log("- Core Implementation:", await coreImplementation.getAddress());
  console.log("- Module Registry:", await moduleRegistry.getAddress());
  console.log("- LibMinting:", await libMinting.getAddress());
  console.log("\n🔧 Module Addresses:");
  modules.forEach(module => {
    console.log(`- ${module.name}:`, module.address);
  });
  
  return {
    proxyRouter: await proxyRouter.getAddress(),
    coreImplementation: await coreImplementation.getAddress(),
    moduleRegistry: await moduleRegistry.getAddress(),
    libMinting: await libMinting.getAddress(),
    modules: modules.reduce((acc, module) => {
      acc[module.name] = module.address;
      return acc;
    }, {})
  };
}

main()
  .then((result) => {
    console.log("\n✅ Modular UUPS Deployment successful!");
    console.log("Use proxy router address for interaction:", result.proxyRouter);
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }); 