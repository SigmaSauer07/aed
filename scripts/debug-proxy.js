const { ethers } = require("hardhat");

async function main() {
  console.log("🔍 Debugging proxy initialization...");
  
  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Testing with account:", deployer.address);
  
  // Connect to the proxy
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation");
  const proxy = AEDCoreImplementation.attach("0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"); // Proxy address
  
  console.log("Connected to AED proxy at: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");
  
  // Try to initialize the proxy (this should fail if already initialized)
  console.log("\n🔍 Testing proxy initialization...");
  try {
    const tx = await proxy.initialize(
      "Alsania Enhanced Domains",
      "AED", 
      deployer.address,
      deployer.address
    );
    await tx.wait();
    console.log("✅ Proxy initialized successfully");
  } catch (error) {
    console.log("❌ Proxy initialization failed (expected if already initialized):", error.message);
  }
  
  // Now try the view functions
  console.log("\n🔍 Basic contract info:");
  try {
    const name = await proxy.name();
    const symbol = await proxy.symbol();
    console.log("✅ Name:", name);
    console.log("✅ Symbol:", symbol);
  } catch (error) {
    console.log("❌ Basic info error:", error.message);
  }
  
  // Check next token ID
  console.log("\n🔍 Next Token ID:");
  try {
    const nextTokenId = await proxy.getNextTokenId();
    console.log("✅ Next Token ID:", nextTokenId.toString());
  } catch (error) {
    console.log("❌ Next Token ID error:", error.message);
  }
  
  // Try to mint a domain
  console.log("\n🔍 Minting domain...");
  try {
    const tx = await proxy.registerDomain("test.alsania", deployer.address, {
      value: ethers.parseEther("1.0")
    });
    await tx.wait();
    console.log("✅ Domain minted successfully");
  } catch (error) {
    console.log("❌ Domain minting failed:", error.message);
  }
  
  // Check next token ID after minting
  console.log("\n🔍 Next Token ID after minting:");
  try {
    const nextTokenId = await proxy.getNextTokenId();
    console.log("✅ Next Token ID:", nextTokenId.toString());
  } catch (error) {
    console.log("❌ Next Token ID error:", error.message);
  }
  
  // Try to get owner for token 1
  console.log("\n🔍 Testing token 1 owner:");
  try {
    const owner = await proxy.ownerOf(1);
    console.log("✅ Token 1 owner:", owner);
  } catch (error) {
    console.log("❌ Token 1 owner error:", error.message);
  }
  
  // Try tokenURI
  console.log("\n🔍 Testing tokenURI:");
  try {
    // Get user's first domain instead of assuming tokenId=1
    const userDomains = await proxy.getUserDomains(deployer.address);
    if (userDomains.length > 0) {
      const firstDomain = userDomains[0];
      const firstTokenId = await proxy.getTokenIdByDomain(firstDomain);
      const tokenURI = await proxy.tokenURI(firstTokenId);
      console.log(`✅ Token URI for ${firstDomain} (tokenId: ${firstTokenId}):`, tokenURI.substring(0, 100) + "...");
    } else {
      console.log("⚠️  No domains found for this user");
    }
  } catch (error) {
    console.log("❌ Token URI error:", error.message);
  }
  
  // Check if domain is registered
  console.log("\n🔍 Checking domain registration:");
  try {
    const isRegistered = await proxy.isRegistered("test.alsania");
    console.log("✅ Domain registered:", isRegistered);
  } catch (error) {
    console.log("❌ Domain registration check error:", error.message);
  }
}

main()
  .then(() => {
    console.log("\n✅ Proxy debugging completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Proxy debugging failed:", error);
    process.exit(1);
  }); 