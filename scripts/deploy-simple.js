const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Deploying SIMPLE AED to Hardhat...");
  console.log("🔧 This is a working version without proxy complexity");
  
  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");

  // Deploy the simple contract
  console.log("\n🏗️  Deploying AEDSimple...");
  const AEDSimple = await ethers.getContractFactory("AEDSimple");
  const aed = await AEDSimple.deploy(
    "Alsania Enhanced Domains", // name
    "AED",                      // symbol
    deployer.address            // fee collector
  );
  
  await aed.waitForDeployment();
  const aedAddress = await aed.getAddress();
  
  console.log("✅ AEDSimple deployed to:", aedAddress);
  
  // Test basic functionality
  console.log("\n🔍 Testing basic functionality...");
  
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
    
    console.log("\n🎉 ALL TESTS PASSED! AEDSimple is working perfectly!");
    
  } catch (error) {
    console.log("❌ Test failed:", error.message);
  }
  
  // Save addresses
  const addresses = {
    aedSimple: aedAddress,
    deployer: deployer.address
  };
  
  fs.writeFileSync("simple-addresses.json", JSON.stringify(addresses, null, 2));
  console.log("\n💾 Addresses saved to: simple-addresses.json");
  
  console.log("\n✅ SIMPLE AED Deployment successful!");
  console.log("Use address for interaction:", aedAddress);
}

main()
  .then(() => {
    console.log("\n🎉 SIMPLE AED Deployment completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ SIMPLE AED Deployment failed:", error);
    process.exit(1);
  });