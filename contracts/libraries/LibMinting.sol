// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";

library LibMinting {
    using LibAppStorage for AppStorage;
    
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event SubdomainCreated(string indexed subdomain, string indexed parent, address indexed owner);
    
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.s();
        
        // Validate inputs
        require(bytes(name).length >= MIN_NAME_LENGTH && bytes(name).length <= MAX_NAME_LENGTH, "Invalid name length");
        require(LibAppStorage.validateDomainName(name), "Invalid domain name");
        require(s.validTlds[tld], "Invalid TLD");
        
        // Create full domain name
        string memory fullDomain = string(abi.encodePacked(name, ".", tld));
        require(!s.domainExists[fullDomain], "Domain already exists");
        
        // Get next token ID
        uint256 tokenId = s.nextTokenId;
        s.nextTokenId++;
        
        // Create domain record
        Domain memory newDomain = Domain({
            name: name,
            tld: tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: s.freeTlds[tld] ? 0 : s.tldPrices[tld],
            expiresAt: 0, // No expiration for now
            feeEnabled: false,
            isSubdomain: false,
            owner: msg.sender
        });
        
        // Store domain data
        s.domains[tokenId] = newDomain;
        s.domainToTokenId[fullDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullDomain;
        s.domainExists[fullDomain] = true;
        
        // Update ERC721 storage
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        
        // Add to user domains
        s.userDomains[msg.sender].push(fullDomain);
        
        // Enable subdomains if requested
        if (enableSubdomains) {
            s.enhancedDomains[fullDomain] = true;
        }
        
        emit DomainRegistered(fullDomain, msg.sender, tokenId);
        return tokenId;
    }
    
    function createSubdomain(
        string calldata label,
        string memory parentDomain
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.s();
        
        // Validate parent domain
        require(s.domainExists[parentDomain], "Parent domain not found");
        require(s.enhancedDomains[parentDomain], "Subdomains not enabled");
        
        // Validate subdomain label
        require(bytes(label).length >= MIN_NAME_LENGTH && bytes(label).length <= MAX_NAME_LENGTH, "Invalid label length");
        require(LibAppStorage.validateDomainName(label), "Invalid subdomain label");
        
        // Create subdomain name
        string memory subdomain = string(abi.encodePacked(label, ".", parentDomain));
        require(!s.domainExists[subdomain], "Subdomain already exists");
        
        // Check subdomain limit
        uint256 parentId = s.domainToTokenId[parentDomain];
        require(s.domains[parentId].subdomainCount < MAX_SUBDOMAINS, "Subdomain limit reached");
        
        // Get next token ID
        uint256 tokenId = s.nextTokenId;
        s.nextTokenId++;
        
        // Create subdomain record
        Domain memory newSubdomain = Domain({
            name: label,
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
        
        // Store subdomain data
        s.domains[tokenId] = newSubdomain;
        s.domainToTokenId[subdomain] = tokenId;
        s.tokenIdToDomain[tokenId] = subdomain;
        s.domainExists[subdomain] = true;
        
        // Update ERC721 storage
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        
        // Add to user domains
        s.userDomains[msg.sender].push(subdomain);
        
        // Update parent domain
        s.domains[parentId].subdomainCount++;
        s.domainSubdomains[parentDomain].push(subdomain);
        
        emit SubdomainCreated(subdomain, parentDomain, msg.sender);
        return tokenId;
    }
    
    function getDomainOwner(string memory domain) internal view returns (address) {
        AppStorage storage s = LibAppStorage.s();
        uint256 tokenId = s.domainToTokenId[domain];
        if (tokenId == 0) return address(0);
        return s.domains[tokenId].owner;
    }
    
    function calculateSubdomainFee(uint256 parentId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.s();
        uint256 subdomainCount = s.domains[parentId].subdomainCount;
        
        // First 2 subdomains are free, then linear pricing
        if (subdomainCount < 2) return 0;
        return (subdomainCount - 1) * 0.1 ether;
    }
    
    function batchRegisterDomains(
        string[] calldata names,
        string[] calldata tlds,
        bool[] calldata enableSubdomains
    ) internal returns (uint256[] memory tokenIds) {
        require(
            names.length == tlds.length && names.length == enableSubdomains.length,
            "Input array length mismatch"
        );
        
        tokenIds = new uint256[](names.length);
        
        for (uint256 i = 0; i < names.length; i++) {
            tokenIds[i] = registerDomain(names[i], tlds[i], enableSubdomains[i]);
        }
        
        return tokenIds;
    }
}
