// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./core/AppStorage.sol";
import "./core/AEDCore.sol";
import "./modules/admin/AEDAdmin.sol";
import "./modules/registry/AEDRegistry.sol";
import "./modules/minting/AEDMinting.sol";
import "./modules/metadata/AEDMetadata.sol";
import "./modules/reverse/AEDReverse.sol";
import "./modules/enhancements/AEDEnhancements.sol";
import "./modules/recovery/AEDRecovery.sol";
import "./modules/bridge/AEDBridge.sol";

contract AEDImplementation is 
    UUPSUpgradeable,
    ERC721Upgradeable,
    AccessControlUpgradeable,
    AEDCore,
    AEDAdmin,
    AEDRegistry,
    AEDMinting,
    AEDMetadata,
    AEDReverse,
    AEDEnhancements,
    AEDRecovery,
    AEDBridge
{
    using LibAppStorage for AppStorage;
    
    function initialize(
        string memory name,
        string memory symbol,
        address paymentWallet,
        address admin
    ) public initializer {
        __ERC721_init(name, symbol);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        __AEDCore_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        
        AppStorage storage s = LibAppStorage.appStorage();
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
    
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approval to current owner");
        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "Not owner nor approved"
        );
        
        _approve(to, tokenId);
    }
    
    function getApproved(uint256 tokenId) public view override returns (address) {
        require(_tokenExists(tokenId), "Token does not exist");
        return LibAppStorage.appStorage().tokenApprovals[tokenId];
    }
    
    function setApprovalForAll(address operator, bool approved) public override {
        require(operator != msg.sender, "Approve to caller");
        _setApprovalForAll(msg.sender, operator, approved);
    }
    
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return LibAppStorage.appStorage().operatorApprovals[owner][operator];
    }
    
    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _transfer(from, to, tokenId);
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {
        safeTransferFrom(from, to, tokenId, "");
    }
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }
    
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "Transfer to non ERC721Receiver");
    }
    
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private returns (bool) {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non ERC721Receiver");
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
    
    // Support interface detection
    function supportsInterface(bytes4 interfaceId) 
        public 
        view 
        override(ERC721Upgradeable, AccessControlUpgradeable) 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}
