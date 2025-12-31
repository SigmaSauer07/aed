
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDDomainRegistry {
    struct Domain {
        string name;
        string tld;
        address owner;
        uint256 expirationTime;
        string ipfsHash;
        address resolverAddress;
        bool canMintSubdomains;
        bool isActive;
    }

    struct SubdomainConfig {
        bool enabled;
        uint256 price;
        address paymentToken;
    }

    event DomainRegistered(
        bytes32 indexed domainHash,
        string domain,
        address indexed owner,
        uint256 expirationTime
    );

    event DomainRenewed(
        bytes32 indexed domainHash,
        uint256 newExpirationTime
    );

    event DomainTransferred(
        bytes32 indexed domainHash,
        address indexed from,
        address indexed to
    );

    event SubdomainMinted(
        bytes32 indexed parentDomainHash,
        bytes32 indexed subdomainHash,
        string subdomain,
        address indexed owner
    );

    event ResolverUpdated(
        bytes32 indexed domainHash,
        address indexed resolver
    );

    function registerDomain(
        string calldata name,
        string calldata tld,
        uint256 duration,
        string calldata ipfsHash
    ) external payable returns (bytes32);

    function renewDomain(bytes32 domainHash, uint256 duration) external payable;

    function transferDomain(bytes32 domainHash, address to) external;

    function setResolver(bytes32 domainHash, address resolver) external;

    function getDomain(bytes32 domainHash) external view returns (Domain memory);

    function isDomainActive(bytes32 domainHash) external view returns (bool);

    function getOwner(bytes32 domainHash) external view returns (address);
}
