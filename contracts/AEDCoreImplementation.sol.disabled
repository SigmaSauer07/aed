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
/// @dev Minimal implementation containing only essential ERC721 functionality
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
    event SubdomainCreated(string indexed subdomain, string indexed parent, address indexed owner);

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
    
    function _tokenExistsCustom(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.appStorage().owners[tokenId] != address(0);
    }
    
    function _isApprovedOrOwnerCustom(address spender, uint256 tokenId) internal view returns (bool) {
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

    function isRegistered(string calldata name, string calldata tld) external view returns (bool) {
        string memory fullDomain = string(abi.encodePacked(name, ".", tld));
        return LibAppStorage.appStorage().domainExists[fullDomain];
    }

    function getDomainInfo(uint256 tokenId) external view returns (Domain memory) {
        require(_tokenExistsCustom(tokenId), "Token does not exist");
        return LibAppStorage.appStorage().domains[tokenId];
    }

    function getUserDomains(address user) external view returns (string[] memory) {
        return LibAppStorage.appStorage().userDomains[user];
    }

    function getTotalRevenue() external view returns (uint256) {
        return LibAppStorage.appStorage().totalRevenue;
    }
    
    // Basic transfer functionality
    function transferFrom(address from, address to, uint256 tokenId) 
        public 
        override 
    {
        require(_isApprovedOrOwnerCustom(msg.sender, tokenId), "Not approved");
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
    
    function safeTransferFrom(address from, address to, uint256 tokenId) 
        public 
        virtual 
        override 
    {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) 
        public 
        virtual 
        override 
    {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_tokenExistsCustom(tokenId), "Token does not exist");
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
    
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) 
        private 
        returns (bool) 
    {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
    
    // Required overrides
    function _transfer(address from, address to, uint256 tokenId) internal virtual override {
        // This is handled by our custom transferFrom
    }
    
    function _approve(address to, uint256 tokenId, address auth) internal virtual override {
        // This is handled by our custom approve
    }
    
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual override {
        // This is handled by our custom setApprovalForAll
    }
    
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlUpgradeable, ERC721Upgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
} 