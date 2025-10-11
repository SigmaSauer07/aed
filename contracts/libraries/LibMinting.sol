// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "./LibAppStorage.sol";

library LibMinting {
    using LibAppStorage for AppStorage;

    uint256 constant MIN_NAME_LENGTH = 1;
    uint256 constant MAX_NAME_LENGTH = 63;
    uint256 constant MAX_SUBDOMAINS = 20;
    uint256 constant FEATURE_SUBDOMAINS = 1 << 0;

    string constant PROFILE_SUFFIX = "/profile.json";
    string constant DEFAULT_DOMAIN_IMAGE_URI = "ipfs://bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png";
    string constant DEFAULT_SUBDOMAIN_IMAGE_URI = "ipfs://bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png";

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

        string memory normalizedName = _normalizeName(name);
        string memory fullDomain = string(abi.encodePacked(normalizedName, ".", tld));
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

        uint256 mintFee = _domainMintFee(s, tld, enableSubdomains);
        string memory metadataBase = string(abi.encodePacked(s.baseURI, fullDomain));

        s.domains[tokenId] = Domain({
            name: normalizedName,
            tld: tld,
            profileURI: string(abi.encodePacked(metadataBase, PROFILE_SUFFIX)),
            imageURI: DEFAULT_DOMAIN_IMAGE_URI,
            subdomainCount: 0,
            mintFee: mintFee,
            expiresAt: 0,
            feeEnabled: false,
            isSubdomain: false,
            owner: msg.sender
        });

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

        require(s.domainExists[parentDomain], "Parent domain not found");
        uint256 parentTokenId = s.domainToTokenId[parentDomain];
        require((s.domainFeatures[parentTokenId] & FEATURE_SUBDOMAINS) != 0, "Subdomains not enabled");
        require(s.owners[parentTokenId] == msg.sender, "Not parent domain owner");
        require(s.subdomainCounts[parentDomain] < MAX_SUBDOMAINS, "Max subdomains reached");

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

        string memory metadataBase = string(abi.encodePacked(s.baseURI, subdomainName));

        s.domains[tokenId] = Domain({
            name: normalizedLabel,
            tld: _extractTld(parentDomain),
            profileURI: string(abi.encodePacked(metadataBase, PROFILE_SUFFIX)),
            imageURI: DEFAULT_SUBDOMAIN_IMAGE_URI,
            subdomainCount: 0,
            mintFee: mintFee,
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

        if (subdomainCount < 2) {
            return 0;
        }

        uint256 baseFee = 0.1 ether;
        uint256 multiplier = 2 ** (subdomainCount - 2);
        return baseFee * multiplier;
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

    function _extractTld(string memory domain) private pure returns (string memory) {
        bytes memory domainBytes = bytes(domain);
        for (uint256 i = domainBytes.length; i > 0; ) {
            unchecked {
                i--;
            }
            if (domainBytes[i] == bytes1(".")) {
                uint256 tldLength = domainBytes.length - (i + 1);
                bytes memory tldBytes = new bytes(tldLength);
                for (uint256 j = 0; j < tldLength; j++) {
                    tldBytes[j] = domainBytes[i + 1 + j];
                }
                return string(tldBytes);
            }
        }
        return domain;
    }

    function _domainMintFee(
        AppStorage storage s,
        string memory tld,
        bool enableSubdomains
    ) private view returns (uint256) {
        uint256 mintFee = 0;
        if (!s.freeTlds[tld]) {
            mintFee += s.tldPrices[tld];
        }
        if (enableSubdomains) {
            mintFee += s.enhancementPrices["subdomain"];
        }
        return mintFee;
    }
}
