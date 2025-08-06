// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./core/AppStorage.sol";
import "./libraries/LibAppStorage.sol";
import "./libraries/LibAdmin.sol";

/// @title AED Core Implementation
/// @dev Simplified implementation containing only essential ERC721 functionality
/// This contract is designed to be small enough to deploy while maintaining core functionality
contract AEDCoreImplementation is 
    UUPSUpgradeable,
    ERC721Upgradeable,
    AccessControlUpgradeable
{
    using LibAppStorage for AppStorage;
    
    // Core events
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
        _grantRole(LibAdmin.ADMIN_ROLE, admin);
        
        AppStorage storage s = LibAppStorage.appStorage();
        s.nextTokenId = 1;
        s.baseURI = "https://api.alsania.io/metadata/";
        s.feeCollector = paymentWallet;
        s.admins[admin] = true;
        
        // Initialize default pricing
        s.enhancementPrices["subdomain"] = 2 ether;
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
        s.validTlds["aelion"] = true;
        s.validTlds["sigma"] = true;
        s.validTlds["mcp"] = true;
        s.validTlds["n3xt"] = true;
        s.validTlds["chain"] = true;
        s.validTlds["mind"] = true;
        s.validTlds["ai"] = true;
    }
    
    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) 
        internal 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        override 
    {}
    
    // ERC721 overrides using AppStorage
    function ownerOf(uint256 tokenId) 
        public 
        view 
        override 
        returns (address) 
    {
        AppStorage storage s = LibAppStorage.appStorage();
        address owner = s.owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    
    function balanceOf(address owner) 
        public 
        view 
        override 
        returns (uint256) 
    {
        require(owner != address(0), "Zero address query");
        return LibAppStorage.appStorage().balances[owner];
    }
    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        address owner = s.owners[tokenId];
        return (spender == owner || 
                s.operatorApprovals[owner][spender] || 
                s.tokenApprovals[tokenId] == spender);
    }
    
    // Core AED functions
    function getNextTokenId() external view returns (uint256) {
        return LibAppStorage.appStorage().nextTokenId;
    }

    function isRegistered(string calldata domain) external view returns (bool) {
        return LibAppStorage.appStorage().domainExists[domain];
    }

    function getDomainInfo(uint256 tokenId) external view returns (Domain memory) {
        require(LibAppStorage.appStorage().owners[tokenId] != address(0), "Token does not exist");
        return LibAppStorage.appStorage().domains[tokenId];
    }

    function getUserDomains(address user) external view returns (string[] memory) {
        return LibAppStorage.appStorage().userDomains[user];
    }

    function getTotalRevenue() external view returns (uint256) {
        return LibAppStorage.appStorage().totalRevenue;
    }
    
    // Domain registration function
    function registerDomain(string calldata domain, address owner) external payable {
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Parse domain into name and TLD
        (string memory name, string memory tld) = _parseDomain(domain);
        
        // Check if domain is already registered
        require(!s.domainExists[domain], "Domain already registered");
        
        // Validate TLD
        require(s.validTlds[tld], "Invalid TLD");
        
        // Check pricing
        uint256 price = s.freeTlds[tld] ? 0 : s.tldPrices[tld];
        require(msg.value >= price, "Insufficient payment");
        
        // Register the domain
        uint256 tokenId = s.nextTokenId;
        s.nextTokenId++;
        
        s.owners[tokenId] = owner;
        s.balances[owner]++;
        s.domainExists[domain] = true;
        
        // Store domain info
        s.domains[tokenId] = Domain({
            name: name,
            tld: tld,
            profileURI: "",
            imageURI: "",
            subdomainCount: 0,
            mintFee: 0,
            expiresAt: uint64(block.timestamp + 365 days),
            feeEnabled: false,
            isSubdomain: false,
            owner: owner
        });
        
        // Add to user's domain list
        s.userDomains[owner].push(domain);
        
        // Collect fees
        if (msg.value > 0) {
            s.totalRevenue += msg.value;
            (bool success, ) = s.feeCollector.call{value: msg.value}("");
            require(success, "Fee transfer failed");
        }
        
        emit Transfer(address(0), owner, tokenId);
        emit DomainRegistered(domain, owner, tokenId);
    }
    
    // Helper function to parse domain
    function _parseDomain(string calldata domain) internal pure returns (string memory name, string memory tld) {
        bytes memory domainBytes = bytes(domain);
        uint256 dotIndex = 0;
        
        // Find the last dot
        for (uint256 i = 0; i < domainBytes.length; i++) {
            if (domainBytes[i] == ".") {
                dotIndex = i;
            }
        }
        
        require(dotIndex > 0, "Invalid domain format");
        
        // Extract name and TLD
        bytes memory nameBytes = new bytes(dotIndex);
        bytes memory tldBytes = new bytes(domainBytes.length - dotIndex - 1);
        
        for (uint256 i = 0; i < dotIndex; i++) {
            nameBytes[i] = domainBytes[i];
        }
        
        for (uint256 i = 0; i < tldBytes.length; i++) {
            tldBytes[i] = domainBytes[dotIndex + 1 + i];
        }
        
        return (string(nameBytes), string(tldBytes));
    }
    
    // Basic transfer functionality
    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        override 
    {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        require(from == ownerOf(tokenId), "Wrong owner");
        require(to != address(0), "Invalid recipient");
        
        AppStorage storage s = LibAppStorage.appStorage();
        
        // Update balances
        s.balances[from]--;
        s.balances[to]++;
        
        // Update ownership
        s.owners[tokenId] = to;
        
        // Clear approval
        s.tokenApprovals[tokenId] = address(0);
        
        emit Transfer(from, to, tokenId);
        emit DomainTransferred(tokenId, from, to);
    }
    
    function approve(address to, uint256 tokenId) 
        public 
        override 
    {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approve to owner");
        require(msg.sender == owner || LibAppStorage.appStorage().operatorApprovals[owner][msg.sender], "Not approved");
        
        LibAppStorage.appStorage().tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }
    
    function setApprovalForAll(address operator, bool approved) 
        public 
        override 
    {
        require(operator != msg.sender, "Approve to self");
        LibAppStorage.appStorage().operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }
    
    function getApproved(uint256 tokenId) 
        public 
        view 
        override 
        returns (address) 
    {
        require(LibAppStorage.appStorage().owners[tokenId] != address(0), "Token does not exist");
        return LibAppStorage.appStorage().tokenApprovals[tokenId];
    }
    
    function isApprovedForAll(address owner, address operator) 
        public 
        view 
        override 
        returns (bool) 
    {
        return LibAppStorage.appStorage().operatorApprovals[owner][operator];
    }
    
    // Note: We don't override _transfer, _approve, or _setApprovalForAll
    // because OpenZeppelin's functions are not virtual
    // Our custom implementations handle the functionality directly
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
} 