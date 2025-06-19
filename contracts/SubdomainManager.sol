// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract DomainRegistry is ERC721URIStorageUpgradeable, AccessControlUpgradeable, IERC2981Upgradeable {
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
    bool public paused;
    address public pendingAdmin;

    event DomainMinted(uint256 indexed tokenId, address owner);
    event PaymentSplitterDeployed(uint256 indexed tokenId, address splitter);
    event ResolverSet(uint256 indexed tokenId, address resolver);
    event ContentHashSet(uint256 indexed tokenId, bytes contentHash);

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
    ) external onlyRole(ADMIN_ROLE) {
        require(!paused, "Paused");
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _domainMeta[tokenId].imageURI = imageURI;
        PaymentSplitter splitter = new PaymentSplitter(payees, shares);
        _domainMeta[tokenId].paymentSplitter = address(splitter);
        emit DomainMinted(tokenId, to);
        emit PaymentSplitterDeployed(tokenId, address(splitter));
    }

    function setResolver(uint256 tokenId, address resolver) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        _domainMeta[tokenId].resolver = resolver;
        emit ResolverSet(tokenId, resolver);
    }

    function setContentHash(uint256 tokenId, bytes calldata contentHash) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        _domainMeta[tokenId].contentHash = contentHash;
        emit ContentHashSet(tokenId, contentHash);
    }

    function royaltyInfo(uint256, uint256 salePrice) external view override returns (address, uint256) {
        return (_royaltyRecipient, (salePrice * _royaltyBps) / 10_000);
    }
}

contract SubdomainManager {
    struct SubdomainData {
        uint256 parentTokenId;
        uint256 expiry;
        address owner;
        string profileURI;
        string imageURI;
    }

    mapping(bytes32 => SubdomainData) internal _subdomains;

    uint256 public baseSubdomainFee;
    uint256 public feeIncrement;
    uint256 public subdomainLeasePeriod;

    event SubdomainCreated(string indexed name, uint256 indexed parentId, address indexed owner, uint256 expiry);

    function _normalize(string memory input) internal pure returns (bytes32) {
        bytes memory bStr = bytes(input);
        for (uint i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bStr[i] = bytes1(uint8(bStr[i]) + 32);
            }
        }
        return keccak256(bStr);
    }

    function createSubdomain(
        string calldata name,
        uint256 parentTokenId,
        address owner,
        string calldata profileURI,
        string calldata imageURI
    ) external payable {
        bytes32 hash = _normalize(name);
        require(_subdomains[hash].parentTokenId == 0, "Subdomain exists");
        uint256 expiry = block.timestamp + subdomainLeasePeriod;
        _subdomains[hash] = SubdomainData({
            parentTokenId: parentTokenId,
            expiry: expiry,
            owner: owner,
            profileURI: profileURI,
            imageURI: imageURI
        });
        emit SubdomainCreated(name, parentTokenId, owner, expiry);
    }

    struct SubdomainLease {
        uint256 expiry;
        uint256 leasePeriod;
        uint256 renewalFee;
        address owner;
        bool transferable;
    }

    mapping(bytes32 => SubdomainLease) public subdomainLeases;

    event SubdomainLeased(string indexed name, address indexed owner, uint256 expiry, uint256 leasePeriod, uint256 renewalFee, bool transferable);

    function leaseSubdomain(
        string calldata name,
        address owner,
        uint256 leasePeriod,
        uint256 renewalFee,
        bool transferable
    ) external payable {
        bytes32 hash = _normalize(name);
        require(subdomainLeases[hash].expiry < block.timestamp, "Lease active");
        require(msg.value >= renewalFee, "Insufficient fee");
        subdomainLeases[hash] = SubdomainLease({
            expiry: block.timestamp + leasePeriod,
            leasePeriod: leasePeriod,
            renewalFee: renewalFee,
            owner: owner,
            transferable: transferable
        });
        emit SubdomainLeased(name, owner, block.timestamp + leasePeriod, leasePeriod, renewalFee, transferable);
    }

    function renewSubdomain(string calldata name) external payable {
        bytes32 hash = _normalize(name);
        SubdomainLease storage lease = subdomainLeases[hash];
        require(msg.sender == lease.owner, "Not lease owner");
        require(msg.value >= lease.renewalFee, "Insufficient fee");
        lease.expiry = block.timestamp + lease.leasePeriod;
        emit SubdomainLeased(name, lease.owner, lease.expiry, lease.leasePeriod, lease.renewalFee, lease.transferable);
    }
}

contract GuardianRecovery is AccessControlUpgradeable {
    using BitMaps for BitMaps.BitMap;

    struct RecoveryData {
        bytes32 recoveryRoot;
        BitMaps.BitMap approvals;
        address pendingNewOwner;
        uint256 approvalCount;
        uint256 threshold;
    }
    mapping(uint256 => RecoveryData) internal _recovery;

    event GuardianThresholdSet(uint256 indexed tokenId, uint256 threshold);
    event RecoveryInitiated(uint256 indexed tokenId, address indexed newOwner, uint256 approvals);
    event RecoveryFinalized(uint256 indexed tokenId, address indexed newOwner);

    function setRecoveryRoot(uint256 tokenId, bytes32 root) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _recovery[tokenId].recoveryRoot = root;
    }

    function setGuardianThreshold(uint256 tokenId, uint256 threshold) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _recovery[tokenId].threshold = threshold;
        emit GuardianThresholdSet(tokenId, threshold);
    }

    function approveRecovery(uint256 tokenId, address newOwner, bytes32[] calldata merkleProof) external {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, _recovery[tokenId].recoveryRoot, leaf), "Invalid proof");
        uint256 idx = uint256(uint160(msg.sender));
        require(!_recovery[tokenId].approvals.get(idx), "Already approved");
        if (_recovery[tokenId].pendingNewOwner != newOwner) {
            _recovery[tokenId].pendingNewOwner = newOwner;
            _recovery[tokenId].approvalCount = 0;
            _recovery[tokenId].approvals = BitMaps.BitMap();
        }
        _recovery[tokenId].approvals.set(idx);
        _recovery[tokenId].approvalCount++;
        emit RecoveryInitiated(tokenId, newOwner, _recovery[tokenId].approvalCount);
    }
}

contract FeeManager {
    address public feeRecipient;

    event FeeRecipientSet(address indexed recipient);

    function setFeeRecipient(address recipient) external {
        require(recipient != address(0), "Invalid address");
        feeRecipient = recipient;
        emit FeeRecipientSet(recipient);
    }
}