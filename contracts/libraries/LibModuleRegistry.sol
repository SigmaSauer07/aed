// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";
import "../core/AEDConstants.sol";
import "../core/interfaces/IAEDModule.sol";

library LibModuleRegistry {
    using LibAppStorage for AppStorage;
    
    event ModuleRegistered(string indexed modName, address indexed moduleAddress, uint256 version);
    event ModuleUpgraded(string indexed modName, address indexed oldAddress, address indexed newAddress, uint256 oldVersion, uint256 newVersion);
    event ModuleEnabled(string indexed modName);
    event ModuleDisabled(string indexed modName);

    // Register a new module
    function registerModule(
        string calldata modName,
        address moduleAddress,
        uint256 version,
        bytes4[] calldata selectors
    ) internal {
        AppStorage storage s = LibAppStorage.s();
        require(s.modules[modName].moduleAddress == address(0), "Module already exists");

        _setModuleInfo(s, modName, moduleAddress, version, selectors);
        emit ModuleRegistered(modName, moduleAddress, version);
    }

    // Upgrade existing module
    function upgradeModule(
        string calldata modName,
        address newModuleAddress,
        uint256 newVersion,
        bytes4[] calldata newSelectors
    ) internal {
        AppStorage storage s = LibAppStorage.s();
        ModuleInfo storage module = s.modules[modName];
        require(module.moduleAddress != address(0), "Module not found");
        require(newVersion > module.version, "Version must be higher");

        address oldAddress = module.moduleAddress;
        uint256 oldVersion = module.version;

        // Remove old selectors
        _removeSelectors(s, modName);

        // Set new module info
        _setModuleInfo(s, modName, newModuleAddress, newVersion, newSelectors);

        emit ModuleUpgraded(modName, oldAddress, newModuleAddress, oldVersion, newVersion);
    }

    // Enable/disable modules without upgrading
    function toggleModule(string calldata modName, bool enabled) internal {
        AppStorage storage s = LibAppStorage.s();
        ModuleInfo storage module = s.modules[modName];
        require(module.moduleAddress != address(0), "Module not found");
        module.enabled = enabled;

        if (enabled) {
            emit ModuleEnabled(modName);
        } else {
            emit ModuleDisabled(modName);
        }
    }

    // Get module info
    function getModuleInfo(string calldata modName)
        internal
        view
        returns (ModuleInfo memory)
    {
        AppStorage storage s = LibAppStorage.s();
        return s.modules[modName];
    }

    // Check if module needs upgrade
    function isModuleUpgradeable(string calldata modName, uint256 targetVersion)
        internal
        view
        returns (bool)
    {
        AppStorage storage s = LibAppStorage.s();
        return s.modules[modName].version < targetVersion;
    }

    // Check if module is enabled
    function isModuleEnabled(string calldata modName) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.s();
        return s.modules[modName].enabled;
    }

    // Internal helper functions
    function _setModuleInfo(
        AppStorage storage s,
        string memory modName,
        address moduleAddress,
        uint256 version,
        bytes4[] memory selectors
    ) internal {
        ModuleInfo storage module = s.modules[modName];
        module.moduleAddress = moduleAddress;
        module.version = version;
        module.enabled = true;
        module.deployedAt = block.timestamp;
        module.selectors = selectors;

        s.moduleVersions[modName] = version;
        s.moduleAddresses[modName] = moduleAddress;
        s.moduleEnabled[modName] = true;
    }

    function _removeSelectors(AppStorage storage s, string memory modName) internal {
        bytes4[] memory selectors = s.modules[modName].selectors;
        // Note: In a full implementation, you'd want to track selector mappings
        // For now, we just clear the selectors array
        delete s.modules[modName].selectors;
    }

    // Batch operations for efficiency
    function batchUpgradeModules(
        string[] calldata moduleNames,
        address[] calldata moduleAddresses,
        uint256[] calldata versions,
        bytes4[][] calldata selectors
    ) internal {
        require(moduleNames.length == moduleAddresses.length, "Length mismatch");
        require(moduleNames.length == versions.length, "Length mismatch");
        require(moduleNames.length == selectors.length, "Length mismatch");

        AppStorage storage s = LibAppStorage.s();
        for (uint i = 0; i < moduleNames.length; i++) {
            _upgradeModule(
                s,
                moduleNames[i],
                moduleAddresses[i],
                versions[i],
                selectors[i]
            );
        }
    }

    // Internalized upgrade logic for batch and single upgrades
    function _upgradeModule(
        AppStorage storage s,
        string calldata modName,
        address newModuleAddress,
        uint256 newVersion,
        bytes4[] calldata newSelectors
    ) internal {
        ModuleInfo storage module = s.modules[modName];
        require(module.moduleAddress != address(0), "Module not found");
        require(newVersion > module.version, "Version must be higher");

        address oldAddress = module.moduleAddress;
        uint256 oldVersion = module.version;

        // Remove old selectors
        _removeSelectors(s, modName);

        // Set new module info
        _setModuleInfo(s, modName, newModuleAddress, newVersion, newSelectors);

        emit ModuleUpgraded(modName, oldAddress, newModuleAddress, oldVersion, newVersion);
    }
}