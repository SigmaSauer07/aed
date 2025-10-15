// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../core/AppStorage.sol";
import "../../libraries/LibAppStorage.sol";
import "../../core/interfaces/IAEDModule.sol";

contract ModuleRegistry {
    using LibAppStorage for AppStorage;
    
    event ModuleRegistered(bytes32 indexed moduleId, address indexed moduleAddress, string name);
    event ModuleUpgraded(bytes32 indexed moduleId, address indexed oldAddress, address indexed newAddress);
    event ModuleDeactivated(bytes32 indexed moduleId);
    
    modifier onlyAdmin() {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.admins[msg.sender], "Not admin");
        _;
    }
    
    function registerModule(
        bytes32 moduleId,
        address moduleAddress,
        string calldata name
    ) external onlyAdmin {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(moduleAddress != address(0), "Invalid module address");
        require(!s.moduleRegistry[moduleId].isActive, "Module already registered");
        
        s.moduleRegistry[moduleId] = ModuleInfo({
            moduleAddress: moduleAddress,
            name: name,
            version: 1,
            isActive: true
        });
        
        emit ModuleRegistered(moduleId, moduleAddress, name);
    }
    
    function upgradeModule(
        bytes32 moduleId,
        address newModuleAddress
    ) external onlyAdmin {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(newModuleAddress != address(0), "Invalid module address");
        require(s.moduleRegistry[moduleId].isActive, "Module not registered");
        
        address oldAddress = s.moduleRegistry[moduleId].moduleAddress;
        s.moduleRegistry[moduleId].moduleAddress = newModuleAddress;
        s.moduleRegistry[moduleId].version++;
        
        emit ModuleUpgraded(moduleId, oldAddress, newModuleAddress);
    }
    
    function deactivateModule(bytes32 moduleId) external onlyAdmin {
        AppStorage storage s = LibAppStorage.appStorage();
        
        require(s.moduleRegistry[moduleId].isActive, "Module not active");
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