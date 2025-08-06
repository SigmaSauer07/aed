// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../core/AppStorage.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibAdmin.sol";
import "../interfaces/modules/IAEDEnhancements.sol";

/// @title AED Enhancements Module
/// @dev Standalone enhancements module for the modular UUPS system
contract AEDEnhancementsModule is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IAEDEnhancements
{
    using LibAppStorage for AppStorage;
    
    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(LibAdmin.ADMIN_ROLE, admin);
    }
    
    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) 
        internal 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        override 
    {}
    
    // Module interface
    function moduleId() external pure returns (bytes32) {
        return keccak256("AEDEnhancements");
    }
    
    function moduleName() external pure returns (string memory) {
        return "AEDEnhancements";
    }
} 