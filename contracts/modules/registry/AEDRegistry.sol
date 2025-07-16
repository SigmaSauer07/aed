// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../modules/base/ModuleBase.sol";
import "../../interfaces/modules/IAEDRegistry.sol";
/**
 * @title AEDRegistry
 * @dev Module for managing Top-Level Domains (TLDs) and domain feature flags.
 * Allows adding/updating TLD pricing, configuring "Bring Your Own Domain" (BYOD) settings,
 * and enabling/disabling feature flags on domains.
 */

abstract contract AEDRegistry is Initializable, ModuleBase, IAEDRegistry {
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
    // mapping(uint256 => mapping(uint8 => bool)) internal activeModules; // Removed: not in AppStorage

    /** @dev Initialize the registry module (sets up default TLDs). */
    function __AEDRegistry_init() internal {
        _setInitialTLDs();
    }

    // TLD management
    function setTLDPrice(string memory tld, uint256 price) external {
        require(_hasRole(TLD_MANAGER_ROLE, msg.sender), "Not authorized");
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
     * @notice Batch set TLD prices.
     * @param tlds Array of TLDs.
     * @param prices Array of prices.
     */
    function batchSetTLDPrices(string[] calldata tlds, uint256[] calldata prices) external {
        require(tlds.length == prices.length, "Length mismatch");
        for (uint256 i = 0; i < tlds.length; ) {
            // Use internal logic to avoid external call
            require(_hasRole(TLD_MANAGER_ROLE, msg.sender), "Not authorized");
            require(bytes(tlds[i]).length > 0, "Invalid TLD");
            AppStorage storage s = LibAppStorage.getStorage();
            uint256 oldPrice = s.tldPrices[tlds[i]];
            s.tldPrices[tlds[i]] = prices[i];
            if (oldPrice == 0) {
                emit TLDAdded(tlds[i], prices[i]);
            } else {
                emit TLDPriceUpdated(tlds[i], oldPrice, prices[i]);
            }
            unchecked { ++i; }
        }
    }

    function setBYODomain(string memory domain, bool allowed) external {
        require(_hasRole(TLD_MANAGER_ROLE, msg.sender), "Not authorized");
        require(bytes(domain).length > 0, "Invalid domain");
        byoDomains[domain] = allowed;
        emit BYODomainConfigured(domain, allowed);
    }

    // Domain feature flags - Gas optimized
    function setFeature(uint256 tokenId, uint256 feature) external {
        require(_hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        AppStorage storage s = LibAppStorage.getStorage();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        
        uint256 currentFeatures = s.domainFeatures[tokenId];
        s.domainFeatures[tokenId] = currentFeatures | feature;
        
        emit FeatureSet(tokenId, uint8(feature));
    }

    /**
     * @notice Batch set features for multiple domains.
     * @param tokenIds Array of token IDs.
     * @param features Array of features.
     */
    function batchSetFeatures(uint256[] calldata tokenIds, uint256[] calldata features) external {
        require(tokenIds.length == features.length, "Length mismatch");
        for (uint256 i = 0; i < tokenIds.length; ) {
            // Use internal logic to avoid external call
            require(_hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
            AppStorage storage s = LibAppStorage.getStorage();
            require(s.owners[tokenIds[i]] != address(0), "Token does not exist");
            require(_isValidFeature(features[i]), "Invalid feature");
            uint256 currentFeatures = s.domainFeatures[tokenIds[i]];
            s.domainFeatures[tokenIds[i]] = currentFeatures | features[i];
            emit FeatureSet(tokenIds[i], uint8(features[i]));
            unchecked { ++i; }
        }
    }

    function removeFeature(uint256 tokenId, uint256 feature) external {
        require(_hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        AppStorage storage s = LibAppStorage.getStorage();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        
        uint256 currentFeatures = s.domainFeatures[tokenId];
        s.domainFeatures[tokenId] = currentFeatures & ~feature;
        
        emit FeatureRemoved(tokenId, uint8(feature));
    }

    function _setFeature(uint256 tokenId, uint256 feature) internal override {
        AppStorage storage s = LibAppStorage.getStorage();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        require(_isValidFeature(feature), "Invalid feature");
        
        uint256 currentFeatures = s.domainFeatures[tokenId];
        s.domainFeatures[tokenId] = currentFeatures | feature;
        emit FeatureSet(tokenId, uint8(feature));
    }
    
    // View functions - Gas optimized
    function getTLDPrice(string calldata tld) external view returns (uint256) {
        return tldPrices[tld];
    }

    function isBYODomain(string calldata domain) external view returns (bool) {
        return byoDomains[domain];
    }

    // Duplicate hasFeature function removed

    function getDomainFeatures(uint256 tokenId) external view returns (uint256) {
        AppStorage storage s = LibAppStorage.getStorage();
        return s.domainFeatures[tokenId];
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

    // Module activation management per domain removed: not supported by AppStorage
}