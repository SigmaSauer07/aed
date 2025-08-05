// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibMinting.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDMinting.sol";

abstract contract AEDMinting is ModuleBase, IAEDMinting {
    
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
        string memory parentDomain = s().tokenIdToDomain[parentId];
        require(bytes(parentDomain).length > 0, "Parent not found");
        
        uint256 tokenId = LibMinting.createSubdomain(label, parentDomain);
        _processSubdomainPayment(parentId);
        return tokenId;
    }
    
    function calculateSubdomainFee(uint256 parentId) external view override returns (uint256) {
        string memory parentDomain = s().tokenIdToDomain[parentId];
        return LibMinting.calculateSubdomainFee(parentDomain);
    }
    
    function getDomainOwner(string calldata domain) external view returns (address) {
        return LibMinting.getDomainOwner(domain);
    }
    
    function _processDomainPayment(string calldata tld, bool withEnhancements) internal {
        AppStorage storage store = s();
        
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
    
    function _processSubdomainPayment(uint256 parentId) internal {
        uint256 cost = this.calculateSubdomainFee(parentId);
        require(msg.value >= cost, "Insufficient payment");
        
        AppStorage storage store = s();
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
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDMinting");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDMinting";
    }
}
