import express from 'express';
import { ethers } from 'ethers';
import dotenv from 'dotenv';
import cors from 'cors';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// AED Contract ABI (minimal - only what we need)
const AED_ABI = [
  "function ownerOf(uint256 tokenId) view returns (address)",
  "function isAISubdomain(uint256 tokenId) view returns (bool)",
  "function hasAICapability(uint256 tokenId, string capability) view returns (bool)",
  "function getModelType(uint256 tokenId) view returns (string)",
  "function getActiveCapabilities(uint256 tokenId) view returns (string[])"
];

const provider = new ethers.JsonRpcProvider(process.env.AMOY_RPC);
const contract = new ethers.Contract(process.env.CONTRACT_ADDRESS, AED_ABI, provider);

// Verify badge ownership and capabilities
async function verifyBadgeAccess(walletAddress, tokenId, requiredCapability = null) {
  try {
    // Check if token is a badge
    const isBadge = await contract.isAISubdomain(tokenId);
    if (!isBadge) {
      return { valid: false, reason: "Token is not an AI badge" };
    }

    // Check ownership
    const owner = await contract.ownerOf(tokenId);
    if (owner.toLowerCase() !== walletAddress.toLowerCase()) {
      return { valid: false, reason: "Wallet does not own this badge" };
    }

    // Check specific capability if required
    if (requiredCapability) {
      const hasCapability = await contract.hasAICapability(tokenId, requiredCapability);
      if (!hasCapability) {
        return { valid: false, reason: `Badge missing required capability: ${requiredCapability}` };
      }
    }

    // Get badge info
    const modelType = await contract.getModelType(tokenId);
    const capabilities = await contract.getActiveCapabilities(tokenId);

    return {
      valid: true,
      badge: {
        tokenId,
        owner,
        modelType,
        capabilities
      }
    };
  } catch (error) {
    return { valid: false, reason: `Verification failed: ${error.message}` };
  }
}

// API endpoint: AI responds only if badge is valid
app.post('/api/chat', async (req, res) => {
  const { message, walletAddress, badgeTokenId } = req.body;

  if (!message || !walletAddress || !badgeTokenId) {
    return res.status(400).json({ error: "Missing required fields: message, walletAddress, badgeTokenId" });
  }

  // Verify badge ownership
  const verification = await verifyBadgeAccess(walletAddress, badgeTokenId);

  if (!verification.valid) {
    return res.status(403).json({
      error: "Access Denied",
      reason: verification.reason,
      hint: "Connect your wallet and ensure you own a valid AI badge with required capabilities"
    });
  }

  // Badge is valid - AI can respond
  const aiResponse = {
    message: `✅ Badge verified! I can now assist you.`,
    badgeInfo: verification.badge,
    response: `You asked: "${message}"\n\nAs an AI with badge #${badgeTokenId} (${verification.badge.modelType}), I have access to: ${verification.badge.capabilities.join(', ')}\n\nThis is a demo response. In production, this would route to the actual AI model.`
  };

  res.json(aiResponse);
});

// API endpoint: Check if badge has specific capability
app.post('/api/check-capability', async (req, res) => {
  const { walletAddress, badgeTokenId, capability } = req.body;

  if (!walletAddress || !badgeTokenId || !capability) {
    return res.status(400).json({ error: "Missing required fields" });
  }

  const verification = await verifyBadgeAccess(walletAddress, badgeTokenId, capability);

  res.json({
    hasCapability: verification.valid,
    badge: verification.badge || null,
    reason: verification.reason || null
  });
});

// API endpoint: Get badge details
app.get('/api/badge/:tokenId', async (req, res) => {
  const tokenId = req.params.tokenId;

  try {
    const isBadge = await contract.isAISubdomain(tokenId);
    if (!isBadge) {
      return res.status(404).json({ error: "Not a badge" });
    }

    const owner = await contract.ownerOf(tokenId);
    const modelType = await contract.getModelType(tokenId);
    const capabilities = await contract.getActiveCapabilities(tokenId);

    res.json({
      tokenId,
      owner,
      modelType,
      capabilities,
      isBadge: true
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    contract: process.env.CONTRACT_ADDRESS,
    network: 'Polygon Amoy'
  });
});

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`\n🤖 AED AI Demo Server running on port ${PORT}`);
  console.log(`📝 Contract: ${process.env.CONTRACT_ADDRESS}`);
  console.log(`🌐 Network: Polygon Amoy`);
  console.log(`\n✨ Example request:`);
  console.log(`curl -X POST http://localhost:${PORT}/api/chat \\`);
  console.log(`  -H "Content-Type: application/json" \\`);
  console.log(`  -d '{"message":"Hello","walletAddress":"0x78dB155AA7f39A8D13a0e1E8EEB41d71e2ce3F43","badgeTokenId":"1"}'`);
});
