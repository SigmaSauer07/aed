const { ethers, network } = require("hardhat");

async function main() {
  console.log("🧪 Quick mint + check");
  const proxy = "0x0785077782f01b8fCc80Ed0709Fdf5a9226149Cf";
  const aed = await ethers.getContractAt("AEDMinimal", proxy);
  const [signer] = await ethers.getSigners();

  const name = "showcase";
  const tld = "alsania";
  const cost = 3n * 10n ** 18n; // 3 ETH in wei
  const tx = await aed.connect(signer).registerDomain(name, tld, true, { value: cost });
  await tx.wait();
  const domain = `${name}.${tld}`;
  const tokenId = await aed.getTokenIdByDomain(domain);
  const uri = await aed.tokenURI(tokenId);
  console.log("Token URI prefix:", uri.slice(0, 40));
  console.log("Token URI length:", uri.length);
  if (uri.startsWith("data:application/json;base64,")) {
    const b64 = uri.substring("data:application/json;base64,".length);
    const json = Buffer.from(b64, 'base64').toString('utf8');
    console.log("Decoded JSON:", json);
  }
}

main().catch(console.error);
