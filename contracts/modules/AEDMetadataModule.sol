// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibMetadata.sol";
import "../interfaces/modules/IAEDMetadata.sol";
import "./base/ModuleBase.sol";

/// @title AED Metadata Module
/// @dev Standalone metadata module for the modular UUPS system
contract AEDMetadataModule is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IAEDMetadata,
    AEDConstants,
    ModuleBase
{
    using LibAppStorage for AppStorage;
    using LibMetadata for AppStorage;
    
    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }
    
    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) 
        internal 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        override 
    {}
    
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
    
    // Module interface
    function moduleId() external pure returns (bytes32) {
        return keccak256("AEDMetadata");
    }
    
    function moduleName() external pure returns (string memory) {
        return "AEDMetadata";
    }
} 