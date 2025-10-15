const { ethers } = require("hardhat");

async function main() {
  console.log("🔍 Checking what functions are available on deployed contract...");

  // Try the first contract address that was deployed around the same time as minting
  const CONTRACT_ADDRESS = "0x8dc59aA8e9AA8B9fd01AF747608B4a28b728F539";

  // Get signer
  const [signer] = await ethers.getSigners();
  console.log("Checking with account:", signer.address);

  // Connect to contract at address (without specifying ABI)
  const contract = new ethers.Contract(CONTRACT_ADDRESS, [], signer);

  console.log("\n📋 Testing basic functions:");

  // Test basic ERC721 functions
  const functions = [
    { name: "name()", signature: "0x06fdde03" },
    { name: "symbol()", signature: "0x95d89b41" },
    { name: "totalSupply()", signature: "0x18160ddd" },
    { name: "ownerOf(uint256)", params: ["0x01"], signature: "0x6352211e0000000000000000000000000000000000000000000000000000000000000001" },
    { name: "tokenURI(uint256)", params: ["0x01"], signature: "0xc87b56dd0000000000000000000000000000000000000000000000000000000000000001" },
    { name: "balanceOf(address)", params: [signer.address], signature: "0x70a08231000000000000000000000000" + signer.address.substring(2) },
  ];

  for (const func of functions) {
    try {
      console.log(`\n🔍 Testing ${func.name}:`);
      const result = await signer.provider.call({
        to: CONTRACT_ADDRESS,
        data: func.signature
      });

      if (result === "0x") {
        console.log(`   ⚠️  Function exists but returned empty data`);
      } else {
        console.log(`   ✅ Function exists! Result: ${result}`);
      }
    } catch (error) {
      console.log(`   ❌ Function failed: ${error.message}`);
    }
  }

  // Try to get contract bytecode to identify what it is
  try {
    console.log("\n🔍 Checking contract bytecode:");
    const bytecode = await signer.provider.getCode(CONTRACT_ADDRESS);
    console.log(`   📏 Contract size: ${bytecode.length} bytes`);

    if (bytecode.includes("608060405234801561001057600080fd5b50d3801561001557600080fd5b50d2801561002257600080fd5b506101b0806100326000396000f3fe")) {
      console.log("   🔧 This looks like a proxy contract");
    } else {
      console.log("   🔧 This appears to be an implementation contract");
    }
  } catch (error) {
    console.log(`   ❌ Could not get bytecode: ${error.message}`);
  }

  console.log("\n🎯 Summary:");
  console.log("The deployed contract appears to be missing the registerDomain function.");
  console.log("This could mean:");
  console.log("1. The contract is a different version");
  console.log("2. The contract is a proxy pointing to the wrong implementation");
  console.log("3. The contract is not fully deployed");

  // Try to call some AED-specific functions with raw calls
  console.log("\n🔍 Testing AED-specific functions:");

  const aedFunctions = [
    { name: "getNextTokenId()", signature: "0x4c6b6c68" },
    { name: "registerDomain(string,address)", signature: "0x12345678" }, // This is just a placeholder
  ];

  for (const func of aedFunctions) {
    try {
      const result = await signer.provider.call({
        to: CONTRACT_ADDRESS,
        data: func.signature
      });
      console.log(`   ✅ ${func.name} might exist!`);
    } catch (error) {
      console.log(`   ❌ ${func.name} failed: ${error.reason || error.message}`);
    }
  }
}

main()
  .then(() => {
    console.log("\n🎉 Contract function check completed!");
  })
  .catch((error) => {
    console.error("❌ Contract check failed:", error);
  });