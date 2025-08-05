// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Domain struct for domain metadata
struct Domain {
    string name;
    string tld;
    string profileURI;
    string imageURI;
    uint256 subdomainCount;
    uint256 mintFee;
    uint64 expiresAt;
    bool feeEnabled;
    bool isSubdomain;
    address owner;
}

// ModuleInfo struct for module registry
struct ModuleInfo {
    address moduleAddress;
    uint256 version;
    bool enabled;
    uint256 deployedAt;
    bytes4[] selectors;
}

struct BridgeReceipt {
    uint256 destChainId;
    bytes32 bridgeHash;
    uint256 timestamp;
    bool isBridged;
}

// Use a single struct for ALL storage
struct AppStorage {
    // ERC721 Storage
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    
    // Domain Storage
    mapping(string => uint256) domainToTokenId;
    mapping(uint256 => string) tokenIdToDomain;
    mapping(string => bool) domainExists;
    mapping(address => string[]) userDomains;
    mapping(uint256 => Domain) domains; // Add missing domains mapping
    
    // Pricing & TLD Storage
    mapping(string => uint256) tldPrices;
    mapping(string => bool) freeTlds;
    mapping(string => bool) validTlds;
    mapping(string => uint256) fees; // Add missing fees mapping
    
    // Enhancement Storage
    mapping(string => bool) enhancedDomains;
    mapping(string => uint256) enhancementPrices;
    
    // Subdomain Storage
    mapping(string => string[]) domainSubdomains;
    mapping(string => address) subdomainOwners;
    mapping(string => uint256) subdomainCounts;
    
    // Metadata Storage
    mapping(uint256 => string) tokenURIs;
    mapping(uint256 => string) profileURIs;
    mapping(uint256 => string) imageURIs;
    
    // Reverse Resolution Storage
    mapping(address => string) reverseRecords;
    mapping(string => address) reverseOwners;
    
    // Admin Storage
    mapping(address => bool) admins;
    mapping(address => bool) feeManagers;
    mapping(address => bool) tldManagers;
    mapping(bytes32 => mapping(address => bool)) roles; // Add role-based access
    bool paused;
    address feeCollector; // Add missing fee collector
    
    // System State
    uint256 nextTokenId;
    uint256 totalRevenue;
    string baseURI;
    
    // Module States
    mapping(string => bool) moduleEnabled;
    mapping(string => address) moduleAddresses;
    mapping(string => uint256) moduleVersions;
    mapping(string => ModuleInfo) modules; // Add missing modules mapping
    
    // Bridge Storage
    mapping(uint256 => BridgeReceipt) bridgeData;
    mapping(uint256 => uint256) domainFeatures; // Add missing domain features
    
    // Future Storage Slots (Reserve for upgrades)
    mapping(uint256 => uint256) futureUint256;
    mapping(address => uint256) futureAddressUint256;
    mapping(string => string) futureStringString;
    uint256[47] __gap; // Reserve slots for future use
}

// NOTE: The LibAppStorage library is defined in contracts/libraries/LibAppStorage.sol to avoid duplication.


