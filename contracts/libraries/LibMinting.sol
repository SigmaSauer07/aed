// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "./LibValidation.sol";
import "./LibAppStorage.sol";
import "./LibMetadata.sol";

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
        require(LibValidation.isValidDomainName(name), "Invalid name characters");
        require(LibValidation.isValidTLD(tld), "Invalid TLD");

        string memory normalizedName = _normalizeLabel(name);
        string memory normalizedTld = LibValidation.toLower(tld);
        require(s.validTlds[normalizedTld], "Invalid TLD");

        // Normalize and check domain availability
        string memory fullDomain = string(abi.encodePacked(normalizedName, ".", normalizedTld));
        require(!s.domainExists[fullDomain], "Domain already exists");

        // Generate token ID
        // Cache nextTokenId locally and manually increment to save an extra SLOAD/STORE
        uint256 tokenId = s.nextTokenId;
        s.nextTokenId = tokenId + 1;
        
        // Mint NFT
        s.owners[tokenId] = msg.sender;
        // Use unchecked increment for gas efficiency; balance cannot realistically overflow
        unchecked { s.balances[msg.sender]++; }
        
        // Store domain mappings
        s.domainToTokenId[fullDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullDomain;
        s.domainExists[fullDomain] = true;
        s.userDomains[msg.sender].push(fullDomain);

        // Initialize domain struct
        string memory defaultProfile = LibMetadata.defaultProfileURI(fullDomain, msg.sender);
        string memory defaultImage = LibMetadata.defaultImageURI(false);

        s.domains[tokenId] = Domain({
            name: normalizedName,
            tld: normalizedTld,
            profileURI: defaultProfile,
            imageURI: defaultImage,
            subdomainCount: 0,
            mintFee: s.freeTlds[normalizedTld] ? 0 : s.tldPrices[normalizedTld],
            expiresAt: 0,
            feeEnabled: enableSubdomains,
            isSubdomain: false,
            owner: msg.sender
        });

        s.profileURIs[tokenId] = defaultProfile;
        s.imageURIs[tokenId] = defaultImage;

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

        require(LibValidation.isValidDomainName(label), "Invalid name characters");

        // Create subdomain name
        string memory normalizedLabel = _normalizeLabel(label);
        string memory subdomainName = string(abi.encodePacked(normalizedLabel, ".", parentDomain));
        require(!s.domainExists[subdomainName], "Subdomain already exists");

        // Generate token ID
        uint256 tokenId = s.nextTokenId;
        s.nextTokenId = tokenId + 1;
        
        // Mint NFT
        s.owners[tokenId] = msg.sender;
        unchecked { s.balances[msg.sender]++; }
        
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
        string memory subdomainProfile = LibMetadata.defaultProfileURI(subdomainName, msg.sender);
        string memory subdomainImage = LibMetadata.defaultImageURI(true);
        uint256 currentFee = _currentSubdomainFee(s.subdomainCounts[parentDomain] - 1);
        string memory parentTld = _extractTLD(parentDomain);

        s.domains[tokenId] = Domain({
            name: normalizedLabel,
            tld: parentTld,
            profileURI: subdomainProfile,
            imageURI: subdomainImage,
            subdomainCount: 0,
            mintFee: currentFee,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: true,
            owner: msg.sender
        });

        s.profileURIs[tokenId] = subdomainProfile;
        s.imageURIs[tokenId] = subdomainImage;

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

        return _currentSubdomainFee(subdomainCount);
    }

    function _normalizeLabel(string memory label) private pure returns (string memory) {
        bytes memory nameBytes = bytes(label);
        bytes memory normalized = new bytes(nameBytes.length);

        for (uint256 i = 0; i < nameBytes.length; i++) {
            bytes1 char = nameBytes[i];
            if (char >= 0x41 && char <= 0x5A) {
                normalized[i] = bytes1(uint8(char) + 32);
            } else {
                normalized[i] = char;
            }
        }

        return string(normalized);
    }

    function _currentSubdomainFee(uint256 existingCount) private pure returns (uint256) {
        if (existingCount < 2) {
            return 0;
        }

        uint256 baseFee = 0.1 ether;
        uint256 multiplier = 2 ** (existingCount - 2);
        return baseFee * multiplier;
    }

    function _extractTLD(string memory domain) private pure returns (string memory) {
        bytes memory domainBytes = bytes(domain);
        uint256 lastDot = domainBytes.length;

        for (uint256 i = domainBytes.length; i > 0; i--) {
            if (domainBytes[i - 1] == 0x2E) {
                lastDot = i - 1;
                break;
            }
        }

        if (lastDot == domainBytes.length) {
            return "";
        }

        uint256 tldLength = domainBytes.length - lastDot - 1;
        bytes memory tldBytes = new bytes(tldLength);
        for (uint256 i = 0; i < tldLength; i++) {
            tldBytes[i] = domainBytes[lastDot + 1 + i];
        }

        return string(tldBytes);
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
        
        for (uint256 i = 0; i < names.length; ) {
            tokenIds[i] = registerDomain(names[i], tlds[i], enableSubdomains[i]);
            unchecked { ++i; }
        }
        
        return tokenIds;
    }
}
