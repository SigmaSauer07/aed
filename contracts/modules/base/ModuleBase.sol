// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibRoles.sol";
import "../../core/AEDConstants.sol";
import "../../core/interfaces/IAEDModule.sol";

abstract contract ModuleBase is Initializable, IAEDModule, AEDConstants {
    using LibAppStorage for AppStorage;
    using LibRoles for AppStorage;
    
    function s() internal pure returns (AppStorage storage) {
        return LibAppStorage.s();
    }
    
    modifier onlyAdmin() {
        LibRoles.requireAdmin(msg.sender);
        _;
    }
    
    modifier onlyFeeManager() {
        LibRoles.requireFeeManager(msg.sender);
        _;
    }
    
    modifier onlyTLDManager() {
        LibRoles.requireTLDManager(msg.sender);
        _;
    }
    
    modifier onlyBridgeManager() {
        LibRoles.requireBridgeManager(msg.sender);
        _;
    }
    
    modifier whenNotPaused() {
        require(!s().paused, "Contract paused");
        _;
    }
    
    modifier onlyTokenOwner(uint256 tokenId) {
        require(s().owners[tokenId] == msg.sender, "Not token owner");
        _;
    }
    
    function _hasRole(bytes32 role, address account) internal view returns (bool) {
        return LibRoles.hasRole(role, account);
    }
    
    function _tokenExists(uint256 tokenId) internal view returns (bool) {
        return s().owners[tokenId] != address(0);
    }
    
    function _isModuleEnabled(string memory modName) internal view returns (bool) {
        return s().moduleEnabled[modName];
    }
    
    // IAEDModule implementation stubs - to be overridden by modules
    function moduleId() external pure virtual override returns (bytes32) {
        return bytes32(0);
    }
    
    function moduleVersion() external pure virtual override returns (uint256) {
        return 1;
    }
    
    function dependencies() external pure virtual override returns (bytes32[] memory) {
        return new bytes32[](0);
    }
    
    function initialize(bytes calldata) external virtual override {}
    
    function isEnabled() external view virtual override returns (bool) {
        return !s().paused;
    }
    
    function moduleName() external pure virtual override returns (string memory) {
        return "BaseModule";
    }
    
    function getSelectors() external pure virtual override returns (bytes4[] memory) {
        return new bytes4[](0);
    }
    
    function initializeModule() external virtual override {}
    
    function isInitialized() external view virtual override returns (bool) {
        return true;
    }
    
    function disable() external virtual override onlyAdmin {
        // Module-specific disable logic
    }
    
    function enable() external virtual override onlyAdmin {
        // Module-specific enable logic
    }
}
