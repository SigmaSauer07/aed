// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibAppStorage.sol";
import "../../core/AEDConstants.sol";

library LibMinting {
    using LibAppStorage for AppStorage;
    
    event DomainRegistered(string domain, address owner, uint256 tokenId);
    event SubdomainCreated(string subdomain, string parentDomain, address owner);
    
    function registerDomain(
        string calldata domain,
        string calldata tld,
        bool withEnhancements
    ) internal returns (uint256 tokenId) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        string memory fullDomain = string(abi.encodePacked(domain, ".", tld));
        require(!s.domainExists[fullDomain], "Domain exists");
        require(_isValidTLD(s, tld), "Invalid TLD");
        
        tokenId = s.nextTokenId++;
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        s.domainToTokenId[fullDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullDomain;
        s.domainExists[fullDomain] = true;
        s.userDomains[msg.sender].push(fullDomain);
        
        // Initialize domain struct
        s.domains[tokenId] = Domain({
            name: domain,
            tld: tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: false,
            owner: msg.sender
        });
        
        if (withEnhancements) {
            s.enhancedDomains[fullDomain] = true;
            s.domainFeatures[tokenId] |= AEDConstants.FEATURE_SUBDOMAINS();
        }
        
        emit DomainRegistered(fullDomain, msg.sender, tokenId);
    }
    
    function createSubdomain(
        string calldata subdomain,
        string calldata parentDomain
    ) internal returns (uint256 tokenId) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        uint256 parentTokenId = s.domainToTokenId[parentDomain];
        require(s.owners[parentTokenId] == msg.sender, "Not parent owner");
        require(s.enhancedDomains[parentDomain], "Parent not enhanced");
        
        string memory fullSubdomain = string(abi.encodePacked(subdomain, ".", parentDomain));
        require(!s.domainExists[fullSubdomain], "Subdomain exists");
        
        tokenId = s.nextTokenId++;
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        s.domainToTokenId[fullSubdomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullSubdomain;
        s.domainExists[fullSubdomain] = true;
        s.domainSubdomains[parentDomain].push(fullSubdomain);
        s.subdomainCounts[parentDomain]++;
        
        // Initialize subdomain struct
        s.domains[tokenId] = Domain({
            name: subdomain,
            tld: parentDomain,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: true,
            owner: msg.sender
        });
        
        emit SubdomainCreated(fullSubdomain, parentDomain, msg.sender);
    }
    
    function getDomainOwner(string calldata domain) internal view returns (address) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 tokenId = s.domainToTokenId[domain];
        return s.owners[tokenId];
    }
    
    function normalizeDomain(string calldata domain) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(domain));
    }
    
    function _isValidTLD(AppStorage storage s, string calldata tld) internal view returns (bool) {
        return s.validTlds[tld];
    }
}
