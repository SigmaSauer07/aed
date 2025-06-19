// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./AEDRenderer.sol";
import "./AEDPricing.sol";
import "./modules/SubdomainManager.sol";

contract AEDRegistry is ERC721Upgradeable, UUPSUpgradeable {
    // Alsania brand colors
    string public constant NEON_GREEN = "#39FF14";
    string public constant MIDNIGHT_BLUE = "#0A2472";
    string public constant BACKGROUND_DARK = "#000000";
    string public constant BACKGROUND_LIGHT = "#FFFFFF";
    
    // TLD management
    mapping(string => bool) public registeredTLDs;
    mapping(string => uint256) public nameToId;
    mapping(uint256 => string) public tokenIdToName;
    
    // Modules
    address public renderer;
    address public pricing;
    address public subdomainManager;
    
    event DomainRegistered(uint256 indexed tokenId, string name);
    
    function initialize() public initializer {
        __ERC721_init("Alsania Enhanced Domain", "AED");
        __UUPSUpgradeable_init();
        
        // Register Alsania TLDs
        registeredTLDs["alsa"] = true;
        registeredTLDs["aed"] = true;
        registeredTLDs["fx"] = true;
        registeredTLDs["07"] = true;
        registeredTLDs["alsania"] = true;
        
        // Initialize modules
        renderer = address(new AEDRenderer());
        pricing = address(new AEDPricing());
        subdomainManager = address(new SubdomainManager());
    }
    
    function register(
        string calldata name,
        string calldata tld,
        bool darkMode
    ) external payable {
        require(registeredTLDs[tld], "Invalid TLD");
        string memory fullName = string(abi.encodePacked(name, ".", tld));
        uint256 tokenId = uint256(keccak256(bytes(fullName)));
        
        // Check pricing
        uint256 price = AEDPricing(pricing).getDomainPrice(name, tld);
        require(msg.value >= price, "Insufficient payment");
        
        _mint(msg.sender, tokenId);
        nameToId[fullName] = tokenId;
        tokenIdToName[tokenId] = fullName;
        
        // Initialize metadata
        MetadataStorage(renderer).initializeMetadata(tokenId, fullName, darkMode);
        
        emit DomainRegistered(tokenId, fullName);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return MetadataStorage(renderer).getTokenURI(tokenId);
    }
    
    function _authorizeUpgrade(address) internal override onlyOwner {}
}