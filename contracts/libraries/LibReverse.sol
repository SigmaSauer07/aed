// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "./LibAppStorage.sol";

library LibReverse {
    using LibAppStorage for AppStorage;
    
    event ReverseRecordSet(address indexed addr, string indexed domain);
    event ReverseRecordCleared(address indexed addr, string indexed domain);
    
    /**
     * @dev Sets the reverse record for the caller
     * @param domain The domain to set as reverse record
     */
    function setReverseRecord(string calldata domain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Verify the caller owns the domain
        uint256 tokenId = s.domainToTokenId[domain];
        require(tokenId != 0, "Domain not found");
        require(s.owners[tokenId] == msg.sender, "Not domain owner");
        
        // Clear previous reverse record if exists
        string memory oldDomain = s.reverseRecords[msg.sender];
        if (bytes(oldDomain).length > 0) {
            delete s.reverseOwners[oldDomain];
        }
        
        // Set new reverse record
        s.reverseRecords[msg.sender] = domain;
        s.reverseOwners[domain] = msg.sender;
        
        emit ReverseRecordSet(msg.sender, domain);
    }
    
    /**
     * @dev Clears the reverse record for the caller
     */
    function clearReverseRecord() internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        string memory domain = s.reverseRecords[msg.sender];
        require(bytes(domain).length > 0, "No reverse record set");
        
        // Clear reverse record
        delete s.reverseRecords[msg.sender];
        delete s.reverseOwners[domain];
        
        emit ReverseRecordCleared(msg.sender, domain);
    }
}