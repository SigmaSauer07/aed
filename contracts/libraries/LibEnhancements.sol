// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";
import "./LibMinting.sol";
import "@openzeppelin/contracts/utils/Address.sol";

library LibEnhancements {
    using LibAppStorage for AppStorage;
    using Address for address payable;

    uint256 private constant FEATURE_SUBDOMAINS = 1 << 0;
    uint256 private constant FEATURE_METADATA = 1 << 1;
    uint256 private constant FEATURE_REVERSE = 1 << 2;
    uint256 private constant FEATURE_BRIDGE = 1 << 3;

    event FeaturePurchased(uint256 indexed tokenId, string indexed featureName, uint256 price);
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);

    function purchaseFeature(uint256 tokenId, string calldata featureName) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        require(s.owners[tokenId] == msg.sender, "Not token owner");

        uint256 price = s.enhancementPrices[featureName];
        require(price > 0, "Feature not available");
        require(msg.value >= price, "Insufficient payment");

        uint256 flag = _resolveFeatureFlag(s, featureName);
        require(flag != 0, "Feature not configured");

        s.domainFeatures[tokenId] |= flag;
        if (flag == FEATURE_SUBDOMAINS) {
            string memory domain = s.tokenIdToDomain[tokenId];
            s.enhancedDomains[domain] = true;
            emit FeatureEnabled(tokenId, flag);
        }

        _forwardRevenue(s, price);
        _refundExcess(price);

        emit FeaturePurchased(tokenId, featureName, price);
    }

    function enableSubdomains(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        require(s.owners[tokenId] == msg.sender, "Not token owner");

        uint256 price = s.enhancementPrices["subdomain"];
        require(msg.value >= price, "Insufficient payment");

        s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
        string memory domain = s.tokenIdToDomain[tokenId];
        s.enhancedDomains[domain] = true;

        _forwardRevenue(s, price);
        _refundExcess(price);

        emit FeatureEnabled(tokenId, FEATURE_SUBDOMAINS);
    }

    function upgradeExternalDomain(string calldata externalDomain) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        uint256 price = s.enhancementPrices["byo"];
        require(price > 0, "Feature not available");
        require(msg.value >= price, "Insufficient payment");

        string memory normalizedDomain = LibMinting.normalizeLabel(externalDomain);
        s.futureStringString[normalizedDomain] = "upgraded";
        s.enhancedDomains[normalizedDomain] = true;

        _forwardRevenue(s, price);
        _refundExcess(price);
    }

    function getFeaturePrice(string calldata featureName) internal view returns (uint256) {
        return LibAppStorage.appStorage().enhancementPrices[featureName];
    }

    function isFeatureEnabled(uint256 tokenId, string calldata featureName) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 flag = _resolveFeatureFlag(s, featureName);
        return flag != 0 && (s.domainFeatures[tokenId] & flag) != 0;
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
        require(flag != 0, "Flag required");
        AppStorage storage s = LibAppStorage.appStorage();
        s.enhancementPrices[featureName] = price;
        s.futureUint256[_featureKey(featureName)] = flag;
    }

    function _forwardRevenue(AppStorage storage s, uint256 amount) private {
        if (amount == 0) {
            return;
        }

        s.totalRevenue += amount;
        payable(s.feeCollector).sendValue(amount);
    }

    function _refundExcess(uint256 required) private {
        uint256 refund = msg.value - required;
        if (refund > 0) {
            payable(msg.sender).sendValue(refund);
        }
    }

    function _resolveFeatureFlag(AppStorage storage s, string memory featureName) private view returns (uint256) {
        uint256 storedFlag = s.futureUint256[_featureKey(featureName)];
        if (storedFlag != 0) {
            return storedFlag;
        }

        bytes32 featureHash = keccak256(bytes(featureName));
        if (featureHash == keccak256("subdomain")) {
            return FEATURE_SUBDOMAINS;
        } else if (featureHash == keccak256("metadata")) {
            return FEATURE_METADATA;
        } else if (featureHash == keccak256("reverse")) {
            return FEATURE_REVERSE;
        } else if (featureHash == keccak256("bridge")) {
            return FEATURE_BRIDGE;
        }

        return 0;
    }

    function _featureKey(string memory featureName) private pure returns (uint256) {
        return uint256(keccak256(bytes(featureName)));
    }
}
