// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibMetadata.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDMetadata.sol";

abstract contract AEDMetadata is ModuleBase, IAEDMetadata {
    using LibMetadata for AppStorage;
    
    function setProfileURI(uint256 tokenId, string calldata uri) external override onlyTokenOwner(tokenId) {
        LibMetadata.setProfileURI(tokenId, uri);
    }
    
    function setImageURI(uint256 tokenId, string calldata uri) external override onlyTokenOwner(tokenId) {
        LibMetadata.setImageURI(tokenId, uri);
    }
    
    function getProfileURI(uint256 tokenId) external view override returns (string memory) {
        return LibMetadata.getProfileURI(tokenId);
    }
    
    function getImageURI(uint256 tokenId) external view override returns (string memory) {
        return LibMetadata.getImageURI(tokenId);
    }
    
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        return LibMetadata.tokenURI(tokenId);
    }
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDMetadata");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDMetadata";
    }
}
