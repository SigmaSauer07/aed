// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";

/// @title Library to store and retrieve the AppStorage structure.
/// @author SigmaSauer07 <https://github.com/SigmaSauer07>
/// @notice This library provides a way to access and modify the AppStorage structure in a secure manner.
library LibAppStorage {
    bytes32 constant STORAGE_POSITION = keccak256("aed.app.storage");
    
    /// @dev Returns a reference to the AppStorage struct stored at the designated position.
    function appStorage() internal pure returns (AppStorage storage storageRef) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            storageRef.slot := position
        }
    }
    
    /// @dev Helper function to get storage reference
    function s() internal pure returns (AppStorage storage) {
        return appStorage();
    }
    
    /// @dev Check if a domain exists
    function domainExists(string memory domain) internal view returns (bool) {
        return s().domainExists[domain];
    }
    
    /// @dev Get domain owner
    function getDomainOwner(string memory domain) internal view returns (address) {
        return s().domains[s().domainToTokenId[domain]].owner;
    }
    
    /// @dev Check if TLD supports subdomains
    function withSubdomains(string memory tld, bool checkValid, bool checkFree) internal view returns (bool) {
        if (checkValid && !s().validTlds[tld]) return false;
        if (checkFree && s().freeTlds[tld]) return true;
        return true; // Default to true for paid TLDs
    }
    
    /// @dev Normalize domain name
    function normalizeDomain(string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }
    
    /// @dev Validate domain name
    function validateDomainName(string memory name) internal pure returns (bool) {
        bytes memory nameBytes = bytes(name);
        if (nameBytes.length < 1 || nameBytes.length > 63) return false;
        
        for (uint256 i = 0; i < nameBytes.length; i++) {
            bytes1 char = nameBytes[i];
            if (char < 0x61 || char > 0x7a) { // Not lowercase a-z
                if (char < 0x30 || char > 0x39) { // Not 0-9
                    if (char != 0x2d) { // Not hyphen
                        return false;
                    }
                }
            }
        }
        return true;
    }
    
    /// @dev Check if address is admin
    function isAdmin(address account) internal view returns (bool) {
        return s().admins[account];
    }
    
    /// @dev Check if contract is paused
    function isPaused() internal view returns (bool) {
        return s().paused;
    }
    
    /// @dev Get fee collector address
    function getFeeCollector() internal view returns (address) {
        return s().feeCollector;
    }
    
    /// @dev Get TLD price
    function getTldPrice(string memory tld) internal view returns (uint256) {
        return s().tldPrices[tld];
    }
    
    /// @dev Check if TLD is free
    function isFreeTld(string memory tld) internal view returns (bool) {
        return s().freeTlds[tld];
    }
    
    /// @dev Check if TLD is valid
    function isValidTld(string memory tld) internal view returns (bool) {
        return s().validTlds[tld];
    }
    
    /// @dev Get enhancement price
    function getEnhancementPrice(string memory enhancement) internal view returns (uint256) {
        return s().enhancementPrices[enhancement];
    }
    
    /// @dev Get next token ID
    function getNextTokenId() internal view returns (uint256) {
        return s().nextTokenId;
    }
    
    /// @dev Increment next token ID
    function incrementTokenId() internal {
        s().nextTokenId++;
    }
    
    /// @dev Add revenue
    function addRevenue(uint256 amount) internal {
        s().totalRevenue += amount;
    }
    
    /// @dev Get total revenue
    function getTotalRevenue() internal view returns (uint256) {
        return s().totalRevenue;
    }
}