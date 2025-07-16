// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AEDConstants
 * @dev System-wide constants and feature flags
 */
contract AEDConstants {

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

    // Roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant FEE_MANAGER_ROLE = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant TLD_MANAGER_ROLE = keccak256("TLD_MANAGER_ROLE");
    bytes32 public constant RECOVERY_ROLE = keccak256("RECOVERY_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant BRIDGE_MANAGER_ROLE = keccak256("BRIDGE_MANAGER_ROLE");
    bytes32 public constant RESOLVER_ROLE = keccak256("RESOLVER_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");



    // Feature flags (powers of 2)
    uint256 public constant FEATURE_PROFILE = 1;
    uint256 public constant FEATURE_REVERSE = 2;
    uint256 public constant FEATURE_SUBDOMAINS = 4;
    uint256 public constant FEATURE_BRIDGE = 8;
    uint256 public constant FEATURE_RECOVERY = 16;
    uint256 public constant FEATURE_METADATA = 32;
    uint256 public constant FEATURE_ALL = 63;         // All features combined


    // Pricing constants
    uint256 public constant DEFAULT_SUBDOMAIN_UNLOCK_PRICE = 0.001 ether;
    uint256 public constant DEFAULT_SUBDOMAIN_UNLOCK_PRICE_BYO = 0.002 ether; // For BYO domains
    uint256 public constant DEFAULT_RECOVERY_FEE = 0.001 ether;
    uint256 public constant DEFAULT_ROYALTY_BPS = 100; // 1%
    uint256 public constant DEFAULT_BASE_PRICE = 0.001 ether;
    uint256 public constant DEFAULT_MULTIPLIER = 2;

    // System limits
    uint256 public constant MAX_DOMAIN_LENGTH = 63;
    uint256 public constant MIN_DOMAIN_LENGTH = 1;
    uint256 public constant MAX_TLD_LENGTH = 10;
    uint256 public constant MAX_URI_LENGTH = 512;
    uint256 public constant DEFAULT_MAX_SUBDOMAINS = 20;
    uint256 public constant DEFAULT_MAX_GUARDIANS = 5;
    uint256 public constant MIN_NAME_LENGTH = 3;
    uint256 public constant MAX_NAME_LENGTH = 63;
    uint256 public constant MIN_GUARDIAN_THRESHOLD = 1;

    // Free TLD hashes (for gas optimization)
    bytes32 public constant FREE_TLD_AED = keccak256("aed");
    bytes32 public constant FREE_TLD_ALSA = keccak256("alsa");
    bytes32 public constant FREE_TLD_07 = keccak256("07");


    // Time constants
    uint256 public constant RECOVERY_DELAY_DEFAULT = 3 days;
    uint256 public constant DOMAIN_EXPIRY_DEFAULT = 365 days;

    // Visual constants for metadata
    string public constant NEON_GREEN = "#";
    string public constant DOMAIN_BG = "https://ipfs.io/ipfs/QmX9ZsQkzgWuUwRJyLrKjxNqGvVfPnDhBpCtEaAeYbVdEo/domain-bg.png";
    string public constant SUB_BG = "https://ipfs.io/ipfs/QmX9ZsQkzgWuUwRJyLrKjxNqGvVfPnDhBpCtEaAeYbVdEo/subdomain-bg.png";

    // Fee types
    string public constant FEE_TYPE_MINTING = "minting";
    string public constant FEE_TYPE_RENEWAL = "renewal";
    string public constant FEE_TYPE_TRANSFER = "transfer";
    string public constant FEE_TYPE_SUBDOMAIN = "subdomain";

    // Error messages
    string public constant ERROR_NOT_AUTHORIZED = "Not authorized";
    string public constant ERROR_INVALID_TOKEN = "Invalid token";
    string public constant ERROR_ALREADY_EXISTS = "Already exists";
    string public constant ERROR_DOES_NOT_EXIST = "Does not exist";
    string public constant ERROR_INVALID_PARAMETER = "Invalid parameter";
    string public constant ERROR_INSUFFICIENT_PAYMENT = "Insufficient payment";
    string public constant ERROR_EXPIRED = "Expired";
    string public constant ERROR_PAUSED = "Contract paused";
}