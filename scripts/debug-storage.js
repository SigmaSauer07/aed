const { ethers } = require("hardhat");

async function main() {
  console.log("🔍 Debugging storage state...");
  
  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Testing with account:", deployer.address);
  
  // Connect to the AED contract
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation");
  const aed = AEDCoreImplementation.attach("0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");
  
  console.log("Connected to AED at: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");
  
  // Check initial state
  console.log("\n🔍 Initial state:");
  try {
    const nextTokenId = await aed.getNextTokenId();
    console.log("✅ Next Token ID:", nextTokenId.toString());
  } catch (error) {
    console.log("❌ Next Token ID error:", error.message);
  }
  
  // Mint a domain
  console.log("\n🔍 Minting domain...");
  try {
    const tx = await aed.registerDomain("test.alsania", deployer.address, {
      value: ethers.parseEther("1.0")
    });
    await tx.wait();
    console.log("✅ Domain minted successfully");
  } catch (error) {
    console.log("❌ Domain minting failed:", error.message);
    return;
  }
  
  // Check state after minting
  console.log("\n🔍 State after minting:");
  try {
    const nextTokenId = await aed.getNextTokenId();
    console.log("✅ Next Token ID:", nextTokenId.toString());
    
    // The token ID should be nextTokenId - 1
    const tokenId = nextTokenId - 1n;
    console.log("✅ Expected Token ID:", tokenId.toString());
  } catch (error) {
    console.log("❌ Next Token ID error:", error.message);
  }
  
  // Try to get owner for token 1
  console.log("\n🔍 Testing token 1:");
  try {
    const owner = await aed.ownerOf(1);
    console.log("✅ Token 1 owner:", owner);
  } catch (error) {
    console.log("❌ Token 1 owner error:", error.message);
  }
  
  // Try to get owner for token 0
  console.log("\n🔍 Testing token 0:");
  try {
    const owner = await aed.ownerOf(0);
    console.log("✅ Token 0 owner:", owner);
  } catch (error) {
    console.log("❌ Token 0 owner error:", error.message);
  }
  
  // Check if domain is registered
  console.log("\n🔍 Checking domain registration:");
  try {
    const isRegistered = await aed.isRegistered("test.alsania");
    console.log("✅ Domain registered:", isRegistered);
  } catch (error) {
    console.log("❌ Domain registration check error:", error.message);
  }
  
  // Try to get domain info
  console.log("\n🔍 Getting domain info:");
  try {
    const domainInfo = await aed.getDomainInfo(1);
    console.log("✅ Domain info for token 1:");
    console.log("   Name:", domainInfo.name);
    console.log("   TLD:", domainInfo.tld);
    console.log("   Owner:", domainInfo.owner);
  } catch (error) {
    console.log("❌ Domain info error:", error.message);
  }
  
  // Try tokenURI
  console.log("\n🔍 Testing tokenURI:");
  try {
    // Get user's first domain instead of assuming tokenId=1
    const userDomains = await aed.getUserDomains(deployer.address);
    if (userDomains.length > 0) {
      const firstDomain = userDomains[0];
      const firstTokenId = await aed.getTokenIdByDomain(firstDomain);
      const tokenURI = await aed.tokenURI(firstTokenId);
      console.log(`✅ Token URI for ${firstDomain} (tokenId: ${firstTokenId}):`, tokenURI.substring(0, 100) + "...");
    } else {
      console.log("⚠️  No domains found for this user");
    }
  } catch (error) {
    console.log("❌ Token URI error:", error.message);
  }
  
  // Check user domains
  console.log("\n🔍 Checking user domains:");
  try {
    const userDomains = await aed.getUserDomains(deployer.address);
    console.log("✅ User domains:", userDomains);
  } catch (error) {
    console.log("❌ User domains error:", error.message);
  }
}

main()
  .then(() => {
    console.log("\n✅ Storage debugging completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Storage debugging failed:", error);
    process.exit(1);
  }); 