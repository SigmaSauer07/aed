// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

library LibReverse {
    using LibAppStorage for AppStorage;
    
    event ReverseSet(address indexed addr, string domain);
    event ReverseCleared(address indexed addr);
    
    function setReverse(string calldata domain) internal {
        AppStorage storage s = LibAppStorage.s();
        
        // Verify caller owns the domain
        uint256 tokenId = s.domainToTokenId[domain];
        require(tokenId != 0, "Domain not found");
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
        AppStorage storage s = LibAppStorage.s();
        
        string memory domain = s.reverseRecords[msg.sender];
        require(bytes(domain).length > 0, "No reverse set");
        
        delete s.reverseRecords[msg.sender];
        delete s.reverseOwners[domain];
        
        emit ReverseCleared(msg.sender);
    }
    
    function getReverse(address addr) internal view returns (string memory) {
        return LibAppStorage.s().reverseRecords[addr];
    }
    
    function getReverseOwner(string calldata domain) internal view returns (address) {
        return LibAppStorage.s().reverseOwners[domain];
    }
    
    function hasReverse(address addr) internal view returns (bool) {
        return bytes(LibAppStorage.s().reverseRecords[addr]).length > 0;
    }
    
    function isReverseOwner(string calldata domain, address addr) internal view returns (bool) {
        return LibAppStorage.s().reverseOwners[domain] == addr;
    }
}
