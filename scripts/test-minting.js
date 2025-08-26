const { ethers, network } = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("🧪 Testing AED Domain Minting");
  console.log("Network:", network.name);
  
  // Read deployment address from file or environment
  let proxyAddress = process.env.AED_PROXY_ADDRESS;
  
  if (!proxyAddress) {
    console.log("📄 Reading proxy address from amoy-upgradeable-addresses.json...");
    try {
      const deploymentData = require("../amoy-upgradeable-addresses.json");
      proxyAddress = deploymentData.proxy;
    } catch (error) {
      throw new Error("🚨 Could not find AED_PROXY_ADDRESS in .env or amoy-upgradeable-addresses.json");
    }
  }

  console.log("📍 Using AED Proxy:", proxyAddress);

  // Get signer
  const [signer] = await ethers.getSigners();
  console.log("👤 Signer:", signer.address);
  console.log("💰 Balance:", ethers.formatEther(await ethers.provider.getBalance(signer.address)), "ETH");

  // Connect to deployed contract
  const aed = await ethers.getContractAt("AEDMinimal", proxyAddress);
  console.log("✅ Connected to AED contract");

  // Test domains to mint
  const testDomains = [
    { name: "sigmasauer07", tlds: ["aed", "alsa", "07", "alsania", "fx", "echo"] },
    { name: "echo", tlds: ["aed", "alsa", "07", "alsania", "fx", "echo"] },
    { name: "alsania", tlds: ["aed", "alsa", "07", "alsania", "fx", "echo"] }
  ];

  console.log("\n🌟 Starting domain registration tests...");

  const results = {
    successful: [],
    failed: [],
    subdomains: []
  };

  for (const domain of testDomains) {
    console.log(`\n👤 Testing domains for: ${domain.name}`);
    
    for (const tld of domain.tlds) {
      try {
        const fullDomain = `${domain.name}.${tld}`;
        
        // Check if domain already exists
        const exists = await aed.isRegistered(domain.name, tld);
        if (exists) {
          console.log(`  ⚠️  ${fullDomain} already exists - skipping`);
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
        results.successful.push({
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
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
  }

  console.log("\n🌿 Testing subdomain creation...");

  // Test subdomain creation for successfully registered domains
  const subdomainTests = [
    { parent: "sigmasauer07.aed", label: "test1" },
    { parent: "sigmasauer07.aed", label: "test2" },
    { parent: "echo.alsania", label: "web" },
    { parent: "alsania.fx", label: "app" }
  ];

  for (const subdomain of subdomainTests) {
    try {
      // Check if parent domain exists and get token ID
      const parentExists = await aed.isRegistered(subdomain.parent.split('.')[0], subdomain.parent.split('.')[1]);
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

    await new Promise(resolve => setTimeout(resolve, 1000));
  }

  console.log("\n📊 Testing Results Summary:");
  console.log(`  ✅ Successfully registered: ${results.successful.length} domains`);
  console.log(`  🌿 Successfully created: ${results.subdomains.length} subdomains`);
  console.log(`  ❌ Failed operations: ${results.failed.length}`);

  if (results.successful.length > 0) {
    console.log("\n🎉 Successfully Registered Domains:");
    results.successful.forEach(result => {
      console.log(`  • ${result.domain} (Token ${result.tokenId}) - ${result.cost} ETH`);
    });
  }

  if (results.subdomains.length > 0) {
    console.log("\n🌿 Successfully Created Subdomains:");
    results.subdomains.forEach(result => {
      console.log(`  • ${result.subdomain} (Token ${result.tokenId}) - ${result.cost} ETH`);
    });
  }

  if (results.failed.length > 0) {
    console.log("\n❌ Failed Operations:");
    results.failed.forEach(result => {
      console.log(`  • ${result.domain}: ${result.error}`);
    });
  }

  // Test reverse resolution
  console.log("\n🔄 Testing reverse resolution...");
  try {
    if (results.successful.length > 0) {
      const firstDomain = results.successful[0].domain;
      console.log(`  Setting reverse record to: ${firstDomain}`);
      const tx = await aed.connect(signer).setReverse(firstDomain);
      await tx.wait();
      
      const reverseRecord = await aed.getReverse(signer.address);
      console.log(`  ✅ Reverse record set: ${reverseRecord}`);
    }
  } catch (error) {
    console.log(`  ❌ Failed to set reverse record:`, error.message);
  }

  // Test metadata
  console.log("\n🖼️  Testing metadata...");
  try {
    if (results.successful.length > 0) {
      const tokenId = results.successful[0].tokenId;
      console.log(`  Setting profile URI for token ${tokenId}...`);
      
      const profileURI = `https://api.alsania.io/profile/${tokenId}`;
      const tx1 = await aed.connect(signer).setProfileURI(tokenId, profileURI);
      await tx1.wait();
      
      const imageURI = `https://api.alsania.io/image/${tokenId}.png`;
      const tx2 = await aed.connect(signer).setImageURI(tokenId, imageURI);
      await tx2.wait();
      
      console.log(`  ✅ Metadata set for token ${tokenId}`);
      
      // Get tokenURI
      const tokenURI = await aed.tokenURI(tokenId);
      console.log(`  📄 Token URI length: ${tokenURI.length} characters`);
    }
  } catch (error) {
    console.log(`  ❌ Failed to set metadata:`, error.message);
  }

  // Final status
  console.log("\n🎯 Final Status:");
  const totalSupply = await aed.balanceOf(signer.address);
  console.log(`  📊 Total domains owned: ${totalSupply}`);
  
  const userDomains = await aed.getUserDomains(signer.address);
  console.log(`  📋 Domain list: ${userDomains.join(", ")}`);

  // Save results
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const resultsFile = `./minting-results-${network.name}-${timestamp}.json`;
  const fs = require("fs");
  fs.writeFileSync(resultsFile, JSON.stringify(results, null, 2));
  console.log(`\n📝 Results saved to: ${resultsFile}`);

  console.log("\n✅ Minting tests completed!");

  return results;
}

if (require.main === module) {
  main().catch((error) => {
    console.error("❌ Minting test failed:", error);
    process.exitCode = 1;
  });
}

module.exports = main;
