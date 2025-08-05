// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

library LibReverse {
    using LibAppStorage for AppStorage;
    
    event ReverseSet(address indexed addr, string domain);
    event ReverseCleared(address indexed addr);
    
    function setReverse(string calldata domain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Verify caller owns the domain
        uint256 tokenId = s.domainToTokenId[domain];
        require(s.owners[tokenId] == msg.sender, "Not domain owner");
        
        // Clear previous reverse if exists
        string memory oldReverse = s.reverseRecords[msg.sender];
        if (bytes(oldReverse).length > 0) {
            delete s.reverseOwners[oldReverse];
        }
        
        // Set new reverse
        s.reverseRecords[msg.sender] = domain;
        s.reverseOwners[domain] = msg.sender;
        
        emit ReverseSet(msg.sender, domain);
    }
    
    function clearReverse() internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        string memory domain = s.reverseRecords[msg.sender];
        require(bytes(domain).length > 0, "No reverse set");
        
        delete s.reverseRecords[msg.sender];
        delete s.reverseOwners[domain];
        
        emit ReverseCleared(msg.sender);
    }
    
    function getReverse(address addr) internal view returns (string memory) {
        return LibAppStorage.appStorage().reverseRecords[addr];
    }
    
    function getReverseOwner(string calldata domain) internal view returns (address) {
        return LibAppStorage.appStorage().reverseOwners[domain];
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        address owner = s.owners[tokenId];
        return (spender == owner || 
                s.tokenApprovals[tokenId] == spender || 
                s.operatorApprovals[owner][spender]);
    }
    
    function _exists(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.appStorage().owners[tokenId] != address(0);
    }
}
