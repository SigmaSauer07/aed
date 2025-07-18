// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "";
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
    
    struct ModuleInfo {
        address moduleAddress;
        uint256 version;
        bool enabled;
        bytes4[] selectors;
    }
    
    event ModuleRegistered(string moduleName, address moduleAddress, uint256 version);
    event ModuleUpgraded(string moduleName, address oldAddress, address newAddress);
    
    modifier onlyAdmin() {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.admins[msg.sender], "Not admin");
        _;
    }
    
    function registerModule(
        string calldata moduleName,
        address moduleAddress,
        uint256 version,
        bytes4[] calldata selectors
    ) external onlyAdmin {
        AppStorage storage s = LibAppStorage.appStorage();
        
        if (s.moduleAddresses[moduleName] != address(0)) {
            emit ModuleUpgraded(moduleName, s.moduleAddresses[moduleName], moduleAddress);
        }
        
        s.moduleAddresses[moduleName] = moduleAddress;
        s.moduleVersions[moduleName] = version;
        s.moduleEnabled[moduleName] = true;
        
        emit ModuleRegistered(moduleName, moduleAddress, version);
    }
    
    function upgradeModule(
        string calldata moduleName,
        address newModuleAddress,
        uint256 newVersion
    ) external onlyAdmin {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.moduleAddresses[moduleName] != address(0), "Module not found");
        
        address oldAddress = s.moduleAddresses[moduleName];
        s.moduleAddresses[moduleName] = newModuleAddress;
        s.moduleVersions[moduleName] = newVersion;
        
        emit ModuleUpgraded(moduleName, oldAddress, newModuleAddress);
    }
}