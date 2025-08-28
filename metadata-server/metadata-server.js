// Simple dynamic metadata server (UD-style)
// Serves /domain/:tokenId.json and /sub/:tokenId.json
// Reads on-chain data (name, type, image/profile overrides) and returns JSON

import express from 'express';

// CONFIG via env
const RPC_URL = process.env.AMOY_RPC || process.env.RPC_URL;
const CONTRACT = process.env.CONTRACT_ADDRESS || "0x8dc59aA8e9AA8B9fd01AF747608B4a28b728F539"; // Working contract

// Load ABI - Add getDomainInfo function to get actual domain data
const ABI = [
   'function tokenURI(uint256) view returns (string)',
   'function ownerOf(uint256) view returns (address)',
   'function name() view returns (string)',
   'function symbol() view returns (string)',
   'function getGlobalDescription() view returns (string)',
   'function getDomainInfo(uint256) view returns (tuple(string name, string tld, string profileURI, string imageURI, uint256 subdomainCount, uint256 mintFee, uint64 expiresAt, bool feeEnabled, bool isSubdomain, address owner))',
   'function getDomainByTokenId(uint256) view returns (string)',
];

// Defaults
const DOMAIN_BG = 'https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png';
const SUB_BG = 'https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png';

// Create Express app
const app = express();

// Global variables
let provider, contract, globalDescription = '';

// Initialize contract connection
async function initializeContract() {
   if (!RPC_URL || !CONTRACT) {
      console.error('Missing RPC_URL/CONTRACT_ADDRESS environment variables');
      return false;
   }

   try {
      // Import ethers dynamically to avoid issues
      const { ethers } = await import('ethers');

      provider = new ethers.JsonRpcProvider(RPC_URL);
      contract = new ethers.Contract(CONTRACT, ABI, provider);

      // Fetch global description once at startup
      try {
         globalDescription = await contract.getGlobalDescription();
         console.log('Global description loaded:', globalDescription || 'None set');
      } catch (error) {
         console.warn('Could not fetch global description (function may not exist):', error.message);
         globalDescription = 'Alsania Enhanced Domain'; // Fallback
      }

      return true;
   } catch (error) {
      console.error('Failed to initialize contract:', error);
      return false;
   }
}

async function buildJson(tokenId, isSub, globalDesc) {
   if (!contract) {
      throw new Error('Contract not initialized');
   }

   try {
      // Get owner - this function works
      const owner = await contract.ownerOf(tokenId);
      console.log(`Building metadata for token ${tokenId}, owner: ${owner}`);

      let domainName = '';
      let domainInfo = null;
      let isSubdomain = false;

      // First try to get domain info from the contract
      try {
         domainInfo = await contract.getDomainInfo(tokenId);
         console.log(`Domain info for ${tokenId}:`, domainInfo);
         
         // Construct full domain name from domain info
         domainName = `${domainInfo.name}.${domainInfo.tld}`;
         isSubdomain = domainInfo.isSubdomain;
         
         console.log(`Constructed domain name: ${domainName}, isSubdomain: ${isSubdomain}`);
      } catch (domainInfoError) {
         console.log(`getDomainInfo failed for ${tokenId}:`, domainInfoError.message);
         
         // Try alternative method - getDomainByTokenId
         try {
            domainName = await contract.getDomainByTokenId(tokenId);
            console.log(`Got domain name from getDomainByTokenId: ${domainName}`);
            
            // Check if it's a subdomain by looking for multiple dots
            isSubdomain = (domainName.split('.').length > 2);
         } catch (domainByTokenError) {
            console.log(`getDomainByTokenId also failed for ${tokenId}:`, domainByTokenError.message);
            
            // Last resort - try parsing from tokenURI
            try {
               const tokenURI = await contract.tokenURI(tokenId);
               if (tokenURI && tokenURI.startsWith('data:application/json;base64,')) {
                  const jsonString = Buffer.from(tokenURI.split(',')[1], 'base64').toString();
                  const metadata = JSON.parse(jsonString);
                  domainName = metadata.name || `domain${tokenId}`;
                  isSubdomain = metadata.attributes?.some(attr =>
                     attr.trait_type === 'Type' && attr.value === 'Subdomain'
                  ) || domainName.includes('.');
                  console.log(`Extracted from tokenURI - name: ${domainName}, isSubdomain: ${isSubdomain}`);
               }
            } catch (tokenURIError) {
               console.log(`TokenURI parsing failed for ${tokenId}:`, tokenURIError.message);
               domainName = `domain${tokenId}`;
               isSubdomain = isSub; // Use the parameter as fallback
            }
         }
      }

      // If we still don't have a proper domain name, use fallback
      if (!domainName || domainName === '') {
         domainName = `domain${tokenId}`;
      }

      // Build the metadata JSON
      const metadata = {
         name: domainName,
         description: globalDesc || "Alsania Enhanced Domain",
         external_url: `https://alsania.io/domain/${domainName}`,
         image: isSubdomain ? SUB_BG : DOMAIN_BG,
         attributes: [
            { trait_type: 'Token ID', value: tokenId.toString() },
            { trait_type: 'Owner', value: owner },
            { trait_type: 'Type', value: isSubdomain ? 'Subdomain' : 'Domain' },
            { trait_type: 'Contract', value: 'Alsania Enhanced Domains' }
         ]
      };

      // Add additional attributes from domain info if available
      if (domainInfo) {
         metadata.attributes.push(
            { trait_type: 'TLD', value: domainInfo.tld },
            { trait_type: 'Subdomain Count', value: domainInfo.subdomainCount.toString() }
         );
         
         // Add feature count if available
         if (domainInfo.subdomainCount > 0) {
            metadata.attributes.push({ trait_type: 'Has Subdomains', value: 'true' });
         }
      }

      console.log(`Final metadata for ${tokenId}:`, metadata);
      return metadata;

   } catch (error) {
      console.error(`Error building metadata for ${tokenId}:`, error);
      // If everything fails, return minimal metadata
      return {
         name: `Domain #${tokenId}`,
         description: globalDesc || "Alsania Enhanced Domain",
         external_url: `https://alsania.io/token/${tokenId}`,
         image: isSub ? SUB_BG : DOMAIN_BG,
         attributes: [
            { trait_type: 'Token ID', value: tokenId.toString() },
            { trait_type: 'Type', value: isSub ? 'Subdomain' : 'Domain' },
            { trait_type: 'Contract', value: 'Alsania Enhanced Domains' }
         ]
      };
   }
}

// Routes
app.get('/domain/:tokenId.json', async (req, res) => {
   try {
      if (!contract) {
         const initialized = await initializeContract();
         if (!initialized) {
            return res.status(500).json({ error: 'Contract not initialized', details: 'Check RPC_URL and CONTRACT_ADDRESS environment variables' });
         }
      }

      const tokenId = BigInt(req.params.tokenId);
      const json = await buildJson(tokenId, false, globalDescription);
      res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(json));
   } catch (e) {
      console.error('Domain metadata error:', e);
      res.status(500).json({ error: 'failed', details: e.message });
   }
});

app.get('/sub/:tokenId.json', async (req, res) => {
   try {
      if (!contract) {
         const initialized = await initializeContract();
         if (!initialized) {
            return res.status(500).json({ error: 'Contract not initialized', details: 'Check RPC_URL and CONTRACT_ADDRESS environment variables' });
         }
      }

      const tokenId = BigInt(req.params.tokenId);
      const json = await buildJson(tokenId, true, globalDescription);
      res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(json));
   } catch (e) {
      console.error('Subdomain metadata error:', e);
      res.status(500).json({ error: 'failed', details: e.message });
   }
});

app.get('/', (req, res) => {
   res.send('AED Metadata Server OK');
});

// Debug endpoint to check environment variables
app.get('/debug', (req, res) => {
   const debug = {
      timestamp: new Date().toISOString(),
      environment: {
         RPC_URL_SET: !!process.env.AMOY_RPC,
         CONTRACT_ADDRESS_SET: !!process.env.CONTRACT_ADDRESS,
         RPC_URL_VALUE: process.env.AMOY_RPC ? `${process.env.AMOY_RPC.substring(0, 20)}...` : 'NOT SET',
         CONTRACT_VALUE: process.env.CONTRACT_ADDRESS || 'NOT SET'
      },
      contract: {
         initialized: !!contract,
         globalDescription: globalDescription || 'None loaded'
      }
   };
   res.json(debug);
});

// Test contract connectivity
app.get('/test-contract', async (req, res) => {
   try {
      // Import ethers dynamically
      const { ethers } = await import('ethers');

      const provider = new ethers.JsonRpcProvider(process.env.AMOY_RPC);
      const testContract = new ethers.Contract(process.env.CONTRACT_ADDRESS, ABI, provider);

      // Try to get basic contract info
      const tests = {
         contractAddress: process.env.CONTRACT_ADDRESS,
         rpcUrl: process.env.AMOY_RPC ? `${process.env.AMOY_RPC.substring(0, 30)}...` : 'NOT SET'
      };

      // Test different token IDs
      const tokenTests = [];
      for (let i = 1; i <= 15; i++) {
         try {
            // First try to get owner to see if token exists
            const owner = await testContract.ownerOf(i);
            
            // Try to get domain info
            let domainData = { exists: true, tokenId: i, owner };
            
            try {
               const info = await testContract.getDomainInfo(i);
               const domain = `${info.name}.${info.tld}`;
               domainData = {
                  ...domainData,
                  domain,
                  name: info.name,
                  tld: info.tld,
                  isSubdomain: info.isSubdomain,
                  method: 'getDomainInfo'
               };
            } catch (domainInfoError) {
               // Try alternative method
               try {
                  const domain = await testContract.getDomainByTokenId(i);
                  domainData = {
                     ...domainData,
                     domain,
                     method: 'getDomainByTokenId'
                  };
               } catch (domainByTokenError) {
                  domainData = {
                     ...domainData,
                     error: `Both methods failed: ${domainInfoError.message} | ${domainByTokenError.message}`,
                     method: 'none'
                  };
               }
            }
            
            tokenTests.push(domainData);
         } catch (error) {
            tokenTests.push({
               tokenId: i,
               error: error.message,
               exists: false
            });
         }
      }

      tests.tokens = tokenTests;

      // Test global description
      try {
         const globalDesc = await testContract.getGlobalDescription();
         tests.globalDescription = globalDesc;
      } catch (error) {
         tests.globalDescriptionError = error.message;
      }

      res.json(tests);
   } catch (error) {
      res.status(500).json({
         error: 'Contract test failed',
         details: error.message,
         contractAddress: process.env.CONTRACT_ADDRESS,
         rpcUrl: process.env.AMOY_RPC ? 'Set' : 'NOT SET'
      });
   }
});

// Export for Vercel
export default app;

// For local development
if (import.meta.url === `file://${process.argv[1]}`) {
   const PORT = process.env.PORT || 3000;
   app.listen(PORT, async () => {
      console.log(`Metadata server listening on ${PORT}`);
      console.log('Contract:', CONTRACT);
      await initializeContract();
   });
}
