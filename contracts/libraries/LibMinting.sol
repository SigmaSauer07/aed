// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "./LibValidation.sol";
import "./LibAppStorage.sol";

library LibMinting {
    using LibAppStorage for AppStorage;
    
    // Constants from AEDConstants (hardcoded since it's a contract)
    uint256 constant MIN_NAME_LENGTH = 1;
    uint256 constant MAX_NAME_LENGTH = 63;
    uint256 constant MAX_SUBDOMAINS = 20;
    uint256 constant FEATURE_SUBDOMAINS = 1 << 0;
    
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event SubdomainCreated(string indexed subdomain, string indexed parent, address indexed owner, uint256 tokenId);
    
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Validate inputs
        require(bytes(name).length >= MIN_NAME_LENGTH && 
                bytes(name).length <= MAX_NAME_LENGTH, "Invalid name length");
        require(s.validTlds[tld], "Invalid TLD");
        
        // Normalize and check domain availability
        string memory normalizedName = _normalizeName(name);
        string memory fullDomain = string(abi.encodePacked(normalizedName, ".", tld));
        require(!s.domainExists[fullDomain], "Domain already exists");
        
        // Generate token ID
        uint256 tokenId = s.nextTokenId++;
        
        // Mint NFT
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        
        // Store domain mappings
        s.domainToTokenId[fullDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullDomain;
        s.domainExists[fullDomain] = true;
        s.userDomains[msg.sender].push(fullDomain);
        
        // Initialize domain struct
        s.domains[tokenId] = Domain({
            name: normalizedName,
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
        
        // Enable subdomains if requested
        if (enableSubdomains) {
            s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
            s.enhancedDomains[fullDomain] = true;
        }
        
        emit DomainRegistered(fullDomain, msg.sender, tokenId);
        return tokenId;
    }
    
    function createSubdomain(
        string calldata label,
        string memory parentDomain
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Validate parent domain exists and has subdomain feature
        require(s.domainExists[parentDomain], "Parent domain not found");
        uint256 parentTokenId = s.domainToTokenId[parentDomain];
        require((s.domainFeatures[parentTokenId] & FEATURE_SUBDOMAINS) != 0, "Subdomains not enabled");
        require(s.owners[parentTokenId] == msg.sender, "Not parent domain owner");
        
        // Validate subdomain limits
        require(s.subdomainCounts[parentDomain] < MAX_SUBDOMAINS, "Max subdomains reached");
        
        // Create subdomain name
        string memory normalizedLabel = _normalizeName(label);
        string memory subdomainName = string(abi.encodePacked(normalizedLabel, ".", parentDomain));
        require(!s.domainExists[subdomainName], "Subdomain already exists");
        
        // Generate token ID
        uint256 tokenId = s.nextTokenId++;
        
        // Mint NFT
        s.owners[tokenId] = msg.sender;
        s.balances[msg.sender]++;
        
        // Store subdomain mappings
        s.domainToTokenId[subdomainName] = tokenId;
        s.tokenIdToDomain[tokenId] = subdomainName;
        s.domainExists[subdomainName] = true;
        s.userDomains[msg.sender].push(subdomainName);
        s.domainSubdomains[parentDomain].push(subdomainName);
        s.subdomainOwners[subdomainName] = msg.sender;
        s.subdomainCounts[parentDomain]++;
        
        // Update parent domain
        s.domains[parentTokenId].subdomainCount++;
        
        // Initialize subdomain struct
        s.domains[tokenId] = Domain({
            name: normalizedLabel,
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
        
        emit SubdomainCreated(subdomainName, parentDomain, msg.sender, tokenId);
        return tokenId;
    }
    
    function getDomainOwner(string calldata domain) internal view returns (address) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 tokenId = s.domainToTokenId[domain];
        return s.owners[tokenId];
    }
    
    function calculateSubdomainFee(uint256 parentId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        string memory parentDomain = s.tokenIdToDomain[parentId];
        uint256 subdomainCount = s.subdomainCounts[parentDomain];
        
        // First 2 subdomains are free, then $0.10 doubling
        if (subdomainCount < 2) {
            return 0;
        }
        
        uint256 baseFee = 0.1 ether;
        uint256 multiplier = 2 ** (subdomainCount - 2);
        return baseFee * multiplier;
    }
    
    function _normalizeName(string memory name) private pure returns (string memory) {
        bytes memory nameBytes = bytes(name);
        bytes memory normalized = new bytes(nameBytes.length);
        
        for (uint256 i = 0; i < nameBytes.length; i++) {
            bytes1 char = nameBytes[i];
            // Convert to lowercase
            if (char >= 0x41 && char <= 0x5A) {
                normalized[i] = bytes1(uint8(char) + 32);
            } else {
                normalized[i] = char;
            }
        }
        
        return string(normalized);
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
