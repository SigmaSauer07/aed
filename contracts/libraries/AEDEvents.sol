// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Events library for AED system
library AEDEvents {
    // Domain events
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event DomainTransferred(string indexed domain, address indexed from, address indexed to, uint256 tokenId);
    event DomainExpired(string indexed domain, uint256 indexed tokenId);
    
    // Subdomain events
    event SubdomainCreated(string indexed subdomain, string indexed parent, address indexed owner, uint256 tokenId);
    event SubdomainFeeUpdated(string indexed parent, uint256 oldFee, uint256 newFee);
    
    // Enhancement events
    event FeaturePurchased(uint256 indexed tokenId, string indexed featureName, uint256 price);
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);
    
    // Admin events
    event FeeUpdated(string indexed feeType, uint256 oldFee, uint256 newFee);
    event TLDConfigured(string indexed tld, bool isActive, uint256 price);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    
    // Metadata events
    event ProfileURISet(uint256 indexed tokenId, string uri);
    event ImageURISet(uint256 indexed tokenId, string uri);
    
    // Reverse resolution events
    event ReverseRecordSet(address indexed addr, string indexed domain);
    event ReverseRecordCleared(address indexed addr, string indexed domain);
    
    // Bridge events
    event DomainBridged(uint256 indexed tokenId, string indexed domain, uint256 indexed chainId);
    event DomainUnbridged(uint256 indexed tokenId, string indexed domain, uint256 indexed chainId);
    
    // Recovery events
    event RecoveryInitiated(uint256 indexed tokenId, address indexed initiator, uint256 deadline);
    event RecoveryCompleted(uint256 indexed tokenId, address indexed newOwner);
    event RecoveryCancelled(uint256 indexed tokenId);
}
