// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./LibAppStorage.sol";

library LibRoles {
    using LibAppStorage for AppStorage;
    
    // Role constants
    bytes32 constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 constant TLD_MANAGER_ROLE = keccak256("TLD_MANAGER_ROLE");
    bytes32 constant BRIDGE_MANAGER_ROLE = keccak256("BRIDGE_MANAGER_ROLE");
    
    event RoleGranted(bytes32 indexed role, address indexed account);
    event RoleRevoked(bytes32 indexed role, address indexed account);
    
    function grantRole(bytes32 role, address account) internal {
        AppStorage storage s = LibAppStorage.s();
        require(account != address(0), "Invalid account");
        
        s.roles[role][account] = true;
        
        // Update legacy mappings for compatibility
        if (role == ADMIN_ROLE) {
            s.admins[account] = true;
        } else if (role == FEE_MANAGER_ROLE) {
            s.feeManagers[account] = true;
        } else if (role == TLD_MANAGER_ROLE) {
            s.tldManagers[account] = true;
        } else if (role == BRIDGE_MANAGER_ROLE) {
            // Store in future storage for bridge managers
            s.futureAddressUint256[account] = 1;
        }
        
        emit RoleGranted(role, account);
    }
    
    function revokeRole(bytes32 role, address account) internal {
        AppStorage storage s = LibAppStorage.s();
        
        s.roles[role][account] = false;
        
        // Update legacy mappings for compatibility
        if (role == ADMIN_ROLE) {
            s.admins[account] = false;
        } else if (role == FEE_MANAGER_ROLE) {
            s.feeManagers[account] = false;
        } else if (role == TLD_MANAGER_ROLE) {
            s.tldManagers[account] = false;
        } else if (role == BRIDGE_MANAGER_ROLE) {
            // Clear from future storage
            s.futureAddressUint256[account] = 0;
        }
        
        emit RoleRevoked(role, account);
    }
    
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.s();
        return s.roles[role][account];
    }
    
    function isAdmin(address account) internal view returns (bool) {
        return hasRole(ADMIN_ROLE, account);
    }
    
    function isFeeManager(address account) internal view returns (bool) {
        return hasRole(FEE_MANAGER_ROLE, account);
    }
    
    function isTLDManager(address account) internal view returns (bool) {
        return hasRole(TLD_MANAGER_ROLE, account);
    }
    
    function isBridgeManager(address account) internal view returns (bool) {
        return hasRole(BRIDGE_MANAGER_ROLE, account);
    }
    
    function requireRole(bytes32 role, address account) internal view {
        require(hasRole(role, account), "Missing required role");
    }
    
    function requireAdmin(address account) internal view {
        require(isAdmin(account), "Admin role required");
    }
    
    function requireFeeManager(address account) internal view {
        require(isFeeManager(account), "Fee manager role required");
    }
    
    function requireTLDManager(address account) internal view {
        require(isTLDManager(account), "TLD manager role required");
    }
    
    function requireBridgeManager(address account) internal view {
        require(isBridgeManager(account), "Bridge manager role required");
    }
}