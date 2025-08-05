// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";
import "../core/interfaces/IAEDModule.sol";

/**
 * @title LibModuleRegistry
 * @dev Library for managing module registration and lifecycle
 */
library LibModuleRegistry {
    using LibAppStorage for AppStorage;
    
    event ModuleRegistered(string indexed moduleId, address indexed moduleAddress, uint256 version);
    event ModuleEnabled(string indexed moduleId);
    event ModuleDisabled(string indexed moduleId);
    event ModuleUpgraded(string indexed moduleId, address indexed newAddress, uint256 newVersion);
    
    /**
     * @notice Register a new module
     * @param moduleId The unique identifier for the module
     * @param moduleAddress The address of the module contract
     * @param version The version of the module
     */
    function registerModule(
        string memory moduleId,
        address moduleAddress,
        uint256 version
    ) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(moduleAddress != address(0), "Invalid module address");
        require(!s.moduleEnabled[moduleId], "Module already exists");
        
        s.moduleAddresses[moduleId] = moduleAddress;
        s.moduleVersions[moduleId] = version;
        s.moduleEnabled[moduleId] = true;
        
        emit ModuleRegistered(moduleId, moduleAddress, version);
    }
    
    /**
     * @notice Enable a module
     * @param moduleId The module identifier
     */
    function enableModule(string memory moduleId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.moduleAddresses[moduleId] != address(0), "Module not registered");
        s.moduleEnabled[moduleId] = true;
        emit ModuleEnabled(moduleId);
    }
    
    /**
     * @notice Disable a module
     * @param moduleId The module identifier
     */
    function disableModule(string memory moduleId) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.moduleAddresses[moduleId] != address(0), "Module not registered");
        s.moduleEnabled[moduleId] = false;
        emit ModuleDisabled(moduleId);
    }
    
    /**
     * @notice Upgrade a module to a new version
     * @param moduleId The module identifier
     * @param newAddress The new module contract address
     * @param newVersion The new version number
     */
    function upgradeModule(
        string memory moduleId,
        address newAddress,
        uint256 newVersion
    ) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.moduleAddresses[moduleId] != address(0), "Module not registered");
        require(newAddress != address(0), "Invalid new address");
        require(newVersion > s.moduleVersions[moduleId], "Version must be higher");
        
        s.moduleAddresses[moduleId] = newAddress;
        s.moduleVersions[moduleId] = newVersion;
        
        emit ModuleUpgraded(moduleId, newAddress, newVersion);
    }
    
    /**
     * @notice Check if a module is enabled
     * @param moduleId The module identifier
     * @return enabled Whether the module is enabled
     */
    function isModuleEnabled(string memory moduleId) internal view returns (bool) {
        return LibAppStorage.appStorage().moduleEnabled[moduleId];
    }
    
    /**
     * @notice Get module address
     * @param moduleId The module identifier
     * @return moduleAddress The address of the module
     */
    function getModuleAddress(string memory moduleId) internal view returns (address) {
        return LibAppStorage.appStorage().moduleAddresses[moduleId];
    }
    
    /**
     * @notice Get module version
     * @param moduleId The module identifier
     * @return version The version of the module
     */
    function getModuleVersion(string memory moduleId) internal view returns (uint256) {
        return LibAppStorage.appStorage().moduleVersions[moduleId];
    }
}