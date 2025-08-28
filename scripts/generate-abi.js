const { ethers } = require("hardhat");

async function main() {
  try {
    // Get the contract factory
    const AEDMinimal = await ethers.getContractFactory("AEDMinimal");
    
    // Get the ABI in proper format
    const abi = AEDMinimal.interface.fragments.map(fragment => JSON.parse(fragment.format("json")));
    
    // Create ABI object
    const abiObject = { abi: abi };
    const prettyAbi = JSON.stringify(abiObject, null, 2);
    
    console.log("ABI generated successfully");
    
    // Save to file
    const fs = require('fs');
    fs.writeFileSync('frontend/aed-home/js/aedABI.json', prettyAbi);
    fs.writeFileSync('frontend/aed-admin/js/aedABI.json', prettyAbi);
    
    console.log("\n✅ ABI files generated successfully!");
    
  } catch (error) {
    console.error("❌ Failed to generate ABI:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });