const { ethers, network } = require("hardhat");

// Set the base URI to a CID root; tokenURI will append domain/ or sub/ + tokenId.json
const PROXY = "0xd0E5EB4C244d0e641ee10EAd309D3F6DC627F63E";
const CID = "bafybeiautd6snqb5eelmfzwuca7ff5slubz3ftcq7uncskjjnhg5zwpmry"; // provided by user
const BASE_URI = `ipfs://${CID}/`;

async function main() {
  console.log("🔧 Setting baseURI on:", PROXY);
  console.log("Base URI:", BASE_URI, "(tokenURI => baseURI + domain|sub + tokenId.json)");

  const aed = await ethers.getContractAt("AEDMinimal", PROXY);
  const tx = await aed.setBaseURI(BASE_URI);
  const rcpt = await tx.wait();
  console.log("✅ baseURI set. tx:", rcpt.hash);
}

if (require.main === module) {
  main().catch((e) => { console.error(e); process.exit(1); });
}

module.exports = main;
