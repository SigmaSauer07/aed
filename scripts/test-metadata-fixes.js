const { ethers, network } = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("🧪 Testing AED Metadata & Image Fixes");
  console.log("Network:", network.name);
  
  // Use the latest deployment address
  const proxyAddress = "0x3FACD1fD7D8E63fBF05345939b53EDF427568E5b";

  console.log("📍 Using AED Proxy:", proxyAddress);

  // Get signer
  const [signer] = await ethers.getSigners();
  console.log("👤 Signer:", signer.address);
  console.log("💰 Balance:", ethers.formatEther(await ethers.provider.getBalance(signer.address)), "ETH");

  // Connect to deployed contract
  const aed = await ethers.getContractAt("AEDMinimal", proxyAddress);
  console.log("✅ Connected to AED contract");

  const results = {
    domains: [],
    subdomains: [],
    metadataTests: [],
    failed: []
  };

  console.log("\n🌟 Testing domain registration with metadata...");

  // Test domains to mint (including corrected sigmasauer07)
  const testDomains = [
    { name: "sigmasauer07", tlds: ["aed", "alsania"] },
    { name: "echo", tlds: ["alsa", "fx"] },
    { name: "alsania", tlds: ["07", "echo"] }
  ];

  for (const domain of testDomains) {
    console.log(`\n👤 Testing domains for: ${domain.name}`);
    
    for (const tld of domain.tlds) {
      try {
        const fullDomain = `${domain.name}.${tld}`;
        
        // Check if domain already exists
        const exists = await aed.isRegistered(domain.name, tld);
        if (exists) {
          console.log(`  ⚠️  ${fullDomain} already exists - testing metadata only`);
          
          // Get token ID and test metadata
          const tokenId = await aed.getTokenIdByDomain(fullDomain);
          const tokenURI = await aed.tokenURI(tokenId);
          
          console.log(`  📋 Token ID: ${tokenId}`);
          console.log(`  📄 Metadata URI length: ${tokenURI.length} characters`);
          console.log(`  🔗 Metadata starts with: ${tokenURI.substring(0, 50)}...`);
          
          results.metadataTests.push({
            domain: fullDomain,
            tokenId: tokenId.toString(),
            metadataLength: tokenURI.length,
            hasMetadata: tokenURI.includes("data:application/json;base64"),
            status: "existing"
          });
          
          continue;
        }

        // Calculate cost
        const freeTlds = ["aed", "alsa", "07"];
        const isFreeTld = freeTlds.includes(tld);
        const baseCost = isFreeTld ? 0 : ethers.parseEther("1");
        const subdomainCost = ethers.parseEther("2"); // Enable subdomains
        const totalCost = baseCost + subdomainCost;

        console.log(`  💸 Registering ${fullDomain} with subdomains (${ethers.formatEther(totalCost)} ETH)...`);

        const tx = await aed.connect(signer).registerDomain(
          domain.name,
          tld,
          true, // Enable subdomains
          { value: totalCost }
        );

        const receipt = await tx.wait();
        const tokenId = await aed.getTokenIdByDomain(fullDomain);
        
        console.log(`  ✅ ${fullDomain} registered - Token ID: ${tokenId}`);
        
        // Test metadata immediately
        const tokenURI = await aed.tokenURI(tokenId);
        console.log(`  📄 Metadata URI length: ${tokenURI.length} characters`);
        
        // Decode and analyze metadata
        if (tokenURI.startsWith("data:application/json;base64,")) {
          try {
            const base64Data = tokenURI.substring("data:application/json;base64,".length);
            const jsonStr = Buffer.from(base64Data, 'base64').toString('utf8');
            const metadata = JSON.parse(jsonStr);
            
            console.log(`  📝 Name: "${metadata.name}"`);
            console.log(`  📝 Description: "${metadata.description}"`);
            console.log(`  🖼️  Has image: ${metadata.image ? "✅" : "❌"}`);
            console.log(`  🔗 External URL: ${metadata.external_url}`);
            console.log(`  📊 Attributes count: ${metadata.attributes ? metadata.attributes.length : 0}`);
            
            if (metadata.image && metadata.image.startsWith("data:image/svg+xml;base64,")) {
              console.log(`  🎨 SVG image embedded successfully`);
            }
            
            results.metadataTests.push({
              domain: fullDomain,
              tokenId: tokenId.toString(),
              metadata: metadata,
              hasImage: !!metadata.image,
              hasSVG: metadata.image && metadata.image.startsWith("data:image/svg+xml;base64,"),
              attributesCount: metadata.attributes ? metadata.attributes.length : 0,
              status: "new"
            });
            
          } catch (decodeError) {
            console.log(`  ❌ Failed to decode metadata: ${decodeError.message}`);
          }
        }
        
        results.domains.push({
          domain: fullDomain,
          tokenId: tokenId.toString(),
          cost: ethers.formatEther(totalCost),
          txHash: receipt.hash
        });

      } catch (error) {
        console.log(`  ❌ Failed to register ${domain.name}.${tld}:`, error.message);
        results.failed.push({
          domain: `${domain.name}.${tld}`,
          error: error.message
        });
      }

      // Small delay to avoid overwhelming the network
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
  }

  console.log("\n🌿 Testing subdomain creation with metadata...");

  // Test subdomain creation
  const subdomainTests = [
    { parent: "sigmasauer07.aed", label: "test" },
    { parent: "echo.alsa", label: "web" },
    { parent: "alsania.07", label: "app" }
  ];

  for (const subdomain of subdomainTests) {
    try {
      // Check if parent domain exists and get token ID
      const [name, tld] = subdomain.parent.split('.');
      const parentExists = await aed.isRegistered(name, tld);
      if (!parentExists) {
        console.log(`  ⚠️  Parent domain ${subdomain.parent} not found - skipping subdomain`);
        continue;
      }

      const parentTokenId = await aed.getTokenIdByDomain(subdomain.parent);
      const subdomainFee = await aed.calculateSubdomainFee(parentTokenId);
      
      console.log(`  🌿 Creating subdomain ${subdomain.label}.${subdomain.parent} (${ethers.formatEther(subdomainFee)} ETH)...`);

      const tx = await aed.connect(signer).mintSubdomain(
        parentTokenId,
        subdomain.label,
        { value: subdomainFee }
      );

      const receipt = await tx.wait();
      const subdomainName = `${subdomain.label}.${subdomain.parent}`;
      const subdomainTokenId = await aed.getTokenIdByDomain(subdomainName);
      
      console.log(`  ✅ ${subdomainName} created - Token ID: ${subdomainTokenId}`);
      
      // Test subdomain metadata
      const tokenURI = await aed.tokenURI(subdomainTokenId);
      console.log(`  📄 Subdomain metadata length: ${tokenURI.length} characters`);
      
      // Decode subdomain metadata
      if (tokenURI.startsWith("data:application/json;base64,")) {
        try {
          const base64Data = tokenURI.substring("data:application/json;base64,".length);
          const jsonStr = Buffer.from(base64Data, 'base64').toString('utf8');
          const metadata = JSON.parse(jsonStr);
          
          console.log(`  📝 Subdomain name: "${metadata.name}"`);
          console.log(`  🎨 Has subdomain-style image: ${metadata.image && metadata.image.includes("#2D1B69") ? "✅" : "❌"}`);
          
          const typeAttribute = metadata.attributes?.find(attr => attr.trait_type === "Type");
          console.log(`  🏷️  Type attribute: ${typeAttribute?.value || "Missing"}`);
          
        } catch (decodeError) {
          console.log(`  ❌ Failed to decode subdomain metadata: ${decodeError.message}`);
        }
      }
      
      results.subdomains.push({
        subdomain: subdomainName,
        parent: subdomain.parent,
        tokenId: subdomainTokenId.toString(),
        cost: ethers.formatEther(subdomainFee),
        txHash: receipt.hash
      });

    } catch (error) {
      console.log(`  ❌ Failed to create subdomain ${subdomain.label}.${subdomain.parent}:`, error.message);
      results.failed.push({
        domain: `${subdomain.label}.${subdomain.parent}`,
        error: error.message
      });
    }

    await new Promise(resolve => setTimeout(resolve, 2000));
  }

  console.log("\n🖼️  Testing custom image setting...");

  // Test setting custom images
  if (results.domains.length > 0) {
    const testDomain = results.domains[0];
    const tokenId = testDomain.tokenId;
    
    try {
      console.log(`  🎨 Setting custom image for token ${tokenId}...`);
      
      const customImageURI = "https://api.alsania.io/images/custom-domain.png";
      const setImageTx = await aed.connect(signer).setImageURI(tokenId, customImageURI);
      await setImageTx.wait();
      
      console.log(`  ✅ Custom image set: ${customImageURI}`);
      
      // Get updated metadata
      const updatedTokenURI = await aed.tokenURI(tokenId);
      const base64Data = updatedTokenURI.substring("data:application/json;base64,".length);
      const jsonStr = Buffer.from(base64Data, 'base64').toString('utf8');
      const updatedMetadata = JSON.parse(jsonStr);
      
      console.log(`  🔄 Updated image URI: ${updatedMetadata.image}`);
      console.log(`  ✅ Custom image properly applied: ${updatedMetadata.image === customImageURI ? "✅" : "❌"}`);
      
    } catch (error) {
      console.log(`  ❌ Failed to set custom image: ${error.message}`);
    }
  }

  console.log("\n🔄 Testing reverse resolution...");

  // Test reverse resolution
  if (results.domains.length > 0) {
    try {
      const firstDomain = results.domains[0].domain;
      console.log(`  Setting reverse record to: ${firstDomain}`);
      const tx = await aed.connect(signer).setReverse(firstDomain);
      await tx.wait();
      
      const reverseRecord = await aed.getReverse(signer.address);
      console.log(`  ✅ Reverse record set: ${reverseRecord}`);
      
    } catch (error) {
      console.log(`  ❌ Failed to set reverse record: ${error.message}`);
    }
  }

  console.log("\n📊 METADATA & IMAGE FIXES - TEST RESULTS:");
  console.log(`  ✅ Successfully registered domains: ${results.domains.length}`);
  console.log(`  🌿 Successfully created subdomains: ${results.subdomains.length}`);
  console.log(`  📄 Metadata tests performed: ${results.metadataTests.length}`);
  console.log(`  ❌ Failed operations: ${results.failed.length}`);

  if (results.domains.length > 0) {
    console.log("\n🎉 Successfully Registered Domains:");
    results.domains.forEach(result => {
      console.log(`  • ${result.domain} (Token ${result.tokenId}) - ${result.cost} ETH`);
    });
  }

  if (results.subdomains.length > 0) {
    console.log("\n🌿 Successfully Created Subdomains:");
    results.subdomains.forEach(result => {
      console.log(`  • ${result.subdomain} (Token ${result.tokenId}) - ${result.cost} ETH`);
    });
  }

  console.log("\n🔍 METADATA ANALYSIS:");
  let successfulMetadata = 0;
  let withImages = 0;
  let withSVG = 0;
  
  results.metadataTests.forEach(test => {
    if (test.metadata) {
      successfulMetadata++;
      if (test.hasImage) withImages++;
      if (test.hasSVG) withSVG++;
      console.log(`  📋 ${test.domain}: ${test.attributesCount} attributes, ${test.hasImage ? "✅" : "❌"} image, ${test.hasSVG ? "✅" : "❌"} SVG`);
    }
  });

  console.log(`\n📈 METADATA SUCCESS METRICS:`);
  console.log(`  📄 Successful metadata generation: ${successfulMetadata}/${results.metadataTests.length}`);
  console.log(`  🖼️  Domains with images: ${withImages}/${results.metadataTests.length}`);
  console.log(`  🎨 Domains with SVG images: ${withSVG}/${results.metadataTests.length}`);

  if (results.failed.length > 0) {
    console.log("\n❌ Failed Operations:");
    results.failed.forEach(result => {
      console.log(`  • ${result.domain}: ${result.error}`);
    });
  }

  // Final status
  console.log("\n🎯 Final Status:");
  const totalSupply = await aed.balanceOf(signer.address);
  console.log(`  📊 Total domains owned: ${totalSupply}`);
  
  const userDomains = await aed.getUserDomains(signer.address);
  console.log(`  📋 Domain list: ${userDomains.slice(0, 5).join(", ")}${userDomains.length > 5 ? "..." : ""}`);

  // Save comprehensive results
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const resultsFile = `./metadata-test-results-${network.name}-${timestamp}.json`;
  const fs = require("fs");
  
  const comprehensiveResults = {
    ...results,
    testSummary: {
      totalDomains: results.domains.length,
      totalSubdomains: results.subdomains.length,
      metadataTests: results.metadataTests.length,
      successfulMetadata,
      withImages,
      withSVG,
      failedOperations: results.failed.length
    },
    contractAddress: proxyAddress,
    timestamp: new Date().toISOString()
  };
  
  fs.writeFileSync(resultsFile, JSON.stringify(comprehensiveResults, null, 2));
  console.log(`\n📝 Comprehensive results saved to: ${resultsFile}`);

  console.log("\n✅ METADATA & IMAGE FIXES VERIFICATION COMPLETED!");

  // Return success indicator
  const allMetadataWorking = successfulMetadata === results.metadataTests.length && withImages === results.metadataTests.length;
  if (allMetadataWorking) {
    console.log("🎉 ALL METADATA AND IMAGE FUNCTIONALITY IS WORKING PERFECTLY!");
  } else {
    console.log("⚠️  Some metadata issues detected. Check results above.");
  }

  return {
    success: allMetadataWorking,
    results: comprehensiveResults
  };
}

if (require.main === module) {
  main().catch((error) => {
    console.error("❌ Metadata test failed:", error);
    process.exitCode = 1;
  });
}

module.exports = main;
