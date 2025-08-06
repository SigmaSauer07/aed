const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Deploying AED Simple Version...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));

  // Deploy libraries first
  console.log("📚 Deploying LibMinting...");
  const LibMinting = await ethers.getContractFactory("LibMinting");
  const libMinting = await LibMinting.deploy();
  await libMinting.waitForDeployment();
  console.log("LibMinting deployed to:", await libMinting.getAddress());

  // Deploy implementation
  console.log("🏗️  Deploying AED Implementation...");
  const AEDImplementation = await ethers.getContractFactory("AEDImplementation", {
    libraries: {
      "contracts/libraries/LibMinting.sol:LibMinting": await libMinting.getAddress()
    }
  });
  
  const implementation = await AEDImplementation.deploy();
  await implementation.waitForDeployment();
  console.log("Implementation deployed to:", await implementation.getAddress());

  // Deploy proxy
  console.log("🎭 Deploying Proxy...");
  const AED = await ethers.getContractFactory("AED");
  
  // Encode initialization data
  const initData = implementation.interface.encodeFunctionData(
    'initialize',
    [
      "Alsania Enhanced Domains", // name
      "AED",                      // symbol  
      deployer.address,           // payment wallet
      deployer.address            // admin
    ]
  );

  const proxy = await AED.deploy(await implementation.getAddress(), initData);
  await proxy.waitForDeployment();
  console.log("Proxy deployed to:", await proxy.getAddress());

  // Connect to proxy using implementation interface
  const aed = implementation.attach(await proxy.getAddress());

  // Verify deployment
  console.log("🔍 Verifying deployment...");
  console.log("Name:", await aed.name());
  console.log("Symbol:", await aed.symbol());
  console.log("Next Token ID:", await aed.getNextTokenId());

  console.log("🎉 Deployment completed successfully!");
  console.log("📝 Contract Addresses:");
  console.log("- Proxy (main):", await proxy.getAddress());
  console.log("- Implementation:", await implementation.getAddress());
  console.log("- LibMinting:", await libMinting.getAddress());
  
  return {
    proxy: await proxy.getAddress(),
    implementation: await implementation.getAddress(),
    libMinting: await libMinting.getAddress()
  };
}

main()
  .then((result) => {
    console.log("✅ Deployment successful!");
    console.log("Use proxy address for interaction:", result.proxy);
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });