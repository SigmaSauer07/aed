// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../modules/base/ModuleBase.sol";
import "../libraries/LibBadgeCreator.sol";
import "../libraries/LibBadges.sol";
import "../libraries/LibAppStorage.sol";

/**
 * @title AEDAI
 * @dev Module for AI subdomain management and capability system
 */
contract AEDAI is ModuleBase {
    using LibAppStorage for AppStorage;
    
    /**
     * @dev Create AI subdomain for a specific model
     * @param label Subdomain label (e.g., "echo", "aegis")
     * @param parentDomain Parent domain name
     * @param modelType AI model identifier (e.g., "gpt-4", "claude-3", "deepseek")
     */
    function createAISubdomain(
        string calldata label,
        string calldata parentDomain,
        string calldata modelType
    ) external payable whenNotPaused returns (uint256) {
        // Calculate and check payment
        uint256 price = LibBadgeCreator.calculateAISubdomainFee();
        require(msg.value >= price, "Insufficient payment");
        
        // Create AI subdomain
        uint256 tokenId = LibBadgeCreator.createAISubdomain(label, parentDomain, modelType);
        
        // Process payment
        AppStorage storage s = LibAppStorage.appStorage();
        s.totalRevenue += price;
        
        if (price > 0) {
            payable(s.feeCollector).transfer(price);
        }
        
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
        
        return tokenId;
    }
    
    /**
     * @dev Purchase AI capability for AI subdomain
     * @param tokenId The AI subdomain token ID
     * @param capabilityType Type of capability ("vision", "communication", "memory", "reasoning")
     */
    function purchaseAICapability(
        uint256 tokenId,
        string calldata capabilityType
    ) external payable whenNotPaused {
        LibBadgeCreator.purchaseAICapability(tokenId, capabilityType);
        
        // Payment already processed in LibBadgeCreator
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 price = _getCapabilityPrice(capabilityType);
        
        if (price > 0) {
            payable(s.feeCollector).transfer(price);
        }
        
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }
    
    /**
     * @dev Award a custom badge to a domain (admin only)
     * @param tokenId Token to award badge to
     * @param badgeType Badge identifier
     * @param memoryData Additional badge data
     * @param isCapability Whether this is a capability badge
     */
    function awardBadge(
        uint256 tokenId,
        string calldata badgeType,
        bytes calldata memoryData,
        bool isCapability
    ) external onlyAdmin {
        LibBadges.awardBadge(tokenId, badgeType, memoryData, isCapability);
    }
    
    /**
     * @dev Check if AI subdomain has specific capability
     */
    function hasAICapability(
        uint256 tokenId,
        string calldata capabilityType
    ) external view returns (bool) {
        return LibBadgeCreator.hasAICapability(tokenId, capabilityType);
    }
    
    /**
     * @dev Check if domain has specific badge
     */
    function hasBadge(
        uint256 tokenId,
        string calldata badgeType
    ) external view returns (bool) {
        return LibBadges.hasBadge(tokenId, badgeType);
    }
    
    /**
     * @dev Get all badges for a token
     */
    function getTokenBadges(uint256 tokenId) external view returns (Badge[] memory) {
        return LibBadges.getTokenBadges(tokenId);
    }
    
    /**
     * @dev Get evolution level for a token
     */
    function getEvolutionLevel(uint256 tokenId) external view returns (uint256) {
        return LibBadges.getEvolutionLevel(tokenId);
    }
    
    /**
     * @dev Get AI subdomain token ID for a model under parent
     */
    function getAISubdomain(
        string calldata parentDomain,
        string calldata modelType
    ) external view returns (uint256) {
        return LibBadgeCreator.getAISubdomain(parentDomain, modelType);
    }
    
    /**
     * @dev Check if token is an AI subdomain
     */
    function isAISubdomain(uint256 tokenId) external view returns (bool) {
        return LibBadgeCreator.isAISubdomain(tokenId);
    }
    
    /**
     * @dev Get model type for AI subdomain
     */
    function getModelType(uint256 tokenId) external view returns (string memory) {
        return LibBadgeCreator.getModelType(tokenId);
    }
    
    /**
     * @dev Get AI subdomain creation fee
     */
    function getAISubdomainFee() external pure returns (uint256) {
        return LibBadgeCreator.calculateAISubdomainFee();
    }
    
    /**
     * @dev Get capability price
     */
    function getCapabilityPrice(string calldata capabilityType) external pure returns (uint256) {
        return _getCapabilityPrice(capabilityType);
    }
    
    /**
     * @dev Internal capability price getter
     */
    function _getCapabilityPrice(string memory capabilityType) private pure returns (uint256) {
        bytes32 typeHash = keccak256(bytes(capabilityType));
        
        if (typeHash == keccak256("vision")) return 0.2 ether;
        if (typeHash == keccak256("communication")) return 0.15 ether;
        if (typeHash == keccak256("memory")) return 0.25 ether;
        if (typeHash == keccak256("reasoning")) return 0.3 ether;
        
        return 0.1 ether; // Default
    }
    
    // Module interface
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AED_AI");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AED AI";
    }
    
    function getSelectors() external pure override returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](13);
        selectors[0] = this.createAISubdomain.selector;
        selectors[1] = this.purchaseAICapability.selector;
        selectors[2] = this.awardBadge.selector;
        selectors[3] = this.hasAICapability.selector;
        selectors[4] = this.hasBadge.selector;
        selectors[5] = this.getTokenBadges.selector;
        selectors[6] = this.getEvolutionLevel.selector;
        selectors[7] = this.getAISubdomain.selector;
        selectors[8] = this.isAISubdomain.selector;
        selectors[9] = this.getModelType.selector;
        selectors[10] = this.getAISubdomainFee.selector;
        selectors[11] = this.getCapabilityPrice.selector;
        selectors[12] = this.moduleId.selector;
        return selectors;
    }
}