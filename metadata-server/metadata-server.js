// Simple dynamic metadata server (UD-style)
// Serves /domain/:tokenId.json and /sub/:tokenId.json
// Reads on-chain data (name, type, image/profile overrides) and returns JSON

import express from 'express';
import { ethers } from 'ethers';

// CONFIG via env
const RPC_URL = process.env.AMOY_RPC || process.env.RPC_URL;
const CONTRACT = process.env.CONTRACT_ADDRESS; // e.g. 0xd0E5EB4C244d0e641ee10EAd309D3F6DC627F63E

// Load ABI (minimal subset)
const ABI = [
   'function getTokenIdByDomain(string domain) view returns (uint256)',
   'function getDomainByTokenId(uint256) view returns (string)',
   'function getDomainInfo(uint256) view returns (tuple(string name,string tld,string profileURI,string imageURI,uint256 subdomainCount,uint256 mintFee,uint64 expiresAt,bool feeEnabled,bool isSubdomain,address owner))',
   'function tokenURI(uint256) view returns (string)',
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

   const domain = await contract.getDomainByTokenId(tokenId);
   const info = await contract.getDomainInfo(tokenId);

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
            return res.status(500).json({ error: 'Contract not initialized' });
         }
      }

      const tokenId = BigInt(req.params.tokenId);
      const json = await buildJson(tokenId, false, globalDescription);
      res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(json));
   } catch (e) {
      console.error('Domain metadata error:', e);
      res.status(500).json({ error: 'failed' });
   }
});

app.get('/sub/:tokenId.json', async (req, res) => {
   try {
      if (!contract) {
         const initialized = await initializeContract();
         if (!initialized) {
            return res.status(500).json({ error: 'Contract not initialized' });
         }
      }

      const tokenId = BigInt(req.params.tokenId);
      const json = await buildJson(tokenId, true, globalDescription);
      res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(json));
   } catch (e) {
      console.error('Subdomain metadata error:', e);
      res.status(500).json({ error: 'failed' });
   }
});

app.get('/', (req, res) => {
   res.send('AED Metadata Server OK');
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
