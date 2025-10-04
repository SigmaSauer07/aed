// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibValidation.sol";
import "./LibAppStorage.sol";

library LibMinting {
    using LibAppStorage for AppStorage;

    uint256 private constant MIN_NAME_LENGTH = 1;
    uint256 private constant MAX_NAME_LENGTH = 63;
    uint256 private constant MAX_SUBDOMAINS = 20;
    uint256 private constant FEATURE_SUBDOMAINS = 1 << 0;
    uint256 private constant SUBDOMAIN_BASE_FEE = 0.1 ether;

    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event SubdomainCreated(string indexed subdomain, string indexed parent, address indexed owner, uint256 tokenId);

    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.appStorage();

        require(bytes(name).length >= MIN_NAME_LENGTH && bytes(name).length <= MAX_NAME_LENGTH, "Invalid name length");
        require(LibValidation.isValidDomainName(name), "Invalid name format");

        string memory normalizedName = normalizeLabel(name);
        string memory normalizedTld = normalizeLabel(tld);

        require(LibValidation.isValidTLD(normalizedTld), "Invalid TLD format");
        require(s.validTlds[normalizedTld], "Invalid TLD");

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

        uint256 domainFee = s.freeTlds[normalizedTld] ? 0 : s.tldPrices[normalizedTld];
        uint256 enhancementFee = enableSubdomains ? s.enhancementPrices["subdomain"] : 0;

        string memory profileURI = _composeUri(s.baseURI, fullDomain, "/profile.json");
        string memory imageURI = _composeUri(s.baseURI, fullDomain, "/image.png");

        s.domains[tokenId] = Domain({
            name: normalizedName,
            tld: normalizedTld,
            profileURI: profileURI,
            imageURI: imageURI,
            subdomainCount: 0,
            mintFee: domainFee + enhancementFee,
            expiresAt: 0,
            feeEnabled: domainFee > 0,
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

        require(bytes(label).length >= MIN_NAME_LENGTH && bytes(label).length <= MAX_NAME_LENGTH, "Invalid name length");
        require(LibValidation.isValidDomainName(label), "Invalid name format");

        uint256 existingCount = s.subdomainCounts[parentDomain];
        require(existingCount < MAX_SUBDOMAINS, "Max subdomains reached");

        string memory normalizedLabel = normalizeLabel(label);
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

        s.subdomainCounts[parentDomain] = existingCount + 1;
        s.domains[parentTokenId].subdomainCount = s.subdomainCounts[parentDomain];

        string memory profileURI = _composeUri(s.baseURI, subdomainName, "/profile.json");
        string memory imageURI = _composeUri(s.baseURI, subdomainName, "/image.png");

        s.domains[tokenId] = Domain({
            name: normalizedLabel,
            tld: _extractTld(parentDomain),
            profileURI: profileURI,
            imageURI: imageURI,
            subdomainCount: 0,
            mintFee: _subdomainFeeForCount(existingCount),
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
        require(LibAppStorage.tokenExists(parentId), "Parent not found");
        AppStorage storage s = LibAppStorage.appStorage();
        string memory parentDomain = s.tokenIdToDomain[parentId];
        return _subdomainFeeForCount(s.subdomainCounts[parentDomain]);
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

    function normalizeLabel(string memory label) internal pure returns (string memory) {
        return _toLower(label);
    }

    function _subdomainFeeForCount(uint256 currentCount) private pure returns (uint256) {
        if (currentCount < 2) {
            return 0;
        }
        unchecked {
            return SUBDOMAIN_BASE_FEE << (currentCount - 2);
        }
    }

    function _composeUri(
        string memory base,
        string memory domain,
        string memory suffix
    ) private pure returns (string memory) {
        bytes memory baseBytes = bytes(base);
        if (baseBytes.length == 0) {
            return "";
        }

        if (baseBytes[baseBytes.length - 1] == bytes1(0x2f)) {
            return string(abi.encodePacked(base, domain, suffix));
        }

        return string(abi.encodePacked(base, "/", domain, suffix));
    }

    function _extractTld(string memory domain) private pure returns (string memory) {
        bytes memory domainBytes = bytes(domain);
        for (uint256 i = domainBytes.length; i > 0; ) {
            unchecked {
                i--;
            }
            if (domainBytes[i] == bytes1(0x2e)) {
                uint256 length = domainBytes.length - i - 1;
                bytes memory tld = new bytes(length);
                for (uint256 j = 0; j < length; ) {
                    tld[j] = domainBytes[i + 1 + j];
                    unchecked {
                        ++j;
                    }
                }
                return string(tld);
            }
        }
        return domain;
    }

    function _toLower(string memory value) private pure returns (string memory) {
        bytes memory input = bytes(value);
        bytes memory output = new bytes(input.length);

        for (uint256 i = 0; i < input.length; ) {
            bytes1 char = input[i];
            if (char >= 0x41 && char <= 0x5A) {
                output[i] = bytes1(uint8(char) + 32);
            } else {
                output[i] = char;
            }
            unchecked {
                ++i;
            }
        }

        return string(output);
    }
}
