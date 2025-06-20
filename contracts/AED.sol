// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/finance/PaymentSplitterUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract AED is
    Initializable,
    ERC721URIStorageUpgradeable,
    PaymentSplitterUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IERC2981
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Strings for uint256;

    /* ───── Roles ──── */
    bytes32 public constant ADMIN_ROLE       = keccak256("ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE    = keccak256("UPGRADER_ROLE");
    bytes32 public constant BRIDGE_MANAGER   = keccak256("BRIDGE_MANAGER");

    /* ───── Brand details ──── */
    string private constant NEON_GREEN = "#39FF14";

    /* ───── Pinata backgrounds ──── */
    string private constant DOMAIN_BG =
        "https://gateway.pinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/domain_background.png";
    string private constant SUB_BG    =
        "https://gateway.pinata.cloud/ipfs/bafybeib5jf536bbe7x44kmgvxm6nntlxpzuexg5x7spzwzi6gfqwmkkj5m/subdomain_background.png";

    /* ───── Storage ──── */
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

    mapping(uint256 => Domain)        public domains;
    mapping(string  => bool)          public registered;
    mapping(uint256 => BridgeReceipt) public bridgeReceipts;
    mapping(uint256 => bool)          public isBridged;
    mapping(uint256 => EnumerableSet.AddressSet) private _guardians;
    mapping(uint256 => uint256)       public recoveryTimestamps;

    uint256 public nextTokenId;
    uint256 public renewalPrice;
    uint256 public royaltyBps;                     // 0–1000  (0-10 %)

    /* ───── Events ──── */
    event DomainRegistered (uint256 indexed id, string full);
    event SubdomainCreated (uint256 indexed root, uint256 indexed sub, string full);
    event BridgeInitiated  (uint256 indexed id, uint256 destChain);
    event RecoveryStarted  (uint256 indexed id);
    event Renewed          (uint256 indexed id, uint256 duration);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    /* ───── Initializer ──── */
    function initialize(address[] memory payees, uint256[] memory shares_) public initializer {
        __ERC721_init("Alsania Enhanced Domain", "AED");
        __ERC721URIStorage_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __PaymentSplitter_init(payees, shares_);
        __PaymentSplitter_init_unchained(payees, shares_);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE,         msg.sender);
        _grantRole(UPGRADER_ROLE,      msg.sender);
        _grantRole(BRIDGE_MANAGER,     msg.sender);

        nextTokenId  = 1;
        renewalPrice = 0.01 ether;
        royaltyBps   = 500;   // default 5 %
    }

    /* ───── Minting ──── */
    function registerDomain(
        string memory name,
        string memory tld,
        uint256 mintFee,
        bool    feeEnabled,
        uint256 duration
    ) external payable {
        require(msg.value >= renewalPrice * duration, "Insufficient payment");
        string memory full = string.concat(name, ".", tld);
        require(!registered[full], "Domain taken");

        uint256 id = nextTokenId++;
        _safeMint(msg.sender, id);

        domains[id] = Domain(
            name, tld, "", "", 0, mintFee, feeEnabled,
            uint64(block.timestamp + duration), false
        );
        registered[full] = true;
        emit DomainRegistered(id, full);
    }

    function mintSubdomain(uint256 rootId, string memory sub) external payable {
        require(_exists(rootId), "Root missing");
        require(ownerOf(rootId) == msg.sender, "Not root owner");
        require(domains[rootId].expiresAt > block.timestamp, "Root expired");

        Domain storage r = domains[rootId];
        string memory full = string.concat(sub, ".", r.name, ".", r.tld);
        require(!registered[full], "Taken");

        if (r.feeEnabled) {
            uint256 fee = r.mintFee * (1 + r.subdomainCount);
            require(msg.value >= fee, "Fee low");
        }

        uint256 id = nextTokenId++;
        _safeMint(msg.sender, id);

        domains[id] = Domain(
            sub,
            string.concat(r.name, ".", r.tld),
            "",
            "",
            0,
            0,
            false,
            r.expiresAt,
            true
        );
        r.subdomainCount++;
        registered[full] = true;
        emit SubdomainCreated(rootId, id, full);
    }

    function renewDomain(uint256 id, uint256 duration) external payable {
        require(_isApprovedOrOwner(msg.sender, id), "Not owner");
        require(msg.value >= renewalPrice * duration, "Payment low");
        domains[id].expiresAt += uint64(duration);
        emit Renewed(id, duration);
    }

    /* ───── Metadata ──── */
    function setProfileURI(uint256 id, string memory uri) external {
        require(_isApprovedOrOwner(msg.sender, id), "Not owner");
        domains[id].profileURI = uri;
    }
    function setRoyaltyBps(uint256 bps) external onlyRole(ADMIN_ROLE) {
        require(bps <= 1000, "Royalty must be 0-1000 bps");
        royaltyBps = bps;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Missing");
        Domain memory d = domains[id];
        string memory nm = string.concat(d.name, ".", d.tld);
        string memory img = bytes(d.imageURI).length > 0 ? d.imageURI : _svg(nm, d.isSubdomain);

        string memory meta = Base64.encode(
            bytes(
                string.concat(
                    '{"name":"', nm,
                    '","description":"Alsania Enhanced Domain",',
                    '"image":"', img, '"}'
                )
            )
        );
        return string.concat("data:application/json;base64,", meta);
    }

    /* ───── SVG Helper ──── */
    function _svg(string memory nm, bool sub) internal pure returns (string memory) {
        string memory bg = sub ? SUB_BG : DOMAIN_BG;
        string memory svg = Base64.encode(
            bytes(
                string.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400">',
                      "<defs>",
                        "<style>@import url('https://fonts.googleapis.com/css2?family=Permanent+Marker');</style>",
                        '<filter id="glow" x="-50%" y="-50%" width="200%" height="200%">',
                          '<feGaussianBlur stdDeviation="2.5" result="blur"/>',
                          '<feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>',
                        "</filter>",
                      "</defs>",
                      '<image href="', bg, '" width="400" height="400"/>',
                      '<text x="50%" y="92%" text-anchor="middle" dominant-baseline="middle" ',
                          'font-family="Permanent Marker" font-size="24" fill="', NEON_GREEN, '" filter="url(#glow)">',
                          nm,
                      "</text>"
                    "</svg>"
                )
            )
        );
        return string.concat("data:image/svg+xml;base64,", svg);
    }

    /* ───── Royalty ──── */
    function royaltyInfo(uint256 id, uint256 sale) external view override returns (address, uint256) {
        require(_exists(id), "Missing");
        return (ownerOf(id), (sale * royaltyBps) / 10000);
    }

    /* ───── Hooks & Admin ──── */
    function _beforeTokenTransfer(address f, address t, uint256 first, uint256 batch)
        internal
        override
    {
        require(domains[first].expiresAt > block.timestamp, "Expired");
        super._beforeTokenTransfer(f, t, first, batch);
    }

    function pause()   external onlyRole(ADMIN_ROLE) { _pause(); }
    function unpause() external onlyRole(ADMIN_ROLE) { _unpause(); }

    function _authorizeUpgrade(address newImpl) internal override onlyRole(UPGRADER_ROLE) {}

    /* ───── Interface Support ──── */
    function supportsInterface(bytes4 i)
        public view
        override(ERC721URIStorageUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(i) || i == type(IERC2981).interfaceId;
    }
}
