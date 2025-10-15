const { ethers, network } = require("hardhat");

// Latest metadata-enabled proxy on Amoy (branding-correct)
const PROXY = "0xFDCcf2199A7020587E66814000E449d26A139853";

const NAMES = ["sigmasauer07", "echo", "alsania"];
const TLDS = ["aed", "alsa", "07", "alsania", "fx", "echo"];
const FREE_TLDS = new Set(["aed", "alsa", "07"]);

const toWei = (eth) => ethers.parseEther(eth);

async function main() {
  console.log("🚀 Minting full matrix on:", PROXY);
  console.log("Network:", network.name);

  const [signer] = await ethers.getSigners();
  const aed = await ethers.getContractAt("AEDMinimal", PROXY);

  const results = [];

  for (const name of NAMES) {
    console.log(`\n👤 Name: ${name}`);
    for (const tld of TLDS) {
      const domain = `${name}.${tld}`;
      try {
        const exists = await aed.isRegistered(name, tld);
        if (exists) {
          console.log(`  ⚠️  Exists: ${domain} - skipping mint`);
        } else {
          // Cost: free tlds = 0 + 2, paid tlds = 1 + 2
          const baseCost = FREE_TLDS.has(tld) ? 0n : toWei("1");
          const enhancement = toWei("2");
          const total = baseCost + enhancement;

          console.log(`  💸 Minting ${domain} (with subdomains) cost=${ethers.formatEther(total)} ETH`);
          const tx = await aed.connect(signer).registerDomain(name, tld, true, { value: total });
          const rcpt = await tx.wait();
          console.log(`  ✅ Minted ${domain} (tx: ${rcpt.hash})`);
        }

        const tokenId = await aed.getTokenIdByDomain(domain);
        const uri = await aed.tokenURI(tokenId);
        const uriPrefix = uri.slice(0, 32);

        // Create one subdomain per root
        const label = name === "echo" ? "web" : name === "alsania" ? "app" : "www";
        const fee = await aed.calculateSubdomainFee(tokenId);
        const subTx = await aed.connect(signer).mintSubdomain(tokenId, label, { value: fee });
        const subRcpt = await subTx.wait();
        const subDomain = `${label}.${domain}`;
        const subTokenId = await aed.getTokenIdByDomain(subDomain);
        const subUri = await aed.tokenURI(subTokenId);

        console.log(`  🌿 Subdomain ${subDomain} (fee ${ethers.formatEther(fee)}), token=${subTokenId} uri64=${subUri.slice(0,32)}`);

        results.push({ domain, tokenId: tokenId.toString(), uriPrefix, subDomain, subTokenId: subTokenId.toString() });
      } catch (err) {
        console.log(`  ❌ Failed ${domain}: ${err.message}`);
        results.push({ domain, error: err.message });
      }

      // minor delay to avoid provider throttling
      await new Promise(r => setTimeout(r, 1000));
    }
  }

  // Output a compact JSON with the matrix
  const fs = require("fs");
  const ts = new Date().toISOString().replace(/[:.]/g, "-");
  const outFile = `./mint-matrix-${network.name}-${ts}.json`;
  fs.writeFileSync(outFile, JSON.stringify({ proxy: PROXY, results }, null, 2));
  console.log("\n📝 Saved results to:", outFile);

  console.log("\n✅ Full matrix minting completed.");
}

if (require.main === module) {
  main().catch(err => { console.error("❌ Minting failed:", err); process.exit(1); });
}

module.exports = main;
