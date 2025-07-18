// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibAppStorage.sol";

library LibValidation {
    using LibAppStorage for AppStorage;
    
    function validateDomainName(string calldata domain) internal pure returns (bool) {
        bytes memory domainBytes = bytes(domain);
        if (domainBytes.length == 0 || domainBytes.length > 63) return false;
        
        for (uint i = 0; i < domainBytes.length; i++) {
            bytes1 char = domainBytes[i];
            if (!(char >= 0x30 && char <= 0x39) && // 0-9
                !(char >= 0x61 && char <= 0x7A) && // a-z
                !(char == 0x2D)) { // hyphen
                return false;
            }
        }
        
        // Cannot start or end with hyphen
        if (domainBytes[0] == 0x2D || domainBytes[domainBytes.length - 1] == 0x2D) {
            return false;
        }
        
        return true;
    }
    
    function validateTLD(string calldata tld) internal pure returns (bool) {
        bytes memory tldBytes = bytes(tld);
        if (tldBytes.length == 0 || tldBytes.length > 10) return false;
        
        for (uint i = 0; i < tldBytes.length; i++) {
            bytes1 char = tldBytes[i];
            if (!(char >= 0x61 && char <= 0x7A) && // a-z
                !(char >= 0x30 && char <= 0x39)) { // 0-9
                return false;
            }
        }
        
        return true;
    }
    
    function isAuthorized(uint256 tokenId, address user) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        address owner = s.owners[tokenId];
        if (owner == user) return true;
        if (s.admins[user]) return true;
        if (s.tokenApprovals[tokenId] == user) return true;
        if (s.operatorApprovals[owner][user]) return true;
        
        return false;
    }
}