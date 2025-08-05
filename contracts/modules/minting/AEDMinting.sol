// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibMinting.sol";
import "../../libraries/LibAppStorage.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDMinting.sol";

abstract contract AEDMinting is ModuleBase, IAEDMinting {
    using LibMinting for AppStorage;
    using LibAppStorage for AppStorage;
    
    function registerDomain(
        string calldata name,
        string calldata tld,
        bool enableSubdomains
    ) external payable override whenNotPaused returns (uint256) {
        AppStorage storage s = LibAppStorage.s();
        
        // Calculate total cost
        uint256 totalCost = 0;
        if (!s.freeTlds[tld]) {
            totalCost += s.tldPrices[tld];
        }
        if (enableSubdomains) {
            totalCost += s.enhancementPrices["subdomain"];
        }
        
        // Validate payment
        require(msg.value >= totalCost, "Insufficient payment");
        
        // Register domain
        uint256 tokenId = LibMinting.registerDomain(name, tld, enableSubdomains);
        
        // Process payment
        if (totalCost > 0) {
            s.totalRevenue += totalCost;
            payable(s.feeCollector).transfer(totalCost);
        }
        
        // Refund excess
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        return tokenId;
    }
    
    function mintSubdomain(
        uint256 parentId,
        string calldata label
    ) external payable override returns (uint256) {
        AppStorage storage s = LibAppStorage.s();
        
        // Get parent domain
        string memory parentDomain = s.tokenIdToDomain[parentId];
        require(bytes(parentDomain).length > 0, "Parent domain not found");
        
        // Calculate fee
        uint256 fee = LibMinting.calculateSubdomainFee(parentId);
        require(msg.value >= fee, "Insufficient payment");
        
        // Create subdomain
        uint256 tokenId = LibMinting.createSubdomain(label, parentDomain);
        
        // Process payment
        if (fee > 0) {
            s.totalRevenue += fee;
            payable(s.feeCollector).transfer(fee);
        }
        
        // Refund excess
        if (msg.value > fee) {
            payable(msg.sender).transfer(msg.value - fee);
        }
        
        return tokenId;
    }
    
    function calculateSubdomainFee(uint256 parentId) external view override returns (uint256) {
        return LibMinting.calculateSubdomainFee(parentId);
    }
    
    function getDomainOwner(string calldata domain) external view returns (address) {
        return LibMinting.getDomainOwner(domain);
    }
    
    function batchRegisterDomains(
        string[] calldata names,
        string[] calldata tlds,
        bool[] calldata enableSubdomains
    ) external payable whenNotPaused returns (uint256[] memory) {
        AppStorage storage s = LibAppStorage.s();
        
        // Calculate total cost
        uint256 totalCost = 0;
        for (uint256 i = 0; i < names.length; i++) {
            if (!s.freeTlds[tlds[i]]) {
                totalCost += s.tldPrices[tlds[i]];
            }
            if (enableSubdomains[i]) {
                totalCost += s.enhancementPrices["subdomain"];
            }
        }
        
        require(msg.value >= totalCost, "Insufficient payment");
        
        // Register domains
        uint256[] memory tokenIds = LibMinting.batchRegisterDomains(names, tlds, enableSubdomains);
        
        // Process payment
        if (totalCost > 0) {
            s.totalRevenue += totalCost;
            payable(s.feeCollector).transfer(totalCost);
        }
        
        // Refund excess
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        return tokenIds;
    }
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDMinting");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDMinting";
    }
}
