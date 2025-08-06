const { ethers } = require("hardhat");

async function main() {
  console.log("🎯 Minting AED Domains on Amoy Testnet...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Minting with account:", deployer.address);
  
  // Contract addresses from local deployment
  const AED_PROXY_ADDRESS = "0x0165878A594ca255338adfa4d48449f69242Eb8F"; // Local proxy address
  const AED_CORE_ADDRESS = "0x5FC8d32690cc91D4c39d9d3abcBD16989F875707";  // Local core implementation address
  
  // Connect to the AED contract
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation");
  const aed = AEDCoreImplementation.attach(AED_PROXY_ADDRESS);
  
  console.log("Connected to AED at:", AED_PROXY_ADDRESS);
  
  // Helper function to determine registration fee
  function getRegistrationFee(domain) {
    if (domain.includes(".alsania") || domain.includes(".fx") || domain.includes(".echo")) {
      return ethers.parseEther("1.0"); // 1 ETH for premium TLDs
    }
    return ethers.parseEther("0.01"); // 0.01 ETH for other TLDs
  }
  
  // Alsania TLDs (excluding .07 as requested)
  const alsaniaTlds = [
    ".alsania",
    ".aelion", 
    ".sigma",
    ".echo",
    ".mcp",
    ".n3xt",
    ".fx",
    ".chain",
    ".mind",
    ".ai"
  ];
  
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
      const tx = await aed.registerDomain(domain, deployer.address, {
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
      const tx = await aed.registerDomain(domain, deployer.address, {
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
  const allDomains = [...sigmaDomains, ...echoDomains];
  
  // Get all user domains to verify
  try {
    const userDomains = await aed.getUserDomains(deployer.address);
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
  
  console.log("\n🎉 Domain minting completed!");
  console.log(`📊 Total domains minted: ${allDomains.length}`);
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