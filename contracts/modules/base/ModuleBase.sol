// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../core/AppStorage.sol";
import "../../libraries/LibAppStorage.sol";
import "../../core/interfaces/IAEDModule.sol";

abstract contract ModuleBase is IAEDModule {
    using LibAppStorage for AppStorage;
    
    modifier onlyAdmin() {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.admins[msg.sender], "Not admin");
        _;
    }
    
    modifier onlyTokenOwner(uint256 tokenId) {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.owners[tokenId] == msg.sender, "Not token owner");
        _;
    }
    
    modifier tokenExists(uint256 tokenId) {
        require(_tokenExists(tokenId), "Token does not exist");
        _;
    }
    
    modifier whenNotPaused() {
        AppStorage storage s = LibAppStorage.appStorage();
        require(!s.paused, "Contract paused");
        _;
    }
    
    // Internal view functions
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return LibAppStorage.appStorage().owners[tokenId] != address(0);
    }
    
    function _isModuleEnabled(string memory moduleNameParam) internal view returns (bool) {
        return LibAppStorage.appStorage().moduleEnabled[moduleNameParam];
    }
    
    function _getDomainOwner(uint256 tokenId) internal view returns (address) {
        return LibAppStorage.appStorage().owners[tokenId];
    }
    
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return LibAppStorage.appStorage().roles[role][account];
    }
    
    function _setFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.domainFeatures[tokenId] |= feature;
    }
    
    function _removeFeature(uint256 tokenId, uint256 feature) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.domainFeatures[tokenId] &= ~feature;
    }
    
    function _hasFeature(uint256 tokenId, uint256 feature) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        return (s.domainFeatures[tokenId] & feature) != 0;
    }
    
    // IAEDModule interface implementations
    function moduleVersion() external pure virtual returns (uint256) {
        return 1;
    }
    
    function dependencies() external pure virtual returns (bytes32[] memory) {
        return new bytes32[](0);
    }
    
    function initialize(bytes calldata) external virtual {
        // Default empty implementation
    }
    
    function initializeModule() external virtual {
        // Default empty implementation
    }
    
    function isInitialized() external view virtual returns (bool) {
        return true; // Default to initialized
    }
    
    function isEnabled() external view virtual returns (bool) {
        return !LibAppStorage.appStorage().paused;
    }
    
    function enable() external virtual onlyAdmin {
        // Default empty implementation
    }
    
    function disable() external virtual onlyAdmin {
        // Default empty implementation
    }
    
    // Virtual functions that modules must implement
    function getSelectors() external pure virtual returns (bytes4[] memory) {
        return new bytes4[](0);
    }
    
    function moduleName() external pure virtual returns (string memory) {
        return "BaseModule";
    }
    
    function moduleId() external pure virtual returns (bytes32) {
        return keccak256("BASE_MODULE");
    }
}
