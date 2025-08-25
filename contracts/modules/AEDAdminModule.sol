// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../core/AppStorage.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibAdmin.sol";
import "../interfaces/modules/IAEDAdmin.sol";

/// @title AED Admin Module
/// @dev Standalone admin module for the modular UUPS system
contract AEDAdminModule is 
    UUPSUpgradeable,
    AccessControlUpgradeable,
    IAEDAdmin
{
    using LibAppStorage for AppStorage;
    using LibAdmin for AppStorage;

    function initialize(address admin) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(LibAdmin.ADMIN_ROLE, admin);
        _grantRole(LibAdmin.FEE_MANAGER_ROLE, admin);
        _grantRole(LibAdmin.TLD_MANAGER_ROLE, admin);
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

    function updateFeeRecipient(address newRecipient) external override onlyRole(LibAdmin.ADMIN_ROLE) {
        LibAdmin.updateFeeRecipient(newRecipient);
    }
    
    function configureTLD(string calldata tld, bool isActive, uint256 price) external override onlyRole(LibAdmin.TLD_MANAGER_ROLE) {
        LibAdmin.configureTLD(tld, isActive, price);
    }
    
    function updateSubdomainSettings(uint256 newMax, uint256 newBasePrice, uint256 newMultiplier) external override onlyRole(LibAdmin.ADMIN_ROLE) {
        AppStorage storage store = LibAppStorage.appStorage();
        store.futureUint256[0] = newMax;
        store.futureUint256[1] = newBasePrice;
        store.futureUint256[2] = newMultiplier;
    }
    
    function getFee(string calldata feeType) external view override returns (uint256) {
        return LibAppStorage.appStorage().fees[feeType];
    }
    
    function isTLDActive(string calldata tld) external view override returns (bool) {
        return LibAppStorage.appStorage().validTlds[tld];
    }
    
    function grantRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.grantRole(role, account);
        LibAdmin.grantRole(role, account);
    }
    
    function revokeRole(bytes32 role, address account) public override onlyRole(getRoleAdmin(role)) {
        super.revokeRole(role, account);
        LibAdmin.revokeRole(role, account);
    }
    
    function pause() external onlyRole(LibAdmin.ADMIN_ROLE) {
        LibAdmin.pauseContract();
    }
    
    function unpause() external onlyRole(LibAdmin.ADMIN_ROLE) {
        LibAdmin.unpauseContract();
    }
    
    // Module interface
    function moduleId() external pure returns (bytes32) {
        return keccak256("AEDAdmin");
    }
    
    function moduleName() external pure returns (string memory) {
        return "AEDAdmin";
    }
} 