// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";
import "./LibAppStorage.sol";

/**
 * @title LibRoles
 * @dev Role-based access control library
 */
library LibRoles {
    using LibAppStorage for AppStorage;
    
    // Role constants
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant TLD_MANAGER_ROLE = keccak256("TLD_MANAGER_ROLE");
    bytes32 public constant BRIDGE_MANAGER_ROLE = keccak256("BRIDGE_MANAGER_ROLE");
    
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    
    /**
     * @dev Returns true if account has the role
     */
    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return LibAppStorage.appStorage().roles[role][account];
    }
    
    /**
     * @dev Grants role to account
     */
    function grantRole(bytes32 role, address account) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        if (!hasRole(role, account)) {
            s.roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }
    
    /**
     * @dev Revokes role from account
     */
    function revokeRole(bytes32 role, address account) internal {
        AppStorage storage s = LibAppStorage.appStorage();
        if (hasRole(role, account)) {
            s.roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
    
    /**
     * @dev Renounces role for caller
     */
    function renounceRole(bytes32 role, address account) internal {
        require(account == msg.sender, "Can only renounce roles for self");
        revokeRole(role, account);
    }
    
    /**
     * @dev Modifier to check if caller has role
     */
    function checkRole(bytes32 role) internal view {
        require(hasRole(role, msg.sender), "AccessControl: account missing role");
    }
    
    /**
     * @dev Modifier to check if caller has role with custom message
     */
    function checkRole(bytes32 role, address account) internal view {
        require(hasRole(role, account), "AccessControl: account missing role");
    }
}
