// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";

library LibEnhancements {
    using LibAppStorage for AppStorage;
    
    // Constants from AEDConstants (hardcoded since it's a contract)
    uint256 constant FEATURE_SUBDOMAINS = 1 << 0;
    uint256 constant FEATURE_METADATA = 1 << 1;
    uint256 constant FEATURE_REVERSE = 1 << 2;
    uint256 constant FEATURE_BRIDGE = 1 << 3;
    
    event FeaturePurchased(uint256 indexed tokenId, string indexed featureName, uint256 price);
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);
    
    function purchaseFeature(uint256 tokenId, string calldata featureName) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        
        uint256 price = s.enhancementPrices[featureName];
        require(price > 0, "Feature not available");
        require(msg.value >= price, "Insufficient payment");
        
        // Enable the feature based on name
        if (keccak256(bytes(featureName)) == keccak256("subdomain")) {
            s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
        } else if (keccak256(bytes(featureName)) == keccak256("metadata")) {
            s.domainFeatures[tokenId] |= FEATURE_METADATA;
        } else if (keccak256(bytes(featureName)) == keccak256("reverse")) {
            s.domainFeatures[tokenId] |= FEATURE_REVERSE;
        } else if (keccak256(bytes(featureName)) == keccak256("bridge")) {
            s.domainFeatures[tokenId] |= FEATURE_BRIDGE;
        }
        
        // Update revenue
        s.totalRevenue += price;
        
        // Send to fee collector
        if (price > 0) {
            payable(s.feeCollector).transfer(price);
        }
        
        // Refund excess
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        
        emit FeaturePurchased(tokenId, featureName, price);
    }
    
    function enableSubdomains(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        
        uint256 price = s.enhancementPrices["subdomain"];
        require(msg.value >= price, "Insufficient payment");
        
        s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
        s.totalRevenue += price;
        
        // Send to fee collector
        if (price > 0) {
            payable(s.feeCollector).transfer(price);
        }
        
        // Refund excess
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        
        emit FeatureEnabled(tokenId, FEATURE_SUBDOMAINS);
    }
    
    function upgradeExternalDomain(string calldata externalDomain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        uint256 price = s.enhancementPrices["byo"];
        require(msg.value >= price, "Insufficient payment");
        
        // Store external domain upgrade
        s.futureStringString[externalDomain] = "upgraded";
        s.totalRevenue += price;
        
        // Send to fee collector
        if (price > 0) {
            payable(s.feeCollector).transfer(price);
        }
        
        // Refund excess
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    
    function getFeaturePrice(string calldata featureName) internal view returns (uint256) {
        return LibAppStorage.appStorage().enhancementPrices[featureName];
    }
    
    function isFeatureEnabled(uint256 tokenId, string calldata featureName) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        uint256 feature = 0;
        if (keccak256(bytes(featureName)) == keccak256("subdomain")) {
            feature = FEATURE_SUBDOMAINS;
        } else if (keccak256(bytes(featureName)) == keccak256("metadata")) {
            feature = FEATURE_METADATA;
        } else if (keccak256(bytes(featureName)) == keccak256("reverse")) {
            feature = FEATURE_REVERSE;
        } else if (keccak256(bytes(featureName)) == keccak256("bridge")) {
            feature = FEATURE_BRIDGE;
        }
        
        return (s.domainFeatures[tokenId] & feature) != 0;
    }
    
    function getAvailableFeatures() internal pure returns (string[] memory) {
        string[] memory features = new string[](4);
        features[0] = "subdomain";
        features[1] = "metadata";
        features[2] = "reverse";
        features[3] = "bridge";
        return features;
    }
    
    function setFeaturePrice(string calldata featureName, uint256 price) internal {
        LibAppStorage.appStorage().enhancementPrices[featureName] = price;
    }
    
    function addFeature(string calldata featureName, uint256 price, uint256 /* flag */) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.enhancementPrices[featureName] = price;
        // Feature flag handling would be implemented here
    }
}
