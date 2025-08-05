// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AppStorage.sol";

/// @title LibAppStorage
/// @notice Provides typed access to the shared AppStorage struct used across all AED contracts.
/// @dev Uses a fixed storage slot as recommended by EIP-2535 / Diamond Storage pattern.
library LibAppStorage {
    // keccak256("aed.app.storage") - chosen to avoid collisions
    bytes32 internal constant STORAGE_POSITION = keccak256("aed.app.storage");

    /// @return s - pointer to AppStorage located at the predefined slot
    function appStorage() internal pure returns (AppStorage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}