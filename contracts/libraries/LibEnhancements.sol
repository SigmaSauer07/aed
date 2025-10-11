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

    event ExternalDomainUpgraded(string indexed domain, uint256 price, address indexed purchaser);
    
    event FeaturePurchased(uint256 indexed tokenId, string indexed featureName, uint256 price);
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);
    
    function purchaseFeature(uint256 tokenId, string calldata featureName) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.owners[tokenId] == msg.sender, "Not token owner");

        bytes32 featureKey = keccak256(bytes(featureName));
        uint256 price = s.enhancementPrices[featureName];
        require(price > 0, "Feature not available");
        require(msg.value >= price, "Insufficient payment");

        uint256 featureMask = _featureMask(featureKey);
        require(featureMask != 0, "Unknown feature");
        require((s.domainFeatures[tokenId] & featureMask) == 0, "Feature already enabled");

        s.domainFeatures[tokenId] |= featureMask;
        string memory domain = s.tokenIdToDomain[tokenId];
        if (bytes(domain).length > 0) {
            s.enhancedDomains[domain] = true;
        }
        
        // Update revenue
        s.totalRevenue += price;
        
        // Send to fee collector
        _forwardPayment(price);

        emit FeaturePurchased(tokenId, featureName, price);
        emit FeatureEnabled(tokenId, featureMask);
    }

    function enableSubdomains(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        require(s.owners[tokenId] == msg.sender, "Not token owner");

        uint256 price = s.enhancementPrices["subdomain"];
        require(msg.value >= price, "Insufficient payment");
        require((s.domainFeatures[tokenId] & FEATURE_SUBDOMAINS) == 0, "Feature already enabled");

        s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
        string memory domain = s.tokenIdToDomain[tokenId];
        if (bytes(domain).length > 0) {
            s.enhancedDomains[domain] = true;
        }
        s.totalRevenue += price;

        _forwardPayment(price);

        emit FeatureEnabled(tokenId, FEATURE_SUBDOMAINS);
    }

    function upgradeExternalDomain(string calldata externalDomain) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        uint256 price = s.enhancementPrices["byo"];
        require(msg.value >= price, "Insufficient payment");

        // Store external domain upgrade
        s.futureStringString[externalDomain] = "upgraded";
        s.totalRevenue += price;

        _forwardPayment(price);
        emit ExternalDomainUpgraded(externalDomain, price, msg.sender);
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
    
    function addFeature(string calldata featureName, uint256 price, uint256 flag) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.enhancementPrices[featureName] = price;
        if (flag != 0) {
            uint256 key = uint256(keccak256(bytes(featureName)));
            s.futureUint256[key] = flag;
        }
    }

    function _forwardPayment(uint256 amount) private {
        AppStorage storage s = LibAppStorage.appStorage();
        if (amount > 0) {
            (bool sent, ) = s.feeCollector.call{value: amount}("");
            require(sent, "Payment transfer failed");
        }

        if (msg.value > amount) {
            (bool refundSent, ) = msg.sender.call{value: msg.value - amount}("");
            require(refundSent, "Refund failed");
        }
    }

    function _featureMask(bytes32 featureKey) private view returns (uint256) {
        if (featureKey == keccak256("subdomain")) {
            return FEATURE_SUBDOMAINS;
        }
        if (featureKey == keccak256("metadata")) {
            return FEATURE_METADATA;
        }
        if (featureKey == keccak256("reverse")) {
            return FEATURE_REVERSE;
        }
        if (featureKey == keccak256("bridge")) {
            return FEATURE_BRIDGE;
        }

        uint256 storedFlag = LibAppStorage.appStorage().futureUint256[uint256(featureKey)];
        return storedFlag;
    }
}
