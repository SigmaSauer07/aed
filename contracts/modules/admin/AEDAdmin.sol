// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../../libraries/LibAdmin.sol";
import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDAdmin.sol";

abstract contract AEDAdmin is ModuleBase, IAEDAdmin {
    using LibAdmin for AppStorage;

    function updateFee(string calldata feeType, uint256 newAmount) external override onlyFeeManager {
        LibAdmin.updateFee(feeType, newAmount);
    }

    function updateFeeRecipient(address newRecipient) external override onlyAdmin {
        LibAdmin.updateFeeRecipient(newRecipient);
    }
    
    function configureTLD(string calldata tld, bool isActive, uint256 price) external override onlyTLDManager {
        LibAdmin.configureTLD(tld, isActive, price);
    }
    
    function updateSubdomainSettings(uint256 newMax, uint256 newBasePrice, uint256 newMultiplier) external override onlyAdmin {
        // Implementation for subdomain settings
        AppStorage storage store = s();
        store.futureUint256[0] = newMax;
        store.futureUint256[1] = newBasePrice;
        store.futureUint256[2] = newMultiplier;
    }
    
    function getFee(string calldata feeType) external view override returns (uint256) {
        return s().fees[feeType];
    }
    
    function isTLDActive(string calldata tld) external view override returns (bool) {
        return s().validTlds[tld];
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
    
    // Module interface overrides
    function moduleId() external pure override returns (bytes32) {
        return keccak256("AEDAdmin");
    }
    
    function moduleName() external pure override returns (string memory) {
        return "AEDAdmin";
    }
}
