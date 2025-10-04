// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./external/oz/proxy/ERC1967/ERC1967Proxy.sol";
import "./core/AppStorage.sol";
import "./libraries/LibAppStorage.sol";

/// @title AED Proxy Router
/// @dev Routes calls to appropriate modules in the modular UUPS system
contract ProxyRouter {
    using LibAppStorage for AppStorage;
    
    address public coreImplementation;
    address public moduleRegistry;
    
    // Function selector mappings for each module
    mapping(bytes4 => address) public moduleSelectors;
    
    event ModuleRegistered(bytes4 indexed selector, address indexed module);
    event CallRouted(bytes4 indexed selector, address indexed module, bool success);
    
    constructor(address _coreImplementation, address _moduleRegistry) {
        coreImplementation = _coreImplementation;
        moduleRegistry = _moduleRegistry;
    }
    
    /// @dev Routes calls to appropriate modules based on function selector
    fallback() external payable {
        bytes4 selector = msg.sig;
        address targetModule = moduleSelectors[selector];
        
        if (targetModule == address(0)) {
            // Default to core implementation
            targetModule = coreImplementation;
        }
        
        // Delegate call to the target module
        (bool success, bytes memory result) = targetModule.delegatecall(msg.data);
        
        emit CallRouted(selector, targetModule, success);
        
        if (success) {
            assembly {
                return(add(result, 0x20), mload(result))
            }
        } else {
            assembly {
                revert(add(result, 0x20), mload(result))
            }
        }
    }
    
    /// @dev Initialize the system with core implementation
    function initialize(bytes calldata initData) external {
        require(msg.sender == moduleRegistry, "Only module registry can initialize");
        
        // Delegate call to core implementation for initialization
        (bool success, ) = coreImplementation.delegatecall(initData);
        require(success, "Initialization failed");
    }
    
    /// @dev Register function selectors for modules
    function registerModuleSelectors(bytes4[] calldata selectors, address module) external {
        require(msg.sender == moduleRegistry, "Only module registry can register selectors");
        
        for (uint256 i = 0; i < selectors.length; i++) {
            moduleSelectors[selectors[i]] = module;
            emit ModuleRegistered(selectors[i], module);
        }
    }
    
    /// @dev Get module for a specific function selector
    function getModuleForSelector(bytes4 selector) external view returns (address) {
        address module = moduleSelectors[selector];
        return module == address(0) ? coreImplementation : module;
    }
} 