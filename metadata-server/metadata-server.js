// Simple dynamic metadata server (UD-style)
// Serves /domain/:tokenId.json and /sub/:tokenId.json
// Reads on-chain data (name, type, image/profile overrides) and returns JSON

import express from 'express';
import { ethers } from 'ethers';
import fs from 'fs';
import path from 'path';

// CONFIG via env
const RPC_URL = process.env.AMOY_RPC || process.env.RPC_URL;
const CONTRACT = process.env.CONTRACT_ADDRESS; // e.g. 0xd0E5EB4C244d0e641ee10EAd309D3F6DC627F63E
const PORT = process.env.PORT || 3000;

// Load ABI (minimal subset)
const ABI = [
  'function getTokenIdByDomain(string domain) view returns (uint256)',
  'function getDomainByTokenId(uint256) view returns (string)',
  'function getDomainInfo(uint256) view returns (tuple(string name,string tld,string profileURI,string imageURI,uint256 subdomainCount,uint256 mintFee,uint64 expiresAt,bool feeEnabled,bool isSubdomain,address owner))',
  'function tokenURI(uint256) view returns (string)',
];

// Defaults
const DOMAIN_BG = 'https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png';
const SUB_BG = 'https://moccasin-obvious-mongoose-68.mypinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png';

async function main() {
  if (!RPC_URL || !CONTRACT) {
    console.error('Missing RPC_URL/CONTRACT_ADDRESS');
    process.exit(1);
  }
  const app = express();
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const contract = new ethers.Contract(CONTRACT, ABI, provider);

  async function buildJson(tokenId, isSub) {
    const domain = await contract.getDomainByTokenId(tokenId);
    const info = await contract.getDomainInfo(tokenId);

    const image = info.imageURI && info.imageURI.length > 0 ? info.imageURI : (isSub ? SUB_BG : DOMAIN_BG);
    const attributes = [
      { trait_type: 'TLD', value: info.tld },
      { trait_type: 'Subdomains', value: Number(info.subdomainCount) },
      { trait_type: 'Type', value: isSub ? 'Subdomain' : 'Domain' },
      { trait_type: 'Features Enabled', value: 1 },
    ];

    const json = {
      name: domain,
      description: `Alsania Enhanced Domain - ${domain}`,
      external_url: `https://alsania.io/domain/${domain}`,
      image,
      profile_url: info.profileURI || '',
      attributes,
    };
    return json;
  }

  app.get('/domain/:tokenId.json', async (req, res) => {
    try {
      const tokenId = BigInt(req.params.tokenId);
      const json = await buildJson(tokenId, false);
      res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(json));
    } catch (e) {
      console.error(e);
      res.status(500).json({ error: 'failed' });
    }
  });

  app.get('/sub/:tokenId.json', async (req, res) => {
    try {
      const tokenId = BigInt(req.params.tokenId);
      const json = await buildJson(tokenId, true);
      res.setHeader('Content-Type', 'application/json');
      res.send(JSON.stringify(json));
    } catch (e) {
      console.error(e);
      res.status(500).json({ error: 'failed' });
    }
  });

  app.get('/', (req, res) => {
    res.send('AED Metadata Server OK');
  });

  app.listen(PORT, () => {
    console.log(`Metadata server listening on ${PORT}`);
    console.log('Contract:', CONTRACT);
  });
}

main().catch(err => { console.error(err); process.exit(1); });
