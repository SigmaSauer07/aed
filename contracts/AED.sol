// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// OpenZeppelin upgradeable base contracts
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

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
 * @title AED (Alsania Enhanced Domains)
 * @dev The main contract that combines all modules into a single upgradeable ERC721 implementation.
 * Inherits from AEDCore and all AED modules. This is the contract to deploy and proxy.
 */
contract AED is 
    Initializable,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable,
    ERC721EnumerableUpgradeable,
    AccessControlUpgradeable,
    AEDCore,
    AEDAdmin,
    AEDRegistry,
    AEDMinting,
    AEDBridge,
    AEDRecovery,
    AEDMetadata,
    AEDReverse,
    AEDConstants {

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
     * @dev This function should be called via the proxy on deployment. Can only be called once.
     * Gas optimized by combining validations and using memory efficiently.
     * @param name_   The name of the ERC721 token collection (e.g., "Alsania Enhanced Domains").
     * @param symbol_ The ERC721 token symbol (e.g., "AED").
     * @param feeCollector_ Address to receive any protocol fees (initial fee collector).
     * @param admin Address to be granted admin roles (initial admin for AccessControl).
     */
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address feeCollector_,
        address admin
    ) public initializer {
        // Gas optimization: Combine multiple require statements with && to save gas
        require(
            admin != address(0) && 
            feeCollector_ != address(0) && 
            msg.sender == tx.origin,
            "Invalid initialization parameters"
        );

        // Initialize base and modules
        // Gas optimization: Initialize in a specific order to minimize storage operations
        AEDCore.__AEDCore_init(name_, symbol_, admin);
        AEDAdmin.__AEDAdmin_init(feeCollector_);
        
        // Gas optimization: Group similar initializations together
        AEDRegistry.__AEDRegistry_init();
        AEDMinting.__AEDMinting_init();
        AEDBridge.__AEDBridge_init();
        
        // Set recovery defaults: e.g., max 3 guardians, threshold 2
        AEDRecovery.__AEDRecovery_init(3, 2);
        AEDMetadata.__AEDMetadata_init();
        AEDReverse.__AEDReverse_init();
        
        // Gas optimization: Group OpenZeppelin initializations
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        __ReentrancyGuard_init();

        // Gas optimization: Set version and emit events at the end
        version = 1;
        
        // Gas optimization: Emit events at the end to avoid potential storage operations in between
        emit VersionUpgraded(version);
        emit Initialized(name_, symbol_, feeCollector_, admin);
    }

    /**
     * @dev Authorizes contract upgrades (UUPS). Only callable by accounts with UPGRADER_ROLE.
     * Gas optimized by using a single storage operation.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {
        require(newImplementation != address(0), "Invalid implementation");
        
        // Gas optimization: Increment version in a single operation and emit event
        unchecked {
            // Gas optimization: Use unchecked for version increment since overflow is extremely unlikely
            emit VersionUpgraded(++version);
        }
    }

    /**
     * @notice Override of supportsInterface to aggregate all module and base interfaces, including ERC2981.
     * @dev Gas optimized by using a constant for the interface ID
     */
    // Gas optimization: Define constant for ERC2981 interface ID to avoid recalculating it
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    
    function supportsInterface(bytes4 interfaceId)
        public view 
        override(AEDCore, AccessControlUpgradeable)
        returns (bool) 
    {
        // Gas optimization: Use constant for interface ID comparison
        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }

    /**
     * @notice Override to resolve conflict between AEDAdmin and AEDMinting for updateSubdomainSettings.
     * Syncs the admin config and minting config for subdomain settings.
     * @dev Gas optimized by using a single emit and minimizing storage operations
     */
    function updateSubdomainSettings(uint256 newMax, uint256 newBasePrice, uint256 newMultiplier)
        public override(AEDAdmin, AEDMinting) onlyRole(ADMIN_ROLE)
    {
        require(newMax > 0, "Max subdomains must be > 0");
        
        // Gas optimization: Update both Admin and Minting storages in a single function
        // to avoid duplicate storage operations and reduce gas costs
        
        // Update Admin storage
        _admin.maxSubdomains = newMax;
        _admin.basePrice = newBasePrice;
        _admin.multiplier = newMultiplier;
        
        // Update Minting storage
        subdomainMaxLimit = newMax;
        subdomainBasePrice = newBasePrice;
        subdomainPriceMultiplier = newMultiplier;
        
        // Single event emission saves gas
        emit SubdomainSettingsUpdated(newMax, newBasePrice, newMultiplier);
    }

    // Note: Functions from modules that have identical signatures and are not overridden here (if any) 
    // would use the first-in-line base implementation. The updateSubdomainSettings is explicitly handled above.
    // Other functions like withdrawStuckETH (only in AEDAdmin) or setFeature (only in AEDRegistry) are unique.

    // Placeholder for future variables without affecting existing storage layout
    uint256[50] private __gap;
}