const hre = require("hardhat");

async function main() {
  const CONTRACT_ADDRESS = "<DEPLOYED_PROXY_ADDRESS>";
  const domainName = "ss.aed"; // example domain

  const AED = await hre.ethers.getContractAt("AED", CONTRACT_ADDRESS);

  const nextId = await AED.getNextTokenId();
  const [name, tld] = domainName.split('.');
  const isRegistered = await AED.isRegistered(name, tld);

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
