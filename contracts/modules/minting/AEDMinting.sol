// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibMinting.sol";
import "../base/ModuleBase.sol";
import "../../libraries/LibAppStorage.sol";

contract AEDMinting is ModuleBase {
    using LibAppStorage for AppStorage;
    
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) external payable returns (uint256) {
        return LibMinting.registerDomain(name, tld, enableSubdomains);
    }
    
    function mintSubdomain(
        uint256 parentId,
        string calldata label
    ) external payable returns (uint256) {
        string memory parentDomain = LibAppStorage.appStorage().tokenIdToDomain[parentId];
        require(bytes(parentDomain).length > 0, "Parent not found");
        
        return LibMinting.createSubdomain(label, parentDomain);
    }
    
    function calculateSubdomainFee(uint256 parentId) external view returns (uint256) {
        return LibMinting.calculateSubdomainFee(parentId);
    }
    
    function getDomainOwner(string calldata domain) external view returns (address) {
        return LibMinting.getDomainOwner(domain);
    }
    
    function batchRegisterDomains(
        string[] calldata names,
        string[] calldata tlds,
        bool[] calldata enableSubdomains
    ) external payable returns (uint256[] memory) {
        uint256[] memory tokenIds = LibMinting.batchRegisterDomains(names, tlds, enableSubdomains);
        
        // Calculate and process batch payment
        uint256 totalCost = 0;
        for (uint256 i = 0; i < names.length; i++) {
            totalCost += _calculateDomainCost(tlds[i], enableSubdomains[i]);
        }
        
        require(msg.value >= totalCost, "Insufficient payment");
        LibAppStorage.appStorage().totalRevenue += totalCost;
        
        // Send to fee collector
        if (totalCost > 0) {
            payable(LibAppStorage.appStorage().feeCollector).transfer(totalCost);
        }
        
        // Refund excess
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        return tokenIds;
    }
    
    function _processSubdomainPayment(uint256 parentId) internal {
        uint256 cost = LibMinting.calculateSubdomainFee(parentId);
        require(msg.value >= cost, "Insufficient payment");
        
        LibAppStorage.appStorage().totalRevenue += cost;
        
        // Send to fee collector
        if (cost > 0) {
            payable(LibAppStorage.appStorage().feeCollector).transfer(cost);
        }
        
        // Refund excess
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
    }
    
    function _calculateDomainCost(string calldata tld, bool withEnhancements) internal view returns (uint256) {
        AppStorage storage store = LibAppStorage.appStorage();
        uint256 totalCost = 0;
        
        // Add TLD cost
        if (!store.freeTlds[tld]) {
            totalCost += store.tldPrices[tld];
        }
        
        // Add enhancement cost
        if (withEnhancements) {
            totalCost += store.enhancementPrices["subdomain"];
        }
        
        return totalCost;
    }
    
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AED_MINTING");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AED Minting";
    }
    
    function getSelectors() external pure override returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](6);
        selectors[0] = this.registerDomain.selector;
        selectors[1] = this.mintSubdomain.selector;
        selectors[2] = this.calculateSubdomainFee.selector;
        selectors[3] = this.getDomainOwner.selector;
        selectors[4] = this.batchRegisterDomains.selector;
        selectors[5] = this.moduleId.selector;
        return selectors;
    }
}
