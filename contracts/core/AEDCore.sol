// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./AEDConstants.sol";
import "./CoreState.sol";

    event DomainRegistered(uint256 indexed id, string full);
    event SubdomainCreated(uint256 indexed root, uint256 indexed sub, string full);
    event DomainUpdated(uint256 indexed id, string profileURI, string imageURI);
    event AEDCoreInitialized(address indexed initializer, string name, string symbol);

/**
 * @title AEDCore
 * @dev Core logic for AED, including domain storage and access control.
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
     * @dev Initializes the AEDCore contract.
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

        require(bytes(name_).length > 0, "Name cannot be empty");
        require(bytes(symbol_).length > 0, "Symbol cannot be empty");

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(BRIDGE_MANAGER, admin);
        _grantRole(FEE_MANAGER_ROLE, admin);
        _grantRole(TLD_MANAGER_ROLE, admin);

        nextTokenId = 1;
        royaltyBps = 500; // 5% default royalty
        feeCollector = admin;

        emit AEDCoreInitialized(msg.sender, name_, symbol_);
    }

    function _authorizeUpgrade(address) internal override(UUPSUpgradeable) {}

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved)
        internal override {
        super._setApprovalForAll(owner, operator, approved);
    }

    function _pause() internal whenNotPaused override(PausableUpgradeable) {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller does not have the required role");
        super._pause();
    }

    function _unpause() internal whenPaused override(PausableUpgradeable) {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller does not have the required role");
        super._unpause();
    }

    // Getter functions
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
    
    function _domain(uint256 tokenId) internal view override returns (Domain storage) {
        return domains[tokenId];
    }

    function ownerOf(uint256 tokenId) public view override(CoreState, ERC721Upgradeable) returns (address) {
        return ERC721Upgradeable.ownerOf(tokenId);
    }

    function hasRole(bytes32 role, address account) public view override(AccessControlUpgradeable, CoreState) returns (bool) {
        return AccessControlUpgradeable.hasRole(role, account);
    }

    function _exists(uint256 tokenId) internal view override(ERC721Upgradeable, CoreState) returns (bool) {
        return super._exists(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view override(CoreState, ERC721Upgradeable) returns (bool) {
        return super._isApprovedOrOwner(spender, tokenId);
    }

    // Storage gap for future upgrades
    uint256[50] private __gap;
}