// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../core/AEDConstants.sol";
import "../../libraries/LibAppStorage.sol";
import "../../libraries/LibModuleRegistry.sol";
import "../../core/interfaces/IAEDModule.sol";

/**
 * @title ModuleRegistry
 * @dev Central registry for managing and upgrading AED modules
 */
contract ModuleRegistry is AEDConstants {
    using LibAppStorage for AppStorage;
    using LibModuleRegistry for AppStorage;
    
    event ModuleRegistered(string moduleName, address moduleAddress, uint256 version);
    event ModuleUpgraded(string moduleName, address oldAddress, address newAddress);
    
    modifier onlyAdmin() {
        AppStorage storage s = LibAppStorage.s();
        require(s.admins[msg.sender], "Not admin");
        _;
    }
    
    function registerModule(
        string calldata moduleName,
        address moduleAddress,
        uint256 version,
        bytes4[] calldata selectors
    ) external onlyAdmin {
        LibModuleRegistry.registerModule(moduleName, moduleAddress, version, selectors);
    }
    
    function upgradeModule(
        string calldata moduleName,
        address newModuleAddress,
        uint256 newVersion,
        bytes4[] calldata newSelectors
    ) external onlyAdmin {
        LibModuleRegistry.upgradeModule(moduleName, newModuleAddress, newVersion, newSelectors);
    }
    
    function toggleModule(string calldata moduleName, bool enabled) external onlyAdmin {
        LibModuleRegistry.toggleModule(moduleName, enabled);
    }
    
    function getModuleInfo(string calldata moduleName) external view returns (ModuleInfo memory) {
        return LibModuleRegistry.getModuleInfo(moduleName);
    }
    
    function isModuleEnabled(string calldata moduleName) external view returns (bool) {
        return LibModuleRegistry.isModuleEnabled(moduleName);
    }
    
    function isModuleUpgradeable(string calldata moduleName, uint256 targetVersion) external view returns (bool) {
        return LibModuleRegistry.isModuleUpgradeable(moduleName, targetVersion);
    }
}