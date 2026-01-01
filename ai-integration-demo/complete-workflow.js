#!/usr/bin/env node
/**
 * Complete Badge Workflow Demo
 * 1. Mint a badge
 * 2. Purchase capability
 * 3. AI verifies and grants access
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
  console.log('AED BADGE COMPLETE WORKFLOW DEMONSTRATION');
  console.log('='.repeat(70));
  console.log(`Wallet: ${wallet.address}`);
  console.log(`Contract: ${CONTRACT_ADDRESS}`);
  console.log('='.repeat(70) + '\n');

  try {
    // Step 1: Check existing domains
    console.log('📋 STEP 1: Checking existing domains...\n');
    
    const testDomains = [
      'sigmasauer07.alsania',  
      'echo.fx',
      'echo.ai'
    ];

    let parentDomain = null;
    let parentTokenId = null;

    for (const domain of testDomains) {
      try {
        const tokenId = await contract.getTokenIdByDomain(domain);
        const owner = await contract.ownerOf(tokenId);
        
        if (owner.toLowerCase() === wallet.address.toLowerCase()) {
          parentDomain = domain;
          parentTokenId = tokenId;
          console.log(`✓ Found owned domain: ${domain} (Token ID: ${tokenId})`);
          break;
        }
      } catch (e) {
        // Domain doesn't exist or we don't own it
      }
    }

    if (!parentDomain) {
      console.log('✗ No owned domains found. Please mint a domain first.');
      return;
    }

    console.log(`\n✓ Using parent domain: ${parentDomain}`);
    console.log(`✓ Parent token ID: ${parentTokenId}\n`);

    // Step 2: Mint badge
    console.log('🎫 STEP 2: Minting AI badge...\n');
    
    const badgeLabel = 'claude-demo';
    const badgeDomain = `${badgeLabel}.${parentDomain}`;
    const modelType = 'claude-sonnet-4';

    // Check if badge already exists
    let badgeExists = false;
    let badgeTokenId;
    
    try {
      badgeTokenId = await contract.getTokenIdByDomain(badgeDomain);
      badgeExists = true;
      console.log(`✓ Badge already exists: ${badgeDomain} (Token ID: ${badgeTokenId})`);
    } catch (e) {
      // Badge doesn't exist, we'll mint it
    }

    if (!badgeExists) {
      const fee = await contract.getAISubdomainFee(parentTokenId);
      console.log(`   Badge mint fee: ${ethers.formatEther(fee)} MATIC`);
      
      console.log(`   Minting badge: ${badgeDomain}`);
      console.log(`   Model type: ${modelType}`);
      console.log(`   Sending transaction...`);
      
      const tx = await contract.createAISubdomain(
        badgeLabel,
        parentDomain,
        modelType,
        { value: fee }
      );
      
      console.log(`   TX hash: ${tx.hash}`);
      console.log(`   Waiting for confirmation...`);
      
      const receipt = await tx.wait();
      console.log(`   ✓ Badge minted! Gas used: ${receipt.gasUsed.toString()}`);
      
      // Get the new badge token ID
      badgeTokenId = await contract.getTokenIdByDomain(badgeDomain);
      console.log(`   ✓ Badge Token ID: ${badgeTokenId}\n`);
    }

    // Step 3: Verify badge
    console.log('🔍 STEP 3: Verifying badge properties...\n');
    
    const isBadge = await contract.isAISubdomain(badgeTokenId);
    const modelTypeCheck = await contract.getModelType(badgeTokenId);
    const owner = await contract.ownerOf(badgeTokenId);
    
    console.log(`✓ Is AI badge: ${isBadge}`);
    console.log(`✓ Model type: ${modelTypeCheck}`);
    console.log(`✓ Owner: ${owner}\n`);

    // Step 4: Check capabilities
    console.log('🔐 STEP 4: Checking capabilities...\n');
    
    const capabilities = ['ai_communication', 'ai_vision', 'ai_memory', 'ai_reasoning'];
    const activeCapabilities = await contract.getActiveCapabilities(badgeTokenId);
    
    console.log(`Active capabilities: [${activeCapabilities.join(', ')}]`);
    
    if (activeCapabilities.length === 0) {
      console.log(`\n💰 No capabilities yet. Let's purchase one!\n`);
      
      // Purchase communication capability
      const capabilityType = 'ai_communication';
      const capFee = await contract.getCapabilityFee(badgeTokenId);
      
      console.log(`   Purchasing: ${capabilityType}`);
      console.log(`   Fee: ${ethers.formatEther(capFee)} MATIC`);
      console.log(`   Sending transaction...`);
      
      const tx = await contract.purchaseAICapability(
        badgeTokenId,
        capabilityType,
        { value: capFee }
      );
      
      console.log(`   TX hash: ${tx.hash}`);
      console.log(`   Waiting for confirmation...`);
      
      const receipt = await tx.wait();
      console.log(`   ✓ Capability purchased! Gas used: ${receipt.gasUsed.toString()}\n`);
      
      // Check again
      const updatedCaps = await contract.getActiveCapabilities(badgeTokenId);
      console.log(`✓ Updated capabilities: [${updatedCaps.join(', ')}]\n`);
    }

    // Step 5: AI Access Check
    console.log('🤖 STEP 5: Simulating AI access check...\n');
    
    const requiredCap = 'ai_communication';
    const hasCap = await contract.hasAICapability(badgeTokenId, requiredCap);
    
    console.log(`${'='.repeat(70)}`);
    console.log(`AI Agent: Checking permissions for ${wallet.address}`);
    console.log(`Badge: ${badgeDomain} (Token ID: ${badgeTokenId})`);
    console.log(`Required Capability: ${requiredCap}`);
    console.log(`${'='.repeat(70)}`);
    
    if (hasCap) {
      console.log(`✅ ACCESS GRANTED`);
      console.log(`\n🤖 AI Response:`);
      console.log(`   "Message sent to agent network successfully."`);
      console.log(`   "Your badge: ${badgeDomain}"`);
      console.log(`   "Model: ${modelTypeCheck}"`);
      console.log(`   "Active capabilities: ${activeCapabilities.length}"`);
    } else {
      console.log(`❌ ACCESS DENIED`);
      console.log(`\n🤖 AI Response:`);
      console.log(`   "Sorry, you need '${requiredCap}' capability."`);
      console.log(`   "Purchase it for ${ethers.formatEther(await contract.getCapabilityFee(badgeTokenId))} MATIC"`);
    }
    
    console.log(`${'='.repeat(70)}\n`);

    // Summary
    console.log('📊 SUMMARY\n');
    console.log(`✓ Badge: ${badgeDomain}`);
    console.log(`✓ Token ID: ${badgeTokenId}`);
    console.log(`✓ Model: ${modelTypeCheck}`);
    console.log(`✓ Owner: ${wallet.address}`);
    console.log(`✓ Capabilities: ${(await contract.getActiveCapabilities(badgeTokenId)).length}/4`);
    console.log(`✓ AI Access: ${hasCap ? 'GRANTED' : 'DENIED'}\n`);

    console.log('='.repeat(70));
    console.log('✅ WORKFLOW COMPLETE');
    console.log('='.repeat(70));
    console.log('\nKey Points:');
    console.log('1. Badge minted and synced to AI model');
    console.log('2. Capability purchased on-chain');
    console.log('3. AI verified access before responding');
    console.log('4. All verifiable on Polygon Amoy');
    console.log('='.repeat(70) + '\n');

  } catch (error) {
    console.error('\n❌ Error:', error.message);
    if (error.data) {
      console.error('Data:', error.data);
    }
  }
}

main().catch(console.error);
