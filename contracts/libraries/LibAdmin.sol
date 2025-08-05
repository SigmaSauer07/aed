// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AEDConstants.sol";
import "./LibAppStorage.sol";

library LibAdmin {
    using LibAppStorage for AppStorage;
    
    event FeeUpdated(string feeType, uint256 oldFee, uint256 newFee);
    event TLDConfigured(string tld, bool isActive, uint256 price);
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);
    
    function updateFee(string calldata feeType, uint256 newAmount) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        uint256 oldFee = s.fees[feeType];
        s.fees[feeType] = newAmount;
        emit FeeUpdated(feeType, oldFee, newAmount);
    }

    function updateFeeRecipient(address newRecipient) internal {
        require(newRecipient != address(0), "Invalid recipient");
        AppStorage storage s = LibAppStorage.appStorage();
        s.feeCollector = newRecipient;
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
        s.roles[role][account] = true;
        
        // Update legacy mappings for compatibility
        bytes32 ADMIN_ROLE = keccak256("ADMIN_ROLE");
        bytes32 FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
        bytes32 TLD_MANAGER_ROLE = keccak256("TLD_MANAGER_ROLE");
        
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
        bytes32 ADMIN_ROLE = keccak256("ADMIN_ROLE");
        bytes32 FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
        bytes32 TLD_MANAGER_ROLE = keccak256("TLD_MANAGER_ROLE");
        
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
        s.paused = true;
    }
    
    function unpauseContract() internal {
        AppStorage storage s = LibAppStorage.appStorage();
        s.paused = false;
    }
}
