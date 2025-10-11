// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./external/oz/access/AccessControl.sol";

/// @title AED Module Registry
/// @dev Manages module registration and routing in the modular UUPS system
contract ModuleRegistry is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    
    struct ModuleInfo {
        address implementation;
        string name;
        bool active;
        bytes4[] selectors;
    }
    
    mapping(bytes32 => ModuleInfo) public modules;
    mapping(bytes4 => bytes32) public selectorToModule;
    
    address public proxyRouter;
    
    event ModuleRegistered(bytes32 indexed moduleId, address indexed implementation, string name);
    event ModuleUpgraded(bytes32 indexed moduleId, address indexed oldImplementation, address indexed newImplementation);
    event ModuleDeactivated(bytes32 indexed moduleId);
    event SelectorRegistered(bytes4 indexed selector, bytes32 indexed moduleId);
    
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }
    
    /// @dev Register a new module
    function registerModule(
        bytes32 moduleId, 
        address implementation, 
        string memory name
    ) external onlyRole(ADMIN_ROLE) {
        require(modules[moduleId].implementation == address(0), "Module already exists");
        require(implementation != address(0), "Invalid implementation");
        
        modules[moduleId] = ModuleInfo({
            implementation: implementation,
            name: name,
            active: true,
            selectors: new bytes4[](0)
        });
        
        emit ModuleRegistered(moduleId, implementation, name);
    }
    
    /// @dev Upgrade a module implementation
    function upgradeModule(bytes32 moduleId, address newImplementation) external onlyRole(ADMIN_ROLE) {
        require(modules[moduleId].implementation != address(0), "Module does not exist");
        require(newImplementation != address(0), "Invalid implementation");
        
        address oldImplementation = modules[moduleId].implementation;
        modules[moduleId].implementation = newImplementation;
        
        emit ModuleUpgraded(moduleId, oldImplementation, newImplementation);
    }
    
    /// @dev Deactivate a module
    function deactivateModule(bytes32 moduleId) external onlyRole(ADMIN_ROLE) {
        require(modules[moduleId].implementation != address(0), "Module does not exist");
        
        modules[moduleId].active = false;
        
        emit ModuleDeactivated(moduleId);
    }
    
    /// @dev Register function selectors for a module
    function registerSelectors(bytes32 moduleId, bytes4[] calldata selectors) external onlyRole(ADMIN_ROLE) {
        require(modules[moduleId].implementation != address(0), "Module does not exist");
        require(modules[moduleId].active, "Module is not active");
        
        ModuleInfo storage module = modules[moduleId];
        
        for (uint256 i = 0; i < selectors.length; i++) {
            bytes4 selector = selectors[i];
            
            // Remove selector from old module if it exists
            bytes32 oldModuleId = selectorToModule[selector];
            if (oldModuleId != bytes32(0)) {
                _removeSelectorFromModule(oldModuleId, selector);
            }
            
            // Add selector to new module
            selectorToModule[selector] = moduleId;
            module.selectors.push(selector);
            
            emit SelectorRegistered(selector, moduleId);
        }
    }
    
    /// @dev Get module implementation for a selector
    function getModuleForSelector(bytes4 selector) external view returns (address) {
        bytes32 moduleId = selectorToModule[selector];
        if (moduleId == bytes32(0)) {
            return address(0); // No module found
        }
        
        ModuleInfo storage module = modules[moduleId];
        return module.active ? module.implementation : address(0);
    }
    
    /// @dev Get module info
    function getModuleInfo(bytes32 moduleId) external view returns (ModuleInfo memory) {
        return modules[moduleId];
    }
    
    /// @dev Set proxy router address
    function setProxyRouter(address _proxyRouter) external onlyRole(ADMIN_ROLE) {
        proxyRouter = _proxyRouter;
    }
    
    /// @dev Remove selector from module (internal)
    function _removeSelectorFromModule(bytes32 moduleId, bytes4 selector) internal {
        ModuleInfo storage module = modules[moduleId];
        bytes4[] storage selectors = module.selectors;
        
        for (uint256 i = 0; i < selectors.length; i++) {
            if (selectors[i] == selector) {
                // Remove by swapping with last element
                selectors[i] = selectors[selectors.length - 1];
                selectors.pop();
                break;
            }
        }
    }
} 