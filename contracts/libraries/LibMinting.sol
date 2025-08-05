// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";
import "./LibValidation.sol";

/**
 * @title LibMinting
 * @dev Library for domain minting and registration functionality
 */
library LibMinting {
    using LibAppStorage for AppStorage;
    
    // Events
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event SubdomainCreated(string indexed subdomain, string indexed parent, address indexed owner);
    
    /**
     * @notice Register a new domain
     * @param name The domain name
     * @param tld The top-level domain
     * @param withEnhancements Whether to enable enhancements like subdomains
     * @return tokenId The minted token ID
     */
    function registerDomain(
        string memory name,
        string memory tld,
        bool withEnhancements
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Validate inputs
        LibValidation.validateDomainName(name);
        require(s.validTlds[tld], "Invalid TLD");
        
        // Normalize name
        string memory normalizedName = LibValidation.normalizeName(name);
        string memory fullDomain = string(abi.encodePacked(normalizedName, ".", tld));
        
        // Check if domain already exists
        require(!s.domainExists[fullDomain], "Domain already exists");
        
        // Get next token ID
        uint256 tokenId = s.nextTokenId;
        unchecked {
            s.nextTokenId++;
        }
        
        // Create domain struct
        Domain memory domain = Domain({
            name: normalizedName,
            tld: tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0, // No expiration for now
            feeEnabled: false,
            isSubdomain: false,
            owner: msg.sender
        });
        
        // Store mappings (but not ERC721 ownership - that's handled by _mint)
        s.domains[tokenId] = domain;
        s.domainToTokenId[fullDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullDomain;
        s.domainExists[fullDomain] = true;
        s.userDomains[msg.sender].push(fullDomain);
        
        // Enable enhancements if requested
        if (withEnhancements) {
            s.enhancedDomains[fullDomain] = true;
            uint256 FEATURE_SUBDOMAINS = 1 << 0;
            s.domainFeatures[tokenId] |= FEATURE_SUBDOMAINS;
        }
        
        emit DomainRegistered(fullDomain, msg.sender, tokenId);
        
        return tokenId;
    }
    
    /**
     * @notice Create a subdomain
     * @param label The subdomain label
     * @param parentDomain The parent domain
     * @return tokenId The minted token ID
     */
    function createSubdomain(
        string memory label,
        string memory parentDomain
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Validate label
        LibValidation.validateLabel(label);
        
        // Check parent domain exists and has subdomain feature
        require(s.domainExists[parentDomain], "Parent domain does not exist");
        require(s.enhancedDomains[parentDomain], "Subdomains not enabled");
        
        uint256 parentTokenId = s.domainToTokenId[parentDomain];
        require(s.owners[parentTokenId] == msg.sender, "Not parent domain owner");
        
        // Check subdomain limit
        uint256 MAX_SUBDOMAINS = 20;
        require(s.subdomainCounts[parentDomain] < MAX_SUBDOMAINS, "Max subdomains reached");
        
        // Create subdomain name
        string memory normalizedLabel = LibValidation.normalizeName(label);
        string memory fullSubdomain = string(abi.encodePacked(normalizedLabel, ".", parentDomain));
        
        // Check if subdomain already exists
        require(!s.domainExists[fullSubdomain], "Subdomain already exists");
        
        // Get next token ID
        uint256 tokenId = s.nextTokenId;
        unchecked {
            s.nextTokenId++;
        }
        
        // Create subdomain struct
        Domain memory subdomain = Domain({
            name: normalizedLabel,
            tld: s.domains[parentTokenId].tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: true,
            owner: msg.sender
        });
        
        // Store mappings (but not ERC721 ownership - that's handled by _mint)
        s.domains[tokenId] = subdomain;
        s.domainToTokenId[fullSubdomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullSubdomain;
        s.domainExists[fullSubdomain] = true;
        s.userDomains[msg.sender].push(fullSubdomain);
        s.domainSubdomains[parentDomain].push(fullSubdomain);
        s.subdomainCounts[parentDomain]++;
        s.subdomainOwners[fullSubdomain] = msg.sender;
        
        emit SubdomainCreated(fullSubdomain, parentDomain, msg.sender);
        
        return tokenId;
    }
    
    /**
     * @notice Get domain owner
     * @param domain The full domain name
     * @return owner The domain owner address
     */
    function getDomainOwner(string memory domain) internal view returns (address) {
        AppStorage storage s = LibAppStorage.appStorage();
        if (!s.domainExists[domain]) {
            return address(0);
        }
        uint256 tokenId = s.domainToTokenId[domain];
        return s.owners[tokenId];
    }
    
    /**
     * @notice Calculate subdomain minting fee
     * @param parentDomain The parent domain
     * @return fee The calculated fee
     */
    function calculateSubdomainFee(string memory parentDomain) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 subdomainCount = s.subdomainCounts[parentDomain];
        
        // First 2 subdomains are free, then linear pricing starting at 0.1 ETH
        if (subdomainCount < 2) {
            return 0;
        }
        
        // Linear pricing: 0.1 ETH * (count - 1)
        return (subdomainCount - 1) * 0.1 ether;
    }
    
    /**
     * @notice Check if domain has enhancement
     * @param domain The domain name
     * @param enhancement The enhancement type
     * @return enabled Whether the enhancement is enabled
     */
    function hasEnhancement(string memory domain, string memory enhancement) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        if (keccak256(bytes(enhancement)) == keccak256(bytes("subdomain"))) {
            return s.enhancedDomains[domain];
        }
        return false;
    }
    
    /**
     * @notice Normalize domain name to bytes32 for efficient storage
     * @param domain The domain name
     * @return normalized The normalized bytes32 representation
     */
    function normalizeDomain(string memory domain) internal pure returns (bytes32) {
        return keccak256(bytes(LibValidation.normalizeName(domain)));
    }
}
