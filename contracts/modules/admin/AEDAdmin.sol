// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibAdmin.sol";
import "../base/ModuleBase.sol";
import "../../libraries/LibAppStorage.sol";

contract AEDAdmin is ModuleBase {
    using LibAppStorage for AppStorage;
    
    // Role constants
    bytes32 constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 constant TLD_MANAGER_ROLE = keccak256("TLD_MANAGER_ROLE");
    
    modifier onlyFeeManager() {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.roles[FEE_MANAGER_ROLE][msg.sender] || s.admins[msg.sender], "Not fee manager");
        _;
    }
    
    modifier onlyTLDManager() {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.roles[TLD_MANAGER_ROLE][msg.sender] || s.admins[msg.sender], "Not TLD manager");
        _;
    }

    function updateFee(string calldata feeType, uint256 newAmount) external onlyFeeManager {
        LibAdmin.updateFee(feeType, newAmount);
    }

    function updateFeeRecipient(address newRecipient) external onlyAdmin {
        LibAdmin.updateFeeRecipient(newRecipient);
    }
    
    function configureTLD(string calldata tld, bool isActive, uint256 price) external onlyTLDManager {
        LibAdmin.configureTLD(tld, isActive, price);
    }
    
    function updateSubdomainSettings(uint256 newMax, uint256 newBasePrice, uint256 newMultiplier) external onlyAdmin {
        // Implementation for subdomain settings
        AppStorage storage store = LibAppStorage.appStorage();
        store.futureUint256[0] = newMax;
        store.futureUint256[1] = newBasePrice;
        store.futureUint256[2] = newMultiplier;
    }
    
    function getFee(string calldata feeType) external view returns (uint256) {
        return LibAppStorage.appStorage().fees[feeType];
    }
    
    function isTLDActive(string calldata tld) external view returns (bool) {
        return LibAppStorage.appStorage().validTlds[tld];
    }
    
    function grantRole(bytes32 role, address account) external onlyAdmin {
        LibAdmin.grantRole(role, account);
    }
    
    function revokeRole(bytes32 role, address account) external onlyAdmin {
        LibAdmin.revokeRole(role, account);
    }
    
    function pause() external onlyAdmin {
        LibAdmin.pauseContract();
    }
    
    function unpause() external onlyAdmin {
        LibAdmin.unpauseContract();
    }

    function setGlobalDescription(string calldata description) external onlyAdmin {
        AppStorage storage s = LibAppStorage.appStorage();
        s.globalDescription = description;
    }

    function getGlobalDescription() external view returns (string memory) {
        return LibAppStorage.appStorage().globalDescription;
    }
    
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AED_ADMIN");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AED Admin";
    }
}
