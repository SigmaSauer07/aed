// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// OpenZeppelin Upgradeable Imports
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// AED Core and Modules
import "./core/AEDCore.sol";
import "./modules/AEDAdmin.sol";
import "./modules/AEDRegistry.sol";
import "./modules/AEDMinting.sol";
import "./modules/AEDBridge.sol";
import "./modules/AEDRecovery.sol";
import "./modules/AEDMetadata.sol";
import "./modules/AEDReverse.sol";
import "./core/AEDConstants.sol";

/**
 * @title AED
 * @dev Main contract for the Alsania Ecosystem Domains (AED) system.
 * Inherits all AED modules and OpenZeppelin upgradeable patterns.
 */
contract AED is
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    AEDCore,
    AEDAdmin,
    AEDRegistry,
    AEDMinting,
    AEDBridge,
    AEDRecovery,
    AEDMetadata,
    AEDReverse,
    AEDConstants
{
    // Versioning for upgrades
    uint256 public version;

    // Events
    event VersionUpgraded(uint256 newVersion);
    event Initialized(string name, string symbol, address feeCollector, address admin);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the AED contract and all inherited modules.
     * @dev Can only be called once. Uses OpenZeppelin's initializer modifier.
     * @param name_ The name of the ERC721 token.
     * @param symbol_ The symbol of the ERC721 token.
     * @param feeCollector_ Address to collect protocol fees.
     * @param admin Address with admin privileges.
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        address feeCollector_,
        address admin
    )
        public
        override(
            AEDCore,
            AEDAdmin,
            AEDRegistry,
            AEDMinting,
            AEDBridge,
            AEDRecovery,
            AEDMetadata,
            AEDReverse,
            AEDConstants,
            UUPSUpgradeable,
            ReentrancyGuardUpgradeable
        )
        initializer {

        require(admin != address(0), "Admin address cannot be zero");
        require(feeCollector_ != address(0), "Fee collector address cannot be zero");
        require(msg.sender == tx.origin, "Only EOA can initialize");

        // Initialize all modules and base contracts
        AEDCore.__AEDCore_init(name_, symbol_, admin);
        AEDAdmin.__AEDAdmin_init(feeCollector_);
        AEDRegistry.__AEDRegistry_init();
        AEDMinting.__AEDMinting_init();
        AEDBridge.__AEDBridge_init();
        AEDRecovery.__AEDRecovery_init();
        AEDMetadata.__AEDMetadata_init();
        AEDReverse.__AEDReverse_init();
        UUPSUpgradeable.__UUPSUpgradeable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        version = 1;

        emit VersionUpgraded(version);
        emit Initialized(name_, symbol_, feeCollector_, admin);
    }

    /**
     * @dev Authorizes contract upgrades. Only callable by UPGRADER_ROLE.
     * @param newImplementation Address of the new implementation contract.
     */
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(UPGRADER_ROLE)
    {
        require(newImplementation != address(0), "Invalid implementation");
        version += 1;
        emit VersionUpgraded(version);
    }

    /**
     * @notice Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(AEDCore, AEDMetadata, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // Storage gap for future upgrades
    uint256[50] private __gap;
}