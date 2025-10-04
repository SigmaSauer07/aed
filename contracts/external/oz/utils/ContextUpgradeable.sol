// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "../proxy/utils/Initializable.sol";

/// @title ContextUpgradeable
/// @notice Provides information about the current execution context, mirroring OpenZeppelin behaviour.
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
