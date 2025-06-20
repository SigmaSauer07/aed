// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

abstract contract AEDCore is
    Initializable,
    ERC721URIStorageUpgradeable,
    PaymentSplitterUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;

    /* Roles */
    bytes32 public constant ADMIN_ROLE     = keccak256("ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE  = keccak256("UPGRADER_ROLE");
    bytes32 public constant BRIDGE_MANAGER = keccak256("BRIDGE_MANAGER");

    /* Brand */
    string internal constant NEON_GREEN = "#39FF14";

    /* IPFS backgrounds */
    string internal constant DOMAIN_BG = "https://gateway.pinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png";
    string internal constant SUB_BG    = "https://gateway.pinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png";

    /* Storage */
    struct Domain {
        string  name;
        string  tld;
        string  profileURI;
        string  imageURI;
        uint256 subdomainCount;
        uint256 mintFee;
        bool    feeEnabled;
        uint64  expiresAt;
        bool    isSubdomain;
    }
    struct BridgeReceipt {
        uint256 destChainId;
        bytes32 merkleRoot;
        uint256 timestamp;
    }

    mapping(uint256 => Domain) internal domains;
    mapping(string  => bool)  internal registered;
    mapping(uint256 => BridgeReceipt) internal bridgeReceipts;
    mapping(uint256 => bool)  internal isBridged;
    mapping(uint256 => EnumerableSet.AddressSet) internal guardians;
    mapping(uint256 => uint256) internal recoveryTimestamps;

    uint256 public nextTokenId;
    uint256 public renewalPrice;
    uint256 public royaltyBps;

    /* Events */
    event DomainRegistered(uint256 indexed id,string full);
    event SubdomainCreated(uint256 indexed root,uint256 indexed sub,string full);
    event Renewed(uint256 indexed id,uint256 duration);
    event BridgeInitiated(uint256 indexed id,uint256 dest);
    event RecoveryStarted(uint256 indexed id);

    function __AEDCore_init(string memory name_,string memory symbol_,address[] memory payees_,uint256[] memory shares_) internal onlyInitializing {
        __ERC721_init(name_,symbol_);
        __ERC721URIStorage_init();
        __AccessControl_init();
        __Pausable_init();
        __PaymentSplitter_init(payees_,shares_);

        _grantRole(DEFAULT_ADMIN_ROLE,msg.sender);
        _grantRole(ADMIN_ROLE,msg.sender);
        _grantRole(UPGRADER_ROLE,msg.sender);
        _grantRole(BRIDGE_MANAGER,msg.sender);

        nextTokenId=1;
        renewalPrice=0.01 ether;
        royaltyBps=500;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721URIStorageUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}