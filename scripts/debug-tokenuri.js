const { ethers } = require("hardhat");

async function main() {
  console.log("🔍 Debugging tokenURI functionality...");
  
  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Testing with account:", deployer.address);
  
  // Connect to the AED contract
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation");
  const aed = AEDCoreImplementation.attach("0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");
  
  console.log("Connected to AED at: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");
  
  // Step 1: Mint a test domain
  console.log("\n🔍 Step 1: Minting test domain...");
  try {
    const tx = await aed.registerDomain("test.alsania", deployer.address, {
      value: ethers.parseEther("1.0")
    });
    await tx.wait();
    console.log("✅ Test domain minted successfully");
  } catch (error) {
    console.log("❌ Domain minting failed:", error.message);
    return;
  }
  
  // Step 2: Check if token 1 exists
  console.log("\n🔍 Step 2: Checking token 1 existence...");
  try {
    const owner = await aed.ownerOf(1);
    console.log("✅ Token 1 owner:", owner);
  } catch (error) {
    console.log("❌ Token 1 doesn't exist:", error.message);
    return;
  }
  
  // Step 3: Check domain mapping directly
  console.log("\n🔍 Step 3: Checking domain mapping...");
  try {
    // Try to get domain info
    const domainInfo = await aed.getDomainInfo(1);
    console.log("✅ Domain info retrieved:");
    console.log("   Name:", domainInfo.name);
    console.log("   TLD:", domainInfo.tld);
    console.log("   Owner:", domainInfo.owner);
  } catch (error) {
    console.log("❌ Domain info error:", error.message);
  }
  
  // Step 4: Try tokenURI
  console.log("\n🔍 Step 4: Testing tokenURI...");
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
    
    // Decode the base64 to see the actual JSON
    if (tokenURI.startsWith("data:application/json;base64,")) {
      const base64Data = tokenURI.substring(29); // Remove the prefix
      const jsonData = Buffer.from(base64Data, 'base64').toString();
      console.log("📄 Decoded JSON:", jsonData);
    }
  } catch (error) {
    console.log("❌ Token URI error:", error.message);
    
    // Let's try to debug what's happening
    console.log("\n🔍 Debugging tokenURI failure...");
    
    // Check if the token exists in storage
    try {
      const exists = await aed.isRegistered("test.alsania");
      console.log("✅ Domain registered check:", exists);
    } catch (error) {
      console.log("❌ Domain registered check failed:", error.message);
    }
  }
  
  // Step 5: Test a simple function to see if contract is working
  console.log("\n🔍 Step 5: Testing basic contract functions...");
  try {
    const name = await aed.name();
    const symbol = await aed.symbol();
    const nextTokenId = await aed.getNextTokenId();
    console.log("✅ Basic contract info:");
    console.log("   Name:", name);
    console.log("   Symbol:", symbol);
    console.log("   Next Token ID:", nextTokenId.toString());
  } catch (error) {
    console.log("❌ Basic contract functions failed:", error.message);
  }
}

main()
  .then(() => {
    console.log("\n✅ Debugging completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Debugging failed:", error);
    process.exit(1);
  }); 