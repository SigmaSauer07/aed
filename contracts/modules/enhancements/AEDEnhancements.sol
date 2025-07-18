// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibEnhancements.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDEnhancements.sol";

abstract contract AEDEnhancements is ModuleBase, IAEDEnhancements {
    using LibEnhancements for AppStorage;
    
    function purchaseFeature(uint256 tokenId, string calldata featureName) external payable override {
        LibEnhancements.purchaseFeature(tokenId, featureName);
    }
    
    function enableSubdomains(uint256 tokenId) external payable override {
        LibEnhancements.enableSubdomains(tokenId);
    }
    
    function upgradeExternalDomain(string calldata externalDomain) external payable override {
        LibEnhancements.upgradeExternalDomain(externalDomain);
    }
    
    function getFeaturePrice(string calldata featureName) external view override returns (uint256) {
        return LibEnhancements.getFeaturePrice(featureName);
    }
    
    function isFeatureEnabled(uint256 tokenId, string calldata featureName) external view override returns (bool) {
        return LibEnhancements.isFeatureEnabled(tokenId, featureName);
    }
    
    function getAvailableFeatures() external view override returns (string[] memory) {
        return LibEnhancements.getAvailableFeatures();
    }
    
    function setFeaturePrice(string calldata featureName, uint256 price) external onlyAdmin {
        LibEnhancements.setFeaturePrice(featureName, price);
    }
    
    function addFeature(string calldata featureName, uint256 price, uint256 flag) external onlyAdmin {
        LibEnhancements.addFeature(featureName, price, flag);
    }
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDEnhancements");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDEnhancements";
    }
}
