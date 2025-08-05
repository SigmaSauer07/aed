// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AEDEvents
 * @dev Centralized events for the AED system
 */
library AEDEvents {
    // Core domain events
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event DomainTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    event SubdomainCreated(string indexed subdomain, string indexed parent, address indexed owner);
    
    // Metadata events
    event ProfileURIUpdated(uint256 indexed tokenId, string uri);
    event ImageURIUpdated(uint256 indexed tokenId, string uri);
    
    // Reverse resolution events
    event ReverseSet(address indexed addr, string domain);
    event ReverseCleared(address indexed addr);
    
    // Enhancement events
    event FeaturePurchased(uint256 indexed tokenId, string featureName, uint256 price);
    event SubdomainsEnabled(uint256 indexed tokenId, uint256 price);
    event ExternalDomainUpgraded(string indexed externalDomain, uint256 price);
    event FeaturePriceUpdated(string featureName, uint256 oldPrice, uint256 newPrice);
    event FeatureAdded(string featureName, uint256 price, uint256 flag);
    
    // Registry events
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);
    event ExternalDomainLinked(string indexed externalDomain, uint256 indexed tokenId);
    event ExternalDomainUnlinked(string indexed externalDomain);
    
    // Recovery events
    event GuardianAdded(uint256 indexed tokenId, address indexed guardian);
    event GuardianRemoved(uint256 indexed tokenId, address indexed guardian);
    event RecoveryInitiated(uint256 indexed tokenId, address indexed newOwner, uint256 deadline);
    event RecoveryConfirmed(uint256 indexed tokenId, address indexed guardian);
    event RecoveryCancelled(uint256 indexed tokenId);
    event RecoveryExecuted(uint256 indexed tokenId, address indexed oldOwner, address indexed newOwner);
    
    // Bridge events
    event DomainBridged(uint256 indexed tokenId, uint256 destChainId, bytes32 bridgeHash);
    event DomainClaimed(uint256 indexed tokenId, address indexed claimer, uint256 sourceChainId);
    event ChainSupportUpdated(uint256 indexed chainId, bool supported);
    
    // Admin events
    event FeeUpdated(string feeType, uint256 oldFee, uint256 newFee);
    event TLDConfigured(string tld, bool isActive, uint256 price);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);
    
    // Module events
    event ModuleRegistered(string indexed modName, address indexed moduleAddress, uint256 version);
    event ModuleUpgraded(string indexed modName, address indexed oldAddress, address indexed newAddress, uint256 oldVersion, uint256 newVersion);
    event ModuleEnabled(string indexed modName);
    event ModuleDisabled(string indexed modName);
}
