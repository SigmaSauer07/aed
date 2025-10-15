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
    event FeatureEnabled(uint256 indexed tokenId, uint256 feature);
    event FeatureDisabled(uint256 indexed tokenId, uint256 feature);
    event ExternalDomainLinked(string indexed domain, uint256 indexed tokenId);
    event ExternalDomainUnlinked(string indexed domain);
    
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
    
    function enableFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        
        s.domainFeatures[tokenId] |= feature;
        emit FeatureEnabled(tokenId, feature);
    }
    
    function disableFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] != address(0), "Token does not exist");
        
        s.domainFeatures[tokenId] &= ~feature;
        emit FeatureDisabled(tokenId, feature);
    }
    
    function hasFeature(uint256 tokenId, uint256 feature) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        return (s.domainFeatures[tokenId] & feature) != 0;
    }
    
    function linkExternalDomain(string calldata externalDomain, uint256 tokenId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        require(!s.domainExists[externalDomain], "Domain name conflict");
        
        // Store the link in future storage
        s.futureStringString[externalDomain] = s.tokenIdToDomain[tokenId];
        
        emit ExternalDomainLinked(externalDomain, tokenId);
    }
    
    function unlinkExternalDomain(string calldata externalDomain) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(bytes(s.futureStringString[externalDomain]).length > 0, "Domain not linked");
        
        delete s.futureStringString[externalDomain];
        emit ExternalDomainUnlinked(externalDomain);
    }
    
    function isExternalDomainLinked(string calldata externalDomain) internal view returns (bool) {
        return bytes(LibAppStorage.appStorage().futureStringString[externalDomain]).length > 0;
    }
    
    function getLinkedToken(string calldata externalDomain) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        string memory linkedDomain = s.futureStringString[externalDomain];
        require(bytes(linkedDomain).length > 0, "Domain not linked");
        
        return s.domainToTokenId[linkedDomain];
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
