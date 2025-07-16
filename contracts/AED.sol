// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "./core/AEDCore.sol";
import "./core/AEDConstants.sol";
import "./modules/admin/AEDAdmin.sol";
import "./modules/registry/AEDRegistry.sol";
import "./modules/minting/AEDMinting.sol";
import "./modules/metadata/AEDMetadata.sol";
import "./modules/reverse/AEDReverse.sol";
import "./modules/enhancements/AEDEnhancements.sol";
import "./modules/recovery/AEDRecovery.sol";

/// @title AED Main Proxy Contract (Alsania Enhanced Domains)
/// @dev UUPS proxy entry point that initializes and wires all modules
contract AED is
    Initializable,
    UUPSUpgradeable,
    AEDCore,
    AEDAdmin,
    AEDRegistry,
    AEDMinting,
    AEDMetadata,
    AEDReverse,
    AEDEnhancements,
    AEDRecovery,
    AEDConstants
{
    uint256 public version;

    event Initialized(string name, string symbol, address admin);
    event VersionUpgraded(uint256 newVersion);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin
    ) public initializer {
        require(admin != address(0), "Admin address cannot be zero");

        __AEDCore_init(name_, symbol_, admin);
        __AEDAdmin_init();
        __AEDRegistry_init();
        __AEDMinting_init();
        __AEDMetadata_init();
        __AEDReverse_init();
        __AEDEnhancements_init();
        __AEDRecovery_init(3, 2); // default maxGuardians: 3, approvalThreshold: 2

        version = 1;
        emit Initialized(name_, symbol_, admin);
    }

    function _authorizeUpgrade(address newImpl) internal view override onlyRole(UPGRADER_ROLE) {}
}