// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library LibEnhancements {
    using LibAppStorage for AppStorage;
    using Strings for uint256;

    // Constants from AEDConstants (hardcoded since it's a contract)
    uint256 constant FEATURE_SUBDOMAINS = 1 << 0;
    uint256 constant FEATURE_METADATA = 1 << 1;
    uint256 constant FEATURE_REVERSE = 1 << 2;
    uint256 constant FEATURE_BRIDGE = 1 << 3;

    // Storage keys for dynamic feature registry (leverages reserved slots)
    uint256 constant FEATURE_COUNT_KEY = uint256(keccak256("aed.enhancements.count"));

    event FeatureCatalogued(string indexed featureName, uint256 flag);
    
    event FeaturePurchased(uint256 indexed tokenId, string indexed featureName, uint256 price);
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);
    
    function purchaseFeature(uint256 tokenId, string calldata featureName) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        require(s.owners[tokenId] == msg.sender, "Not token owner");

        uint256 flag = _featureFlag(s, featureName);
        require(flag != 0, "Feature not supported");

        uint256 price = s.enhancementPrices[featureName];
        if (price > 0) {
            require(msg.value >= price, "Insufficient payment");
            s.totalRevenue += price;

            payable(s.feeCollector).transfer(price);

            if (msg.value > price) {
                payable(msg.sender).transfer(msg.value - price);
            }
        } else {
            require(msg.value == 0, "No payment required");
        }

        s.domainFeatures[tokenId] |= flag;
        string memory domain = s.tokenIdToDomain[tokenId];
        if (bytes(domain).length > 0) {
            s.enhancedDomains[domain] = true;
        }

        emit FeaturePurchased(tokenId, featureName, price);
        emit FeatureEnabled(tokenId, flag);
    }

    function enableSubdomains(uint256 tokenId) internal {
        purchaseFeature(tokenId, "subdomain");
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
        uint256 flag = _featureFlag(s, featureName);
        if (flag == 0) {
            return false;
        }
        return (s.domainFeatures[tokenId] & flag) != 0;
    }

    function getAvailableFeatures() internal view returns (string[] memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 count = s.futureUint256[FEATURE_COUNT_KEY];
        string[] memory features = new string[](count);

        for (uint256 i = 0; i < count; ++i) {
            features[i] = s.futureStringString[_featureNameKey(i)];
        }

        return features;
    }

    function setFeaturePrice(string calldata featureName, uint256 price) internal {
        require(bytes(featureName).length != 0, "Feature required");
        LibAppStorage.appStorage().enhancementPrices[featureName] = price;
    }

    function addFeature(string calldata featureName, uint256 price, uint256 flag) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(bytes(featureName).length != 0, "Feature required");
        require(flag != 0 && (flag & (flag - 1)) == 0, "Flag must be power of two");

        s.enhancementPrices[featureName] = price;
        _setFeatureFlag(s, featureName, flag);

        if (!_featureExists(s, featureName)) {
            uint256 index = s.futureUint256[FEATURE_COUNT_KEY];
            s.futureStringString[_featureNameKey(index)] = featureName;
            s.futureUint256[FEATURE_COUNT_KEY] = index + 1;
        }

        emit FeatureCatalogued(featureName, flag);
    }

    function ensureDefaultFeatures() internal {
        AppStorage storage s = LibAppStorage.appStorage();
        _ensureFeature(s, "subdomain", FEATURE_SUBDOMAINS);
        _ensureFeature(s, "metadata", FEATURE_METADATA);
        _ensureFeature(s, "reverse", FEATURE_REVERSE);
        _ensureFeature(s, "bridge", FEATURE_BRIDGE);
    }

    // ===== Internal helpers =====

    function _featureFlag(AppStorage storage s, string memory featureName) private view returns (uint256) {
        return s.futureUint256[uint256(keccak256(abi.encodePacked("aed.enhancements.flag:", featureName)))];
    }

    function _setFeatureFlag(AppStorage storage s, string memory featureName, uint256 flag) private {
        s.futureUint256[uint256(keccak256(abi.encodePacked("aed.enhancements.flag:", featureName)))] = flag;
    }

    function _featureNameKey(uint256 index) private pure returns (string memory) {
        return string(abi.encodePacked("aed.enhancements.name:", index.toString()));
    }

    function _featureExists(AppStorage storage s, string memory featureName) private view returns (bool) {
        uint256 count = s.futureUint256[FEATURE_COUNT_KEY];
        bytes32 featureHash = keccak256(bytes(featureName));

        for (uint256 i = 0; i < count; ++i) {
            if (keccak256(bytes(s.futureStringString[_featureNameKey(i)])) == featureHash) {
                return true;
            }
        }

        return false;
    }

    function _ensureFeature(AppStorage storage s, string memory featureName, uint256 flag) private {
        if (_featureFlag(s, featureName) == 0) {
            _setFeatureFlag(s, featureName, flag);

            if (!_featureExists(s, featureName)) {
                uint256 index = s.futureUint256[FEATURE_COUNT_KEY];
                s.futureStringString[_featureNameKey(index)] = featureName;
                s.futureUint256[FEATURE_COUNT_KEY] = index + 1;
            }

            emit FeatureCatalogued(featureName, flag);
        }
    }
}
