const { ethers, network } = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("🔍 Checking AED Metadata Directly");
  console.log("Network:", network.name);
  
  // Use latest deployment address
  const proxyAddress = "0x3FACD1fD7D8E63fBF05345939b53EDF427568E5b";
  console.log("📍 Using AED Proxy:", proxyAddress);

  // Get signer
  const [signer] = await ethers.getSigners();
  
  // Connect to deployed contract
  const aed = await ethers.getContractAt("AEDMinimal", proxyAddress);
  console.log("✅ Connected to AED contract");

  // Test with token ID 1 (sigmasauer07.alsania)
  const tokenId = 1;
  
  try {
    console.log(`\n🧪 Testing metadata for token ${tokenId}...`);
    
    // Get domain name
    const domainName = await aed.getDomainByTokenId(tokenId);
    console.log(`📋 Domain: ${domainName}`);
    
    // Get token URI
    const tokenURI = await aed.tokenURI(tokenId);
    console.log(`📄 Token URI length: ${tokenURI.length}`);
    console.log(`🔗 URI prefix: ${tokenURI.substring(0, 100)}...`);
    
    if (tokenURI.startsWith("data:application/json;base64,")) {
      const base64Data = tokenURI.substring("data:application/json;base64,".length);
      console.log(`📦 Base64 data length: ${base64Data.length}`);
      console.log(`🔗 Base64 start: ${base64Data.substring(0, 50)}...`);
      
      try {
        // Try to decode
        const jsonStr = Buffer.from(base64Data, 'base64').toString('utf8');
        console.log(`📝 Decoded JSON length: ${jsonStr.length}`);
        console.log(`📄 JSON content: ${jsonStr}`);
        
        // Try to parse
        const metadata = JSON.parse(jsonStr);
        console.log(`✅ Successfully parsed metadata!`);
        console.log(`📋 Name: "${metadata.name}"`);
        console.log(`📝 Description: "${metadata.description}"`);
        console.log(`🖼️  Image: ${metadata.image ? metadata.image.substring(0, 50) + "..." : "None"}`);
        console.log(`🔗 External URL: ${metadata.external_url}`);
        console.log(`📊 Attributes: ${JSON.stringify(metadata.attributes, null, 2)}`);
        
      } catch (decodeError) {
        console.log(`❌ Failed to decode/parse: ${decodeError.message}`);
        
        // Try to see what the actual content is
        try {
          const rawDecode = Buffer.from(base64Data, 'base64').toString('utf8');
          console.log(`🔍 Raw decoded content (first 200 chars): ${rawDecode.substring(0, 200)}`);
        } catch (rawError) {
          console.log(`❌ Even raw decode failed: ${rawError.message}`);
        }
      }
    } else {
      console.log(`❌ Token URI doesn't start with expected prefix`);
    }
    
  } catch (error) {
    console.log(`❌ Error checking metadata: ${error.message}`);
  }
  
  // Also test with a simple manual metadata call
  try {
    console.log(`\n🛠️  Testing domain info directly...`);
    const domainInfo = await aed.getDomainInfo(tokenId);
    console.log(`📋 Domain Info:`, {
      name: domainInfo.name,
      tld: domainInfo.tld,
      isSubdomain: domainInfo.isSubdomain,
      subdomainCount: domainInfo.subdomainCount.toString(),
      owner: domainInfo.owner
    });
    
  } catch (error) {
    console.log(`❌ Error getting domain info: ${error.message}`);
  }
  
  console.log("\n✅ Metadata check completed!");
}

if (require.main === module) {
  main().catch((error) => {
    console.error("❌ Metadata check failed:", error);
    process.exitCode = 1;
  });
}

module.exports = main;
