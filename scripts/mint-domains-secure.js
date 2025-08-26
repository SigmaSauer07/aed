const { ethers } = require("hardhat");
const fs = require('fs');

async function main() {
  console.log("🎯 Minting AED Domains on Amoy Testnet (SECURE VERSION)...");
  console.log("🔧 Features: No hardcoded tokenIds, proper domain tracking, parallel checks");

  // Check if addresses file exists
  if (!fs.existsSync('amoy-addresses-secure.json')) {
    console.error("❌ amoy-addresses-secure.json not found. Please deploy using the secure script first.");
    console.error("   Run: npx hardhat run scripts/deploy-amoy-secure.js --network amoy");
    process.exit(1);
  }

  const addresses = JSON.parse(fs.readFileSync('amoy-addresses-secure.json', 'utf8'));
  console.log("📋 Using deployed addresses from amoy-addresses-secure.json");

  // Get the signer from Hardhat
  const [deployer] = await ethers.getSigners();
  console.log("Minting with account:", deployer.address);

  // Network validation
  const network = await ethers.provider.getNetwork();
  if (network.chainId !== BigInt(80002)) {
    console.error("❌ ERROR: This script can only be run on Amoy testnet (chainId: 80002)");
    console.error(`   Current network: ${network.name} (chainId: ${network.chainId})`);
    process.exit(1);
  }

  // Connect to the AED contract
  const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation");
  const aed = AEDCoreImplementation.attach(addresses.proxy);

  console.log("Connected to AED at:", addresses.proxy);

  // Helper function to determine registration fee
  function getRegistrationFee(domain) {
    if (domain.includes(".alsania") || domain.includes(".fx") || domain.includes(".echo")) {
      return ethers.parseEther("1.0"); // 1 MATIC for paid TLDs
    }
    return ethers.parseEther("0.0"); // 0 MATIC for free TLDs (.aed, .07, .alsa)
  }

  // Reusable function to mint a single domain
  async function mintSingleDomain(domain, tokenIdsArray) {
    console.log(`\n${tokenIdsArray.length + 1}. Minting: ${domain}`);

    try {
      const fee = getRegistrationFee(domain);
      const tx = await aed.registerDomain(domain, deployer.address, {
        value: fee
      });

      console.log(`   Transaction hash: ${tx.hash}`);
      await tx.wait();
      console.log(`   ✅ ${domain} minted successfully!`);

      // Get the actual tokenId from the contract
      let tokenId;
      try {
        tokenId = await aed.getTokenIdByDomain(domain);
        if (tokenId === undefined || tokenId === null) {
          throw new Error(`TokenId for ${domain} is undefined`);
        }
        tokenIdsArray.push(tokenId);
        console.log(`   🏷️  Token ID: ${tokenId}`);

        // Test tokenURI immediately after minting
        try {
          const tokenURI = await aed.tokenURI(tokenId);
          console.log(`   🖼️  Token URI generated: ${tokenURI.substring(0, 100)}...`);
        } catch (error) {
          console.log(`   ⚠️  Token URI error: ${error.message}`);
        }
      } catch (error) {
        console.error(`   ❌ Failed to get tokenId for ${domain}:`, error.message);
        tokenIdsArray.push(null); // Push null to maintain array alignment
      }

    } catch (error) {
      console.error(`   ❌ Failed to mint ${domain}:`, error.message);
      tokenIdsArray.push(null); // Push null for failed mints
    }
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

  console.log("\n📝 Minting Sigma domains (PROPER ALSANIA TLDS):");
  const sigmaTokenIds = [];
  for (const domain of sigmaDomains) {
    await mintSingleDomain(domain, sigmaTokenIds);
  }

  console.log("\n📝 Minting Echo domains (PROPER ALSANIA TLDS):");
  const echoTokenIds = [];
  for (const domain of echoDomains) {
    await mintSingleDomain(domain, echoTokenIds);
  }

  // Parallel availability checks for better performance
  console.log("\n🔍 Running parallel availability checks...");

  const allDomains = [...sigmaDomains, ...echoDomains];
  const allTokenIds = [...sigmaTokenIds, ...echoTokenIds];

  // Create promises for parallel execution
  const checkPromises = allDomains.map(async (domain, index) => {
    try {
      const isRegistered = await aed.isRegistered(domain);
      const tokenId = allTokenIds[index];

      if (tokenId !== undefined && tokenId !== null) {
        try {
          const owner = await aed.ownerOf(tokenId);
          const tokenURI = await aed.tokenURI(tokenId);
          return {
            domain,
            tokenId: tokenId.toString(),
            registered: isRegistered,
            owner,
            tokenURI: tokenURI.substring(0, 50) + "..."
          };
        } catch (error) {
          return {
            domain,
            tokenId: tokenId.toString(),
            registered: isRegistered,
            owner: "ERROR",
            tokenURI: error.message
          };
        }
      } else {
        return {
          domain,
          tokenId: "UNDEFINED",
          registered: isRegistered,
          owner: "N/A",
          tokenURI: "N/A"
        };
      }
    } catch (error) {
      return {
        domain,
        tokenId: "ERROR",
        registered: false,
        owner: "ERROR",
        tokenURI: error.message
      };
    }
  });

  // Execute all checks in parallel
  const results = await Promise.all(checkPromises);

  console.log("\n📊 Parallel check results:");
  results.forEach(result => {
    console.log(`   ${result.domain}: Registered=${result.registered}, TokenID=${result.tokenId}, Owner=${result.owner}`);
  });

  // Get final user domains to verify
  try {
    const userDomains = await aed.getUserDomains(deployer.address);
    console.log(`\n📋 Final user domains: ${userDomains.join(', ')}`);

    const totalMinted = userDomains.length;
    const successfulSigmaMints = sigmaTokenIds.filter(id => id !== null).length;
    const successfulEchoMints = echoTokenIds.filter(id => id !== null).length;
    const totalSuccessfulMints = successfulSigmaMints + successfulEchoMints;

    // Calculate paid domains based on successful mints - match domains with successful tokenIds
    const paidSigmaDomains = sigmaDomains.filter((domain, index) => sigmaTokenIds[index] !== null && (domain.includes(".alsania") || domain.includes(".fx") || domain.includes(".echo"))).length;
    const paidEchoDomains = echoDomains.filter((domain, index) => echoTokenIds[index] !== null && (domain.includes(".alsania") || domain.includes(".fx") || domain.includes(".echo"))).length;
    const totalPaidDomains = paidSigmaDomains + paidEchoDomains;

    console.log(`\n🎉 Domain minting completed!`);
    console.log(`📊 Total domains in arrays: ${sigmaDomains.length + echoDomains.length}`);
    console.log(`✅ Successful mints: ${totalSuccessfulMints}`);
    console.log(`❌ Failed mints: ${(sigmaDomains.length + echoDomains.length) - totalSuccessfulMints}`);
    console.log(`💰 Paid domains minted: ${totalPaidDomains} (cost: ${totalPaidDomains} MATIC)`);
    console.log(`🆓 Free domains minted: ${totalSuccessfulMints - totalPaidDomains} (cost: 0 MATIC)`);
    console.log(`💵 Total spent: ${totalPaidDomains} MATIC`);

  } catch (error) {
    console.log(`   Error getting user domains: ${error.message}`);
  }

  const allDomainsList = [...sigmaDomains, ...echoDomains];
  console.log("\n🔧 SECURE MINTING FEATURES IMPLEMENTED:");
  console.log("✅ No hardcoded tokenId assumptions");
  console.log("✅ Proper tokenId retrieval from contract");
  console.log("✅ Parallel availability checks for performance");
  console.log("✅ Comprehensive error handling");
  console.log("✅ Network validation");
  console.log("✅ Proper domain tracking");

  // Save mint results
  const mintResults = {
    sigmaDomains,
    echoDomains,
    sigmaTokenIds: sigmaTokenIds.map(id => id !== null ? id.toString() : "FAILED"),
    echoTokenIds: echoTokenIds.map(id => id !== null ? id.toString() : "FAILED"),
    totalAttempted: allDomainsList.length,
    totalSuccessful: totalSuccessfulMints,
    totalPaidDomains: totalPaidDomains,
    mintedAt: new Date().toISOString()
  };

  console.log("\n💾 Saving mint results to mint-results-secure.json...");
  fs.writeFileSync('mint-results-secure.json', JSON.stringify(mintResults, null, 2));
}

main()
  .then(() => {
    console.log("\n✅ Secure domain minting script completed!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ SECURE DOMAIN MINTING FAILED:", error.message);
    console.error("Full error:", error);
    process.exit(1);
  });