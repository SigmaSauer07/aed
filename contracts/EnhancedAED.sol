// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract EnhancedDomain is
    Initializable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    IERC2981
{
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    struct Domain {
        string name;
        string tld;
        string profileURI;
        string imageURI;
        uint256 subdomainCount;
        uint256 mintFee;
        bool feeEnabled;
    }

    mapping(uint256 => Domain) public domains;
    mapping(string => bool) public registered;
    uint256 public nextTokenId;
    string public baseImageURI;

    function initialize() public initializer {
        __ERC721_init("Alsania Enhanced Domain", "AED");
        __ERC721URIStorage_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);

        nextTokenId = 1;
    }

    function registerDomain(string memory name, string memory tld, uint256 mintFee, bool feeEnabled) external {
        string memory full = string(abi.encodePacked(name, ".", tld));
        require(!registered[full], "Domain already registered");

        uint256 tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);

        domains[tokenId] = Domain({
            name: name,
            tld: tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: mintFee,
            feeEnabled: feeEnabled
        });

        registered[full] = true;
    }

    function mintSubdomain(uint256 rootTokenId, string memory subName) external payable {
        require(_exists(rootTokenId), "Root domain doesn't exist");

        Domain storage root = domains[rootTokenId];
        string memory full = string(abi.encodePacked(subName, ".", root.name, ".", root.tld));
        require(!registered[full], "Subdomain taken");

        if (root.feeEnabled && msg.sender != ownerOf(rootTokenId)) {
            uint256 requiredFee = root.mintFee * (1 + root.subdomainCount);
            require(msg.value >= requiredFee, "Insufficient mint fee");
        }

        uint256 tokenId = nextTokenId++;
        _safeMint(msg.sender, tokenId);

        domains[tokenId] = Domain({
            name: subName,
            tld: string(abi.encodePacked(root.name, ".", root.tld)),
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            feeEnabled: false
        });

        root.subdomainCount++;
        registered[full] = true;
    }

    function setBaseImageURI(string memory uri) external onlyRole(ADMIN_ROLE) {
        baseImageURI = uri;
    }

    function setProfileURI(uint256 tokenId, string memory uri) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        domains[tokenId].profileURI = uri;
    }

    function setImageURI(uint256 tokenId, string memory uri) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not authorized");
        domains[tokenId].imageURI = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Token doesn't exist");
        Domain memory d = domains[tokenId];

        string memory name = string(abi.encodePacked(d.name, ".", d.tld));
        string memory image = bytes(d.imageURI).length > 0 ? d.imageURI : generateDefaultSVG(name);
        string memory profile = d.profileURI;

        return string(abi.encodePacked(
            'data:application/json;utf8,{',
                '"name":"', name, '",',
                '"description":"Alsania Enhanced Domain",',
                '"image":"', image, '",',
                '"external_url":"', profile, '"',
            '}'
        ));
    }

    function generateDefaultSVG(string memory name) internal pure returns (string memory) {
        string memory svg = string(abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" width="400" height="400" style="background:#0a2472">',
                '<style>.text{fill:#39ff14;font-size:24px;font-family:monospace;}</style>',
                '<text x="50%" y="50%" class="text" dominant-baseline="middle" text-anchor="middle">',
                    name,
                '</text>',
            '</svg>'
        ));
        return string(abi.encodePacked("data:image/svg+xml;utf8,", svg));
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function pause() public onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721URIStorageUpgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId) || interfaceId == type(IERC2981).interfaceId;
    }
}

