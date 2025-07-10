// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../core/AEDConstants.sol";
import "../core/CoreState.sol";

/**
 * @title AEDEnhancements
 * @dev Module for purchasing and enabling enhancement features on domains (e.g., enabling certain flags for a fee).
 * (NOTE: This module is not integrated in the main AED contract yet; potential future use.)
 */
abstract contract AEDEnhancements is CoreState, ReentrancyGuardUpgradeable, AEDConstants {
    // Events
    event FeatureEnabled(uint256 indexed tokenId, uint8 feature);
    event FeatureRemoved(uint256 indexed tokenId, uint8 feature);
    event FeaturePriceUpdated(uint8 feature, uint256 price);
    event FeaturePurchased(address indexed buyer, uint256 indexed tokenId, uint8 feature, uint256 price);
    event FeaturePayment(address indexed payer, address indexed feeCollector, uint256 amount, uint256 tokenId, uint8 feature);
    event DomainFeaturesUpdated(uint256 indexed tokenId, uint256 features);
    event EnhancementPriceSet(uint8 indexed feature, uint256 price);

    // Errors
    error PriceMustBeGreaterThanZero();
    error InvalidFeature();

    // State
    mapping(uint8 => uint256) public enhancementPrices;
    mapping(uint256 => uint256) public domainFeatures;

    function __AEDEnhancements_init() internal onlyInitializing {
        __ReentrancyGuard_init();
        // Set a default price for an enhancement (example: enabling subdomains for 0.002 ETH)
        enhancementPrices[FEATURE_SUBDOMAINS] = 0.002 ether;
    }

    function getEnhancementPrice(uint8 feature) external view returns (uint256) {
        return enhancementPrices[feature];
    }

    function getDomainFeatures(uint256 tokenId) external view returns (uint256) {
        return domainFeatures[tokenId];
    }

    function purchaseFeature(uint256 tokenId, uint8 feature) external payable nonReentrant {
        require(tx.origin == msg.sender, "Contracts not allowed");
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require((domainFeatures[tokenId] & feature) == 0, "Already enabled");
        require(_isValidFeature(feature), "Invalid feature");
        require(feature != 0 && (feature & (feature - 1)) == 0, "Feature must be a power of two");

        uint256 price = enhancementPrices[feature];
        require(msg.value >= price, "Insufficient payment");
        require(feeCollector != address(0), "Fee collector not set");

        uint256 updatedFeatures;
        unchecked {
            updatedFeatures = domainFeatures[tokenId] | feature;
        }
        require(updatedFeatures >= domainFeatures[tokenId], "Overflow in feature flags");
        domainFeatures[tokenId] = updatedFeatures;
        emit FeatureEnabled(tokenId, feature);
        emit DomainFeaturesUpdated(tokenId, domainFeatures[tokenId]);

        Address.sendValue(payable(feeCollector), price);
        if (msg.value > price) {
            Address.sendValue(payable(msg.sender), msg.value - price);
        }

        emit FeaturePayment(msg.sender, feeCollector, price, tokenId, feature);
        emit FeaturePurchased(msg.sender, tokenId, feature, price);
    }

    function setEnhancementPrice(uint8 feature, uint256 price) public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        if (!_isValidFeature(feature)) revert InvalidFeature();
        if (price == 0) revert PriceMustBeGreaterThanZero();
        enhancementPrices[feature] = price;
        emit EnhancementPriceSet(feature, price);
    }

    function _isValidFeature(uint8 feature) internal pure returns (bool) {
        if (feature == 0 || (feature & (feature - 1)) != 0) {
            return false;
        }
        // Only features defined in constants are allowed
        return feature == FEATURE_PROFILE ||
               feature == FEATURE_REVERSE ||
               feature == FEATURE_SUBDOMAINS ||
               feature == FEATURE_BRIDGE ||
               feature == FEATURE_RECOVERY ||
               feature == FEATURE_METADATA;
    }

    uint256[50] private __gap;
}
