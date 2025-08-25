// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "../libraries/LibAppStorage.sol";
import "../interfaces/modules/IAEDReverse.sol";
import "./base/ModuleBase.sol";

/// @title AED Reverse Module
/// @dev Standalone reverse module for the modular UUPS system
contract AEDReverseModule is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IAEDReverse,
    AEDConstants,
    ModuleBase
{
    using LibAppStorage for AppStorage;
    
    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
    }
    
    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) 
        internal 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        override 
    {}
    
    // Module interface
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AED_REVERSE");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AED Reverse";
    }
    
    // Reverse functions
    function setReverse(string calldata domain) external override {
        require(LibAppStorage.appStorage().owners[LibAppStorage.appStorage().domainToTokenId[domain]] == msg.sender, "Not domain owner");
        // Placeholder implementation - would need actual reverse logic
    }
    
    function clearReverse() external override {
        // Placeholder implementation - would need actual reverse logic
    }
    
    function getReverse(address addr) external view override returns (string memory) {
        return LibAppStorage.appStorage().reverseRecords[addr];
    }
    
    function getReverseOwner(string calldata domain) external view override returns (address) {
        return LibAppStorage.appStorage().reverseOwners[domain];
    }
} 