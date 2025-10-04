// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../AEDImplementation.sol";

/// @dev Simple upgrade target used in tests to prove upgradeability.
contract AEDImplementationV2 is AEDImplementation {
    function version() external pure returns (string memory) {
        return "v2";
    }
}
