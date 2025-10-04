// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {AEDImplementation} from "../AEDImplementation.sol";

contract AEDImplementationV2Mock is AEDImplementation {
    function version() external pure returns (string memory) {
        return "v2-mock";
    }
}
