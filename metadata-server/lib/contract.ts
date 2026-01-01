import { ethers } from 'ethers';

export const ABI = [
  'function tokenURI(uint256) view returns (string)',
  'function ownerOf(uint256) view returns (address)',
  'function name() view returns (string)',
  'function symbol() view returns (string)',
  'function getGlobalDescription() view returns (string)',
  'function getDomainInfo(uint256) view returns (tuple(string name, string tld, string profileURI, string imageURI, uint256 subdomainCount, uint256 mintFee, uint64 expiresAt, bool feeEnabled, bool isSubdomain, address owner))',
  'function getDomainByTokenId(uint256) view returns (string)',
  'function getEvolutionLevel(uint256) view returns (uint256)',
  'function getFragmentCount(uint256) view returns (uint256)',
  'function getTokenFragments(uint256) view returns (tuple(string fragmentType, uint256 earnedAt, bytes32 eventHash)[])',
  'function hasFragment(uint256, string) view returns (bool)',
];

const RPC_URL = process.env.AMOY_RPC || process.env.RPC_URL;
const CONTRACT_ADDRESS = process.env.CONTRACT_ADDRESS || "0x6452DCd7Bbee694223D743f09FF07c717Eeb34DF";

let provider: ethers.JsonRpcProvider | null = null;
let contract: ethers.Contract | null = null;
let globalDescription = '';

export function initializeContract() {
  if (!RPC_URL || !CONTRACT_ADDRESS) {
    console.error('Missing RPC_URL/CONTRACT_ADDRESS environment variables');
    return false;
  }

  try {
    provider = new ethers.JsonRpcProvider(RPC_URL);
    contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, provider);
    return true;
  } catch (error) {
    console.error('Failed to initialize contract:', error);
    return false;
  }
}

export async function loadGlobalDescription() {
  if (!contract) {
    initializeContract();
  }

  if (contract) {
    try {
      globalDescription = await contract.getGlobalDescription();
      console.log('Global description loaded:', globalDescription || 'None set');
    } catch (error) {
      console.warn('Could not fetch global description:', error);
      globalDescription = 'Alsania Enhanced Domain';
    }
  }
}

export function getContract() {
  if (!contract) {
    initializeContract();
  }
  return contract;
}

export function getGlobalDescription() {
  return globalDescription;
}

// Initialize on module load
if (!contract) {
  initializeContract();
  loadGlobalDescription();
}