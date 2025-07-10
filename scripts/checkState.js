// scripts/checkState.js
const hre = require("hardhat");

async function main() {
  const CONTRACT_ADDRESS = "0xD34DA46f15a44B9475877db8dd7daCd9dA534896";
  const domainName = "ss.aed"; // replace with your actual domain

  const AED = await hre.ethers.getContractAt("AED", CONTRACT_ADDRESS);

  const nextId = await AED.nextTokenId();
  const isRegistered = await AED.registered(domainName);

  console.log("➡️  Next Token ID:", nextId.toString());
  console.log(`➡️  Registered: ${domainName} =>`, isRegistered);

  try {
    const owner = await AED.ownerOf(1);
    console.log("➡️  Owner of token 1:", owner);
  } catch (err) {
    console.error("❌ No token 1 exists (maybe not minted yet)");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
