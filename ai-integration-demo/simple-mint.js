#!/usr/bin/env node
/**
 * Simple Badge Demo - Uses known token IDs
 */

import { ethers } from 'ethers';
import * as dotenv from 'dotenv';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config();

const RPC_URL = process.env.AMOY_RPC;
const CONTRACT_ADDRESS = process.env.AED_CONTRACT_ADDRESS;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const ABI = JSON.parse(readFileSync(join(__dirname, 'aed-abi.json'), 'utf8'));

const provider = new ethers.JsonRpcProvider(RPC_URL);
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
const contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, wallet);

async function main() {
  console.log('\n' + '='.repeat(70));
  console.log('AED BADGE WORKFLOW - SIMPLIFIED DEMO');
  console.log('='.repeat(70));
  console.log(`Wallet: ${wallet.address}`);
  console.log(`Contract: ${CONTRACT_ADDRESS}`);
  console.log('='.repeat(70) + '\n');

  try {
    // Known token IDs from deployment
    const knownDomains = [
      { name: 'sigmasauer07.alsania', tokenId: 1 },
      { name: 'echo.fx', tokenId: 7 },
    ];

    console.log('📋 STEP 1: Finding owned domain...\n');
    
    let parentDomain = null;
    let parentTokenId = null;

    for (const domain of knownDomains) {
      try {
        const owner = await contract.ownerOf(domain.tokenId);
        console.log(`   ${domain.name} (${domain.tokenId}): ${owner}`);
        
        if (owner.toLowerCase() === wallet.address.toLowerCase()) {
          parentDomain = domain.name;
          parentTokenId = domain.tokenId;
          console.log(`   ✓ YOU OWN THIS ONE!`);
        }
      } catch (e) {
        console.log(`   ${domain.name}: Not found`);
      }
    }

    if (!parentDomain) {
      console.log('\n✗ You don\'t own any test domains');
      console.log(`Your wallet: ${wallet.address}`);
      return;
    }

    console.log(`\n✓ Using: ${parentDomain} (Token ID: ${parentTokenId})\n`);

    // STEP 2: Mint badge
    console.log('🎫 STEP 2: Minting AI badge...\n');
    
    const badgeLabel = 'demo-claude';
    const modelType = 'claude-sonnet-4';
    const fee = await contract.getAISubdomainFee(parentTokenId);
    
    console.log(`   Creating badge: ${badgeLabel}.${parentDomain}`);
    console.log(`   Model: ${modelType}`);
    console.log(`   Fee: ${ethers.formatEther(fee)} MATIC`);
    
    const tx = await contract.createAISubdomain(
      badgeLabel,
      parentDomain,
      modelType,
      { value: fee, gasLimit: 500000 }
    );
    
    console.log(`   TX: ${tx.hash}`);
    const receipt = await tx.wait();
    console.log(`   ✓ Minted! Gas: ${receipt.gasUsed.toString()}\n`);

    // Find the new token ID from events or estimate
    const newTokenId = parentTokenId + 100; // Estimate - would parse from events in production
    
    console.log('🔍 STEP 3: Checking badge...\n');
    
    try {
      const isBadge = await contract.isAISubdomain(newTokenId);
      const modelCheck = await contract.getModelType(newTokenId);
      
      console.log(`✓ Token ${newTokenId} is badge: ${isBadge}`);
      console.log(`✓ Model: ${modelCheck}\n`);
    } catch (e) {
      console.log(`⚠️  Can't query new token yet (expected)`);
      console.log(`   Token ID estimation may be off\n`);
    }

    console.log('='.repeat(70));
    console.log('✅ BADGE MINTED SUCCESSFULLY');
    console.log('='.repeat(70));
    console.log(`\nNext steps:`);
    console.log(`1. Find actual token ID from transaction logs`);
    console.log(`2. Purchase capabilities`);
    console.log(`3. Test AI access with hasAICapability()`);
    console.log('='.repeat(70) + '\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    console.error('\nFull error:', error);
  }
}

main().catch(console.error);
