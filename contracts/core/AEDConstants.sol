// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/**
 * @title AEDConstants
 * @dev Centralized constants for the AED system.
 * Contains role identifiers and feature flags used across modules.
 */
abstract contract AEDConstants {
    // ============ ROLES ============
    bytes32 public constant ADMIN_ROLE           = keccak256("ADMIN_ROLE");
    bytes32 public constant UPGRADER_ROLE        = keccak256("UPGRADER_ROLE");
    bytes32 public constant BRIDGE_MANAGER       = keccak256("BRIDGE_MANAGER");
    bytes32 public constant FEE_MANAGER_ROLE     = keccak256("FEE_MANAGER_ROLE");
    bytes32 public constant TLD_MANAGER_ROLE     = keccak256("TLD_MANAGER_ROLE");
    bytes32 public constant DOMAIN_MANAGER       = keccak256("DOMAIN_MANAGER");
    bytes32 public constant PROFILE_MANAGER      = keccak256("PROFILE_MANAGER");
    bytes32 public constant RECOVERY_MANAGER     = keccak256("RECOVERY_MANAGER");
    bytes32 public constant ENHANCEMENT_MANAGER  = keccak256("ENHANCEMENT_MANAGER");
    bytes32 public constant FEE_COLLECTOR_ROLE   = keccak256("FEE_COLLECTOR_ROLE");

    // ============ FEATURE FLAGS ============ 
    uint8 public constant FEATURE_PROFILE    = 0x01;
    uint8 public constant FEATURE_REVERSE    = 0x02;
    uint8 public constant FEATURE_SUBDOMAINS = 0x04;
    uint8 public constant FEATURE_BRIDGE     = 0x08;
    uint8 public constant FEATURE_RECOVERY   = 0x10;
    uint8 public constant FEATURE_METADATA   = 0x20;
    uint8 public constant FEATURE_ALL        = FEATURE_PROFILE | FEATURE_REVERSE | 
                                               FEATURE_SUBDOMAINS | FEATURE_BRIDGE | 
                                               FEATURE_RECOVERY | FEATURE_METADATA;

    // ============ PRICING CONSTANTS ============
    uint256 public constant DEFAULT_ROYALTY_BPS = 100;   // 1%
    uint256 public constant MAX_ROYALTY_BPS     = 1000;  // 10%

    // ============ LIMITS ============
    uint256 public constant DEFAULT_MAX_SUBDOMAINS = 20;
    uint256 public constant MIN_NAME_LENGTH       = 1;
    uint256 public constant MAX_NAME_LENGTH       = 64;
    uint256 public constant MAX_URI_LENGTH        = 256;

    // ============ VISUAL CONSTANTS ============
    string public constant NEON_GREEN = "#39FF14";
    string public constant DOMAIN_BG  = "https://gateway.pinata.cloud/ipfs/.../domain_background.png";
    string public constant SUB_BG     = "https://gateway.pinata.cloud/ipfs/.../subdomain_background.png";

    // ============ FREE TLDs ============
    bytes32 public constant FREE_TLD_AED  = keccak256("aed");
    bytes32 public constant FREE_TLD_ALSA = keccak256("alsa");
    bytes32 public constant FREE_TLD_07   = keccak256("07");
}

// Tracks which modules are active per domain (used in Registry)
enum AEDModule { Core, Minting, Recovery, Registry, Metadata, Bridge, Reverse }
