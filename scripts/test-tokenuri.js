const { ethers } = require("hardhat");

async function main() {
    console.log("🔍 Testing TokenURI Functionality...\n");
    
    // Get the deployed contract address
    const addresses = require("../amoy-upgradeable-addresses.json");
    const proxyAddress = addresses.proxy;
    
    console.log("📋 Contract Addresses:");
    console.log(`Proxy: ${proxyAddress}\n`);
    
    // Get signer
    const [signer] = await ethers.getSigners();
    console.log(`🔑 Testing with signer: ${signer.address}\n`);
    
    // Get contract instance - use AEDSimpleUpgradeable since that's what we deployed
    const AEDSimpleUpgradeable = await ethers.getContractFactory("AEDSimpleUpgradeable");
    const contract = AEDSimpleUpgradeable.attach(proxyAddress);
    
    try {
        // Test basic contract info
        console.log("📊 Basic Contract Info:");
        const name = await contract.name();
        const symbol = await contract.symbol();
        const nextTokenId = await contract.nextTokenId();
        
        console.log(`Name: ${name}`);
        console.log(`Symbol: ${symbol}`);
        console.log(`Next Token ID: ${nextTokenId}\n`);
        
        // Test user domains
        console.log("🏠 User Domains:");
        const userDomains = await contract.getUserDomains(signer.address);
        console.log(`User has ${userDomains.length} domains:\n`);
        
        for (let i = 0; i < userDomains.length; i++) {
            const domain = userDomains[i];
            console.log(`  ${i + 1}. ${domain}`);
            
            // Check if domain is registered
            const isRegistered = await contract.isRegistered(domain);
            console.log(`     Registered: ${isRegistered}`);
            
            // Get domain info if registered
            if (isRegistered) {
                try {
                    const domainInfo = await contract.getDomainInfo(i + 1); // Assuming tokenId = index + 1
                    console.log(`     Owner: ${domainInfo.owner}`);
                    console.log(`     TLD: ${domainInfo.tld}`);
                    console.log(`     Expires: ${new Date(domainInfo.expiresAt * 1000).toISOString()}`);
                } catch (error) {
                    console.log(`     Error getting domain info: ${error.message}`);
                }
            }
        }
        
        // Test tokenURI for first domain
        if (userDomains.length > 0) {
            console.log("\n🖼️  Testing TokenURI for first domain:");
            try {
                const tokenURI = await contract.tokenURI(1);
                console.log(`TokenURI: ${tokenURI.substring(0, 100)}...`);
                
                // Decode base64 JSON
                const jsonData = tokenURI.replace("data:application/json;base64,", "");
                const decoded = Buffer.from(jsonData, 'base64').toString();
                const metadata = JSON.parse(decoded);
                
                console.log("\n📄 Decoded Metadata:");
                console.log(`Name: ${metadata.name}`);
                console.log(`Description: ${metadata.description}`);
                console.log(`Image: ${metadata.image.substring(0, 50)}...`);
                console.log(`Attributes:`, metadata.attributes);
                
                // Test if image is accessible
                console.log("\n🖼️  Image URL (first 100 chars):");
                console.log(metadata.image.substring(0, 100));
                
            } catch (error) {
                console.log(`❌ TokenURI Error: ${error.message}`);
            }
        }
        
        // Test total revenue
        console.log("\n💰 Revenue Info:");
        const totalRevenue = await contract.totalRevenue();
        console.log(`Total Revenue: ${ethers.formatEther(totalRevenue)} ETH`);
        
    } catch (error) {
        console.error("❌ Test failed:", error.message);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 