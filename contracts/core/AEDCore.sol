// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
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
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC2981Upgradeable,
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
    ) internal onlyInitializing {
        __ERC721_init(name_, symbol_);
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        __ERC2981_init();
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        require(bytes(name_).length > 0, "Name cannot be empty");
        require(bytes(symbol_).length > 0, "Symbol cannot be empty");
        require(admin != address(0), "Admin cannot be zero address");

        // Grant all essential roles to the provided admin address
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(BRIDGE_MANAGER, admin);
        _grantRole(FEE_MANAGER_ROLE, admin);
        _grantRole(TLD_MANAGER_ROLE, admin);

        nextTokenId = 1;
        royaltyBps = 100;       // 1% default royalty (can be changed via setRoyaltyBps)
        feeCollector = admin;   // initial fee collector (can be changed via setFeeCollector)

        emit AEDCoreInitialized(admin, name_, symbol_);
    }

    /** @dev Authorization hook for UUPS proxy upgrades. Only accounts with UPGRADER_ROLE can upgrade. */
    function _authorizeUpgrade(address newImplementation) internal view override onlyRole(UPGRADER_ROLE) {
        require(newImplementation != address(0), "Invalid implementation");
        // (Versioning handled in main AED contract)
    }

    function supportsInterface(bytes4 interfaceId)
        public view 
        virtual 
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC721URIStorageUpgradeable, ERC2981Upgradeable, AccessControlUpgradeable)
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

    function paused() public view virtual override(PausableUpgradeable, CoreState) returns (bool) {
        return PausableUpgradeable.paused();
    }

    // Override CoreState's abstract functions using OpenZeppelin library logic
    function ownerOf(uint256 tokenId) public view virtual override(CoreState, ERC721Upgradeable, IERC721) returns (address) {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function hasRole(bytes32 role, address account) 
        public view virtual override(AccessControlUpgradeable, CoreState) 
        returns (bool) 
    {
        return AccessControlUpgradeable.hasRole(role, account);
    }

    function exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) 
        internal view virtual override(CoreState) 
        returns (bool) 
    {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }

    // Override functions with conflicts between parent contracts
    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._increaseBalance(account, value);
    }

    function _update(address to, uint256 tokenId, address auth) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) returns (address) {
        return super._update(to, tokenId, auth);
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721Upgradeable, ERC721URIStorageUpgradeable) returns (string memory) {
        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
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

    // ========== Admin functions ==========

    function setRoyaltyBps(uint256 _royaltyBps) external onlyRole(ADMIN_ROLE) {
        require(_royaltyBps <= 10000, "Royalty cannot exceed 100%");
        royaltyBps = _royaltyBps;
    }

    function setFeeCollector(address _feeCollector) external onlyRole(FEE_MANAGER_ROLE) {
        require(_feeCollector != address(0), "Fee collector cannot be zero address");
        feeCollector = _feeCollector;
    }

    // (Additional core logic like domain transfer hooks, etc., can be added as needed)

    uint256[50] private __gap;
}