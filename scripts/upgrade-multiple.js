const { ethers, network } = require("hardhat");
require("dotenv").config();

// Proxies we want to upgrade (older deployments)
const PROXIES = [
  // First minimal deployment
  "0x8dc59aA8e9AA8B9fd01AF747608B4a28b728F539",
  // Earlier metadata deployment
  "0xFC81A3Ab2A7112da7E8721b95703DFA05a381071",
  // Another metadata deployment
  "0x3FACD1fD7D8E63fBF05345939b53EDF427568E5b"
];

function getUpgradeContract(address, signer) {
  const iface = new ethers.Interface([
    "function upgradeTo(address newImplementation)",
    "function DEFAULT_ADMIN_ROLE() view returns (bytes32)",
    "function hasRole(bytes32,address) view returns (bool)",
    "function getUserDomains(address) view returns (string[])",
    "function getTokenIdByDomain(string) view returns (uint256)",
    "function tokenURI(uint256) view returns (string)"
  ]);
  return new ethers.Contract(address, iface, signer);
}

async function main() {
  console.log("🔄 Upgrading multiple AED proxies to latest implementation...");
  console.log("Network:", network.name);

  const [signer] = await ethers.getSigners();
  console.log("👤 Signer:", signer.address);

  // 1) Deploy latest implementation once
  console.log("\n📦 Deploying latest AEDMinimal implementation...");
  const Impl = await ethers.getContractFactory("AEDMinimal");
  const impl = await Impl.deploy();
  await impl.waitForDeployment();
  const newImplAddr = await impl.getAddress();
  console.log("✅ New implementation:", newImplAddr);

  // 2) Iterate proxies and upgrade
  const results = [];
  for (const proxy of PROXIES) {
    try {
      console.log(`\n⬆️  Upgrading proxy ${proxy} ...`);
      const aed = getUpgradeContract(proxy, signer);

      // Try calling upgradeTo; UUPS requires DEFAULT_ADMIN_ROLE
      const adminRole = await aed.DEFAULT_ADMIN_ROLE();
      const hasAdmin = await aed.hasRole(adminRole, signer.address);
      console.log("   🔑 Has admin:", hasAdmin);
      if (!hasAdmin) throw new Error("Missing admin role on proxy " + proxy);

      const tx = await aed.upgradeTo(newImplAddr);
      const receipt = await tx.wait();
      console.log("   ✅ Upgraded (tx):", receipt.hash);

      // Quick spot-check: call tokenURI for one of signer domains if any
      const domains = await aed.getUserDomains(signer.address);
      if (domains.length > 0) {
        const domain = domains[0];
        const tokenId = await aed.getTokenIdByDomain(domain);
        const uri = await aed.tokenURI(tokenId);
        console.log("   🔍 tokenURI prefix:", uri.slice(0, 36));
      }

      results.push({ proxy, status: "upgraded", tx: receipt.hash });
    } catch (e) {
      console.error("   ❌ Upgrade failed for", proxy, e.message);
      results.push({ proxy, status: "failed", error: e.message });
    }
  }

  console.log("\n📊 Upgrade summary:");
  console.log(results);

  return { newImpl: newImplAddr, results };
}

if (require.main === module) {
  main().catch((err) => {
    console.error("❌ Upgrade script error:", err);
    process.exit(1);
  });
}

module.exports = main;
