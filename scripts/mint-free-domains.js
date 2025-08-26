const { ethers, network } = require("hardhat");
require("dotenv").config();

async function main() {
  console.log("🆓 Minting Free AED Domains");
  console.log("Network:", network.name);
  
  // Read deployment address from file
  const deploymentData = require("../amoy-upgradeable-addresses.json");
  const proxyAddress = deploymentData.proxy;
  console.log("📍 Using AED Proxy:", proxyAddress);

  // Get signer
  const [signer] = await ethers.getSigners();
  console.log("👤 Signer:", signer.address);
  console.log("💰 Balance:", ethers.formatEther(await ethers.provider.getBalance(signer.address)), "ETH");

  // Connect to deployed contract
  const aed = await ethers.getContractAt("AEDMinimal", proxyAddress);
  console.log("✅ Connected to AED contract");

  // Free domains to mint
  const freeDomains = [
    { name: "sigmasauer07", tlds: ["aed", "alsa", "07"] },
    { name: "echo", tlds: ["aed", "alsa", "07"] }, 
    { name: "alsania", tlds: ["aed", "alsa", "07"] }
  ];

  console.log("\n🆓 Minting free domains...");

  const results = {
    successful: [],
    failed: []
  };

  for (const domain of freeDomains) {
    console.log(`\n👤 Minting free domains for: ${domain.name}`);
    
    for (const tld of domain.tlds) {
      try {
        const fullDomain = `${domain.name}.${tld}`;
        
        // Check if domain already exists
        const exists = await aed.isRegistered(domain.name, tld);
        if (exists) {
          console.log(`  ⚠️  ${fullDomain} already exists - skipping`);
          continue;
        }

        // For free domains, only pay for subdomain enhancement (2 ETH)
        const subdomainCost = ethers.parseEther("2");
        
        console.log(`  💸 Registering ${fullDomain} with subdomains (${ethers.formatEther(subdomainCost)} ETH)...`);

        const tx = await aed.connect(signer).registerDomain(
          domain.name,
          tld,
          true, // Enable subdomains
          { value: subdomainCost }
        );

        const receipt = await tx.wait();
        const tokenId = await aed.getTokenIdByDomain(fullDomain);
        
        console.log(`  ✅ ${fullDomain} registered - Token ID: ${tokenId}`);
        results.successful.push({
          domain: fullDomain,
          tokenId: tokenId.toString(),
          cost: ethers.formatEther(subdomainCost),
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

  console.log("\n🌿 Testing subdomain creation for free domains...");

  // Test subdomain creation for successfully registered free domains
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
      results.successful.push({
        domain: subdomainName,
        tokenId: subdomainTokenId.toString(),
        cost: ethers.formatEther(subdomainFee),
        txHash: receipt.hash,
        type: "subdomain"
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

  console.log("\n📊 Final Results:");
  console.log(`  ✅ Successfully registered/created: ${results.successful.length} domains`);
  console.log(`  ❌ Failed operations: ${results.failed.length}`);

  if (results.successful.length > 0) {
    console.log("\n🎉 Successfully Registered/Created:");
    results.successful.forEach(result => {
      const type = result.type === "subdomain" ? "Subdomain" : "Domain";
      console.log(`  • ${result.domain} (${type} Token ${result.tokenId}) - ${result.cost} ETH`);
    });
  }

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
  console.log(`  📋 Domain list: ${userDomains.join(", ")}`);

  // Save results
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const resultsFile = `./free-domains-results-${network.name}-${timestamp}.json`;
  const fs = require("fs");
  fs.writeFileSync(resultsFile, JSON.stringify(results, null, 2));
  console.log(`\n📝 Results saved to: ${resultsFile}`);

  console.log("\n✅ Free domain minting completed!");

  return results;
}

if (require.main === module) {
  main().catch((error) => {
    console.error("❌ Free domain minting failed:", error);
    process.exitCode = 1;
  });
}

module.exports = main;
