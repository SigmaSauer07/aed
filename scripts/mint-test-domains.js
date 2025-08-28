// Mint test domains with sigmasauer07 and echo for each TLD
const { ethers } = require("hardhat");

async function main() {
    console.log("🎯 Minting test domains for sigmasauer07 and echo...");
    
    const [deployer] = await ethers.getSigners();
    console.log("Minting with account:", deployer.address);
    console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "MATIC");

    // Use the current deployed proxy
    const PROXY_ADDRESS = "0xd0E5EB4C244d0e641ee10EAd309D3F6DC627F63E";
    
    console.log("Using proxy at:", PROXY_ADDRESS);
    
    // Connect to the contract
    const AEDImplementation = await ethers.getContractFactory("AEDImplementation");
    const contract = AEDImplementation.attach(PROXY_ADDRESS);
    
    // Test contract connection
    try {
        const name = await contract.name();
        const symbol = await contract.symbol();
        const totalSupply = await contract.totalSupply();
        
        console.log("✅ Contract name:", name);
        console.log("✅ Contract symbol:", symbol);
        console.log("✅ Current total supply:", totalSupply.toString());
        
        // Test ERC721 compliance
        const ERC721_INTERFACE_ID = "0x80ac58cd";
        const ERC721_METADATA_INTERFACE_ID = "0x5b5e139f";
        
        const supportsERC721 = await contract.supportsInterface(ERC721_INTERFACE_ID);
        const supportsMetadata = await contract.supportsInterface(ERC721_METADATA_INTERFACE_ID);
        
        console.log("✅ Supports ERC721:", supportsERC721);
        console.log("✅ Supports ERC721Metadata:", supportsMetadata);
        
    } catch (error) {
        console.error("❌ Contract connection failed:", error.message);
        return;
    }

    // Available TLDs
    const tlds = ['aed', 'alsa', '07', 'alsania', 'fx', 'echo'];
    const testNames = ['sigmasauer07', 'echo'];
    
    let currentSupply = parseInt(await contract.totalSupply());
    let tokenId = currentSupply + 1;
    
    console.log(`\n🚀 Starting minting from token ID: ${tokenId}`);
    
    for (const name of testNames) {
        console.log(`\n👤 Minting domains for: ${name}`);
        
        for (const tld of tlds) {
            try {
                console.log(`  🌐 Minting ${name}.${tld}...`);
                
                // Check if domain already exists
                try {
                    const exists = await contract.isRegistered(name, tld);
                    if (exists) {
                        console.log(`    ⚠️  ${name}.${tld} already exists, skipping...`);
                        continue;
                    }
                } catch (existsError) {
                    // Continue if the function doesn't exist
                }
                
                // Check if TLD is free
                const isFreeTLD = ['aed', 'alsa', '07'].includes(tld);
                const value = isFreeTLD ? 0 : ethers.parseEther("1.0");
                
                console.log(`    💰 Cost: ${isFreeTLD ? "FREE" : "1.0 MATIC"}`);
                
                const tx = await contract.registerDomain(name, tld, false, { 
                    value,
                    gasLimit: 500000 // Set explicit gas limit
                });
                
                console.log(`    ⏳ Transaction sent: ${tx.hash}`);
                await tx.wait();
                
                console.log(`    ✅ ${name}.${tld} minted as token #${tokenId}`);
                
                // Test tokenURI and metadata
                try {
                    const tokenURI = await contract.tokenURI(tokenId);
                    const isDataURI = tokenURI.startsWith('data:application/json;base64,');
                    console.log(`    📄 TokenURI type: ${isDataURI ? 'Base64 JSON' : 'External URL'}`);
                    
                    if (isDataURI) {
                        // Decode and check the JSON
                        const jsonString = Buffer.from(tokenURI.split(',')[1], 'base64').toString();
                        const metadata = JSON.parse(jsonString);
                        console.log(`    📋 Metadata name: ${metadata.name}`);
                        console.log(`    🖼️  Image: ${metadata.image ? 'Available' : 'Missing'}`);
                    }
                    
                    // Test domain info
                    const domainInfo = await contract.getDomainInfo(tokenId);
                    console.log(`    📋 Domain struct: ${domainInfo.name}.${domainInfo.tld}`);
                    console.log(`    👤 Owner: ${domainInfo.owner}`);
                    
                } catch (metaError) {
                    console.log(`    ⚠️  Metadata error: ${metaError.message}`);
                }
                
                tokenId++;
                
                // Small delay to avoid rate limiting
                await new Promise(resolve => setTimeout(resolve, 1000));
                
            } catch (error) {
                console.log(`    ❌ Failed to mint ${name}.${tld}: ${error.message}`);
                if (error.message.includes("revert")) {
                    console.log(`    💡 Reason: ${error.reason || "Transaction reverted"}`);
                }
            }
        }
    }

    // Create some test subdomains
    console.log("\n🏗️  Creating test subdomains...");
    
    try {
        const subdomainNames = ['www', 'api', 'blog', 'app'];
        const newTotalSupply = parseInt(await contract.totalSupply());
        
        // Try to create subdomains for the first few newly minted domains
        for (let parentId = currentSupply + 1; parentId <= Math.min(currentSupply + 4, newTotalSupply); parentId++) {
            try {
                const parentDomain = await contract.getDomainByTokenId(parentId);
                console.log(`  👨‍👩‍👧‍👦 Creating subdomains for ${parentDomain} (token #${parentId})`);
                
                // Only create 1 subdomain per parent to avoid gas issues
                const subName = subdomainNames[0]; // Just create 'www'
                
                try {
                    console.log(`    🌿 Creating ${subName}.${parentDomain}...`);
                    
                    // Calculate subdomain fee
                    const subdomainFee = await contract.calculateSubdomainFee(parentId);
                    console.log(`    💰 Subdomain fee: ${ethers.formatEther(subdomainFee)} MATIC`);
                    
                    const subTx = await contract.mintSubdomain(parentId, subName, { 
                        value: subdomainFee,
                        gasLimit: 400000
                    });
                    
                    console.log(`    ⏳ Subdomain transaction: ${subTx.hash}`);
                    await subTx.wait();
                    
                    console.log(`    ✅ ${subName}.${parentDomain} created as token #${tokenId}`);
                    tokenId++;
                    
                } catch (subError) {
                    console.log(`    ❌ Failed to create ${subName}: ${subError.message}`);
                }
                
            } catch (parentError) {
                console.log(`  ❌ Failed to get parent domain for token #${parentId}: ${parentError.message}`);
            }
        }
        
    } catch (error) {
        console.log("❌ Subdomain creation failed:", error.message);
    }

    // Final summary
    const finalSupply = await contract.totalSupply();
    console.log("\n📊 Minting Summary:");
    console.log("=".repeat(50));
    console.log(`Contract: ${PROXY_ADDRESS}`);
    console.log(`Network: Amoy Testnet`);
    console.log(`Minter: ${deployer.address}`);
    console.log(`Initial Supply: ${currentSupply}`);
    console.log(`Final Supply: ${finalSupply}`);
    console.log(`Domains Minted: ${finalSupply - currentSupply}`);
    console.log("=".repeat(50));
    
    console.log("\n🔄 Next steps:");
    console.log("1. Test domains in MetaMask");
    console.log("2. Check metadata on block explorer");
    console.log("3. Verify frontend integration");
    console.log("4. Test subdomain functionality");
    
    console.log("\n🎉 Test domain minting completed!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });