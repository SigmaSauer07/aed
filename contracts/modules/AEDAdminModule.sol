// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../core/AppStorage.sol";
import "../core/AEDConstants.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibAdmin.sol";
import "../interfaces/modules/IAEDAdmin.sol";
import "./base/ModuleBase.sol";

/// @title AED Admin Module
/// @dev Standalone admin module for the modular UUPS system
contract AEDAdminModule is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IAEDAdmin,
    AEDConstants,
    ModuleBase
{
    using LibAppStorage for AppStorage;
    using LibAdmin for AppStorage;

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

    function updateFee(string calldata feeType, uint256 newAmount) external override onlyRole(LibAdmin.FEE_MANAGER_ROLE) {
        LibAdmin.updateFee(feeType, newAmount);
    }

    function updateFeeRecipient(address newRecipient) external override onlyRole(ADMIN_ROLE) {
        LibAppStorage.appStorage().feeCollector = newRecipient;
        emit FeeRecipientUpdated(newRecipient);
    }
    
    function configureTLD(string calldata tld, bool isActive, uint256 price) external override onlyRole(LibAdmin.TLD_MANAGER_ROLE) {
        LibAdmin.configureTLD(tld, isActive, price);
    }
    
    function updateSubdomainSettings(uint256 newMax, uint256 newBasePrice, uint256 newMultiplier) external override onlyRole(ADMIN_ROLE) {
        AppStorage storage s = LibAppStorage.appStorage();
        s.maxSubdomains = newMax;
        s.subdomainBasePrice = newBasePrice;
        s.subdomainMultiplier = newMultiplier;
        emit SubdomainSettingsUpdated(newMax, newBasePrice, newMultiplier);
    }
    
    function getFee(string calldata feeType) external view override returns (uint256) {
        return LibAppStorage.appStorage().fees[feeType];
    }
    
    function isTLDActive(string calldata tld) external view override returns (bool) {
        return LibAppStorage.appStorage().validTlds[tld];
    }
    
    function grantRole(bytes32 role, address account) public override(AccessControlUpgradeable, IAEDAdmin) onlyRole(ADMIN_ROLE) {
        _grantRole(role, account);
    }
    
    function revokeRole(bytes32 role, address account) public override(AccessControlUpgradeable, IAEDAdmin) onlyRole(ADMIN_ROLE) {
        _revokeRole(role, account);
    }
    
    function pause() external override onlyRole(ADMIN_ROLE) {
        LibAppStorage.appStorage().paused = true;
        emit ContractPaused();
    }
    
    function unpause() external override onlyRole(ADMIN_ROLE) {
        LibAppStorage.appStorage().paused = false;
        emit ContractUnpaused();
    }
    
    // Module interface
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AED_ADMIN");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AED Admin";
    }
} 