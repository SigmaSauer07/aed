// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "../core/AEDCore.sol";

abstract contract AEDRecovery is AEDCore {
    using EnumerableSet for EnumerableSet.AddressSet;

    function addGuardian(uint256 id, address account) external {
        require(_isApprovedOrOwner(msg.sender, id), "Not owner");
        EnumerableSet.AddressSet storage g = guardians[id];
        require(g.add(account), "Already guardian");
    }

    function removeGuardian(uint256 id, address account) external {
        require(_isApprovedOrOwner(msg.sender, id), "Not owner");
        EnumerableSet.AddressSet storage g = guardians[id];
        require(g.remove(account), "Not guardian");
    }

    function getGuardians(uint256 id) external view returns (address[] memory) {
        return guardians[id].values();
    }
    function initiateRecovery(uint256 id) external {
        require(guardians[id].contains(msg.sender),"Not guardian");
        recoveryTimestamps[id] = block.timestamp + 3 days;
        emit RecoveryStarted(id);
    }
    function completeRecovery(uint256 id, address newOwner) external {
        require(guardians[id].contains(msg.sender),"Not guardian");
        require(block.timestamp >= recoveryTimestamps[id],"Timer");
        _transfer(ownerOf(id), newOwner, id);
    }
}
