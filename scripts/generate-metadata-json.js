const { ethers, network } = require("hardhat");
const fs = require("fs");

// Choose the proxy we will standardize (latest with setBaseURI):
const PROXY = "0xbA048371f2cCA1dDfC0eC3F3058381D02A41398D";

// Default images (domain/subdomain)
const DOMAIN_BG = "https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png";
const SUB_BG = "https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png";

async function main() {
  console.log("🧰 Generating off-chain metadata JSON for:", PROXY);
  const aed = await ethers.getContractAt("AEDMinimal", PROXY);
  const [signer] = await ethers.getSigners();

  const outDir = `metadata-json-${network.name}`;
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir);

  const domains = await aed.getUserDomains(signer.address);
  console.log("Found domains:", domains.length);

  const results = [];
  for (const d of domains) {
    try {
      const tokenId = await aed.getTokenIdByDomain(d);
      const info = await aed.getDomainInfo(tokenId);
      const name = d; // e.g., sigmasauer07.alsania
      const isSub = info.isSubdomain;

      // pick image (custom not stored here; off-chain json points to defaults)
      const image = isSub ? SUB_BG : DOMAIN_BG;

      const json = {
        name,
        description: `Alsania Enhanced Domain - ${name}`,
        external_url: `https://alsania.io/domain/${name}`,
        image,
        attributes: [
          { trait_type: "TLD", value: info.tld },
          { trait_type: "Subdomains", value: Number(info.subdomainCount) },
          { trait_type: "Type", value: isSub ? "Subdomain" : "Domain" },
          { trait_type: "Features Enabled", value: 1 }
        ]
      };

      const path = `${outDir}/${tokenId}.json`;
      fs.writeFileSync(path, JSON.stringify(json, null, 2));
      console.log("  ✅", name, "->", path);
      results.push({ name, tokenId: tokenId.toString(), path });
    } catch (e) {
      console.log("  ❌", d, e.message);
    }
  }

  const indexPath = `${outDir}/index.json`;
  fs.writeFileSync(indexPath, JSON.stringify({ proxy: PROXY, results }, null, 2));
  console.log("\n📝 Wrote index:", indexPath);
  console.log("📦 Next: Pin the folder", outDir, "to IPFS (Pinata) and share the CID");
  console.log("🔧 Then we will setBaseURI to ipfs://<CID>/ and refresh metadata in marketplaces.");
}

if (require.main === module) {
  main().catch((e) => { console.error(e); process.exit(1); });
}

module.exports = main;
