// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AppStorage
 * @dev Unified storage layout for all AED modules (future-proofed)
 */

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

// Unified storage struct for all modules
struct AppStorage {
    // ERC721 Storage
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    string name;
    string symbol;
    uint256 royaltyBps;
    uint256 maxSubdomains;

    // Domain Storage
    mapping(uint256 => Domain) domains;
    mapping(string => uint256) domainToTokenId;
    mapping(uint256 => string) tokenIdToDomain;
    mapping(string => bool) domainExists;
    mapping(address => string[]) userDomains;
    mapping(uint256 => uint256) domainFeatures;

    // Pricing & TLD Storage
    mapping(string => uint256) tldPrices;
    mapping(string => bool) freeTlds;
    mapping(string => bool) validTlds;
    uint256 basePrice;

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
    mapping(string => bool) activeTLDs;
    mapping(string => uint256) fees;
    uint256 multiplier;
    address feeCollector;
    bool paused;

    // System State
    uint256 nextTokenId;
    uint256 totalRevenue;
    string baseURI;

    // Module Registry Storage
    mapping(string => ModuleInfo) modules;
    mapping(bytes4 => string) selectorToModule;
    mapping(string => uint256) moduleVersions;

    // Future Storage Slots (Reserve for upgrades)
    mapping(uint256 => uint256) futureUint256;
    mapping(address => uint256) futureAddressUint256;
    mapping(string => string) futureStringString;

    uint256[50] __gap; // Reserve 50 slots for future use
}