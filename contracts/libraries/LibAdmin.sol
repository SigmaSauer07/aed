// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AEDConstants.sol";
import "../core/AppStorage.sol";
import "./LibAppStorage.sol";

library LibAdmin {
    using LibAppStorage for AppStorage;
    
    // Define role constants locally since AEDConstants is a contract
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 constant TLD_MANAGER_ROLE = keccak256("TLD_MANAGER_ROLE");
    
    event FeeUpdated(string feeType, uint256 oldFee, uint256 newFee);
    event TLDConfigured(string tld, bool isActive, uint256 price);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);
    event FeeRecipientUpdated(address indexed oldRecipient, address indexed newRecipient);
    event ContractPaused();
    event ContractUnpaused();
    
    function updateFee(string calldata feeType, uint256 newAmount) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 oldFee = s.fees[feeType];
        s.fees[feeType] = newAmount;

        if (s.featureExists[feeType]) {
            s.enhancementPrices[feeType] = newAmount;
        }

        emit FeeUpdated(feeType, oldFee, newAmount);
    }

    function updateFeeRecipient(address newRecipient) internal {
        require(newRecipient != address(0), "Invalid recipient");
        AppStorage storage s = LibAppStorage.appStorage();
        address oldRecipient = s.feeCollector;
        s.feeCollector = newRecipient;
        emit FeeRecipientUpdated(oldRecipient, newRecipient);
    }
    
    function configureTLD(string calldata tld, bool isActive, uint256 price) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.validTlds[tld] = isActive;
        if (price > 0) {
            s.tldPrices[tld] = price;
            s.freeTlds[tld] = false;
        } else {
            s.freeTlds[tld] = true;
        }
        emit TLDConfigured(tld, isActive, price);
    }
    
    function grantRole(bytes32 role, address account) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(account != address(0), "Invalid account");
        
        s.roles[role][account] = true;
        
        // Update legacy mappings for compatibility
        if (role == ADMIN_ROLE) {
            s.admins[account] = true;
        } else if (role == FEE_MANAGER_ROLE) {
            s.feeManagers[account] = true;
        } else if (role == TLD_MANAGER_ROLE) {
            s.tldManagers[account] = true;
        }
        
        emit RoleGranted(role, account);
    }
    
    function revokeRole(bytes32 role, address account) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.roles[role][account] = false;
        
        // Update legacy mappings for compatibility
        if (role == ADMIN_ROLE) {
            s.admins[account] = false;
        } else if (role == FEE_MANAGER_ROLE) {
            s.feeManagers[account] = false;
        } else if (role == TLD_MANAGER_ROLE) {
            s.tldManagers[account] = false;
        }
        
        emit RoleRevoked(role, account);
    }
    
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.appStorage();
        return s.roles[role][account];
    }
    
    function pauseContract() internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(!s.paused, "Already paused");
        s.paused = true;
        emit ContractPaused();
    }
    
    function unpauseContract() internal {
        AppStorage storage s = LibAppStorage.appStorage();
        require(s.paused, "Not paused");
        s.paused = false;
        emit ContractUnpaused();
    }
    
    function getFee(string calldata feeType) internal view returns (uint256) {
        return LibAppStorage.appStorage().fees[feeType];
    }
    
    function isTLDActive(string calldata tld) internal view returns (bool) {
        return LibAppStorage.appStorage().validTlds[tld];
    }
    
    function getTLDPrice(string calldata tld) internal view returns (uint256) {
        return LibAppStorage.appStorage().tldPrices[tld];
    }
    
    function isFreeTLD(string calldata tld) internal view returns (bool) {
        return LibAppStorage.appStorage().freeTlds[tld];
    }
    
    function getFeeCollector() internal view returns (address) {
        return LibAppStorage.appStorage().feeCollector;
    }
    
    function isPaused() internal view returns (bool) {
        return LibAppStorage.appStorage().paused;
    }
}
