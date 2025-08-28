const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.provider.getBalance(deployer.address)).toString());

  try {
    // Deploy AEDMinimal
    console.log("\n🏗️  Deploying AEDMinimal...");
    const AEDMinimal = await ethers.getContractFactory("AEDMinimal");
    const aedMinimal = await AEDMinimal.deploy();
    await aedMinimal.waitForDeployment();
    const aedMinimalAddress = await aedMinimal.getAddress();
    
    console.log("✅ AEDMinimal deployed to:", aedMinimalAddress);
    
    // Test basic functionality
    console.log("\n🧪 Testing basic functionality...");
    
    // Test contract name and symbol
    const name = await aedMinimal.name();
    const symbol = await aedMinimal.symbol();
    console.log("Contract name:", name);
    console.log("Contract symbol:", symbol);
    
    // Test domain registration
    console.log("\n📝 Testing domain registration...");
    try {
      const tx = await aedMinimal.registerDomain("sigmasauer07", "alsania", false, {
        value: ethers.parseEther("0.1")
      });
      await tx.wait();
      console.log("✅ Domain 'sigmasauer07.alsania' registered successfully!");
      
      // Get token ID
      const tokenId = 1; // First token
      const owner = await aedMinimal.ownerOf(tokenId);
      console.log("Token owner:", owner);
      
      // Test metadata
      const tokenURI = await aedMinimal.tokenURI(tokenId);
      console.log("Token URI:", tokenURI);
      
    } catch (error) {
      console.log("❌ Domain registration failed:", error.message);
    }
    
    // Save deployment info
    const deploymentInfo = `
amoy - ${new Date().toISOString()}
Contract: ${aedMinimalAddress}
Deployer: ${deployer.address}
Version: minimal
`;

    require('fs').appendFileSync('deployedAddress.txt', deploymentInfo);
    
    console.log("\n🎉 Deployment complete!");
    console.log("Contract Address:", aedMinimalAddress);
    console.log("Network: Amoy Testnet");
    
    return aedMinimalAddress;
    
  } catch (error) {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });