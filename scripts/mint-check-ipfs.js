const { ethers } = require("hardhat");

const PROXY = "0xd0E5EB4C244d0e641ee10EAd309D3F6DC627F63E";

async function main() {
  const aed = await ethers.getContractAt("AEDMinimal", PROXY);
  const [signer] = await ethers.getSigners();

  // mint one domain + subdomain
  const name = "udstyle";
  const tld = "alsania";
  const cost = ethers.parseEther("3");
  const tx = await aed.connect(signer).registerDomain(name, tld, true, { value: cost });
  await tx.wait();
  const domain = `${name}.${tld}`;
  const tokenId = await aed.getTokenIdByDomain(domain);
  const uri = await aed.tokenURI(tokenId);
  console.log("Domain tokenURI:", uri);

  const fee = await aed.calculateSubdomainFee(tokenId);
  const stx = await aed.connect(signer).mintSubdomain(tokenId, "www", { value: fee });
  await stx.wait();
  const sub = `www.${domain}`;
  const subId = await aed.getTokenIdByDomain(sub);
  const subUri = await aed.tokenURI(subId);
  console.log("Subdomain tokenURI:", subUri);
}

main().catch(console.error);
