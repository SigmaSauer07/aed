const { ethers } = require("hardhat");
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function main() {
  console.log("🚀 Deploying AED to Amoy Testnet with Sigma's Wallet...");
  console.log("Wallet Address: 0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43");
  
  // Get private key securely
  const privateKey = await question("ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
  rl.close();
  
  if (!privateKey || privateKey.length !== 64) {
    console.error("❌ Invalid private key format. Should be 64 hex characters.");
    process.exit(1);
  }
  
  // Create wallet from private key
  const wallet = new ethers.Wallet(`0x${privateKey}`);
  const provider = new ethers.JsonRpcProvider("https://rpc-amoy.polygon.technology");
  const signer = wallet.connect(provider);
  
  console.log("Deploying with account:", signer.address);
  console.log("Account balance:", ethers.formatEther(await provider.getBalance(signer.address)), "MATIC");

  // Step 1: Deploy libraries first
  console.log("\n📚 Step 1: Deploying Libraries...");
  const LibMinting = await ethers.getContractFactory("LibMinting", signer);
  const libMinting = await LibMinting.deploy();
  await libMinting.waitForDeployment();
  console.log("✅ LibMinting deployed to:", await libMinting.getAddress());

  // Step 2: Deploy AEDCoreImplementation
  console.log("\n🏗️  Step 2: Deploying AEDCoreImplementation...");
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation", signer);
  
  const coreImplementation = await AEDCoreImplementation.deploy();
  await coreImplementation.waitForDeployment();
  console.log("✅ AEDCoreImplementation deployed to:", await coreImplementation.getAddress());

  // Step 3: Deploy proxy
  console.log("\n🎭 Step 3: Deploying Proxy...");
  const AED = await ethers.getContractFactory("AED", signer);
  
  // Encode initialization data
  const initData = coreImplementation.interface.encodeFunctionData(
    'initialize',
    [
      "Alsania Enhanced Domains", // name
      "AED",                      // symbol  
      signer.address,             // payment wallet
      signer.address              // admin
    ]
  );

  const proxy = await AED.deploy(await coreImplementation.getAddress(), initData);
  await proxy.waitForDeployment();
  console.log("✅ Proxy deployed to:", await proxy.getAddress());

  // Step 4: Connect to proxy using core implementation interface
  const aed = coreImplementation.attach(await proxy.getAddress());

  // Step 5: Verify deployment
  console.log("\n🔍 Step 5: Verifying Deployment...");
  console.log("Name:", await aed.name());
  console.log("Symbol:", await aed.symbol());
  console.log("Next Token ID:", await aed.getNextTokenId());

  console.log("\n🎉 AED Deployment to Amoy Testnet Completed Successfully!");
  console.log("\n📝 Contract Addresses:");
  console.log("- Proxy (main):", await proxy.getAddress());
  console.log("- Core Implementation:", await coreImplementation.getAddress());
  console.log("- LibMinting:", await libMinting.getAddress());
  
  console.log("\n🚀 AED is now live on Amoy testnet!");
  console.log("✅ Ready for domain minting");
  console.log("✅ Ready for subdomain creation");
  console.log("✅ Ready for testing");
  
  // Save addresses to file for later use
  const addresses = {
    proxy: await proxy.getAddress(),
    coreImplementation: await coreImplementation.getAddress(),
    libMinting: await libMinting.getAddress(),
    deployer: signer.address
  };
  
  console.log("\n💾 Saving addresses to amoy-addresses.json...");
  const fs = require('fs');
  fs.writeFileSync('amoy-addresses.json', JSON.stringify(addresses, null, 2));
  
  return addresses;
}

main()
  .then((result) => {
    console.log("\n✅ AED Amoy Deployment successful!");
    console.log("Use proxy address for interaction:", result.proxy);
    console.log("Addresses saved to: amoy-addresses.json");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  }); 