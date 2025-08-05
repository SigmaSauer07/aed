// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

library LibEnhancements {
    using LibAppStorage for AppStorage;
    
    event FeaturePurchased(uint256 indexed tokenId, string featureName, uint256 price);
    event SubdomainsEnabled(uint256 indexed tokenId, uint256 price);
    event ExternalDomainUpgraded(string indexed externalDomain, uint256 price);
    event FeaturePriceUpdated(string featureName, uint256 oldPrice, uint256 newPrice);
    event FeatureAdded(string featureName, uint256 price, uint256 flag);
    
    function purchaseFeature(uint256 tokenId, string calldata featureName) internal {
        AppStorage storage s = LibAppStorage.s();
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        
        uint256 price = s.enhancementPrices[featureName];
        require(price > 0, "Feature not available");
        require(msg.value >= price, "Insufficient payment");
        
        // Enable feature based on name
        if (keccak256(bytes(featureName)) == keccak256("subdomain")) {
            s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
            s.enhancedDomains[s.tokenIdToDomain[tokenId]] = true;
        } else if (keccak256(bytes(featureName)) == keccak256("metadata")) {
            s.domainFeatures[tokenId] |= FEATURE_METADATA;
        } else if (keccak256(bytes(featureName)) == keccak256("reverse")) {
            s.domainFeatures[tokenId] |= FEATURE_REVERSE;
        } else if (keccak256(bytes(featureName)) == keccak256("bridge")) {
            s.domainFeatures[tokenId] |= FEATURE_BRIDGE;
        }
        
        s.totalRevenue += price;
        payable(s.feeCollector).transfer(price);
        emit FeaturePurchased(tokenId, featureName, price);
        
        // Refund excess
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    
    function enableSubdomains(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.s();
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        require((s.domainFeatures[tokenId] & FEATURE_SUBDOMAINS) == 0, "Already enabled");
        
        uint256 price = s.enhancementPrices["subdomain"];
        require(msg.value >= price, "Insufficient payment");
        
        s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
        s.enhancedDomains[s.tokenIdToDomain[tokenId]] = true;
        s.totalRevenue += price;
        payable(s.feeCollector).transfer(price);
        
        emit SubdomainsEnabled(tokenId, price);
        
        // Refund excess
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    
    function upgradeExternalDomain(string calldata externalDomain) internal {
        AppStorage storage s = LibAppStorage.s();
        
        uint256 price = s.enhancementPrices["byo"];
        require(price > 0, "BYO not available");
        require(msg.value >= price, "Insufficient payment");
        
        // Create a virtual token for external domain
        uint256 tokenId = s.nextTokenId;
        s.nextTokenId++;
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        s.domainToTokenId[externalDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = externalDomain;
        s.domainExists[externalDomain] = true;
        s.userDomains[msg.sender].push(externalDomain);
        
        // Initialize domain struct for external domain
        s.domains[tokenId] = Domain({
            name: externalDomain,
            tld: "external",
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: false,
            owner: msg.sender
        });
        
        // Enable subdomain feature
        s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
        s.enhancedDomains[externalDomain] = true;
        s.totalRevenue += price;
        payable(s.feeCollector).transfer(price);
        
        emit ExternalDomainUpgraded(externalDomain, price);
        
        // Refund excess
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    
    function getFeaturePrice(string calldata featureName) internal view returns (uint256) {
        return LibAppStorage.s().enhancementPrices[featureName];
    }
    
    function isFeatureEnabled(uint256 tokenId, string calldata featureName) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.s();
        
        if (keccak256(bytes(featureName)) == keccak256("subdomain")) {
            return (s.domainFeatures[tokenId] & FEATURE_SUBDOMAINS) != 0;
        } else if (keccak256(bytes(featureName)) == keccak256("metadata")) {
            return (s.domainFeatures[tokenId] & FEATURE_METADATA) != 0;
        } else if (keccak256(bytes(featureName)) == keccak256("reverse")) {
            return (s.domainFeatures[tokenId] & FEATURE_REVERSE) != 0;
        } else if (keccak256(bytes(featureName)) == keccak256("bridge")) {
            return (s.domainFeatures[tokenId] & FEATURE_BRIDGE) != 0;
        }
        
        return false;
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
        AppStorage storage s = LibAppStorage.s();
        uint256 oldPrice = s.enhancementPrices[featureName];
        s.enhancementPrices[featureName] = price;
        emit FeaturePriceUpdated(featureName, oldPrice, price);
    }
    
    function addFeature(string calldata featureName, uint256 price, uint256 flag) internal {
        AppStorage storage s = LibAppStorage.s();
        s.enhancementPrices[featureName] = price;
        // Store feature flag in future storage
        s.futureUint256[uint256(keccak256(bytes(featureName)))] = flag;
        emit FeatureAdded(featureName, price, flag);
    }
}
