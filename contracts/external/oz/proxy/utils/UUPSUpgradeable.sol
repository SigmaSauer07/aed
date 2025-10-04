// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "./Initializable.sol";
import {ERC1967UpgradeUpgradeable} from "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import {AddressUpgradeable} from "../../utils/AddressUpgradeable.sol";

abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init();
    }

    modifier onlyProxy() {
        require(address(this) != _getImplementation(), "UUPS: must be called through proxy");
        require(_getImplementation() == _self(), "UUPS: active proxy required");
        _;
    }

    modifier notDelegated() {
        require(address(this) == _self(), "UUPS: must not be delegatecall");
        _;
    }

    function upgradeTo(address newImplementation) external onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeTo(newImplementation);
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCall(newImplementation, data, data.length > 0);
    }

    function proxiableUUID() external view notDelegated returns (bytes32) {
        return keccak256("eip1967.proxy.implementation");
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;

    function _self() private view returns (address) {
        return address(this);
    }
}
