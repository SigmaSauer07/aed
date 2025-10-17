// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../AEDImplementation.sol";

/// @title AEDImplementationV2Mock
/// @notice Lightweight mock used in tests to validate upgrade safety
contract AEDImplementationV2Mock is AEDImplementation {
    function version() external pure returns (string memory) {
        return "2.0";
    }
}
