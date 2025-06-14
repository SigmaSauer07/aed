// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract EnhancedDomain is
    Initializable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

    struct DomainData {
        string profileURI;
        string imageURI;
        EnumerableSet.AddressSet linkedWallets;
        bytes32 recoveryRoot;
    }

    mapping(uint256 => DomainData) private _domainInfo;
    mapping(bytes32 => uint256) public subdomainParent; // hash(name) => parent tokenId
    uint256 private _subdomainCounter;

    event DomainMinted(uint256 indexed tokenId, address owner);
    event SubdomainMinted(uint256 indexed subId, string name, uint256 indexed parentId);
    event ProfileUpdated(uint256 indexed tokenId);
    event WalletLinked(uint256 indexed tokenId, address wallet);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address admin_
    ) public initializer {
        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(ADMIN_ROLE, admin_);
    }

    function _normalize(string memory input) internal pure returns (string memory) {
        bytes memory bStr = bytes(input);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bStr[i] = bytes1(uint8(bStr[i]) + 32); // A-Z to a-z
            }
        }
        return string(bStr);
    }

    // ====== Minting Domains ======
    function mintDomain(
        address to,
        uint256 tokenId,
        string calldata profileURI,
        string calldata domainImageURI
    ) external onlyRole(ADMIN_ROLE) {
        _mint(to, tokenId);
        _domainInfo[tokenId].profileURI = profileURI;
        _domainInfo[tokenId].imageURI = domainImageURI;
        _domainInfo[tokenId].linkedWallets.add(to);

        emit DomainMinted(tokenId, to);
    }

    // ====== Minting Subdomains as NFTs ======
    function mintSubdomain(string calldata name, uint256 parentTokenId) external {
        require(ownerOf(parentTokenId) == msg.sender, "Not owner of parent");

        string memory lower = _normalize(name);
        bytes32 hash = keccak256(abi.encodePacked(lower));
        require(subdomainParent[hash] == 0, "Subdomain exists");

        _subdomainCounter++;
        uint256 subId = _subdomainCounter + 10_000_000; // offset to avoid overlap

        _mint(msg.sender, subId);
        subdomainParent[hash] = parentTokenId;

        emit SubdomainMinted(subId, lower, parentTokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC721URIStorageUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // ====== Profile Metadata ======
    function updateProfile(uint256 tokenId, string calldata newProfileURI, string calldata newImageURI) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");

        _domainInfo[tokenId].profileURI = newProfileURI;
        _domainInfo[tokenId].imageURI = newImageURI;

        emit ProfileUpdated(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return _domainInfo[tokenId].profileURI;
    }

    function imageURI(uint256 tokenId) public view returns (string memory) {
        _requireOwned(tokenId);
        return _domainInfo[tokenId].imageURI;
    }

    // ====== Wallet Linking ======
    function linkWallet(uint256 tokenId, address wallet) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        require(wallet != address(0), "Invalid wallet");
        _domainInfo[tokenId].linkedWallets.add(wallet);
        emit WalletLinked(tokenId, wallet);
    }

    function isWalletLinked(uint256 tokenId, address wallet) external view returns (bool) {
        return _domainInfo[tokenId].linkedWallets.contains(wallet);
    }

    function getLinkedWallets(uint256 tokenId) external view returns (address[] memory) {
        return _domainInfo[tokenId].linkedWallets.values();
    }

    // ====== Recovery ======
    function setRecoveryRoot(uint256 tokenId, bytes32 root) external onlyRole(GUARDIAN_ROLE) {
        _domainInfo[tokenId].recoveryRoot = root;
    }

    function getRecoveryRoot(uint256 tokenId) external view returns (bytes32) {
        return _domainInfo[tokenId].recoveryRoot;
    }

    // ====== Upgradeability ======
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}
}
