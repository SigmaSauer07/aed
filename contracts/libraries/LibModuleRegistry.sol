// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "../libraries/LibAppStorage.sol";
import "../core/interfaces/IAEDModule.sol";

library LibModuleRegistry {
    using LibAppStorage for AppStorage;
    
    event ModuleRegistered(bytes32 indexed moduleId, address indexed moduleAddress, uint256 version);
    event ModuleUpgraded(bytes32 indexed moduleId, address indexed oldAddress, address indexed newAddress);
    event ModuleDeactivated(bytes32 indexed moduleId);
    
    function registerModule(
        bytes32 moduleId,
        address moduleAddress,
        uint256 version,
        bytes4[] calldata selectors
    ) external {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.moduleRegistry[moduleId].moduleAddress == address(0), "Module already exists");

        s.moduleRegistry[moduleId] = ModuleInfo({
            moduleAddress: moduleAddress,
            name: "",
            version: version,
            isActive: true
        });
        
        emit ModuleRegistered(moduleId, moduleAddress, version);
    }

    function upgradeModule(
        bytes32 moduleId,
        address newModuleAddress,
        uint256 newVersion
    ) external {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.moduleRegistry[moduleId].isActive, "Module not found");

        address oldAddress = s.moduleRegistry[moduleId].moduleAddress;
        s.moduleRegistry[moduleId].moduleAddress = newModuleAddress;
        s.moduleRegistry[moduleId].version = newVersion;

        emit ModuleUpgraded(moduleId, oldAddress, newModuleAddress);
    }

    function deactivateModule(bytes32 moduleId) external {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.moduleRegistry[moduleId].isActive, "Module not found");
        
        s.moduleRegistry[moduleId].isActive = false;
        emit ModuleDeactivated(moduleId);
    }

    function getModuleInfo(bytes32 moduleId) external view returns (ModuleInfo memory) {
        return LibAppStorage.appStorage().moduleRegistry[moduleId];
    }

    function isModuleActive(bytes32 moduleId) external view returns (bool) {
        return LibAppStorage.appStorage().moduleRegistry[moduleId].isActive;
    }

    function getModuleAddress(bytes32 moduleId) external view returns (address) {
        return LibAppStorage.appStorage().moduleRegistry[moduleId].moduleAddress;
    }
}