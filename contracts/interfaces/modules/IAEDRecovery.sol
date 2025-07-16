// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IAEDRecovery {
    function addGuardian(uint256 tokenId, address guardian) external;
    function initiateRecovery(uint256 tokenId) external;
    function completeRecovery(uint256 tokenId, address newOwner) external;
}
