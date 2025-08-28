const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Simple minting test...");

  const [deployer] = await ethers.getSigners();
  console.log("Using account:", deployer.address);

  // Fresh contract address
  const CONTRACT_ADDRESS = "0x8e7BF91e4B6e5B556ba1D5076Aa19d10765e99f0";

  // Try different ways to connect
  let contract;

  try {
    // Method 1: Use AED contract factory
    contract = await ethers.getContractAt("AED", CONTRACT_ADDRESS, deployer);
    console.log("✅ Connected using AED factory");
  } catch (error) {
    console.log("❌ AED factory failed, trying AEDCoreImplementation...");
    try {
      // Method 2: Use AEDCoreImplementation
      contract = await ethers.getContractAt("AEDCoreImplementation", CONTRACT_ADDRESS, deployer);
      console.log("✅ Connected using AEDCoreImplementation factory");
    } catch (error2) {
      console.log("❌ All factory methods failed");
      console.log("Error:", error2.message);
      return;
    }
  }

  // Test basic functions first
  try {
    console.log("\n🔍 Testing basic functions:");
    const name = await contract.name();
    console.log("✅ Name:", name);

    const symbol = await contract.symbol();
    console.log("✅ Symbol:", symbol);

    const nextId = await contract.getNextTokenId();
    console.log("✅ Next Token ID:", nextId.toString());
  } catch (error) {
    console.log("❌ Basic functions failed:", error.message);
    return;
  }

  // Now try to mint
  console.log("\n🔍 Testing domain registration:");
  const testDomains = [
    { name: "test", tld: "alsania" }
  ];

  for (const domain of testDomains) {
    const fullDomain = `${domain.name}.${domain.tld}`;
    console.log(`\n📝 Attempting to mint: ${fullDomain}`);

    try {
      // Try the registerDomain function
      const tx = await contract.registerDomain(fullDomain, deployer.address);
      console.log("✅ Register transaction sent:", tx.hash);

      const receipt = await tx.wait();
      console.log("✅ Transaction confirmed:", receipt.transactionHash);

      // Check if it worked
      const nextId = await contract.getNextTokenId();
      console.log("✅ Next Token ID after mint:", nextId.toString());

    } catch (error) {
      console.log(`❌ Minting failed: ${error.message}`);

      // Try alternative function names
      console.log("🔍 Trying alternative function names...");

      const alternativeCalls = [
        { name: "register", params: [fullDomain, deployer.address] },
        { name: "mint", params: [fullDomain] },
        { name: "mintDomain", params: [domain.name, domain.tld] }
      ];

      for (const alt of alternativeCalls) {
        try {
          console.log(`   Trying ${alt.name}...`);
          const tx = await contract[alt.name](...alt.params);
          console.log(`   ✅ ${alt.name} worked!`);
          const receipt = await tx.wait();
          console.log(`   ✅ Transaction: ${receipt.transactionHash}`);
          break;
        } catch (altError) {
          console.log(`   ❌ ${alt.name} also failed: ${altError.message}`);
        }
      }
    }
  }

  console.log("\n🎉 Test completed!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Test failed:", error);
    process.exit(1);
  });