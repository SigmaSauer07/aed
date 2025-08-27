const { ethers, network } = require("hardhat");

async function main() {
  console.log("🔎 Verify default image mapping (domain vs subdomain)");
  const proxy = "0xbA048371f2cCA1dDfC0eC3F3058381D02A41398D";
  const aed = await ethers.getContractAt("AEDMinimal", proxy);
  const [signer] = await ethers.getSigners();

  const name = "bgcheck";
  const tld = "alsania";
  const cost = ethers.parseEther("3");
  const mintTx = await aed.connect(signer).registerDomain(name, tld, true, { value: cost });
  await mintTx.wait();
  const domain = `${name}.${tld}`;
  const tokenId = await aed.getTokenIdByDomain(domain);
  const uri = await aed.tokenURI(tokenId);
  const json = JSON.parse(Buffer.from(uri.replace("data:application/json;base64,", ""), 'base64').toString('utf8'));
  console.log("Domain image:", json.image);

  const label = "sub";
  const fee = await aed.calculateSubdomainFee(tokenId);
  const subTx = await aed.connect(signer).mintSubdomain(tokenId, label, { value: fee });
  await subTx.wait();
  const sub = `${label}.${domain}`;
  const subId = await aed.getTokenIdByDomain(sub);
  const subURI = await aed.tokenURI(subId);
  const subJSON = JSON.parse(Buffer.from(subURI.replace("data:application/json;base64,", ""), 'base64').toString('utf8'));
  console.log("Subdomain image:", subJSON.image);
}

main().catch(console.error);
