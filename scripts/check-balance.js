const { ethers } = require("hardhat");

async function main() {
  console.log("💰 Checking account balances on Amoy testnet...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Account address:", deployer.address);
  
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Balance:", ethers.formatEther(balance), "MATIC");
  
  if (balance === 0n) {
    console.log("\n❌ No funds available!");
    console.log("🔗 Get testnet MATIC from:");
    console.log("   - Polygon Faucet: https://faucet.polygon.technology/");
    console.log("   - QuickNode Amoy Faucet: https://faucet.quicknode.com/polygon/amoy");
    console.log("   - Alchemy Polygon Faucet: https://www.alchemy.com/faucets/polygon-amoy");
    console.log("   - Or use a different account with funds");
  } else {
    console.log("\n✅ Sufficient funds available for deployment!");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 