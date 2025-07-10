// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./AEDConstants.sol";
import "./CoreState.sol";

event DomainRegistered(uint256 indexed id, string fullName);
event SubdomainCreated(uint256 indexed rootId, uint256 indexed subId, string fullName);
event DomainUpdated(uint256 indexed id, string profileURI, string imageURI);
event AEDCoreInitialized(address indexed initializer, string name, string symbol);

/**
 * @title AEDCore
 * @dev Core logic for AED, including domain storage, base ERC721 and access control.
 * Inherits OpenZeppelin upgradeable contracts for proxy support.
 */
abstract contract AEDCore is 
    ERC721Upgradeable, 
    AccessControlUpgradeable, 
    PausableUpgradeable, 
    UUPSUpgradeable, 
    ReentrancyGuardUpgradeable, 
    AEDConstants, 
    CoreState {
        
    /**
     * @dev Initializes the core contract. Must be called only once (by the main initialize).
     */
    function __AEDCore_init(
        string memory name_,
        string memory symbol_,
        address admin
    ) external initializer {
        __ERC721_init(name_, symbol_);
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();  // Ensure reentrancy guard is initialized

        require(bytes(name_).length > 0, "Name cannot be empty");
        require(bytes(symbol_).length > 0, "Symbol cannot be empty");

        // Grant all essential roles to the provided admin address
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(BRIDGE_MANAGER, admin);
        _grantRole(FEE_MANAGER_ROLE, admin);
        _grantRole(TLD_MANAGER_ROLE, admin);

        nextTokenId = 1;
        royaltyBps = 500;       // 5% default royalty (can be changed via setRoyaltyBps)
        feeCollector = admin;   // initial fee collector (can be changed via setFeeCollector)

        emit AEDCoreInitialized(msg.sender, name_, symbol_);
    }

    /** @dev Authorization hook for UUPS proxy upgrades. Only accounts with UPGRADER_ROLE can upgrade. */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {
        require(newImplementation != address(0), "Invalid implementation");
        // (Versioning handled in main AED contract)
    }

    function supportsInterface(bytes4 interfaceId)
        public view 
        virtual 
        override(ERC721Upgradeable, AccessControlUpgradeable) 
        returns (bool) 
    {
        // Combine ERC721 and AccessControl interface support
        return super.supportsInterface(interfaceId);
    }

    // Override CoreState’s abstract functions using OpenZeppelin library logic
    function ownerOf(uint256 tokenId) public view virtual override(CoreState, ERC721Upgradeable) returns (address) {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function hasRole(bytes32 role, address account) 
        public view virtual override(AccessControlUpgradeable, CoreState) 
        returns (bool) 
    {
        return AccessControlUpgradeable.hasRole(role, account);
    }

    function _exists(uint256 tokenId) internal view virtual override(ERC721Upgradeable, CoreState) returns (bool) {
        return ERC721Upgradeable._exists(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) 
        internal view virtual override(CoreState, ERC721Upgradeable) 
        returns (bool) 
    {
        return ERC721Upgradeable._isApprovedOrOwner(spender, tokenId);
    }

    // Implementations for abstract CoreState helpers
    function _isApproved(address spender, uint256 tokenId) internal view virtual override(CoreState) returns (bool) {
        return getApproved(tokenId) == spender;
    }

    function _isApprovedForAll(address owner, address operator) 
        internal view virtual override(CoreState) returns (bool) 
    {
        return isApprovedForAll(owner, operator);
    }

    function _pause() internal virtual override(PausableUpgradeable) {
        // Only ADMIN_ROLE can pause/unpause (added security check)
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        super._pause();
    }
    function _unpause() internal virtual override(PausableUpgradeable) {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
        super._unpause();
    }

    // ========== Core domain read functions ==========

    function getDomain(uint256 id) external view returns (Domain memory) {
        return domains[id];
    }

    function isRegistered(string memory name, string memory tld) external view returns (bool) {
        return registered[keccak256(abi.encodePacked(name, tld))];
    }

    function getNextTokenId() external view returns (uint256) {
        return nextTokenId;
    }

    function getRoyaltyBps() external view returns (uint256) {
        return royaltyBps;
    }

    function getFeeCollector() external view returns (address) {
        return feeCollector;
    }

    // (Additional core logic like domain transfer hooks, etc., can be added as needed)

    uint256[50] private __gap;