const fs = require("fs");
const path = require("path");

try {
  const artifact = require("../artifacts/contracts/AED.sol/AED.json");
  const abiPath = path.join(__dirname, "../artifacts/contracts/AED.sol/AED.json");
  fs.writeFileSync(abiPath, JSON.stringify(artifact.abi, null, 2));
  console.log(`✅ ABI synced to ${abiPath}`);
} catch (err) {
  console.warn("⚠️ Could not sync ABI:", err.message);
}
