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

// Fragment struct for evolution system
struct Fragment {
    string fragmentType; // "first_domain", "vision_pioneer", "subdomain_creator"
    uint256 earnedAt;
    bytes32 eventHash; // Links to achievement event
}

// ModuleInfo struct for module registry
struct ModuleInfo {
    address moduleAddress;
    string name;
    uint256 version;
    bool isActive;
}

// Bridge structs
struct BridgeInfo {
    uint256 chainId;
    address bridgeAddress;
    uint256 bridgedAt;
    bool isBridgedOut;
}

struct BridgeConfig {
    address bridgeAddress;
    bool enabled;
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
    mapping(uint256 => Domain) domains;

    // Pricing & TLD Storage
    mapping(string => uint256) tldPrices;
    mapping(string => bool) freeTlds;
    mapping(string => bool) validTlds;
    mapping(string => uint256) fees;

    // Enhancement Storage
    mapping(string => bool) enhancedDomains;
    mapping(string => uint256) enhancementPrices;
    string[] availableFeatures;
    mapping(string => bool) featureExists;
    mapping(string => uint256) featureFlags;

    // Subdomain Storage
    mapping(string => string[]) domainSubdomains;
    mapping(string => address) subdomainOwners;
    mapping(string => uint256) subdomainCounts;

    // Metadata Storage
    mapping(uint256 => string) tokenURIs;
    mapping(uint256 => string) profileURIs;
    mapping(uint256 => string) imageURIs;
    string globalDescription; // Admin-set description for all domain metadata

    // Reverse Resolution Storage
    mapping(address => string) reverseRecords;
    mapping(string => address) reverseOwners;

    // Admin Storage
    mapping(address => bool) admins;
    mapping(address => bool) feeManagers;
    mapping(address => bool) tldManagers;
    mapping(bytes32 => mapping(address => bool)) roles;
    bool paused;
    address feeCollector;

    // System State
    uint256 nextTokenId;
    uint256 totalRevenue;
    string baseURI;
    string name;
    string symbol;

    // Module States
    mapping(string => bool) moduleEnabled;
    mapping(string => address) moduleAddresses;
    mapping(string => uint256) moduleVersions;
    mapping(bytes32 => ModuleInfo) moduleRegistry;

    // Bridge Storage
    mapping(uint256 => BridgeInfo) bridgedDomains;
    mapping(uint256 => BridgeConfig) bridgeConfigs;
    mapping(uint256 => uint256) domainFeatures;

    // ===== EVOLUTION SYSTEM STORAGE (NEW) =====
    mapping(uint256 => Fragment[]) tokenFragments; // All fragments earned by a token
    mapping(uint256 => uint256) evolutionLevels; // Current evolution level
    mapping(uint256 => mapping(string => bool)) hasFragment; // Quick lookup for specific fragments

    // Future Storage Slots (Reserve for upgrades)
    mapping(uint256 => uint256) futureUint256;
    mapping(address => uint256) futureAddressUint256;
    mapping(string => string) futureStringString;
    uint256[41] __gap; // Reduced from 44 to 41 to account for new mappings
}
