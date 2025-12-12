// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "./LibAppStorage.sol";
import "./LibBadges.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

library LibMinting {
    using LibAppStorage for AppStorage;

    uint256 constant MIN_NAME_LENGTH = 1;
    uint256 constant MAX_NAME_LENGTH = 63;
    uint256 constant MAX_SUBDOMAINS = 20;
    uint256 constant FEATURE_SUBDOMAINS = 1 << 0;

    string constant DEFAULT_PROFILE_TITLE = "Alsania Enhanced Domain";
    string constant DEFAULT_PROFILE_IMAGE = "ipfs://bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png";
    string constant DEFAULT_SUBDOMAIN_IMAGE = "ipfs://bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png";
    
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event SubdomainCreated(string indexed subdomain, string indexed parent, address indexed owner, uint256 tokenId);

    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();

        require(bytes(name).length >= MIN_NAME_LENGTH && bytes(name).length <= MAX_NAME_LENGTH, "Invalid name length");
        require(s.validTlds[tld], "Invalid TLD");
        
        // Normalize and check domain availability
        string memory normalizedName = _normalizeName(name);
        string memory normalizedTld = _normalizeName(tld);
        string memory fullDomain = string(abi.encodePacked(normalizedName, ".", normalizedTld));
        require(!s.domainExists[fullDomain], "Domain already exists");

        uint256 tokenId = s.nextTokenId;
        s.nextTokenId = tokenId + 1;

        s.owners[tokenId] = msg.sender;
        unchecked {
            s.balances[msg.sender]++;
        }

        s.domainToTokenId[fullDomain] = tokenId;
        s.tokenIdToDomain[tokenId] = fullDomain;
        s.domainExists[fullDomain] = true;
        s.userDomains[msg.sender].push(fullDomain);

        // Initialize domain struct
        s.domains[tokenId] = Domain({
            name: normalizedName,
            tld: normalizedTld,
            profileURI: _buildDefaultProfile(fullDomain, false),
            imageURI: DEFAULT_PROFILE_IMAGE,
            subdomainCount: 0,
            mintFee: s.freeTlds[normalizedTld] ? 0 : s.tldPrices[normalizedTld],
            expiresAt: 0,
            feeEnabled: !s.freeTlds[normalizedTld],
            isSubdomain: false,
            owner: msg.sender
        });

        // Enable subdomains if requested
        if (enableSubdomains) {
            uint256 subdomainFlag = s.featureFlags["subdomain"];
            if (subdomainFlag == 0) {
                subdomainFlag = FEATURE_SUBDOMAINS;
            }
            s.domainFeatures[tokenId] |= subdomainFlag;
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

        require(s.domainExists[parentDomain], "Parent domain not found");
        uint256 parentTokenId = s.domainToTokenId[parentDomain];
        uint256 subdomainFlag = s.featureFlags["subdomain"];
        if (subdomainFlag == 0) {
            subdomainFlag = FEATURE_SUBDOMAINS;
        }
        require((s.domainFeatures[parentTokenId] & subdomainFlag) != 0, "Subdomains not enabled");
        require(s.owners[parentTokenId] == msg.sender, "Not parent domain owner");
        require(s.subdomainCounts[parentDomain] < MAX_SUBDOMAINS, "Max subdomains reached");

        // Create subdomain name
        string memory normalizedLabel = _normalizeName(label);
        string memory subdomainName = string(abi.encodePacked(normalizedLabel, ".", parentDomain));
        require(!s.domainExists[subdomainName], "Subdomain already exists");

        uint256 tokenId = s.nextTokenId;
        s.nextTokenId = tokenId + 1;

        s.owners[tokenId] = msg.sender;
        unchecked {
            s.balances[msg.sender]++;
        }

        s.domainToTokenId[subdomainName] = tokenId;
        s.tokenIdToDomain[tokenId] = subdomainName;
        s.domainExists[subdomainName] = true;
        s.userDomains[msg.sender].push(subdomainName);
        s.domainSubdomains[parentDomain].push(subdomainName);
        s.subdomainOwners[subdomainName] = msg.sender;

        uint256 mintFee = calculateSubdomainFee(parentTokenId);
        s.subdomainCounts[parentDomain]++;
        s.domains[parentTokenId].subdomainCount++;

        // Initialize subdomain struct
        s.domains[tokenId] = Domain({
            name: normalizedLabel,
            tld: _extractTLD(parentDomain),
            profileURI: _buildDefaultProfile(subdomainName, true),
            imageURI: DEFAULT_SUBDOMAIN_IMAGE,
            subdomainCount: 0,
            mintFee: mintFee,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: true,
            owner: msg.sender
        });

        // NEW: Award badge to parent domain for creating subdomain
        LibBadges.awardSubdomainBadge(parentTokenId, s.domains[parentTokenId].subdomainCount);

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
        
        uint256 baseFee = s.fees["subdomainBase"];
        if (baseFee == 0) {
            baseFee = 0.1 ether;
        }

        uint256 freeMints = s.fees["subdomainFreeMints"];
        if (freeMints == 0) {
            freeMints = 2;
        }

        if (subdomainCount < freeMints) {
            return 0;
        }

        uint256 multiplier = s.fees["subdomainMultiplier"];
        if (multiplier == 0) {
            multiplier = 2;
        }

        uint256 payableCount = subdomainCount - freeMints;
        uint256 fee = baseFee;

        for (uint256 i = 0; i < payableCount; i++) {
            fee *= multiplier;
        }

        return fee;
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
            unchecked {
                ++i;
            }
        }

        return tokenIds;
    }

    function _normalizeName(string memory name) private pure returns (string memory) {
        bytes memory nameBytes = bytes(name);
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

    function _buildDefaultProfile(string memory fullDomain, bool isSubdomain) private pure returns (string memory) {
        string memory payload = string(
            abi.encodePacked(
                '{"domain":"',
                fullDomain,
                '","label":"',
                DEFAULT_PROFILE_TITLE,
                '","type":"',
                isSubdomain ? "subdomain" : "domain",
                '"}'
            )
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(payload))
            )
        );
    }

    function _extractTLD(string memory domain) private pure returns (string memory) {
        bytes memory domainBytes = bytes(domain);
        for (uint256 i = domainBytes.length; i > 0; i--) {
            if (domainBytes[i - 1] == 0x2E) {
                bytes memory tld = new bytes(domainBytes.length - i);
                for (uint256 j = 0; j < tld.length; j++) {
                    tld[j] = domainBytes[i + j];
                }
                return string(tld);
            }
        }

        return domain;
    }
}
