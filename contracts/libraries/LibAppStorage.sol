// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";

/**
 * @title LibAppStorage
 * @dev Library to access the AppStorage structure using Diamond Storage pattern
 * @author SigmaSauer07
 */
library LibAppStorage {
    bytes32 constant STORAGE_POSITION = keccak256("aed.app.storage");
    
    /**
     * @dev Returns a reference to the AppStorage struct
     * @return s The AppStorage struct
     */
    function appStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
    
    /**
     * @dev Checks if a token exists
     * @param tokenId The token ID to check
     * @return exists True if token exists
     */
    function tokenExists(uint256 tokenId) internal view returns (bool) {
        return appStorage().owners[tokenId] != address(0);
    }
    
    /**
     * @dev Gets the owner of a token
     * @param tokenId The token ID
     * @return owner The owner address
     */
    function getTokenOwner(uint256 tokenId) internal view returns (address) {
        return appStorage().owners[tokenId];
    }
    
    /**
     * @dev Gets the balance of an address
     * @param owner The owner address
     * @return balance The token balance
     */
    function getBalance(address owner) internal view returns (uint256) {
        return appStorage().balances[owner];
    }
    
    /**
     * @dev Checks if an address has a specific role
     * @param role The role to check
     * @param account The account to check
     * @return hasRole True if account has role
     */
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return appStorage().roles[role][account];
    }
    
    /**
     * @dev Checks if the contract is paused
     * @return paused True if contract is paused
     */
    function isPaused() internal view returns (bool) {
        return appStorage().paused;
    }
    
    /**
     * @dev Gets the fee collector address
     * @return collector The fee collector address
     */
    function getFeeCollector() internal view returns (address) {
        return appStorage().feeCollector;
    }
    
    /**
     * @dev Gets the next available token ID
     * @return tokenId The next token ID
     */
    function getNextTokenId() internal view returns (uint256) {
        return appStorage().nextTokenId;
    }
    
    /**
     * @dev Increments and returns the next token ID
     * @return tokenId The new token ID
     */
    function incrementTokenId() internal returns (uint256) {
        AppStorage storage s = appStorage();
        return ++s.nextTokenId;
    }
    
    /**
     * @dev Checks if a domain exists
     * @param domain The domain name
     * @return exists True if domain exists
     */
    function domainExists(string memory domain) internal view returns (bool) {
        return appStorage().domainExists[domain];
    }
    
    /**
     * @dev Gets the token ID for a domain
     * @param domain The domain name
     * @return tokenId The token ID (0 if not found)
     */
    function getDomainTokenId(string memory domain) internal view returns (uint256) {
        return appStorage().domainToTokenId[domain];
    }
    
    /**
     * @dev Gets the domain name for a token ID
     * @param tokenId The token ID
     * @return domain The domain name
     */
    function getTokenDomain(uint256 tokenId) internal view returns (string memory) {
        return appStorage().tokenIdToDomain[tokenId];
    }
    
    /**
     * @dev Checks if a TLD is valid
     * @param tld The TLD to check
     * @return valid True if TLD is valid
     */
    function isValidTLD(string memory tld) internal view returns (bool) {
        return appStorage().validTlds[tld];
    }
    
    /**
     * @dev Checks if a TLD is free
     * @param tld The TLD to check
     * @return free True if TLD is free
     */
    function isFreeTLD(string memory tld) internal view returns (bool) {
        return appStorage().freeTlds[tld];
    }
    
    /**
     * @dev Gets the price for a TLD
     * @param tld The TLD
     * @return price The TLD price
     */
    function getTLDPrice(string memory tld) internal view returns (uint256) {
        return appStorage().tldPrices[tld];
    }
    
    /**
     * @dev Gets the enhancement price for a feature
     * @param feature The feature name
     * @return price The enhancement price
     */
    function getEnhancementPrice(string memory feature) internal view returns (uint256) {
        return appStorage().enhancementPrices[feature];
    }
    
    /**
     * @dev Gets the features enabled for a domain
     * @param tokenId The token ID
     * @return features The enabled features bitmask
     */
    function getDomainFeatures(uint256 tokenId) internal view returns (uint256) {
        return appStorage().domainFeatures[tokenId];
    }
    
    /**
     * @dev Gets the total revenue collected
     * @return revenue The total revenue
     */
    function getTotalRevenue() internal view returns (uint256) {
        return appStorage().totalRevenue;
    }
    
    /**
     * @dev Gets the reverse record for an address
     * @param addr The address
     * @return domain The primary domain
     */
    function getReverseRecord(address addr) internal view returns (string memory) {
        return appStorage().reverseRecords[addr];
    }
    
    /**
     * @dev Gets the domains owned by an address
     * @param owner The owner address
     * @return domains Array of domain names
     */
    function getUserDomains(address owner) internal view returns (string[] memory) {
        return appStorage().userDomains[owner];
    }
}