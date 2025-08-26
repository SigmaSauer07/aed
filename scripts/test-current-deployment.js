const { ethers } = require("hardhat");
const { getLatestAddresses } = require("./utils");

async function main() {
    console.log("🔍 Testing Current AED Deployment on Amoy...\n");

    // Get the deployed contract address using consistent resolution
    const addresses = getLatestAddresses();
    const proxyAddress = addresses.proxy;
    
    console.log("📋 Contract Addresses:");
    console.log(`Proxy: ${proxyAddress}`);
    console.log(`Implementation: ${addresses.implementation}`);
    console.log(`Deployer: ${addresses.deployer}\n`);
    
    // Get signer
    const [signer] = await ethers.getSigners();
    console.log(`🔑 Testing with signer: ${signer.address}\n`);
    
    // Get contract instance
    const AEDCoreImplementation = await ethers.getContractFactory("AEDCoreImplementation");
    const contract = AEDCoreImplementation.attach(proxyAddress);
    
    try {
        // Test basic contract info
        console.log("📊 Basic Contract Info:");
        const name = await contract.name();
        const symbol = await contract.symbol();
        const nextTokenId = await contract.getNextTokenId();
        
        console.log(`Name: ${name}`);
        console.log(`Symbol: ${symbol}`);
        console.log(`Next Token ID: ${nextTokenId}\n`);
        
        // Test user domains
        console.log("🏠 User Domains:");
        const userDomains = await contract.getUserDomains(signer.address);
        console.log(`User has ${userDomains.length} domains:`);
        
        for (let i = 0; i < userDomains.length; i++) {
            const domain = userDomains[i];
            console.log(`  ${i + 1}. ${domain}`);
            
            // Check if domain is registered
            const isRegistered = await contract.isRegistered(domain);
            console.log(`     Registered: ${isRegistered}`);
            
            // Get domain info if registered
            if (isRegistered) {
                try {
                    // Get the actual tokenId from contract instead of assuming index + 1
                    const tokenId = await contract.getTokenIdByDomain(domain);
                    const domainInfo = await contract.getDomainInfo(tokenId);
                    console.log(`     Owner: ${domainInfo.owner}`);
                    console.log(`     TLD: ${domainInfo.tld}`);
                    console.log(`     Expires: ${new Date(Number(domainInfo.expiresAt) * 1000).toISOString()}`);
                } catch (error) {
                    console.log(`     Error getting domain info: ${error.message}`);
                }
            }
        }
        
        // Test tokenURI for first domain
        if (userDomains.length > 0) {
            console.log("\n🖼️  Testing TokenURI for first domain:");
            try {
                // Get the actual tokenId for the first domain
                const firstDomain = userDomains[0];
                const firstTokenId = await contract.getTokenIdByDomain(firstDomain);
                const tokenURI = await contract.tokenURI(firstTokenId);
                console.log(`TokenURI for ${firstDomain} (tokenId: ${firstTokenId}): ${tokenURI.substring(0, 100)}...`);
                
                // Decode base64 JSON
                const jsonData = tokenURI.replace("data:application/json;base64,", "");
                const decoded = Buffer.from(jsonData, 'base64').toString();
                const metadata = JSON.parse(decoded);
                
                console.log("📄 Decoded Metadata:");
                console.log(`Name: ${metadata.name}`);
                console.log(`Description: ${metadata.description}`);
                console.log(`Image: ${metadata.image.substring(0, 50)}...`);
                console.log(`Attributes:`, metadata.attributes);
            } catch (error) {
                console.log(`❌ TokenURI Error: ${error.message}`);
            }
        }
        
        // Test total revenue
        console.log("\n💰 Revenue Info:");
        const totalRevenue = await contract.getTotalRevenue();
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