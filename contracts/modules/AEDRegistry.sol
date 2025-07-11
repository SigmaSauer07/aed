// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../core/CoreState.sol";
import "../core/AEDConstants.sol";
/**
 * @title AEDRegistry
 * @dev Module for managing Top-Level Domains (TLDs) and domain feature flags.
 * Allows adding/updating TLD pricing, configuring "Bring Your Own Domain" (BYOD) settings,
 * and enabling/disabling feature flags on domains.
 */

abstract contract AEDRegistry is Initializable, CoreState, AEDConstants {
    // Events
    event TLDAdded(string indexed tld, uint256 price);
    event TLDPriceUpdated(string indexed tld, uint256 oldPrice, uint256 newPrice);
    event BYODomainConfigured(string indexed domain, bool allowed);
    event FeatureSet(uint256 indexed tokenId, uint8 feature);
    event FeatureRemoved(uint256 indexed tokenId, uint8 feature);
    event ModuleToggled(uint256 indexed tokenId, AEDModule module, bool enabled);

    // State
    mapping(string => uint256) internal tldPrices;
    mapping(string => bool) internal byoDomains;
    mapping(uint256 => mapping(uint8 => bool)) internal activeModules;

    /** @dev Initialize the registry module (sets up default TLDs). */
    function __AEDRegistry_init() internal {
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

    // Domain feature flags - Gas optimized
    function setFeature(uint256 tokenId, uint256 feature) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        require(_exists(tokenId), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        
        // Gas optimization: Use storage pointer to avoid multiple SLOAD/SSTORE
        uint256 currentFeatures = domainFeatures[tokenId];
        domainFeatures[tokenId] = currentFeatures | feature;
        
        emit FeatureSet(tokenId, uint8(feature));
    }

    function removeFeature(uint256 tokenId, uint256 feature) external {
        require(hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        require(_exists(tokenId), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        
        // Gas optimization: Use storage pointer
        uint256 currentFeatures = domainFeatures[tokenId];
        domainFeatures[tokenId] = currentFeatures & ~feature;
        
        emit FeatureRemoved(tokenId, uint8(feature));
    }

    function _setFeature(uint256 tokenId, uint256 feature) internal {
        require(_exists(tokenId), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        
        // Gas optimization: Use storage pointer
        uint256 currentFeatures = domainFeatures[tokenId];
        domainFeatures[tokenId] = currentFeatures | feature;
        emit FeatureSet(tokenId, uint8(feature));
    }
    
    // View functions - Gas optimized
    function getTLDPrice(string calldata tld) external view returns (uint256) {
        return tldPrices[tld];
    }

    function isBYODomain(string calldata domain) external view returns (bool) {
        return byoDomains[domain];
    }

    function hasFeature(uint256 tokenId, uint256 feature) external view returns (bool) {
        // Gas optimization: Single SLOAD operation
        return (domainFeatures[tokenId] & feature) != 0;
    }

    function getDomainFeatures(uint256 tokenId) external view returns (uint256) {
        return domainFeatures[tokenId];
    }

    /**
     * @dev Gas optimized function to check if a TLD is free
     * @param tld The TLD to check
     * @return bool True if the TLD is free, false otherwise
     */
    function isFreeTLD(string calldata tld) public pure returns (bool) {
        // Gas optimization: Use calldata instead of memory for read-only string parameters
        // Gas optimization: Calculate hash only once
        bytes32 tldHash = keccak256(bytes(tld));
        
        // Gas optimization: Use single return with || operators
        return (tldHash == FREE_TLD_AED || tldHash == FREE_TLD_ALSA || tldHash == FREE_TLD_07);
    }

    /**
     * @dev Gas optimized function to get supported TLDs
     * @return Array of supported TLDs
     */
    function getSupportedTLDs() external pure returns (string[] memory) {
        // Gas optimization: Pre-allocate memory array with exact size
        string[] memory tlds = new string[](3);
        
        // Gas optimization: Direct assignment without intermediate variables
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

    function _isValidFeature(uint256 feature) internal pure returns (bool) {
        // Gas optimization: Bitwise operations are more efficient
        // Check if feature is a power of 2 and not zero
        if (feature == 0 || (feature & (feature - 1)) != 0) { 
            return false;  // not a power of two or is zero
        }
        return feature <= FEATURE_ALL; 
    }

    // Module activation management per domain (toggle modules on/off for specific domains)
    function setModuleActive(uint256 tokenId, AEDModule  module, bool enabled) external {
        // Only token owner or admin can activate/deactivate modules for that tokenId
        require(msg.sender == ownerOf(tokenId) || hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        activeModules[tokenId][uint8(module)] = enabled;
        emit ModuleToggled(tokenId, module, enabled);
    }

    function isModuleActive(uint256 tokenId, AEDModule module) public view returns (bool) {
        return activeModules[tokenId][uint8(module)];
    }
}