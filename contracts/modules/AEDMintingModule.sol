// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../core/AppStorage.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibMinting.sol";
import "../interfaces/modules/IAEDMinting.sol";
import "./base/ModuleBase.sol";
import "../libraries/LibAdmin.sol";

/// @title AED Minting Module
/// @dev Standalone minting module for the modular UUPS system
contract AEDMintingModule is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    ModuleBase,
    IAEDMinting
{
    using LibAppStorage for AppStorage;
    using LibMinting for AppStorage;
    
    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(LibAdmin.ADMIN_ROLE, admin);
    }
    
    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) 
        internal 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        override 
    {}
    
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) external payable override whenNotPaused returns (uint256) {
        uint256 tokenId = LibMinting.registerDomain(name, tld, enableSubdomains);
        _processDomainPayment(tld, enableSubdomains);
        return tokenId;
    }
    
    function mintSubdomain(
        uint256 parentId,
        string calldata label
    ) external payable override returns (uint256) {
        string memory parentDomain = LibAppStorage.appStorage().tokenIdToDomain[parentId];
        require(bytes(parentDomain).length > 0, "Parent not found");
        
        uint256 tokenId = LibMinting.createSubdomain(label, parentDomain);
        _processSubdomainPayment(parentId);
        return tokenId;
    }
    
    function calculateSubdomainFee(uint256 parentId) external view override returns (uint256) {
        string memory parentDomain = LibAppStorage.appStorage().tokenIdToDomain[parentId];
        uint256 subdomainCount = LibAppStorage.appStorage().subdomainCounts[parentDomain];
        return subdomainCount * 0.1 ether; // Linear pricing
    }
    
    function getDomainOwner(string calldata domain) external view returns (address) {
        return LibMinting.getDomainOwner(domain);
    }
    
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
        
        // Send excess back
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }
    
    function _processSubdomainPayment(uint256 parentId) internal {
        uint256 cost = this.calculateSubdomainFee(parentId);
        require(msg.value >= cost, "Insufficient payment");
        
        LibAppStorage.appStorage().totalRevenue += cost;
        
        // Send excess back
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    
    // Module interface
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDMinting");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDMinting";
    }
} 