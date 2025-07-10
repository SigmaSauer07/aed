// scripts/mintTest.js
const { ethers } = require("hardhat");

async function main() {
  const [signer] = await ethers.getSigners();

  const AED = await ethers.getContractAt("AED", "0xD34DA46f15a44B9475877db8dd7daCd9dA534896", signer);

  const name = "sigmaspace";
  const tld = "alsania";
  const mintFee = 0;
  const feeEnabled = false;
  const duration = 365 * 24 * 60 * 60; // 1 year

  const tx = await AED.registerDomain(name, tld, mintFee, feeEnabled, duration, {
    value: ethers.parseEther("0.01"), // enough to cover 1 year
  });

  const receipt = await tx.wait();
  console.log("✅ Minted:", receipt.hash);

  const domain = `${name}.${tld}`;
  const registered = await AED.isRegistered(domain);
  console.log(`🟩 Domain "${domain}" registered:`, registered);
}

main().catch((err) => {
  console.error("❌ Minting failed:", err);
  process.exit(1);
});
