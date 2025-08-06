const { ethers, upgrades } = require("hardhat");

async function main() {
  console.log("🚀 Deploying AED Production System...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)));

  // Step 1: Deploy all required libraries
  console.log("📚 Deploying libraries...");
  
  const LibMinting = await ethers.getContractFactory("LibMinting");
  const libMinting = await LibMinting.deploy();
  await libMinting.waitForDeployment();
  console.log("LibMinting deployed to:", await libMinting.getAddress());

  // Step 2: Deploy implementation with libraries linked
  console.log("🏗️  Deploying AED Implementation...");
  
  const AEDImplementation = await ethers.getContractFactory("AEDImplementation", {
    libraries: {
      "contracts/libraries/LibMinting.sol:LibMinting": await libMinting.getAddress()
    }
  });

  // Deploy using OpenZeppelin upgrades for automatic proxy management
  const aed = await upgrades.deployProxy(
    AEDImplementation,
    [
      "Alsania Enhanced Domains", // name
      "AED",                      // symbol  
      deployer.address,           // payment wallet (fee collector)
      deployer.address            // admin
    ],
    { 
      initializer: 'initialize',
      kind: 'uups'
    }
  );
  
  await aed.waitForDeployment();
  const aedAddress = await aed.getAddress();
  
  console.log("✅ AED Proxy deployed to:", aedAddress);
  
  // Get implementation address for verification
  const implementationAddress = await upgrades.erc1967.getImplementationAddress(aedAddress);
  console.log("📋 Implementation deployed to:", implementationAddress);

  // Step 3: Verify deployment
  console.log("🔍 Verifying deployment...");
  
  console.log("Name:", await aed.name());
  console.log("Symbol:", await aed.symbol());
  console.log("Next Token ID:", await aed.getNextTokenId());
  console.log("Admin Role:", await aed.hasRole(await aed.ADMIN_ROLE(), deployer.address));

  // Step 4: Set up basic configuration
  console.log("⚙️  Setting up configuration...");
  
  // TLD prices are already set in initialize, but we can adjust them here
  // await aed.setTLDPrice("premium", ethers.parseEther("10"));
  
  console.log("🎉 Deployment completed successfully!");
  console.log("📝 Summary:");
  console.log("- Proxy Address:", aedAddress);
  console.log("- Implementation Address:", implementationAddress);
  console.log("- LibMinting Address:", await libMinting.getAddress());
  console.log("- Deployer:", deployer.address);
  
  return {
    proxy: aedAddress,
    implementation: implementationAddress,
    libMinting: await libMinting.getAddress(),
    deployer: deployer.address
  };
}

main()
  .then((result) => {
    console.log("Deployment result:", result);
    process.exit(0);
  })
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });