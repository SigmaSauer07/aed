const { ethers } = require("hardhat");
const readline = require('readline');
const fs = require('fs');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

async function main() {
  console.log("🎯 Minting AED Domains on Amoy Testnet...");
  
  // Check if addresses file exists
  if (!fs.existsSync('amoy-addresses.json')) {
    console.error("❌ amoy-addresses.json not found. Please deploy to Amoy first.");
    process.exit(1);
  }
  
  const addresses = JSON.parse(fs.readFileSync('amoy-addresses.json', 'utf8'));
  console.log("📋 Using deployed addresses from amoy-addresses.json");
  
  // Get private key securely
  const privateKey = await question("Enter your private key (without 0x): ");
  rl.close();
  
  if (!privateKey || privateKey.length !== 64) {
    console.error("❌ Invalid private key format. Should be 64 hex characters.");
    process.exit(1);
  }
  
  // Create wallet from private key
  const wallet = new ethers.Wallet(`0x${privateKey}`);
  const provider = new ethers.JsonRpcProvider("https://rpc-amoy.polygon.technology");
  const signer = wallet.connect(provider);
  
  console.log("Minting with account:", signer.address);
  
  // Connect to the AED contract
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation", signer);
  const aed = AEDCoreImplementation.attach(addresses.proxy);
  
  console.log("Connected to AED at:", addresses.proxy);
  
  // Helper function to determine registration fee
  function getRegistrationFee(domain) {
    if (domain.includes(".alsania") || domain.includes(".fx") || domain.includes(".echo")) {
      return ethers.parseEther("1.0"); // 1 ETH for premium TLDs
    }
    return ethers.parseEther("0.01"); // 0.01 ETH for other TLDs
  }
  
  // Domain lists
  const sigmaDomains = [
    "sigmasauer07.alsania",
    "sigmasauer07.aelion", 
    "sigmasauer07.sigma",
    "sigmasauer07.echo",
    "sigmasauer07.mcp"
  ];
  
  const echoDomains = [
    "echo.n3xt",
    "echo.fx", 
    "echo.chain",
    "echo.mind",
    "echo.ai"
  ];
  
  console.log("\n📝 Minting 5 Sigma domains:");
  for (let i = 0; i < sigmaDomains.length; i++) {
    const domain = sigmaDomains[i];
    console.log(`\n${i + 1}. Minting: ${domain}`);
    
    try {
      const fee = getRegistrationFee(domain);
      const tx = await aed.registerDomain(domain, signer.address, {
        value: fee
      });
      
      console.log(`   Transaction hash: ${tx.hash}`);
      await tx.wait();
      console.log(`   ✅ ${domain} minted successfully!`);
      
    } catch (error) {
      console.error(`   ❌ Failed to mint ${domain}:`, error.message);
    }
  }
  
  console.log("\n📝 Minting 5 Echo domains:");
  for (let i = 0; i < echoDomains.length; i++) {
    const domain = echoDomains[i];
    console.log(`\n${i + 1}. Minting: ${domain}`);
    
    try {
      const fee = getRegistrationFee(domain);
      const tx = await aed.registerDomain(domain, signer.address, {
        value: fee
      });
      
      console.log(`   Transaction hash: ${tx.hash}`);
      await tx.wait();
      console.log(`   ✅ ${domain} minted successfully!`);
      
    } catch (error) {
      console.error(`   ❌ Failed to mint ${domain}:`, error.message);
    }
  }
  
  // Verify minted domains
  console.log("\n🔍 Verifying minted domains...");
  
  // Get all user domains to verify
  try {
    const userDomains = await aed.getUserDomains(signer.address);
    console.log(`\n📋 User domains: ${userDomains.join(', ')}`);
    
    for (let i = 0; i < userDomains.length; i++) {
      const domain = userDomains[i];
      const tokenId = i + 1; // Assuming sequential token IDs
      
      try {
        const isRegistered = await aed.isRegistered(domain);
        const domainInfo = await aed.getDomainInfo(tokenId);
        const owner = await aed.ownerOf(tokenId);
        
        console.log(`   ${domain}: Registered=${isRegistered}, Owner=${owner}, TokenID=${tokenId}`);
      } catch (error) {
        console.log(`   ${domain}: Error checking - ${error.message}`);
      }
    }
  } catch (error) {
    console.log(`   Error getting user domains: ${error.message}`);
  }
  
  const allDomains = [...sigmaDomains, ...echoDomains];
  console.log("\n🎉 Domain minting completed!");
  console.log(`📊 Total domains attempted: ${allDomains.length}`);
  console.log(`💰 Total spent: ${ethers.formatEther(ethers.parseEther("0.01") * BigInt(allDomains.length))} ETH`);
}

main()
  .then(() => {
    console.log("\n✅ Domain minting script completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Domain minting failed:", error);
    process.exit(1);
  }); 