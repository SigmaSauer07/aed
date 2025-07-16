// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../../core/AEDConstants.sol";
import "../../core/interfaces/IAEDModule.sol";
import "../../libraries/LibAppStorage.sol";

/**
 * @title ModuleRegistry
 * @dev Uses unified AppStorage via LibAppStorage for all storage access
 */
contract ModuleRegistry is Initializable, IAEDModule, AEDConstants {
    using LibAppStorage for AppStorage;

    // Use ModuleInfo from AppStorage.sol

    modifier onlyAdmin() {
        AppStorage storage s = LibAppStorage.getStorage();
        require(s.admins[msg.sender], "Not admin");
        _;
    }

    event ModuleRegistered(string modName, address moduleAddress, uint256 version);
    event ModuleUpgraded(string modName, address oldAddress, address newAddress, uint256 oldVersion, uint256 newVersion);
    event ModuleEnabled(string modName);
    event ModuleDisabled(string modName);

    // Register a new module
    function registerModule(
        string calldata modName,
        address moduleAddress,
        uint256 version,
        bytes4[] calldata selectors
    ) external {
        AppStorage storage s = LibAppStorage.getStorage();
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
    ) external onlyAdmin {
        AppStorage storage s = LibAppStorage.getStorage();
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
    function toggleModule(string calldata modName, bool enabled) external onlyAdmin {
        AppStorage storage s = LibAppStorage.getStorage();
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
        external
        view
        returns (ModuleInfo memory)
    {
        AppStorage storage s = LibAppStorage.getStorage();
        return s.modules[modName];
    }

    // Check if module needs upgrade
    function isModuleUpgradeable(string calldata modName, uint256 targetVersion)
        external
        view
        returns (bool)
    {
        AppStorage storage s = LibAppStorage.getStorage();
        return s.modules[modName].version < targetVersion;
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

        // Register selectors
        for (uint i = 0; i < selectors.length; i++) {
            s.selectorToModule[selectors[i]] = modName;
        }

        s.moduleVersions[modName] = version;
    }

    function _removeSelectors(AppStorage storage s, string memory modName) internal {
        bytes4[] memory selectors = s.modules[modName].selectors;
        for (uint i = 0; i < selectors.length; i++) {
            delete s.selectorToModule[selectors[i]];
        }
    }

    // Batch operations for efficiency
    function batchUpgradeModules(
        string[] calldata moduleNames,
        address[] calldata moduleAddresses,
        uint256[] calldata versions,
        bytes4[][] calldata selectors
    ) external onlyAdmin {
        require(moduleNames.length == moduleAddresses.length, "Length mismatch");
        require(moduleNames.length == versions.length, "Length mismatch");
        require(moduleNames.length == selectors.length, "Length mismatch");

        AppStorage storage s = LibAppStorage.getStorage();
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

    // --- IAEDModule interface stubs ---

    function moduleId() external pure override returns (bytes32) {
        return keccak256("ModuleRegistry");
    }

    function moduleVersion() external pure override returns (uint256) {
        return 1;
    }

    function dependencies() external pure override returns (bytes32[] memory) {
        bytes32[] memory deps = new bytes32[](0);
        return deps;
    }

    function initialize(bytes calldata) external override {}

    function isEnabled() external pure override returns (bool) {
        return true;
    }

    function moduleName() external pure override returns (string memory) {
        return "ModuleRegistry";
    }

    function getSelectors() external pure override returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](0);
        return selectors;
    }

    function initializeModule() external override {}

    function isInitialized() external pure override returns (bool) {
        return true;
    }

    function disable() external override {}

    function enable() external override {}
}