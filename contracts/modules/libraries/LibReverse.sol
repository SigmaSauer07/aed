// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibAppStorage.sol";

library LibReverse {
    using LibAppStorage for AppStorage;
    
    event ReverseRecordSet(address indexed owner, string domain);
    
    function setReverseRecord(string calldata domain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        uint256 tokenId = s.domainToTokenId[domain];
        require(s.owners[tokenId] == msg.sender, "Not domain owner");
        
        s.reverseRecords[msg.sender] = domain;
        s.reverseOwners[domain] = msg.sender;
        
        emit ReverseRecordSet(msg.sender, domain);
    }
    
    function getReverseRecord(address owner) internal view returns (string memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.reverseRecords[owner];
    }
    
    function clearReverseRecord() internal {
        AppStorage storage s = LibAppStorage.appStorage();
        
        string memory currentDomain = s.reverseRecords[msg.sender];
        if (bytes(currentDomain).length > 0) {
            delete s.reverseRecords[msg.sender];
            delete s.reverseOwners[currentDomain];
        }
    }
}