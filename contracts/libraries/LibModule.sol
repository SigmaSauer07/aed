// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

library LibModule {
    function computeModuleId(string memory name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }
}
