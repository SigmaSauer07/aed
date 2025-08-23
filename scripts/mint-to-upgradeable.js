const { ethers } = require("hardhat");
const fs = require("fs");

async function main() {
  console.log("🚀 Minting domains to UPGRADEABLE AED...");
  console.log("🔧 Using the upgradeable version with proper tokenURI and images");
  
  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Minting with account:", deployer.address);
  
  // Load addresses
  const addresses = JSON.parse(fs.readFileSync("amoy-upgradeable-addresses.json", "utf8"));
  const proxyAddress = addresses.proxy;
  
  console.log("Using AED proxy at:", proxyAddress);
  
  // Connect to the contract
  const AEDSimpleUpgradeable = await ethers.getContractFactory("AEDSimpleUpgradeable");
  const aed = AEDSimpleUpgradeable.attach(proxyAddress);
  
  // Helper function to determine registration fee
  function getRegistrationFee(domain) {
    if (domain.includes(".alsania") || domain.includes(".fx") || domain.includes(".echo")) {
      return ethers.parseEther("1.0"); // 1 ETH for paid TLDs
    }
    return ethers.parseEther("0.0"); // 0 ETH for free TLDs (.aed, .07, .alsa)
  }
  
  // Domain lists - CORRECT ALSANIA TLDS (free and paid)
  const sigmaDomains = [
    "sigmasauer07.alsania",  // paid
    "sigmasauer07.fx",       // paid
    "sigmasauer07.echo",     // paid
    "sigma.aed",             // free
    "sigma.alsa"             // free
  ];
  
  const echoDomains = [
    "echo.alsania",          // paid
    "echo.fx",               // paid
    "echo.echo",             // paid
    "echo.07",               // free
    "echo.aed"               // free
  ];
  
  console.log("\n🔍 Minting Sigma's domains to upgradeable contract...");
  for (let i = 0; i < sigmaDomains.length; i++) {
    const domain = sigmaDomains[i];
    const fee = getRegistrationFee(domain);
    
    console.log(`\n📝 Minting ${domain} (fee: ${ethers.formatEther(fee)} ETH)...`);
    
    try {
      const tx = await aed.registerDomain(domain, deployer.address, {
        value: fee
      });
      await tx.wait();
      console.log(`   ✅ ${domain} minted successfully!`);
      
      // Test tokenURI after minting
      const tokenId = i + 1;
      try {
        const tokenURI = await aed.tokenURI(tokenId);
        console.log(`   🖼️  Token URI generated: ${tokenURI.substring(0, 100)}...`);
      } catch (error) {
        console.log(`   ⚠️  Token URI error: ${error.message}`);
      }
      
    } catch (error) {
      console.log(`   ❌ Failed to mint ${domain}: ${error.message}`);
    }
  }
  
  console.log("\n🔍 Minting Echo's domains to upgradeable contract...");
  for (let i = 0; i < echoDomains.length; i++) {
    const domain = echoDomains[i];
    const fee = getRegistrationFee(domain);
    
    console.log(`\n📝 Minting ${domain} (fee: ${ethers.formatEther(fee)} ETH)...`);
    
    try {
      const tx = await aed.registerDomain(domain, deployer.address, {
        value: fee
      });
      await tx.wait();
      console.log(`   ✅ ${domain} minted successfully!`);
      
      // Test tokenURI after minting
      const tokenId = i + 6; // Start from token 6 for echo domains
      try {
        const tokenURI = await aed.tokenURI(tokenId);
        console.log(`   🖼️  Token URI generated: ${tokenURI.substring(0, 100)}...`);
      } catch (error) {
        console.log(`   ⚠️  Token URI error: ${error.message}`);
      }
      
    } catch (error) {
      console.log(`   ❌ Failed to mint ${domain}: ${error.message}`);
    }
  }
  
  // Verify all domains
  console.log("\n🔍 Verifying all minted domains...");
  try {
    const userDomains = await aed.getUserDomains(deployer.address);
    console.log("✅ User domains:", userDomains);
    
    console.log("\n🔍 Testing tokenURI for all tokens...");
    for (let i = 1; i <= 10; i++) {
      try {
        const tokenURI = await aed.tokenURI(i);
        const domain = await aed.tokenIdToDomain(i);
        console.log(`   Token ${i} (${domain}): ${tokenURI.substring(0, 80)}...`);
      } catch (error) {
        console.log(`   Token ${i}: Error - ${error.message}`);
      }
    }
    
  } catch (error) {
    console.log("❌ Verification failed:", error.message);
  }
  
  console.log("\n🎉 Domain minting to upgradeable contract completed!");
  console.log("✅ All domains should have proper tokenURI with SVG images");
  console.log("✅ Domain names should be visible in metadata");
  console.log("✅ Images should be generated dynamically");
  console.log("✅ Contract is upgradeable for future enhancements");
}

main()
  .then(() => {
    console.log("\n🎉 Domain minting to upgradeable contract completed successfully!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Domain minting to upgradeable contract failed:", error);
    process.exit(1);
  }); 