// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";

error FeatureUnavailable(string featureName);
error FeeTransferFailed();

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
        _applyFeature(s, tokenId, featureName, msg.value);
    }

    function enableSubdomains(uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        _applyFeature(s, tokenId, "subdomain", msg.value);
    }

    function upgradeExternalDomain(string calldata externalDomain) internal {
        AppStorage storage s = LibAppStorage.appStorage();

        uint256 price = s.enhancementPrices["byo"];
        require(msg.value >= price, "Insufficient payment");

        // Store external domain upgrade
        s.futureStringString[externalDomain] = "upgraded";
        s.totalRevenue += price;

        _forwardFee(s.feeCollector, price);

        // Refund excess
        _refundExcess(price);
    }

    function getFeaturePrice(string calldata featureName) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.featureExists[featureName], "Feature not found");
        return s.enhancementPrices[featureName];
    }

    function isFeatureEnabled(uint256 tokenId, string calldata featureName) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();

        uint256 feature = s.featureFlags[featureName];
        require(feature != 0, "Feature not found");

        return (s.domainFeatures[tokenId] & feature) != 0;
    }

    function getAvailableFeatures() internal view returns (string[] memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 length = s.availableFeatures.length;
        string[] memory features = new string[](length);

        for (uint256 i = 0; i < length; i++) {
            features[i] = s.availableFeatures[i];
        }

        return features;
    }

    function setFeaturePrice(string calldata featureName, uint256 price) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.featureExists[featureName], "Feature not found");
        s.enhancementPrices[featureName] = price;
    }

    function addFeature(string calldata featureName, uint256 price, uint256 flag) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(flag != 0, "Invalid feature flag");

        if (!s.featureExists[featureName]) {
            s.availableFeatures.push(featureName);
            s.featureExists[featureName] = true;
        }

        s.featureFlags[featureName] = flag;
        s.enhancementPrices[featureName] = price;
    }

    function _applyFeature(
        AppStorage storage s,
        uint256 tokenId,
        string memory featureName,
        uint256 amountProvided
    ) private {
        require(s.owners[tokenId] == msg.sender, "Not token owner");

        uint256 flag = s.featureFlags[featureName];
        if (flag == 0) {
            revert FeatureUnavailable(featureName);
        }

        uint256 price = s.enhancementPrices[featureName];
        require(amountProvided >= price, "Insufficient payment");

        if ((s.domainFeatures[tokenId] & flag) == 0) {
            s.domainFeatures[tokenId] |= flag;
            emit FeatureEnabled(tokenId, flag);
        }

        // Track special case for subdomains to keep compatibility with legacy UI
        if (keccak256(bytes(featureName)) == keccak256("subdomain")) {
            string memory domain = s.tokenIdToDomain[tokenId];
            s.enhancedDomains[domain] = true;
        }

        s.totalRevenue += price;
        _forwardFee(s.feeCollector, price);
        _refundExcess(price);

        emit FeaturePurchased(tokenId, featureName, price);
    }

    function _forwardFee(address feeCollector, uint256 amount) private {
        if (amount == 0) {
            return;
        }

        (bool success, ) = payable(feeCollector).call{value: amount}("");
        if (!success) {
            revert FeeTransferFailed();
        }
    }

    function _refundExcess(uint256 price) private {
        if (msg.value > price) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - price}("");
            if (!success) {
                revert FeeTransferFailed();
            }
        }
    }
}
