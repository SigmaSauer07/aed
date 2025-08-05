// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";

/**
 * @title LibAppStorage
 * @dev Library for accessing the centralized AppStorage
 */
library LibAppStorage {
    bytes32 constant STORAGE_POSITION = keccak256("aed.app.storage");
    
    function appStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}