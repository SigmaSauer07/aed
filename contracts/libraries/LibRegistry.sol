// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

/// @title Library for managing registry of addresses and their associated data.
/// @author SigmaSauer07 <https://github.com/SigmaSauer07>
/// @notice This library provides a simple way to store and retrieve data associated with an address in the registry.
library LibRegistry {
    using LibAppStorage for AppStorage;
    
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event RegistryUpdated(string indexed key, address indexed value);
    
    function registerDomain(
        string calldata name,
        string calldata tld,
        address owner
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        string memory fullDomain = string(abi.encodePacked(name, ".", tld));
        require(!s.domainExists[fullDomain], "Domain already exists");
        require(s.validTlds[tld], "Invalid TLD");
        
        uint256 tokenId = s.nextTokenId++;
        
        // Store domain mappings
        s.domainToTokenId[fullDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullDomain;
        s.domainExists[fullDomain] = true;
        s.owners[tokenId] = owner;
        s.balances[owner]++;
        s.userDomains[owner].push(fullDomain);
        
        // Initialize domain struct
        s.domains[tokenId] = Domain({
            name: name,
            tld: tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: false,
            owner: owner
        });
        
        emit DomainRegistered(fullDomain, owner, tokenId);
        return tokenId;
    }
    
    function updateRegistry(string calldata key, address value) internal {
        emit RegistryUpdated(key, value);
    }
    
    function getDomainInfo(string calldata domain) internal view returns (Domain memory) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 tokenId = s.domainToTokenId[domain];
        require(tokenId != 0, "Domain not found");
        return s.domains[tokenId];
    }
    
    function isDomainAvailable(string calldata domain) internal view returns (bool) {
        return !LibAppStorage.appStorage().domainExists[domain];
    }
}
