const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Deploying SIMPLE AED to Amoy Testnet...");
  console.log("🔧 This is the WORKING version without proxy complexity");
  
  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // Deploy the simple contract
  console.log("\n🏗️  Deploying AEDSimple to Amoy...");
  const AEDSimple = await ethers.getContractFactory("AEDSimple");
  const aed = await AEDSimple.deploy(
    "Alsania Enhanced Domains", // name
    "AED",                      // symbol
    deployer.address            // fee collector
  );
  
  await aed.waitForDeployment();
  const aedAddress = await aed.getAddress();
  
  console.log("✅ AEDSimple deployed to Amoy:", aedAddress);
  
  // Test basic functionality
  console.log("\n🔍 Testing basic functionality on Amoy...");
  
  try {
    const name = await aed.name();
    const symbol = await aed.symbol();
    const nextTokenId = await aed.nextTokenId();
    
    console.log("✅ Name:", name);
    console.log("✅ Symbol:", symbol);
    console.log("✅ Next Token ID:", nextTokenId.toString());
    
    console.log("\n🎉 AEDSimple is working on Amoy!");
    
  } catch (error) {
    console.log("❌ Test failed:", error.message);
  }
  
  // Save addresses
  const addresses = {
    aedSimple: aedAddress,
    deployer: deployer.address,
    network: "amoy"
  };
  
  fs.writeFileSync("amoy-simple-addresses.json", JSON.stringify(addresses, null, 2));
  console.log("\n💾 Addresses saved to: amoy-simple-addresses.json");
  
  console.log("\n✅ SIMPLE AED Amoy Deployment successful!");
  console.log("Use address for interaction:", aedAddress);
  console.log("\n🚀 Ready to mint domains with proper tokenURI and images!");
}

main()
  .then(() => {
    console.log("\n🎉 SIMPLE AED Amoy Deployment completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ SIMPLE AED Amoy Deployment failed:", error);
    process.exit(1);
  }); 