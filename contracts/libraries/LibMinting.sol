// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../libraries/LibAppStorage.sol";
import "../core/AppStorage.sol";

library LibMinting {
    using LibAppStorage for AppStorage;
    
    event DomainRegistered(string domain, address owner, uint256 tokenId);
    
    function registerDomain(
        string memory domain,
        string memory tld,
        bool withEnhancements
    ) internal {
        AppStorage storage s = LibAppStorage.getStorage();
        
        // All logic here - no storage in module contracts
        string memory fullDomain = string(abi.encodePacked(domain, ".", tld));
        require(!s.domainExists[fullDomain], "Domain exists");
        
        uint256 tokenId = s.nextTokenId++;
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        s.domainToTokenId[fullDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullDomain;
        s.domainExists[fullDomain] = true;
        s.userDomains[msg.sender].push(fullDomain);
        
        if (withEnhancements) {
            s.enhancedDomains[fullDomain] = true;
        }
        
        emit DomainRegistered(fullDomain, msg.sender, tokenId);
    }
    
    function getDomainOwner(string memory domain)
        internal
        view
        returns (address)
    {
        AppStorage storage s = LibAppStorage.getStorage();
        uint256 tokenId = s.domainToTokenId[domain];
        return s.owners[tokenId];
    }
}