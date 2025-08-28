const { ethers } = require("hardhat");

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
    
    // Initialize the contract
    console.log("\n🔧 Initializing contract...");
    const initTx = await aedMinimal.initialize(
      "Alsania Enhanced Domains",  // name
      "AED",                      // symbol
      deployer.address,           // payment wallet (using deployer for now)
      deployer.address            // admin
    );
    await initTx.wait();
    console.log("✅ Contract initialized successfully!");
    
    // Test basic functionality
    console.log("\n🧪 Testing basic functionality...");
    
    // Test contract name and symbol
    const name = await aedMinimal.name();
    const symbol = await aedMinimal.symbol();
    console.log("Contract name:", name);
    console.log("Contract symbol:", symbol);
    
    // Test TLD validation
    const isAlsaniaValid = await aedMinimal.isTLDActive("alsania");
    const isAedValid = await aedMinimal.isTLDActive("aed");
    console.log("TLD 'alsania' is valid:", isAlsaniaValid);
    console.log("TLD 'aed' is valid:", isAedValid);
    
    // Test domain registration with free TLD first
    console.log("\n📝 Testing domain registration with free TLD 'aed'...");
    try {
      const tx1 = await aedMinimal.registerDomain("sigmasauer07", "aed", false, {
        value: ethers.parseEther("0.1") // Should be free but adding value just in case
      });
      await tx1.wait();
      console.log("✅ Domain 'sigmasauer07.aed' registered successfully!");
      
      // Get token ID and test metadata
      const tokenId1 = await aedMinimal.getTokenIdByDomain("sigmasauer07.aed");
      console.log("Token ID:", tokenId1.toString());
      
      const owner1 = await aedMinimal.ownerOf(tokenId1);
      console.log("Token owner:", owner1);
      
      const domainInfo1 = await aedMinimal.getDomainInfo(tokenId1);
      console.log("Domain info:", {
        name: domainInfo1.name,
        tld: domainInfo1.tld,
        isSubdomain: domainInfo1.isSubdomain
      });
      
    } catch (error) {
      console.log("❌ Free domain registration failed:", error.message);
    }
    
    // Test domain registration with paid TLD
    console.log("\n📝 Testing domain registration with paid TLD 'alsania'...");
    try {
      const tx2 = await aedMinimal.registerDomain("echo", "alsania", false, {
        value: ethers.parseEther("1.5") // 1 ETH for alsania TLD
      });
      await tx2.wait();
      console.log("✅ Domain 'echo.alsania' registered successfully!");
      
      // Get token ID and test metadata
      const tokenId2 = await aedMinimal.getTokenIdByDomain("echo.alsania");
      console.log("Token ID:", tokenId2.toString());
      
      const domainInfo2 = await aedMinimal.getDomainInfo(tokenId2);
      console.log("Domain info:", {
        name: domainInfo2.name,
        tld: domainInfo2.tld,
        isSubdomain: domainInfo2.isSubdomain
      });
      
    } catch (error) {
      console.log("❌ Paid domain registration failed:", error.message);
    }
    
    // Test tokenURI
    console.log("\n🔗 Testing metadata (tokenURI)...");
    try {
      const tokenId = 1; // First token
      const tokenURI = await aedMinimal.tokenURI(tokenId);
      console.log("Token URI for token 1:", tokenURI.substring(0, 100) + "...");
      
      // If it's a data URI, decode and show the JSON
      if (tokenURI.startsWith("data:application/json;base64,")) {
        const base64Data = tokenURI.split(",")[1];
        const jsonData = Buffer.from(base64Data, 'base64').toString();
        console.log("Decoded metadata:", JSON.parse(jsonData));
      }
      
    } catch (error) {
      console.log("❌ TokenURI test failed:", error.message);
    }
    
    // Save deployment info
    const deploymentInfo = `
amoy - ${new Date().toISOString()}
Contract: ${aedMinimalAddress}
Deployer: ${deployer.address}
Version: minimal-initialized
`;

    require('fs').appendFileSync('deployedAddress.txt', deploymentInfo);
    
    console.log("\n🎉 Deployment and testing complete!");
    console.log("Contract Address:", aedMinimalAddress);
    console.log("Network: Amoy Testnet");
    console.log("Contract Name:", name);
    console.log("Contract Symbol:", symbol);
    
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