// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AEDConstants
 * @dev System-wide constants and feature flags
 */
contract AEDConstants {
    // Role constants (DEFAULT_ADMIN_ROLE is inherited from AccessControl)
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant TLD_MANAGER_ROLE = keccak256("TLD_MANAGER_ROLE");
    bytes32 public constant BRIDGE_MANAGER_ROLE = keccak256("BRIDGE_MANAGER_ROLE");
    
    // Domain validation constants
    uint256 public constant MIN_NAME_LENGTH = 1;
    uint256 public constant MAX_NAME_LENGTH = 63;
    uint256 public constant MAX_SUBDOMAINS = 20;
    
    // Feature flags
    uint256 public constant FEATURE_SUBDOMAINS = 1 << 0;
    uint256 public constant FEATURE_METADATA = 1 << 1;
    uint256 public constant FEATURE_REVERSE = 1 << 2;
    uint256 public constant FEATURE_BRIDGE = 1 << 3;
    
    // Module enumeration
    enum AEDModule {
        ADMIN,
        REGISTRY,
        MINTING,
        METADATA,
        REVERSE,
        ENHANCEMENTS,
        RECOVERY,
        BRIDGE
    }
    
    // Error messages
    string public constant ERROR_NOT_AUTHORIZED = "Not authorized";
    string public constant ERROR_INVALID_TOKEN = "Invalid token";
    string public constant ERROR_ALREADY_EXISTS = "Already exists";
    string public constant ERROR_DOES_NOT_EXIST = "Does not exist";
    string public constant ERROR_INVALID_PARAMETER = "Invalid parameter";
    string public constant ERROR_INSUFFICIENT_PAYMENT = "Insufficient payment";
    string public constant ERROR_EXPIRED = "Expired";
    string public constant ERROR_PAUSED = "Contract paused";
    
    // Custom errors for gas efficiency
    error InvalidNameLength();
    error DomainNotFound();
    error NotAuthorized();
    error InsufficientFunds();
    error ModuleNotFound();
    error InvalidTLD();
}
