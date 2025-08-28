// Simple dynamic metadata server (UD-style)
// Serves /domain/:tokenId.json and /sub/:tokenId.json
// Reads on-chain data (name, type, image/profile overrides) and returns JSON

import express from 'express';

// CONFIG via env
const RPC_URL = process.env.AMOY_RPC || process.env.RPC_URL;
const CONTRACT = process.env.CONTRACT_ADDRESS; // e.g. 0xd0E5EB4C244d0e641ee10EAd309D3F6DC627F63E

// Load ABI (minimal subset) - Updated to match actual contract
const ABI = [
   'function getTokenIdByDomain(string domain) view returns (uint256)',
   'function getDomainInfo(uint256) view returns (tuple(string name,string tld,string profileURI,string imageURI,uint256 subdomainCount,uint256 mintFee,uint64 expiresAt,bool feeEnabled,bool isSubdomain,address owner))',
   'function tokenURI(uint256) view returns (string)',
   'function ownerOf(uint256) view returns (address)',
   'function balanceOf(address) view returns (uint256)',
   'function name() view returns (string)',
   'function symbol() view returns (string)',
   'function supportsInterface(bytes4) view returns (bool)',
   'function getNextTokenId() view returns (uint256)',
   'function isRegistered(string) view returns (bool)',
   'function getUserDomains(address) view returns (string[])',
   'function getTotalRevenue() view returns (uint256)',
   'function registerDomain(string,address) payable',
   'function getGlobalDescription() view returns (string)',
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
         console.warn('Could not fetch global description:', error.message);
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

   // Get domain info from contract
   const info = await contract.getDomainInfo(tokenId);

   // Reconstruct full domain name from name + tld
   const domain = `${info.name}.${info.tld}`;

   const image = info.imageURI && info.imageURI.length > 0 ? info.imageURI : (isSub ? SUB_BG : DOMAIN_BG);
   const attributes = [
      { trait_type: 'TLD', value: info.tld },
      { trait_type: 'Subdomains', value: Number(info.subdomainCount) },
      { trait_type: 'Type', value: isSub ? 'Subdomain' : 'Domain' },
      { trait_type: 'Features Enabled', value: 1 },
   ];

   // Build description with global description if set
   const baseDescription = `Alsania Enhanced Domain - ${domain}`;
   const description = globalDesc && globalDesc.length > 0
      ? `${globalDesc}\n\n${baseDescription}`
      : baseDescription;

   const json = {
      name: domain,
      description,
      external_url: `https://alsania.io/domain/${domain}`,
      image,
      profile_url: info.profileURI || '',
      attributes,
   };
   return json;
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
      for (let i = 1; i <= 5; i++) {
         try {
            const domain = await testContract.getDomainByTokenId(i);
            tokenTests.push({ tokenId: i, domain, exists: true });
         } catch (error) {
            tokenTests.push({ tokenId: i, error: error.message, exists: false });
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
