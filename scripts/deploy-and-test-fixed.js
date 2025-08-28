// Deploy fixed AED contracts and mint test domains
const { ethers } = require("hardhat");

async function main() {
    console.log("🚀 Deploying fixed AED contracts with ERC721 compliance...");
    
    const [deployer] = await ethers.getSigners();
    console.log("Deploying with account:", deployer.address);
    console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "MATIC");

    // Deploy the implementation directly (without proxy for now)
    console.log("\n📄 Deploying AEDImplementation...");
    const AEDImplementation = await ethers.getContractFactory("AEDImplementation");
    
    // Deploy the implementation contract
    const implementation = await AEDImplementation.deploy();
    await implementation.waitForDeployment();
    const implementationAddress = await implementation.getAddress();
    
    console.log("✅ Implementation deployed to:", implementationAddress);

    // Deploy the proxy contract
    console.log("\n📄 Deploying AED Proxy...");
    const AED = await ethers.getContractFactory("AED");
    
    // Encode the initialize call
    const initData = AEDImplementation.interface.encodeFunctionData("initialize", [
        "Alsania Enhanced Domains",  // name
        "AED",                       // symbol
        "0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43", // payment wallet
        deployer.address             // admin
    ]);
    
    const proxy = await AED.deploy(implementationAddress, initData);
    await proxy.waitForDeployment();
    const proxyAddress = await proxy.getAddress();
    
    console.log("✅ Proxy deployed to:", proxyAddress);
    console.log("✅ Implementation deployed to:", implementationAddress);

    // Update deployed addresses
    const timestamp = new Date().toISOString();
    const deploymentInfo = `\namoy - ${timestamp}\nProxy: ${proxyAddress}\nImplementation: ${implementationAddress}\nDeployer: ${deployer.address}\nVersion: v3-erc721-fixed\n`;
    
    const fs = require('fs');
    fs.appendFileSync('deployedAddress.txt', deploymentInfo);
    console.log("📝 Updated deployedAddress.txt");

    // Wait a bit for deployment to settle
    console.log("⏳ Waiting for deployment to settle...");
    await new Promise(resolve => setTimeout(resolve, 5000));

    // Connect to the proxy with the implementation interface
    const proxyContract = AEDImplementation.attach(proxyAddress);

    // Test ERC721 compliance
    console.log("\n🔍 Testing ERC721 compliance...");
    
    try {
        const name = await proxyContract.name();
        const symbol = await proxyContract.symbol();
        const totalSupply = await proxyContract.totalSupply();
        const contractURI = await proxyContract.contractURI();
        
        console.log("✅ Contract name:", name);
        console.log("✅ Contract symbol:", symbol);
        console.log("✅ Total supply:", totalSupply.toString());
        console.log("✅ Contract URI available:", contractURI ? "Yes" : "No");
        
        // Test interface support
        const ERC721_INTERFACE_ID = "0x80ac58cd";
        const ERC721_METADATA_INTERFACE_ID = "0x5b5e139f";
        
        const supportsERC721 = await proxyContract.supportsInterface(ERC721_INTERFACE_ID);
        const supportsMetadata = await proxyContract.supportsInterface(ERC721_METADATA_INTERFACE_ID);
        
        console.log("✅ Supports ERC721:", supportsERC721);
        console.log("✅ Supports ERC721Metadata:", supportsMetadata);
        
    } catch (error) {
        console.error("❌ ERC721 compliance test failed:", error.message);
    }

    // Mint test domains
    console.log("\n🎯 Minting test domains...");
    
    // Available TLDs
    const tlds = ['aed', 'alsa', '07', 'alsania', 'fx', 'echo'];
    const testNames = ['sigmasauer07', 'echo'];
    
    let tokenId = 1;
    
    for (const name of testNames) {
        console.log(`\n👤 Minting domains for: ${name}`);
        
        for (const tld of tlds) {
            try {
                console.log(`  🌐 Minting ${name}.${tld}...`);
                
                // Check if TLD is free
                const isFreeTLD = ['aed', 'alsa', '07'].includes(tld);
                const value = isFreeTLD ? 0 : ethers.parseEther("1.0");
                
                const tx = await proxyContract.registerDomain(name, tld, false, { value });
                await tx.wait();
                
                console.log(`    ✅ ${name}.${tld} minted as token #${tokenId}`);
                
                // Test tokenURI
                try {
                    const tokenURI = await proxyContract.tokenURI(tokenId);
                    console.log(`    📄 TokenURI available: ${tokenURI.length > 0 ? 'Yes' : 'No'}`);
                    
                    // Test domain info
                    const domainInfo = await proxyContract.getDomainInfo(tokenId);
                    console.log(`    📋 Domain: ${domainInfo.name}.${domainInfo.tld}`);
                    
                } catch (metaError) {
                    console.log(`    ⚠️  Metadata error: ${metaError.message}`);
                }
                
                tokenId++;
                
            } catch (error) {
                console.log(`    ❌ Failed to mint ${name}.${tld}: ${error.message}`);
            }
        }
    }

    // Create some subdomains
    console.log("\n🏗️  Creating test subdomains...");
    
    try {
        // Create subdomains for the first few domains
        const subdomainNames = ['www', 'api', 'blog', 'app'];
        
        for (let parentId = 1; parentId <= 4; parentId++) {
            try {
                const parentDomain = await proxyContract.getDomainByTokenId(parentId);
                console.log(`  👨‍👩‍👧‍👦 Creating subdomains for ${parentDomain} (token #${parentId})`);
                
                for (const subName of subdomainNames.slice(0, 2)) { // Only create 2 subdomains per parent
                    try {
                        console.log(`    🌿 Creating ${subName}.${parentDomain}...`);
                        
                        const subTx = await proxyContract.mintSubdomain(parentId, subName);
                        await subTx.wait();
                        
                        console.log(`    ✅ ${subName}.${parentDomain} created as token #${tokenId}`);
                        tokenId++;
                        
                    } catch (subError) {
                        console.log(`    ❌ Failed to create ${subName}: ${subError.message}`);
                    }
                }
                
            } catch (parentError) {
                console.log(`  ❌ Failed to get parent domain for token #${parentId}: ${parentError.message}`);
            }
        }
        
    } catch (error) {
        console.log("❌ Subdomain creation failed:", error.message);
    }

    // Final summary
    console.log("\n📊 Deployment Summary:");
    console.log("=".repeat(50));
    console.log(`Proxy Address: ${proxyAddress}`);
    console.log(`Implementation: ${implementationAddress}`);
    console.log(`Network: Amoy Testnet`);
    console.log(`Deployer: ${deployer.address}`);
    console.log(`Total Supply: ${await proxyContract.totalSupply()}`);
    console.log(`Contract Name: ${await proxyContract.name()}`);
    console.log(`Contract Symbol: ${await proxyContract.symbol()}`);
    console.log("=".repeat(50));
    
    // Update metadata server environment
    console.log("\n🔄 Next steps:");
    console.log("1. Update metadata server with new contract address:");
    console.log(`   CONTRACT_ADDRESS=${proxyAddress}`);
    console.log("2. Update frontend applications with new address");
    console.log("3. Test MetaMask integration");
    console.log("4. Verify on block explorer");
    
    console.log("\n🎉 Deployment and testing completed!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });