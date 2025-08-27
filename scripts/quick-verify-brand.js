const { ethers, network } = require("hardhat");

async function main() {
  console.log("🎨 Verify branding colors in SVG");
  const proxy = "0xFDCcf2199A7020587E66814000E449d26A139853"; // latest deployment with brand colors
  const aed = await ethers.getContractAt("AEDMinimal", proxy);
  const [signer] = await ethers.getSigners();

  const name = "brandcheck";
  const tld = "alsania";
  const cost = 3n * 10n ** 18n; // 3 ETH in wei
  const tx = await aed.connect(signer).registerDomain(name, tld, true, { value: cost });
  await tx.wait();
  const domain = `${name}.${tld}`;
  const tokenId = await aed.getTokenIdByDomain(domain);
  const uri = await aed.tokenURI(tokenId);
  const b64 = uri.substring("data:application/json;base64,".length);
  const jsonStr = Buffer.from(b64, 'base64').toString('utf8');
  const meta = JSON.parse(jsonStr);
  console.log("Name:", meta.name);
  console.log("Image prefix:", meta.image.slice(0, 30));
  const imgB64 = meta.image.substring("data:image/svg+xml;base64,".length);
  const svg = Buffer.from(imgB64, 'base64').toString('utf8');
  console.log("SVG snippet:", svg.slice(0, 200));
  console.log("Contains #39FF14:", svg.includes("#39FF14"));
  console.log("Contains #0A2472 or #071A52:", svg.includes("#0A2472") || svg.includes("#071A52"));
}

main().catch(console.error);
