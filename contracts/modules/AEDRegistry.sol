// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/CoreState.sol";
import "../core/AEDConstants.sol";
import "./AEDAdmin.sol";

/**
 * @title AEDRegistry
 * @dev Module for managing Top-Level Domains (TLDs) and domain feature flags.
 * Allows adding/updating TLD pricing, configuring "Bring Your Own Domain" (BYOD) settings,
 * and enabling/disabling feature flags on domains.
 */
abstract contract AEDRegistry is CoreState, AEDConstants {
    // Events
    event TLDAdded(string indexed tld, uint256 price);
    event TLDPriceUpdated(string indexed tld, uint256 oldPrice, uint256 newPrice);
    event BYODomainConfigured(string indexed domain, bool allowed);
    event FeatureSet(uint256 indexed tokenId, uint8 feature);
    event FeatureRemoved(uint256 indexed tokenId, uint8 feature);

    // State
    mapping(string => uint256) internal tldPrices;
    mapping(string => bool) internal byoDomains;
    mapping(uint256 => uint8) internal domainFeatures;
    mapping(uint256 => mapping(uint8 => bool)) internal activeModules;  // tracks active modules per domain

    /** @dev Initialize the registry module (sets up default TLDs). */
    function __AEDRegistry_init() internal onlyInitializing {
        _setInitialTLDs();
    }

    // TLD management
    function setTLDPrice(string memory tld, uint256 price) external {
        require(hasRole(TLD_MANAGER_ROLE, msg.sender), "Not authorized");
        require(bytes(tld).length > 0, "Invalid TLD");
        uint256 oldPrice = tldPrices[tld];
        tldPrices[tld] = price;
        if (oldPrice == 0) {
            emit TLDAdded(tld, price);
        } else {
            emit TLDPriceUpdated(tld, oldPrice, price);
        }
    }

    function setBYODomain(string memory domain, bool allowed) external {
        require(hasRole(TLD_MANAGER_ROLE, msg.sender), "Not authorized");
        require(bytes(domain).length > 0, "Invalid domain");
        byoDomains[domain] = allowed;
        emit BYODomainConfigured(domain, allowed);
    }

    // Domain feature flags
    function setFeature(uint256 tokenId, uint8 feature) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        require(_exists(tokenId), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        domainFeatures[tokenId] |= feature;
        emit FeatureSet(tokenId, feature);
    }

    function removeFeature(uint256 tokenId, uint8 feature) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        require(_exists(tokenId), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        domainFeatures[tokenId] &= ~feature;
        emit FeatureRemoved(tokenId, feature);
    }

    // View functions
    function getTLDPrice(string memory tld) external view returns (uint256) {
        return tldPrices[tld];
    }

    function isBYODomain(string memory domain) external view returns (bool) {
        return byoDomains[domain];
    }

    function hasFeature(uint256 tokenId, uint8 feature) external view returns (bool) {
        return (domainFeatures[tokenId] & feature) != 0;
    }

    function getDomainFeatures(uint256 tokenId) external view returns (uint8) {
        return domainFeatures[tokenId];
    }

    function isFreeTLD(string memory tld) public pure returns (bool) {
        bytes32 tldHash = keccak256(bytes(tld));
        return (tldHash == FREE_TLD_AED || tldHash == FREE_TLD_ALSA || tldHash == FREE_TLD_07);
    }

    function getSupportedTLDs() external pure returns (string[] memory) {
        string[] memory tlds = new string[](3);
        tlds[0] = "aed";
        tlds[1] = "alsa";
        tlds[2] = "07";
        return tlds;
    }

    // Internal helpers
    function _setInitialTLDs() internal {
        // Free TLDs
        tldPrices["aed"] = 0;
        tldPrices["alsa"] = 0;
        tldPrices["07"] = 0;
        // Paid TLDs
        tldPrices["alsania"] = 0.001 ether;
        tldPrices["fx"] = 0.001 ether;
        tldPrices["echo"] = 0.001 ether;
        // BYO domain defaults (allowed for all initial TLDs)
        byoDomains["aed"] = true;
        byoDomains["alsa"] = true;
        byoDomains["07"] = true;
        byoDomains["alsania"] = true;
        byoDomains["fx"] = true;
        byoDomains["echo"] = true;
    }

    function _isValidFeature(uint8 feature) internal pure returns (bool) {
        if (feature == 0 || (feature & (feature - 1)) != 0) { 
            return false;  // not a power of two or is zero
        }
        return feature <= FEATURE_ALL;
    }

    // Module activation management per domain (toggle modules on/off for specific domains)
    function setModuleActive(uint256 tokenId, AEDModule module, bool enabled) external {
        // Only token owner or admin can activate/deactivate modules for that tokenId
        require(msg.sender == ownerOf(tokenId) || hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        activeModules[tokenId][uint8(module)] = enabled;
    }

    function isModuleActive(uint256 tokenId, AEDModule module) public view returns (bool) {
        return activeModules[tokenId][uint8(module)];
    }
}
