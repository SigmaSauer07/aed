// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibRegistry.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDRegistry.sol";

abstract contract AEDRegistry is ModuleBase, IAEDRegistry {
    using LibRegistry for AppStorage;
    
    function enableFeature(uint256 tokenId, uint256 feature) external override onlyTokenOwner(tokenId) {
        LibRegistry.enableFeature(tokenId, feature);
    }
    
    function disableFeature(uint256 tokenId, uint256 feature) external override onlyTokenOwner(tokenId) {
        LibRegistry.disableFeature(tokenId, feature);
    }
    
    function hasFeature(uint256 tokenId, uint256 feature) external view override returns (bool) {
        return LibRegistry.hasFeature(tokenId, feature);
    }
    
    function linkExternalDomain(string calldata externalDomain, uint256 tokenId) external override payable {
        LibRegistry.linkExternalDomain(externalDomain, tokenId);
    }
    
    function unlinkExternalDomain(string calldata externalDomain) external override {
        LibRegistry.unlinkExternalDomain(externalDomain);
    }
    
    function getLinkedDomain(string calldata externalDomain) external view override returns (uint256) {
        return LibRegistry.getLinkedDomain(externalDomain);
    }
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDRegistry");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDRegistry";
    }
}
