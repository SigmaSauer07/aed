// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/CoreState.sol";
import "../core/AEDConstants.sol";
import "./AEDAdmin.sol";


/**
 * @title AEDRegistry
 * @dev Registry functions for TLD management and feature configuration
 * @dev This contract manages top-level domains and domain features
 */
abstract contract AEDRegistry is CoreState, AEDConstants {
    
    // ============ EVENTS ============
    event TLDAdded(string indexed tld, uint256 price);
    event TLDPriceUpdated(string indexed tld, uint256 oldPrice, uint256 newPrice);
    event BYODomainConfigured(string indexed domain, bool allowed);
    event FeatureSet(uint256 indexed tokenId, uint8 features);
    event FeatureRemoved(uint256 indexed tokenId, uint8 features);

    /**
     * @dev Initialize the registry module
     */
    function __AEDRegistry_init() internal {
        // Set initial free TLDs
        _setInitialTLDs();
    }

    /**
     * @dev Set TLD price
     * @param tld The TLD to set price for
     * @param price The price in wei
     */
    function setTLDPrice(string memory tld, uint256 price) external hasRole(TLD_MANAGER_ROLE) {
        require(bytes(tld).length > 0, "Invalid TLD");
        
        uint256 oldPrice = tldPrices[tld];
        tldPrices[tld] = price;
        
        if (oldPrice == 0) {
            emit TLDAdded(tld, price);
        } else {
            emit TLDPriceUpdated(tld, oldPrice, price);
        }
    }

    /**
     * @dev Configure BYO (Bring Your Own) domain
     * @param domain The domain to configure
     * @param allowed Whether subdomains are allowed
     */
    function setBYODomain(string memory domain, bool allowed) external hasRole(TLD_MANAGER_ROLE) {
        require(bytes(domain).length > 0, "Invalid domain");
        
        byoDomains[domain] = allowed;
        emit BYODomainConfigured(domain, allowed);
    }

    /**
     * @dev Set feature for a domain
     * @param tokenId The token ID
     * @param feature The feature to set
     */
    function setFeature(uint256 tokenId, uint8 feature) external hasRole(ADMIN_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        
        domainFeatures[tokenId] |= feature;
        emit FeatureSet(tokenId, feature);
    }

    /**
     * @dev Remove feature from a domain
     * @param tokenId The token ID
     * @param feature The feature to remove
     */
    function removeFeature(uint256 tokenId, uint8 feature) external hasRole(ADMIN_ROLE) {
        require(_exists(tokenId), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        
        domainFeatures[tokenId] &= ~feature;
        emit FeatureRemoved(tokenId, feature);
    }

    /**
     * @dev Get TLD price
     * @param tld The TLD to check
     * @return The price in wei
     */
    function getTLDPrice(string memory tld) external view returns (uint256) {
        return tldPrices[tld];
    }

    /**
     * @dev Check if domain allows subdomains
     * @param domain The domain to check
     * @return True if subdomains are allowed
     */
    function isBYODomain(string memory domain) external view returns (bool) {
        return byoDomains[domain];
    }

    /**
     * @dev Check if domain has a specific feature
     * @param tokenId The token ID
     * @param feature The feature to check
     * @return True if the feature is enabled
     */
    function hasFeature(uint256 tokenId, uint8 feature) external view returns (bool) {
        return (domainFeatures[tokenId] & feature) != 0;
    }

    /**
     * @dev Get all features for a domain
     * @param tokenId The token ID
     * @return The feature flags
     */
    function getDomainFeatures(uint256 tokenId) external view returns (uint8) {
        return domainFeatures[tokenId];
    }

    /**
     * @dev Check if TLD is free
     * @param tld The TLD to check
     * @return True if the TLD is free
     */
    function isFreeTLD(string memory tld) public pure returns (bool) {
        bytes32 tldHash = keccak256(bytes(tld));
        return 
            tldHash == FREE_TLD_AED ||
            tldHash == FREE_TLD_ALSA ||
            tldHash == FREE_TLD_07;
    }

    /**
     * @dev Get all supported TLDs (view function for frontend)
     * @return Array of supported TLD strings
     */
    function getSupportedTLDs() external pure returns (string[] memory) {
        string[] memory tlds = new string[](3);
        tlds[0] = "aed";
        tlds[1] = "alsa";
        tlds[2] = "07";
        return tlds;
    }

    // ============ INTERNAL FUNCTIONS ============

    /**
     * @dev Set initial TLD prices
     */
    function _setInitialTLDs() internal {
        // Free TLDs
        tldPrices["aed"] = 0;
        tldPrices["alsa"] = 0;
        tldPrices["07"] = 0;
        
        // Paid TLDs
        tldPrices["alsania"] = 0.001 ether;
        tldPrices["fx"] = 0.001 ether;
        tldPrices["echo"] = 0.001 ether;
        
        // Configure BYO domains
        byoDomains["aed"] = true;
        byoDomains["alsa"] = true;
        byoDomains["07"] = true;
        byoDomains["alsania"] = true;
        byoDomains["fx"] = true;
        byoDomains["echo"] = true;
    }

    /**
     * @dev Validate feature flag
     * @param feature The feature to validate
     * @return True if valid
     */
    function _isValidFeature(uint8 feature) internal pure returns (bool) {
        if (feature == 0 || (feature & (feature - 1)) != 0) {
            return false;
        }
        return feature <= FEATURE_ALL;
    }

    /**
     * @dev Set feature internally
     * @param tokenId The token ID
     * @param feature The feature to set
     */
    function _setFeature(uint256 tokenId, uint8 feature) internal {
        domainFeatures[tokenId] |= feature;
        emit FeatureSet(tokenId, feature);
    }

    /**
     * @dev Remove feature internally
     * @param tokenId The token ID
     * @param feature The feature to remove
     */
    function _removeFeature(uint256 tokenId, uint8 feature) internal {
        domainFeatures[tokenId] &= ~feature;
        emit FeatureRemoved(tokenId, feature);
    }

    mapping(uint256 => mapping(uint8 => bool)) internal activeModules;

    function setModuleActive(uint256 tokenId, AEDModule module, bool enabled) external onlyOwnerOrAdmin(tokenId) {
        activeModules[tokenId][uint8(module)] = enabled;
    }

    function isModuleActive(uint256 tokenId, AEDModule module) public view returns (bool) {
        return activeModules[tokenId][uint8(module)];
    }
}