const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 Minting test tokens on current contract...");

  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Minting with account:", deployer.address);

  // Use the newly deployed contract address
  const CONTRACT_ADDRESS = "0x2E65B8C1861Dd09CECc2360dB879cfd3B6D8f5E4";
  console.log("Using AED contract at:", CONTRACT_ADDRESS);

  // Connect to the contract - try different contract names
  let AED;
  try {
    AED = await ethers.getContractAt("AED", CONTRACT_ADDRESS, deployer);
    console.log("✅ Connected using AED contract");
  } catch (error) {
    console.log("❌ AED contract failed, trying AEDCoreImplementation...");
    try {
      AED = await ethers.getContractAt("AEDCoreImplementation", CONTRACT_ADDRESS, deployer);
      console.log("✅ Connected using AEDCoreImplementation contract");
    } catch (error2) {
      console.log("❌ AEDCoreImplementation failed, trying AEDImplementation...");
      AED = await ethers.getContractAt("AEDImplementation", CONTRACT_ADDRESS, deployer);
      console.log("✅ Connected using AEDImplementation contract");
    }
  }

  // Test domains to mint
  const testDomains = [
    { name: "test1", tld: "alsania" },
    { name: "test2", tld: "fx" },
    { name: "test3", tld: "echo" },
    { name: "demo", tld: "alsania" },
    { name: "sample", tld: "fx" }
  ];

  const results = {
    successful: [],
    failed: []
  };

  console.log("\n🔍 Minting test domains...");

  for (let i = 0; i < testDomains.length; i++) {
    const { name, tld } = testDomains[i];
    const domain = `${name}.${tld}`;

    console.log(`\n📝 Minting ${domain}...`);

    try {
      // Register domain (no fee for these TLDs in your contract)
      const tx = await AED.registerDomain(domain, deployer.address);
      const receipt = await tx.wait();

      // Get token ID (should be i + 1)
      const tokenId = i + 1;

      results.successful.push({
        domain,
        tokenId,
        txHash: receipt.transactionHash
      });

      console.log(`   ✅ ${domain} minted successfully! (Token ID: ${tokenId})`);

      // Test that the metadata works
      try {
        const tokenURI = await AED.tokenURI(tokenId);
        console.log(`   🖼️  Token URI generated: ${tokenURI.substring(0, 80)}...`);
      } catch (error) {
        console.log(`   ⚠️  Token URI error: ${error.message}`);
      }

    } catch (error) {
      console.log(`   ❌ Failed to mint ${domain}: ${error.message}`);

      results.failed.push({
        domain,
        error: error.message
      });
    }
  }

  // Verify results
  console.log("\n🔍 Verification Results:");
  console.log("✅ Successful mints:", results.successful.length);
  console.log("❌ Failed mints:", results.failed.length);

  if (results.successful.length > 0) {
    console.log("\n🎯 Your metadata endpoints to test:");
    results.successful.forEach(({ domain, tokenId }) => {
      console.log(`   https://aed-metadata.vercel.app/domain/${tokenId}.json`);
    });
  }

  // Save results
  const fs = require("fs");
  const timestamp = new Date().toISOString().slice(0, 19).replace(/:/g, '-');
  const filename = `test-mint-results-${timestamp}.json`;
  fs.writeFileSync(filename, JSON.stringify(results, null, 2));
  console.log(`\n💾 Results saved to: ${filename}`);

  console.log("\n🎉 Test minting completed!");
  console.log("✅ You can now test your metadata server endpoints!");
}

main()
  .then(() => {
    console.log("\n🎉 Test minting completed successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Test minting failed:", error);
    process.exit(1);
  });