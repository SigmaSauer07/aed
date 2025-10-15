// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";
import "./LibValidation.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library LibEnhancements {
    using LibAppStorage for AppStorage;
    using Address for address payable;
    
    // Constants from AEDConstants (hardcoded since it's a contract)
    uint256 constant FEATURE_SUBDOMAINS = 1 << 0;
    uint256 constant FEATURE_METADATA = 1 << 1;
    uint256 constant FEATURE_REVERSE = 1 << 2;
    uint256 constant FEATURE_BRIDGE = 1 << 3;
    
    event FeaturePurchased(uint256 indexed tokenId, string indexed featureName, uint256 price);
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);
    event FeatureRegistered(string indexed featureName, uint256 price, uint256 flag);
    
    function purchaseFeature(uint256 tokenId, string calldata featureName) internal {
        _processFeaturePurchase(tokenId, featureName);
    }

    function enableSubdomains(uint256 tokenId) internal {
        _processFeaturePurchase(tokenId, "subdomain");
    }
    
    function upgradeExternalDomain(string calldata externalDomain) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        uint256 price = s.enhancementPrices["byo"];
        require(msg.value >= price, "Insufficient payment");

        string memory normalized = LibValidation.toLower(externalDomain);
        s.futureStringString[normalized] = "upgraded";
        s.totalRevenue += price;

        if (price > 0) {
            payable(s.feeCollector).sendValue(price);
        }

        if (msg.value > price) {
            payable(msg.sender).sendValue(msg.value - price);
        }
    }
    
    function getFeaturePrice(string calldata featureName) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        string memory normalized = LibValidation.toLower(featureName);
        return s.enhancementPrices[normalized];
    }

    function isFeatureEnabled(uint256 tokenId, string calldata featureName) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();

        string memory normalized = LibValidation.toLower(featureName);
        uint256 feature = s.enhancementFlags[normalized];
        require(feature != 0, "Feature not available");

        return (s.domainFeatures[tokenId] & feature) != 0;
    }

    function getAvailableFeatures() internal view returns (string[] memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        string[] memory features = new string[](s.featureCatalog.length);
        for (uint256 i = 0; i < s.featureCatalog.length; i++) {
            features[i] = s.featureCatalog[i];
        }
        return features;
    }

    function setFeaturePrice(string calldata featureName, uint256 price) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        string memory normalized = LibValidation.toLower(featureName);
        require(s.enhancementFlags[normalized] != 0, "Feature not available");
        s.enhancementPrices[normalized] = price;
    }

    function addFeature(string calldata featureName, uint256 price, uint256 flag) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(flag != 0, "Invalid flag");

        string memory normalized = LibValidation.toLower(featureName);
        require(s.enhancementFlags[normalized] == 0, "Feature exists");

        s.enhancementPrices[normalized] = price;
        s.enhancementFlags[normalized] = flag;
        s.featureCatalog.push(normalized);

        emit FeatureRegistered(normalized, price, flag);
    }

    function _processFeaturePurchase(uint256 tokenId, string memory featureName) private {
        AppStorage storage s = LibAppStorage.appStorage();

        require(s.owners[tokenId] == msg.sender, "Not token owner");

        string memory normalized = LibValidation.toLower(featureName);
        uint256 flag = s.enhancementFlags[normalized];
        require(flag != 0, "Feature not available");
        require((s.domainFeatures[tokenId] & flag) == 0, "Feature already enabled");

        uint256 price = s.enhancementPrices[normalized];
        require(msg.value >= price, "Insufficient payment");

        s.domainFeatures[tokenId] |= flag;
        string memory domain = s.tokenIdToDomain[tokenId];
        s.enhancedDomains[domain] = true;
        s.totalRevenue += price;

        if (price > 0) {
            payable(s.feeCollector).sendValue(price);
        }

        if (msg.value > price) {
            payable(msg.sender).sendValue(msg.value - price);
        }

        emit FeaturePurchased(tokenId, normalized, price);
        emit FeatureEnabled(tokenId, flag);
    }
}
