// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

interface ICCIPResolver {
    /// @notice Off-chain lookup per EIP-3668
    error OffchainLookup(address sender, string[] urls, bytes callData, bytes4 callbackFunction, bytes extraData);
}

contract DomainRegistry is
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    IERC2981Upgradeable,
    PausableUpgradeable,
    DefaultOperatorFilterer
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct DomainMeta {
        string imageURI;
        address resolver;
        bytes contentHash;
        address paymentSplitter;
    }
    mapping(uint256 => DomainMeta) internal _domainMeta;

    address internal _royaltyRecipient;
    uint96 internal _royaltyBps;

    address public trustedForwarder;
    address public pendingAdmin;

    event DomainMinted(uint256 indexed tokenId, address owner);
    event PaymentSplitterDeployed(uint256 indexed tokenId, address splitter);
    event ResolverSet(uint256 indexed tokenId, address resolver);
    event ContentHashSet(uint256 indexed tokenId, bytes contentHash);
    event AdminTransferInitiated(address indexed newAdmin);
    event AdminTransferAccepted(address indexed newAdmin);

    function initialize(
        string memory name,
        string memory symbol,
        address admin,
        address royaltyRecipient,
        uint96 royaltyBps
    ) public initializer {
        __ERC721_init(name, symbol);
        __ERC721URIStorage_init();
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _royaltyRecipient = royaltyRecipient;
        _royaltyBps = royaltyBps;
    }

    function mintDomain(
        address to,
        uint256 tokenId,
        string calldata uri,
        string calldata imageURI,
        address[] calldata payees,
        uint256[] calldata shares
    ) external onlyRole(ADMIN_ROLE) whenNotPaused {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _domainMeta[tokenId].imageURI = imageURI;
        PaymentSplitter splitter = new PaymentSplitter(payees, shares);
        _domainMeta[tokenId].paymentSplitter = address(splitter);
        emit DomainMinted(tokenId, to);
        emit PaymentSplitterDeployed(tokenId, address(splitter));
    }

    function setResolver(uint256 tokenId, address resolver) external {
        require(ownerOf(tokenId) == _msgSender(), "Not token owner");
        _domainMeta[tokenId].resolver = resolver;
        emit ResolverSet(tokenId, resolver);
    }

    function setContentHash(uint256 tokenId, bytes calldata contentHash) external {
        require(ownerOf(tokenId) == _msgSender(), "Not token owner");
        _domainMeta[tokenId].contentHash = contentHash;
        emit ContentHashSet(tokenId, contentHash);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (_royaltyRecipient, (salePrice * _royaltyBps) / 10_000);
    }

    function setTrustedForwarder(address forwarder) external onlyRole(ADMIN_ROLE) {
        trustedForwarder = forwarder;
    }

    function _msgSender() internal view override returns (address sender) {
        if (msg.data.length >= 24 && msg.sender == trustedForwarder) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = msg.sender;
        }
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function initiateAdminTransfer(address newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newAdmin != address(0), "Invalid admin");
        pendingAdmin = newAdmin;
        emit AdminTransferInitiated(newAdmin);
    }

    function acceptAdminTransfer() external {
        require(msg.sender == pendingAdmin, "Not pending admin");
        _grantRole(DEFAULT_ADMIN_ROLE, pendingAdmin);
        _grantRole(ADMIN_ROLE, pendingAdmin);
        pendingAdmin = address(0);
        emit AdminTransferAccepted(msg.sender);
    }

    function resolveOffchain(bytes calldata name, bytes calldata data) external view returns (bytes memory) {
        string[] memory urls = new string[](1);
        urls[0] = "https://your-offchain-resolver.com/{data}";
        revert OffchainLookup(address(this), urls, data, this.resolveOffchain.selector, data);
    }

    // OpenSea Operator Filter overrides
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}