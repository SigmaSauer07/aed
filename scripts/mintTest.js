const { ethers } = require("hardhat");

async function main() {
  const [signer] = await ethers.getSigners();
  const AED = await ethers.getContractAt("AED", "<DEPLOYED_PROXY_ADDRESS>", signer);

  const name = "sigmaspace";
  const tld = "alsania";

  const tx = await AED.registerDomain(name, tld, false, {
    value: ethers.parseEther("0.01"),
  });
  const receipt = await tx.wait();
  console.log("✅ Minted:", receipt.transactionHash);

  const domain = `${name}.${tld}`;
  const registered = await AED.isRegistered(name, tld);
  console.log(`🟩 Domain "${domain}" registered:`, registered);
}

main().catch((err) => {
  console.error("❌ Minting failed:", err);
  process.exit(1);
});
