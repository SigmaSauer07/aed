// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../base/ModuleBase.sol";
import "../../interfaces/modules/IAEDAdmin.sol";

/**
 * @title AEDAdmin
 * @dev Central administration module for fees, TLDs, roles, and emergency controls
 */
abstract contract AEDAdmin is ModuleBase, IAEDAdmin {
    event FeeUpdated(string indexed feeType, uint256 oldFee, uint256 newFee);
    event TLDConfigured(string indexed tld, bool isActive, uint256 price);
    event SubdomainSettingsUpdated(uint256 newMax, uint256 newBasePrice, uint256 newMultiplier);
    function initializeModule() external override {
        // Initialize admin defaults
        s().maxSubdomains = 20;
        s().basePrice = 0.001 ether;
        s().futureUint256[0] = 2; // multiplier
    }

    function updateFee(string calldata feeType, uint256 newAmount) external override {
        require(_hasRole(FEE_MANAGER_ROLE, msg.sender), "Not authorized");
        uint256 oldFee = s().fees[feeType];
        s().fees[feeType] = newAmount;
        emit FeeUpdated(feeType, oldFee, newAmount);
    }

    function updateFeeRecipient(address newRecipient) external override {
        require(_hasRole(FEE_MANAGER_ROLE, msg.sender), "Not authorized");
        require(newRecipient != address(0), "Invalid recipient");
        s().feeCollector = newRecipient;
    }

    function configureTLD(string calldata tld, bool isActive, uint256 price) external override {
        require(_hasRole(TLD_MANAGER_ROLE, msg.sender), "Not authorized");
        s().activeTLDs[tld] = isActive;
        s().tldPrices[tld] = price;
        emit TLDConfigured(tld, isActive, price);
    }

    function updateSubdomainSettings(
        uint256 newMax,
        uint256 newBasePrice,
        uint256 newMultiplier
    ) external override {
        require(_hasRole(ADMIN_ROLE, msg.sender), "Not authorized");
        require(newMax > 0, "Max subdomains must be > 0");
        
        s().maxSubdomains = newMax;
        s().basePrice = newBasePrice;
        s().multiplier = newMultiplier;
        
        emit SubdomainSettingsUpdated(newMax, newBasePrice, newMultiplier);
    }

    function getFee(string calldata feeType) external view override returns (uint256) {
        return s().fees[feeType];
    }

    function isTLDActive(string calldata tld) external view override returns (bool) {
        return s().activeTLDs[tld];
    }

    uint256[50] private __gap;
}