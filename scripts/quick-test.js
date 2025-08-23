const { ethers } = require("hardhat");

async function main() {
    console.log("🔍 Quick AED Contract Test\n");
    
    // Contract address - use local deployment
    const contractAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
    
    // Get signer
    const [signer] = await ethers.getSigners();
    console.log(`Testing with: ${signer.address}\n`);
    
    // Get contract
    const AEDSimpleUpgradeable = await ethers.getContractFactory("AEDSimpleUpgradeable");
    const contract = AEDSimpleUpgradeable.attach(contractAddress);
    
    try {
        // Test basic info
        console.log("📊 Basic Contract Info:");
        const name = await contract.name();
        const symbol = await contract.symbol();
        const nextTokenId = await contract.nextTokenId();
        
        console.log(`Name: ${name}`);
        console.log(`Symbol: ${symbol}`);
        console.log(`Next Token ID: ${nextTokenId}\n`);
        
        // Test user domains
        console.log("🏠 Your Domains:");
        const userDomains = await contract.getUserDomains(signer.address);
        console.log(`You have ${userDomains.length} domains:\n`);
        
        for (let i = 0; i < userDomains.length; i++) {
            const domain = userDomains[i];
            console.log(`${i + 1}. ${domain}`);
            
            // Test tokenURI for each domain
            try {
                const tokenURI = await contract.tokenURI(i + 1);
                const jsonData = tokenURI.replace("data:application/json;base64,", "");
                const decoded = Buffer.from(jsonData, 'base64').toString();
                const metadata = JSON.parse(decoded);
                
                console.log(`   ✅ Name: ${metadata.name}`);
                console.log(`   ✅ Image: ${metadata.image.substring(0, 50)}...`);
                console.log(`   ✅ Attributes: ${metadata.attributes.length} attributes\n`);
            } catch (error) {
                console.log(`   ❌ TokenURI error: ${error.message}\n`);
            }
        }
        
        // Test revenue
        const totalRevenue = await contract.totalRevenue();
        console.log(`💰 Total Revenue: ${ethers.formatEther(totalRevenue)} ETH\n`);
        
        console.log("✅ All tests completed successfully!");
        
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