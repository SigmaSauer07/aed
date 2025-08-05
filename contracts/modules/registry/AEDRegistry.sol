// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibRegistry.sol";
import "../base/ModuleBase.sol";
import "../../libraries/LibAppStorage.sol";

contract AEDRegistry is ModuleBase {
    using LibAppStorage for AppStorage;
    
    function enableFeature(uint256 tokenId, uint256 feature) external onlyTokenOwner(tokenId) {
        LibRegistry.enableFeature(tokenId, feature);
    }
    
    function disableFeature(uint256 tokenId, uint256 feature) external onlyTokenOwner(tokenId) {
        LibRegistry.disableFeature(tokenId, feature);
    }
    
    function checkFeature(uint256 tokenId, uint256 feature) external view returns (bool) {
        return LibRegistry.hasFeature(tokenId, feature);
    }
    
    function linkExternalDomain(string calldata externalDomain, uint256 tokenId) external payable {
        LibRegistry.linkExternalDomain(externalDomain, tokenId);
    }
    
    function unlinkExternalDomain(string calldata externalDomain) external {
        LibRegistry.unlinkExternalDomain(externalDomain);
    }
    
    function isExternalDomainLinked(string calldata externalDomain) external view returns (bool) {
        return LibRegistry.isExternalDomainLinked(externalDomain);
    }
    
    function getLinkedToken(string calldata externalDomain) external view returns (uint256) {
        return LibRegistry.getLinkedToken(externalDomain);
    }
    
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AED_REGISTRY");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AED Registry";
    }
}
