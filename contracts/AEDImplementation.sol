// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./core/AppStorage.sol";
import "./core/AEDCore.sol";
import "./libraries/LibMinting.sol";
import "./libraries/LibMetadata.sol";
import "./libraries/LibAdmin.sol";
import "./libraries/LibRegistry.sol";
import "./libraries/LibReverse.sol";

contract AEDImplementation is 
    UUPSUpgradeable,
    ERC721Upgradeable,
    AccessControlUpgradeable
{
    using LibAppStorage for AppStorage;
    
    // Role constants
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    // Events
    event DomainRegistered(string indexed domain, address indexed owner, uint256 indexed tokenId);
    event DomainTransferred(uint256 indexed tokenId, address indexed from, address indexed to);
    
    function initialize(
        string memory name,
        string memory symbol,
        address paymentWallet,
        address admin
    ) public initializer {
        __ERC721_init(name, symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        
        AppStorage storage s = LibAppStorage.appStorage();
        s.feeCollector = paymentWallet;
        s.admins[admin] = true;
        s.nextTokenId = 1;
        s.baseURI = "https://api.alsania.io/metadata/";
        
        // Initialize default pricing
        s.enhancementPrices["subdomain"] = 2 ether;
        s.enhancementPrices["byo"] = 5 ether;
        s.tldPrices["alsania"] = 1 ether;
        s.tldPrices["fx"] = 1 ether;
        s.tldPrices["echo"] = 1 ether;
        
        // Initialize free TLDs
        s.freeTlds["aed"] = true;
        s.freeTlds["alsa"] = true;
        s.freeTlds["07"] = true;
        s.validTlds["aed"] = true;
        s.validTlds["alsa"] = true;
        s.validTlds["07"] = true;
        s.validTlds["alsania"] = true;
        s.validTlds["fx"] = true;
        s.validTlds["echo"] = true;
    }
    
    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) 
        internal 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        override 
    {}
    
    // Minting functions
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) external payable returns (uint256) {
        uint256 tokenId = LibMinting.registerDomain(name, tld, enableSubdomains);
        
        // Mint the ERC721 token
        _mint(msg.sender, tokenId);
        
        _processDomainPayment(tld, enableSubdomains);
        return tokenId;
    }
    
    function mintSubdomain(
        uint256 parentId,
        string calldata label
    ) external payable returns (uint256) {
        string memory parentDomain = LibAppStorage.appStorage().tokenIdToDomain[parentId];
        require(bytes(parentDomain).length > 0, "Parent not found");
        
        uint256 tokenId = LibMinting.createSubdomain(label, parentDomain);
        
        // Mint the ERC721 token
        _mint(msg.sender, tokenId);
        
        _processSubdomainPayment(parentDomain);
        return tokenId;
    }
    
    // Metadata functions
    function setProfileURI(uint256 tokenId, string calldata uri) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        LibMetadata.setProfileURI(tokenId, uri);
    }
    
    function setImageURI(uint256 tokenId, string calldata uri) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        LibMetadata.setImageURI(tokenId, uri);
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return LibMetadata.tokenURI(tokenId);
    }
    
    // Admin functions
    function updateFee(string calldata feeType, uint256 newAmount) external onlyRole(ADMIN_ROLE) {
        LibAdmin.updateFee(feeType, newAmount);
    }
    
    function configureTLD(string calldata tld, bool isActive, uint256 price) external onlyRole(ADMIN_ROLE) {
        LibAdmin.configureTLD(tld, isActive, price);
    }
    
    // Registry functions
    function enableFeature(uint256 tokenId, uint256 feature) external {
        require(ownerOf(tokenId) == msg.sender, "Not token owner");
        LibRegistry.enableFeature(tokenId, feature);
    }
    
    function hasFeature(uint256 tokenId, uint256 feature) external view returns (bool) {
        return LibRegistry.hasFeature(tokenId, feature);
    }
    
    // Reverse resolution functions
    function setReverse(string calldata domain) external {
        LibReverse.setReverse(domain);
    }
    
    function getReverse(address addr) external view returns (string memory) {
        return LibReverse.getReverse(addr);
    }
    
    // Internal payment processing
    function _processDomainPayment(string calldata tld, bool withEnhancements) internal {
        AppStorage storage store = LibAppStorage.appStorage();
        
        uint256 totalCost = 0;
        if (!store.freeTlds[tld]) {
            totalCost += store.tldPrices[tld];
        }
        if (withEnhancements) {
            totalCost += store.enhancementPrices["subdomain"];
        }
        
        require(msg.value >= totalCost, "Insufficient payment");
        store.totalRevenue += totalCost;
        
        // Send to fee collector
        if (totalCost > 0 && store.feeCollector != address(0)) {
            payable(store.feeCollector).transfer(totalCost);
        }
        
        // Send excess back
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }
    
    function _processSubdomainPayment(string memory parentDomain) internal {
        uint256 cost = LibMinting.calculateSubdomainFee(parentDomain);
        require(msg.value >= cost, "Insufficient payment");
        
        AppStorage storage store = LibAppStorage.appStorage();
        store.totalRevenue += cost;
        
        // Send to fee collector
        if (cost > 0 && store.feeCollector != address(0)) {
            payable(store.feeCollector).transfer(cost);
        }
        
        // Send excess back
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    
    // Internal helper functions
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || 
                getApproved(tokenId) == spender || 
                isApprovedForAll(owner, spender));
    }
    
    // Override transfers to maintain our custom storage
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        super.transferFrom(from, to, tokenId);
        
        // Update our custom domain storage
        AppStorage storage s = LibAppStorage.appStorage();
        s.domains[tokenId].owner = to;
        
        emit DomainTransferred(tokenId, from, to);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        super.safeTransferFrom(from, to, tokenId, data);
        
        // Update our custom domain storage
        AppStorage storage s = LibAppStorage.appStorage();
        s.domains[tokenId].owner = to;
        
        emit DomainTransferred(tokenId, from, to);
    }
    
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721Upgradeable, AccessControlUpgradeable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}
